package Net::Async::WebSearch;
# ABSTRACT: IO::Async multi-provider web search aggregator
use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Carp qw( croak );
use Future ();
use Future::Utils qw( fmap_void );
use HTTP::Request::Common qw( GET );
use Net::Async::HTTP ();
use URI ();

use Net::Async::WebSearch::Provider ();
use Net::Async::WebSearch::Result ();

our $VERSION = '0.002';

# Reciprocal Rank Fusion constant (Cormack et al.)
our $RRF_K = 60;

sub _init {
  my ( $self, $args ) = @_;
  $self->SUPER::_init($args);
  $self->{providers} = [];
  $self->{http}      = delete $args->{http};
  $self->{rrf_k}     = delete $args->{rrf_k} // $RRF_K;
  $self->{default_limit} = delete $args->{default_limit} // 10;
  $self->{per_provider_limit} = delete $args->{per_provider_limit} // 10;
  $self->{fetch_concurrency} = delete $args->{fetch_concurrency} // 100;
  $self->{fetch_concurrency_per_target_ip}
    = delete $args->{fetch_concurrency_per_target_ip} // 5;
  $self->{fetch_timeout}     = delete $args->{fetch_timeout};
  $self->{fetch_max_bytes}   = delete $args->{fetch_max_bytes};
  $self->{fetch_user_agent}  = delete $args->{fetch_user_agent};
  if ( my $provs = delete $args->{providers} ) {
    $self->add_provider($_) for @$provs;
  }
  return;
}

sub configure_unknown {
  my ( $self, %args ) = @_;
  for my $k (qw(
    http rrf_k default_limit per_provider_limit providers
    fetch_concurrency fetch_concurrency_per_target_ip
    fetch_timeout fetch_max_bytes fetch_user_agent
  )) {
    delete $args{$k};
  }
  return unless %args;
  croak "Unknown configuration keys: ".join(',', sort keys %args);
}

sub providers         { @{ $_[0]->{providers} } }
sub rrf_k             { @_ > 1 ? ($_[0]->{rrf_k} = $_[1]) : $_[0]->{rrf_k} }
sub default_limit     { @_ > 1 ? ($_[0]->{default_limit} = $_[1]) : $_[0]->{default_limit} }
sub per_provider_limit{ @_ > 1 ? ($_[0]->{per_provider_limit} = $_[1]) : $_[0]->{per_provider_limit} }

sub add_provider {
  my ( $self, $p ) = @_;
  croak "provider must be a Net::Async::WebSearch::Provider"
    unless ref $p && $p->isa('Net::Async::WebSearch::Provider');
  my %taken = map { $_->name => 1 } @{ $self->{providers} };
  if ( $taken{ $p->name } ) {
    my $base = $p->name;
    my $n    = 2;
    $n++ while $taken{ "$base#$n" };
    $p->name( "$base#$n" );
  }
  push @{ $self->{providers} }, $p;
  return $p;
}

sub provider {
  my ( $self, $name ) = @_;
  for my $p ( @{ $self->{providers} } ) {
    return $p if $p->name eq $name;
  }
  return;
}

sub providers_matching {
  my ( $self, $sel ) = @_;
  return grep { $_->matches($sel) } @{ $self->{providers} };
}

sub http {
  my ( $self ) = @_;
  return $self->{http} if $self->{http};
  my $http = Net::Async::HTTP->new(
    user_agent => 'Net-Async-WebSearch/'.$VERSION,
    max_connections_per_host => $self->{fetch_concurrency_per_target_ip} // 5,
    max_in_flight => 0,
  );
  $self->add_child($http);
  return $self->{http} = $http;
}

sub _on_added_to_loop {
  my ( $self, $loop ) = @_;
  $self->SUPER::_on_added_to_loop($loop) if $self->can('SUPER::_on_added_to_loop');
  $self->http;
}

#----------------------------------------------------------------------
# Provider selection
#----------------------------------------------------------------------

sub _select_providers {
  my ( $self, %args ) = @_;
  my $only    = $args{only};
  my $exclude = $args{exclude};
  my @sel;
  for my $p ( @{ $self->{providers} } ) {
    next unless $p->enabled;
    if ( $only && @$only ) {
      next unless grep { $p->matches($_) } @$only;
    }
    if ( $exclude && @$exclude ) {
      next if grep { $p->matches($_) } @$exclude;
    }
    push @sel, $p;
  }
  return @sel;
}

#----------------------------------------------------------------------
# URL normalization for dedup
#----------------------------------------------------------------------

sub _normalize_url {
  my ( $self, $url ) = @_;
  return '' unless defined $url && length $url;
  my $u = eval { URI->new($url)->canonical } or return lc $url;
  my $s = $u->as_string;
  $s =~ s{#.*$}{};
  $s =~ s{/+$}{};
  return lc $s;
}

#----------------------------------------------------------------------
# Fetch (optional page-body retrieval after search)
#----------------------------------------------------------------------

sub _fetch_one {
  my ( $self, $result, %args ) = @_;
  my $url = $result->url;
  return Future->done unless defined $url && length $url;
  my $req = GET($url);
  $req->header( 'User-Agent' => $args{user_agent} // $self->{fetch_user_agent}
                                                  // 'Net-Async-WebSearch/'.$VERSION );
  $req->header( 'Accept'     => $args{accept}     // '*/*' );

  my %req_args = ( request => $req );
  if ( defined $args{timeout} ) {
    $req_args{timeout} = $args{timeout};
  }
  # NB: max_bytes is enforced on the decoded body below — Net::Async::HTTP
  # does not cap the on-the-wire body length itself.

  return $self->http->do_request(%req_args)->then(sub {
    my ( $resp ) = @_;
    my $ct      = $resp->header('Content-Type');
    my $charset = ( $ct && $ct =~ /charset=([^\s;]+)/ ) ? lc $1 : undef;
    my $body    = eval { $resp->decoded_content };
    $body = $resp->content if !defined $body;
    if ( defined $args{max_bytes} && defined $body && length($body) > $args{max_bytes} ) {
      $body = substr($body, 0, $args{max_bytes});
    }
    $result->fetched({
      ok           => $resp->is_success ? 1 : 0,
      status       => $resp->code,
      status_line  => $resp->status_line,
      final_url    => ( $resp->request ? $resp->request->uri.'' : $url ),
      content_type => $ct,
      charset      => $charset,
      body         => $body,
      error        => $resp->is_success ? undef : $resp->status_line,
    });
    Future->done;
  })->else(sub {
    my ( $err ) = @_;
    $result->fetched({
      ok           => 0,
      status       => undef,
      status_line  => undef,
      final_url    => $url,
      content_type => undef,
      charset      => undef,
      body         => undef,
      error        => "$err",
    });
    Future->done;
  });
}

sub _fetch_results {
  my ( $self, $results_ref, %args ) = @_;
  my $n = $args{fetch} or return Future->done($results_ref);
  return Future->done($results_ref) unless $results_ref && @$results_ref;
  my $cap = $n < @$results_ref ? $n : scalar @$results_ref;
  my @targets = @{$results_ref}[ 0 .. $cap - 1 ];
  my $conc = $args{fetch_concurrency} // $self->{fetch_concurrency} // 100;
  my %fargs = (
    timeout    => $args{fetch_timeout}    // $self->{fetch_timeout},
    max_bytes  => $args{fetch_max_bytes}  // $self->{fetch_max_bytes},
    user_agent => $args{fetch_user_agent} // $self->{fetch_user_agent},
    accept     => $args{fetch_accept},
  );
  my $on_fetch = $args{on_fetch};
  return fmap_void(
    sub {
      my $r = shift;
      $self->_fetch_one($r, %fargs)->on_done(sub {
        $on_fetch->($r) if $on_fetch;
      });
    },
    foreach     => \@targets,
    concurrent  => $conc,
  )->then(sub { Future->done($results_ref) });
}

#----------------------------------------------------------------------
# Core dispatch
#----------------------------------------------------------------------

sub _dispatch {
  my ( $self, %args ) = @_;
  my $query = $args{query};
  croak "search requires 'query'" unless defined $query && length $query;

  my @providers = $self->_select_providers( only => $args{only}, exclude => $args{exclude} );
  return ( [], [] ) unless @providers;

  my %base = (
    limit      => $args{per_provider_limit} // $self->per_provider_limit,
    language   => $args{language},
    region     => $args{region},
    safesearch => $args{safesearch},
  );

  my $popts = $args{provider_opts} || {};
  my @futures;
  for my $p (@providers) {
    my %merged = %base;
    # Apply provider_opts in insertion order: class-leaf / tag first,
    # exact name last so it wins.
    for my $sel ( sort { ($a eq $p->name) <=> ($b eq $p->name) } keys %$popts ) {
      next unless $p->matches($sel);
      %merged = ( %merged, %{ $popts->{$sel} } );
    }
    push @futures, {
      provider => $p,
      future   => $p->search( $self->http, $query, \%merged ),
    };
  }
  return ( \@providers, \@futures );
}

#----------------------------------------------------------------------
# Mode: collect
#----------------------------------------------------------------------

sub search {
  my ( $self, %args ) = @_;
  $args{mode} ||= 'collect';
  return $self->search_stream(%args) if $args{mode} eq 'stream';
  return $self->search_race(%args)   if $args{mode} eq 'race';

  my ( $provs, $futs ) = $self->_dispatch(%args);
  return Future->done({ results => [], errors => [], stats => { providers => 0 } })
    unless $futs && @$futs;

  my $limit = $args{limit} // $self->default_limit;
  my $k     = $self->rrf_k;

  my @wrapped = map {
    my $name = $_->{provider}->name;
    $_->{future}->else(sub {
      my @err = @_;
      Future->done({ __error => 1, provider => $name, error => $err[0] });
    });
  } @$futs;

  return Future->needs_all(@wrapped)->then(sub {
    my @per_provider = @_;
    my @errors;
    my %agg;       # normalized_url => { result => $first, score => $n, providers => {p=>rank,...} }
    for my $payload (@per_provider) {
      if ( ref $payload eq 'HASH' && $payload->{__error} ) {
        push @errors, { provider => $payload->{provider}, error => $payload->{error} };
        next;
      }
      for my $r ( @{ $payload || [] } ) {
        my $key = $self->_normalize_url( $r->url );
        next unless length $key;
        my $slot = $agg{$key} ||= { result => $r, score => 0, providers => {} };
        $slot->{providers}{ $r->provider } = $r->rank;
        $slot->{score} += 1 / ( $k + $r->rank );
        # Prefer a result that has a snippet, if the first had none.
        if ( !$slot->{result}->snippet && $r->snippet ) {
          $slot->{result} = $r;
        }
      }
    }
    my @merged =
      map {
        my $s = $_;
        $s->{result}->score( $s->{score} );
        $s->{result}->extra->{providers} = { %{ $s->{providers} } };
        $s->{result};
      }
      sort { $b->{score} <=> $a->{score} }
      values %agg;

    @merged = splice @merged, 0, $limit if @merged > $limit;

    my $final = {
      results => \@merged,
      errors  => \@errors,
      stats   => {
        providers       => scalar @$provs,
        providers_ok    => ( scalar @$provs ) - scalar @errors,
        providers_error => scalar @errors,
        merged          => scalar @merged,
      },
    };

    if ( $args{fetch} ) {
      return $self->_fetch_results(\@merged, %args)->then(sub {
        $final->{stats}{fetched} = scalar grep { $_->fetched } @merged;
        Future->done($final);
      });
    }
    return Future->done($final);
  });
}

#----------------------------------------------------------------------
# Mode: stream — fire on_result per result as soon as each provider arrives
#----------------------------------------------------------------------

sub search_stream {
  my ( $self, %args ) = @_;
  my $cb = $args{on_result} or croak "stream mode requires 'on_result' coderef";
  my $on_provider_done  = $args{on_provider_done};
  my $on_provider_error = $args{on_provider_error};
  my $on_fetch          = $args{on_fetch};

  my ( $provs, $futs ) = $self->_dispatch(%args);
  return Future->done({ results => [], errors => [], stats => { providers => 0 } })
    unless $futs && @$futs;

  my @all;
  my @errors;
  my $seen_key = {};

  my $fetch_cap      = $args{fetch} // 0;
  my $fetch_started  = 0;
  my @fetch_futures;
  my %fargs = (
    timeout    => $args{fetch_timeout}    // $self->{fetch_timeout},
    max_bytes  => $args{fetch_max_bytes}  // $self->{fetch_max_bytes},
    user_agent => $args{fetch_user_agent} // $self->{fetch_user_agent},
    accept     => $args{fetch_accept},
  );

  my @wrapped;
  for my $entry (@$futs) {
    my $name = $entry->{provider}->name;
    my $f = $entry->{future}->then(sub {
      my ( $results ) = @_;
      for my $r (@$results) {
        my $key = $self->_normalize_url( $r->url );
        next unless length $key;
        next if $seen_key->{$key}++;
        push @all, $r;
        $cb->($r);
        if ( $fetch_cap && $fetch_started < $fetch_cap ) {
          $fetch_started++;
          push @fetch_futures, $self->_fetch_one($r, %fargs)->on_done(sub {
            $on_fetch->($r) if $on_fetch;
          });
        }
      }
      $on_provider_done->( $name, $results ) if $on_provider_done;
      Future->done;
    })->else(sub {
      my ( $err ) = @_;
      push @errors, { provider => $name, error => $err };
      $on_provider_error->( $name, $err ) if $on_provider_error;
      Future->done;
    });
    push @wrapped, $f;
  }

  return Future->needs_all(@wrapped)->then(sub {
    # Wait for any pending fetches the stream kicked off.
    return @fetch_futures
      ? Future->needs_all(@fetch_futures)
      : Future->done;
  })->then(sub {
    Future->done({
      results => \@all,
      errors  => \@errors,
      stats   => {
        providers       => scalar @$provs,
        providers_ok    => ( scalar @$provs ) - scalar @errors,
        providers_error => scalar @errors,
        emitted         => scalar @all,
        ( $fetch_cap ? ( fetched => scalar grep { $_->fetched } @all ) : () ),
      },
    });
  });
}

#----------------------------------------------------------------------
# Mode: race — resolve with whichever provider comes back first (non-error)
#----------------------------------------------------------------------

sub search_race {
  my ( $self, %args ) = @_;
  my ( $provs, $futs ) = $self->_dispatch(%args);
  return Future->done({ results => [], errors => [], stats => { providers => 0 } })
    unless $futs && @$futs;

  my $limit = $args{limit} // $self->default_limit;

  # Wrap each so we can distinguish "first success" from "first completion".
  my $winner = Future->new;
  my @errors;
  my @remaining = map {
    my $name = $_->{provider}->name;
    my $f = $_->{future};
    $f->on_done(sub {
      my ( $results ) = @_;
      return if $winner->is_ready;
      my @top = @$results;
      @top = splice @top, 0, $limit if @top > $limit;
      $winner->done({
        provider => $name,
        results  => \@top,
        errors   => \@errors,
        stats    => {
          providers      => scalar @$provs,
          winning        => $name,
        },
      });
    });
    $f->on_fail(sub {
      my ( $err ) = @_;
      push @errors, { provider => $name, error => $err };
    });
    $f;
  } @$futs;

  # If everyone fails, resolve with errors.
  Future->wait_all(@remaining)->on_done(sub {
    return if $winner->is_ready;
    $winner->done({
      provider => undef,
      results  => [],
      errors   => \@errors,
      stats    => {
        providers       => scalar @$provs,
        providers_error => scalar @errors,
      },
    });
  });

  return $winner unless $args{fetch};
  return $winner->then(sub {
    my ( $out ) = @_;
    return Future->done($out) unless @{ $out->{results} };
    $self->_fetch_results( $out->{results}, %args )->then(sub {
      $out->{stats}{fetched} = scalar grep { $_->fetched } @{ $out->{results} };
      Future->done($out);
    });
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::WebSearch - IO::Async multi-provider web search aggregator

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use IO::Async::Loop;
  use Net::Async::WebSearch;
  use Net::Async::WebSearch::Provider::DuckDuckGo;
  use Net::Async::WebSearch::Provider::SearxNG;
  use Net::Async::WebSearch::Provider::Serper;

  my $loop = IO::Async::Loop->new;
  my $ws = Net::Async::WebSearch->new(
    providers => [
      Net::Async::WebSearch::Provider::DuckDuckGo->new(
        tags => ['free'],
      ),
      Net::Async::WebSearch::Provider::SearxNG->new(
        endpoint => 'https://searxng.example.org',
        tags     => ['free', 'private'],
      ),
      Net::Async::WebSearch::Provider::Serper->new(
        api_key => $ENV{SERPER_API_KEY},
        tags    => ['paid'],
      ),
    ],
  );
  $loop->add($ws);

  # Collect mode: fan out, dedup by URL, rank by Reciprocal Rank Fusion.
  my $out = $ws->search(
    query   => 'handyintelligence AI consulting',
    limit   => 20,
    exclude => ['paid'],    # skip Serper (and any other 'paid' provider)
  )->get;
  # $out->{results}  — arrayref of Net::Async::WebSearch::Result, ranked
  # $out->{errors}   — [{ provider, error }, ...]
  # $out->{stats}    — { providers, providers_ok, providers_error, merged }

  # Stream mode: per-result callback as soon as each provider finishes.
  $ws->search_stream(
    query     => 'handy intelligence local AI infrastructure',
    on_result => sub { my $r = shift; say $r->title, ' — ', $r->url },
    on_provider_done  => sub { my ($name, $results) = @_; ... },
    on_provider_error => sub { my ($name, $err)     = @_; ... },
  )->get;

  # Race mode: resolve with whichever provider returns first.
  my $fast = $ws->search( query => 'handyintelligence', mode => 'race', only => ['free'] )->get;
  # $fast->{provider} — name of winning provider

=head1 DESCRIPTION

L<IO::Async>-based aggregator that fans a single query out to multiple web
search providers in parallel and combines their results. Each provider is an
instance of L<Net::Async::WebSearch::Provider>; they all share the same
L<Net::Async::HTTP> client parented to this notifier.

Three modes:

=over 4

=item * C<collect> (default) — wait for every selected provider, dedup results
by normalized URL, score with Reciprocal Rank Fusion (RRF), return the top
C<limit> ranked list plus a per-provider error list.

=item * C<stream> — fire the C<on_result> coderef as soon as each provider's
results arrive, in provider-finish order. Deduplicated — the first provider to
surface a given URL wins. Returns a Future that resolves once all providers
have settled.

=item * C<race> — resolve with the first provider to return successfully. Good
for latency-sensitive UIs that just want I<something>.

=back

Provider selection per call via C<only =E<gt> [...]> (allow-list) or
C<exclude =E<gt> [...]> (deny-list). Disabled providers (C<< $p->enabled(0) >>)
are skipped regardless.

=head1 GETTING API KEYS

Quick reference for every built-in provider — where to sign up, how
much it costs, and whether you need a credit card to start. Prices
and free-tier allowances are as of early 2026 — upstream can move
the goalposts at any time, so verify before you plan your quota.

=over 4

=item * B<DuckDuckGo> — L<https://duckduckgo.com/>

No key, no sign-up. The provider scrapes the no-JS HTML endpoint
C<html.duckduckgo.com>. Free and unlimited but B<inherently fragile> —
DDG can change the markup, and they rate-limit aggressively if you
hammer them. Don't build a crawler on top.

=item * B<SearxNG> — self-hosted, L<https://docs.searxng.org/>

Free, but you run it. The trick people trip on: the default
C<settings.yml> doesn't enable the JSON format. See
F<ex/docker-compose.searxng.yml> and F<ex/searxng/settings.yml> in
this distribution for a working config. Public instances also exist
(L<https://searx.space>) but most block automated JSON queries.

=item * B<Brave Search> — L<https://brave.com/search/api/>

Brave restructured pricing — there is no more "2000 free queries a
month" tier. You now get C<$5 in free credits every month>, automatically
applied. At the Search plan rate of C<$5 / 1000 requests> that's about
1000 queries/month. B<You must pick a plan on signup even to use the
free credits>, and B<a credit card is required> as an anti-fraud check
(not charged while you stay within the credit allowance). API key is
minted at L<https://api.search.brave.com/app/dashboard>.

=item * B<Serper.dev> — L<https://serper.dev>

Best free-tier deal of the paid providers: B<2500 free queries on
signup, no credit card required>. After that, paid plans in the
~$1 / 1000 range. Google results behind a proxy, very fast. Sign up
on the homepage; the API key is shown in the dashboard afterward
(there is no standalone C</api-key> URL).

=item * B<Google Programmable Search> (Custom Search JSON API) —
L<https://programmablesearchengine.google.com>

Two things to set up and both are free at low volume:

=over 4

=item 1. Create a Programmable Search Engine at the URL above. That
gives you the C<cx> value ("Search engine ID"). By default the PSE
is scoped to specific sites you list — to get full web results, open
I<Search features> for that engine and turn B<Search the entire web>
on. (Google has been steadily burying this toggle but it's still
there.)

=item 2. Enable the Custom Search API in a Google Cloud project
(L<https://console.cloud.google.com/apis/library/customsearch.googleapis.com>)
and create an API key under I<Credentials>. No credit card needed at
the free tier.

=back

Quota: 100 free queries/day. Paid: $5 / 1000, capped at 10,000/day.
Results per call capped at 10.

=item * B<Yandex Search API>

=over 4

=item Signup:  L<https://console.yandex.cloud/link/search-api/>

=item Docs:    L<https://yandex.cloud/en/docs/search-api/>

=back

Requires a Yandex Cloud account and a "folder" (their project-scope
concept — the folder id is your C<folderid>). Pricing is via Yandex
Cloud credits; a free trial exists via the standard Cloud welcome
credits. API key: create a service account in the Cloud Console,
grant it the C<search-api.executor> role, then generate an API key
(C<apikey>) or IAM token — that's your C<api_key>.

=item * B<Reddit> (public JSON) — no key

Works out of the box but rate-limited aggressively with generic UAs.
Fine for low-volume use; for anything serious use OAuth (below).

=item * B<Reddit OAuth> — L<https://www.reddit.com/prefs/apps>

Free. You need a Reddit account and a working User-Agent string
(Reddit insists on the form C<< app/1.0 by /u/yourname >>). At the
bottom of L<https://www.reddit.com/prefs/apps> click I<create app>,
pick type B<script> (for C<client_credentials>/C<password>) or
B<installed> (for C<installed>) or B<web> (for the full
C<authorization_code> consent flow). The short string under the app
name is C<client_id>; C<secret> is shown once on creation. Rate limit
is 100 QPM per OAuth identity. See
L<Net::Async::WebSearch::Provider::Reddit::OAuth/SETUP> for the full
walkthrough.

=back

Summary table:

  Provider         Free tier                        CC?   Key source
  ---------------- -------------------------------- ---- --------------------------------------
  DuckDuckGo       unlimited (HTML scrape)          no   (no key)
  SearxNG          self-hosted, unlimited           no   (self-host; see ex/docker-compose.*)
  Brave            $5/month credits (~1000 q)       yes  api.search.brave.com/app/dashboard
  Serper           2500 / signup                    no   serper.dev (dashboard after signup)
  Google CSE       100 / day                        no   Cloud Console + programmablesearchengine.google.com
  Yandex           Cloud trial credits              no   console.yandex.cloud/link/search-api/
  Reddit           keyless (rate-limited)           no   (no key)
  Reddit OAuth     100 QPM per client_id            no   reddit.com/prefs/apps

=head2 Fetching result bodies

Pass C<fetch =E<gt> N> to any of the search modes to additionally GET the top
N result URLs and attach the response to each C<Result> under C<< $r->fetched >>
(see L<Net::Async::WebSearch::Result/fetched> for the hash shape). You still
get the full search result list — fetch is I<additive>.

Semantics per mode:

=over 4

=item * C<collect> — fetches the top C<N> URLs I<after> RRF dedup/ranking, so
every URL is hit at most once no matter how many providers surfaced it.

=item * C<stream> — fetches the first C<N> unique URLs in arrival order, kicked
off the moment C<on_result> fires for each. An optional C<on_fetch> coderef
fires per result once its fetch settles. The outer Future resolves after every
search I<and> every fetch is done.

=item * C<race> — fetches the top C<N> of the winning provider's list.

=back

Knobs (constructor defaults, all overridable per call):

=over 4

=item * C<fetch_concurrency> — global cap on parallel in-flight fetches
(default 100). In C<collect>/C<race> this is the C<concurrent> arg to
L<Future::Utils/fmap_void>. In C<stream> it's the ceiling for fetches queued
on result arrival.

=item * C<fetch_concurrency_per_target_ip> — per-host cap (default 5). Wired
to L<Net::Async::HTTP>'s C<max_connections_per_host> on the shared HTTP
client. Keeps you from hammering a single origin even when the global pool
has headroom. Currently this is B<per-hostname>, not per-resolved-IP;
different names pointing at the same CDN edge are counted separately.

=item * C<fetch_timeout> — seconds per request, passed straight to
L<Net::Async::HTTP>.

=item * C<fetch_max_bytes> — truncate the response body to this many bytes.

=item * C<fetch_user_agent> — User-Agent for fetch requests. Default is the
library's own UA; set it to something representative if you care about
politeness.

=item * C<fetch_accept> — per-call Accept header (e.g. C<text/html>).

=back

This feature is deliberately separate from the provider plumbing — providers
hand back search results only. Fetching is for use-cases like RAG, crawling,
and summarization where you want the actual page bodies, and is optional for
MCP-style consumers that only care about the search hits themselves.

=head2 Stacking providers

You can register multiple instances of the same provider class — five SearxNG
mirrors, two Serper API keys, a private DuckDuckGo clone alongside the public
one. L<add_provider> auto-renames colliding instances (C<serper>, C<serper#2>,
C<serper#3>...) so every one stays individually addressable. Give them
explicit names via C<new(name =E<gt> ...)> when you care about the exact
identifier (for logs, C<only>/C<exclude>, etc.).

Selectors — in C<only>, C<exclude>, and C<provider_opts> keys — match against
three things on each provider: its C<name>, its class leaf (lowercased), and
any of its C<tags>. So:

  my $ws = Net::Async::WebSearch->new(
    providers => [
      Net::Async::WebSearch::Provider::SearxNG->new(
        name     => 'searx-eu',
        endpoint => 'https://searx.eu.example',
        tags     => ['private', 'eu'],
      ),
      Net::Async::WebSearch::Provider::Serper->new(
        name    => 'serper-primary',
        api_key => $KEY1,
        tags    => ['paid', 'google-backed'],
      ),
      Net::Async::WebSearch::Provider::Serper->new(
        name    => 'serper-backup',
        api_key => $KEY2,
        tags    => ['paid', 'google-backed'],
      ),
    ],
  );

  $ws->search( query => $q, exclude => ['paid'] );        # both Serpers skipped
  $ws->search( query => $q, only    => ['eu'] );          # only searx-eu
  $ws->search( query => $q, only    => ['searxng'] );     # every SearxNG instance
  $ws->search( query => $q,
    provider_opts => {
      paid              => { limit => 5 },                # applies to all tagged 'paid'
      'serper-primary'  => { tbs   => 'qdr:w' },          # exact name wins
    },
  );

=head1 CONSTRUCTOR PARAMETERS

=over 4

=item * C<providers> — arrayref of L<Net::Async::WebSearch::Provider> instances.

=item * C<http> — optional pre-built L<Net::Async::HTTP>. One is created and parented otherwise.

=item * C<default_limit> — top-N cap on aggregated results (default 10).

=item * C<per_provider_limit> — how many results to ask each provider for (default 10).

=item * C<rrf_k> — the RRF constant (default 60, as in Cormack et al.).

=back

=head2 search(%args)

The main entry point. C<%args>:

=over 4

=item * C<query> — required, the search string.

=item * C<mode> — C<collect> (default), C<stream>, or C<race>. C<stream> and
C<race> delegate to C<search_stream> / C<search_race>.

=item * C<limit> — top-N merged results. Defaults to C<default_limit>.

=item * C<per_provider_limit> — how many results to ask each provider for.

=item * C<only> — arrayref of selectors; restrict dispatch to providers
matching any of them. A selector is a provider name, a class leaf
(C<searxng>, C<serper>, ...) or a tag. See L</Stacking providers>.

=item * C<exclude> — arrayref of selectors; drop providers matching any of
them. Takes precedence over C<only>.

=item * C<language>, C<region>, C<safesearch> — generic hints, mapped per-provider.

=item * C<provider_opts> — hashref keyed by selector (name / class leaf / tag),
each value a hashref of per-provider option overrides,
e.g. C<< { serper =E<gt> { tbs =E<gt> 'qdr:w' }, paid =E<gt> { limit =E<gt> 5 } } >>.
When multiple keys match the same provider, exact-name matches win over
class-leaf / tag matches.

=back

Resolves to C<< { results, errors, stats } >>. C<results> is an arrayref of
L<Net::Async::WebSearch::Result>, with C<score> set to its RRF score and
C<< extra-E<gt>{providers} >> carrying C<< { name =E<gt> rank, ... } >>.

=head2 search_stream(%args)

Same argument shape as C<search>, but requires an C<on_result> coderef
invoked once per unique result as it arrives. C<on_provider_done> and
C<on_provider_error> coderefs are optional. Returns a Future that resolves
once every provider has settled, to C<< { results, errors, stats } >>
(C<results> is the accumulated dedup list in arrival order, not RRF-ranked).

=head2 search_race(%args)

Same argument shape. Resolves with the first provider to succeed:
C<< { provider, results, errors, stats } >>. If every provider fails,
C<provider> is C<undef> and C<results> is empty.

=head2 add_provider($provider)

Register a provider instance. If its name collides with an already-registered
provider, the new one is renamed by appending C<#2>, C<#3>... Returns the
provider (useful to pick up the final name).

=head2 provider($name)

Look up a registered provider by exact name. Returns undef if none match.

=head2 providers_matching($selector)

Returns every provider whose C<matches($selector)> is true. C<$selector> is a
name, class leaf, or tag.

=head2 providers

Returns the list of registered providers.

=head2 http

The shared L<Net::Async::HTTP> (lazily built, parented to this notifier).

=head1 SEE ALSO

L<Net::Async::WebSearch::Provider>, L<Net::Async::WebSearch::Result>,
L<IO::Async>, L<Net::Async::HTTP>, L<Future>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-websearch/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
