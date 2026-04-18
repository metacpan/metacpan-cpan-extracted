package Net::Async::Firecrawl;
# ABSTRACT: IO::Async Firecrawl v2 client with flow helpers
use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Carp qw( croak );
use WWW::Firecrawl ();
use WWW::Firecrawl::Error ();
use Net::Async::HTTP ();
use Future ();
use Future::Utils qw( repeat );

our $VERSION = '0.001';

sub _init {
  my ( $self, $args ) = @_;
  $self->SUPER::_init($args);
  $self->{firecrawl} ||= WWW::Firecrawl->new(
    ( exists $args->{base_url}    ? ( base_url    => delete $args->{base_url} )    : () ),
    ( exists $args->{api_key}     ? ( api_key     => delete $args->{api_key} )     : () ),
    ( exists $args->{api_version} ? ( api_version => delete $args->{api_version} ) : () ),
  );
  $self->{poll_interval} = exists $args->{poll_interval} ? delete $args->{poll_interval} : 3;
  $self->{http} = delete $args->{http};
  $self->{firecrawl} = delete $args->{firecrawl} if exists $args->{firecrawl};
  $self->{delay_sub} = delete $args->{delay_sub};
  return;
}

sub configure_unknown {
  my ( $self, %args ) = @_;
  for my $k (qw( base_url api_key api_version poll_interval firecrawl http delay_sub )) {
    delete $args{$k};
  }
  return unless %args;
  croak "Unknown configuration keys: ".join(',', sort keys %args);
}

sub firecrawl     { $_[0]->{firecrawl} }
sub poll_interval { @_ > 1 ? ($_[0]->{poll_interval} = $_[1]) : $_[0]->{poll_interval} }

sub http {
  my ( $self ) = @_;
  return $self->{http} if $self->{http};
  my $http = Net::Async::HTTP->new(
    user_agent => $self->firecrawl->user_agent_string,
    max_connections_per_host => 4,
  );
  $self->add_child($http);
  return $self->{http} = $http;
}

sub _on_added_to_loop {
  my ( $self, $loop ) = @_;
  $self->SUPER::_on_added_to_loop($loop) if $self->can('SUPER::_on_added_to_loop');
  # Lazy-build http so it's parented properly
  $self->http;
}

#----------------------------------------------------------------------
# Generic request dispatch
#----------------------------------------------------------------------

sub do_request {
  my ( $self, $request ) = @_;
  croak "do_request requires HTTP::Request" unless $self->firecrawl->is_request($request);
  return $self->_do_request_with_retry($request, 1);
}

sub _delay_future {
  my ( $self, $seconds ) = @_;
  return $self->{delay_sub}->($seconds) if $self->{delay_sub};
  return $self->loop->delay_future( after => $seconds );
}

sub _do_request_with_retry {
  my ( $self, $request, $attempt ) = @_;
  my $fc = $self->firecrawl;
  my $max = $fc->max_attempts;
  return $self->http->do_request( request => $request )->then(sub {
    my ( $response ) = @_;
    my ( $err, $retryable ) = $fc->_classify_response( $response, $attempt );
    return Future->done($response) unless $err;
    if ( $retryable && $attempt < $max ) {
      my $delay = $fc->_retry_delay( $response, $attempt );
      if ( my $cb = $fc->on_retry ) {
        $cb->( $attempt, $delay, $err );
      }
      return $self->_delay_future($delay)->then(sub {
        $self->_do_request_with_retry( $request, $attempt + 1 );
      });
    }
    return Future->fail($err, 'firecrawl', $attempt);
  });
}

# Build a Future-returning wrapper named $name around a WWW::Firecrawl
# request builder + response parser pair.
sub _install_wrapper {
  my ( $class, $name, $opts ) = @_;
  $opts ||= {};
  my $builder = $opts->{builder} || "${name}_request";
  my $parser  = $opts->{parser}  || "parse_${name}_response";

  no strict 'refs';
  *{"${class}::${name}"} = sub {
    my ( $self, @args ) = @_;
    my $fc = $self->firecrawl;
    my $req = $fc->$builder(@args);
    return $self->do_request($req)->then(sub {
      my $response = $_[0];
      my $data = eval { $fc->$parser($response) };
      if ( my $e = $@ ) {
        my $err = ref $e && $e->isa('WWW::Firecrawl::Error')
          ? $e
          : WWW::Firecrawl::Error->new( type => 'api', message => "$e", response => $response );
        return Future->fail($err, 'firecrawl');
      }
      return Future->done($data);
    });
  };
}

# Declarative endpoint list: one Future-returning method per endpoint.
my @ENDPOINTS = qw(
  scrape
  crawl
  crawl_status
  crawl_cancel
  crawl_errors
  crawl_active
  crawl_params_preview
  map
  search
  batch_scrape
  batch_scrape_status
  batch_scrape_cancel
  batch_scrape_errors
  extract
  extract_status
  agent
  agent_status
  agent_cancel
  browser_create
  browser_list
  browser_delete
  browser_execute
  scrape_execute
  scrape_browser_stop
  credit_usage
  credit_usage_historical
  token_usage
  token_usage_historical
  queue_status
  activity
);

__PACKAGE__->_install_wrapper($_) for @ENDPOINTS;

# Pagination-follow helpers — same parser as their base endpoint.
__PACKAGE__->_install_wrapper('crawl_status_next', {
  builder => 'crawl_status_next_request',
  parser  => 'parse_crawl_status_response',
});
__PACKAGE__->_install_wrapper('batch_scrape_status_next', {
  builder => 'batch_scrape_status_next_request',
  parser  => 'parse_batch_scrape_status_response',
});

#----------------------------------------------------------------------
# Flow helpers
#----------------------------------------------------------------------

sub _poll_until_done {
  my ( $self, %args ) = @_;
  my $status_cb = $args{status};
  my $interval  = $args{interval} || $self->poll_interval;
  my $loop      = $self->loop or croak "not added to a loop yet";

  return repeat {
    $status_cb->()->then(sub {
      my ( $status ) = @_;
      my $st = $status->{status} // '';
      if ( $st eq 'failed' || $st eq 'cancelled' ) {
        my $msg = "Firecrawl job $st";
        $msg .= ': ' . $status->{error} if defined $status->{error};
        return Future->fail(
          WWW::Firecrawl::Error->new(
            type => 'job',
            message => $msg,
            data => $status,
          ),
          'firecrawl',
        );
      }
      return Future->done($status) if $st eq 'completed';
      return $self->_delay_future($interval)
        ->then(sub { Future->done($status) });
    });
  } until => sub {
    my $f = $_[0];
    return 1 if $f->is_failed;
    my $s = $f->get;
    return ($s->{status} // '') eq 'completed';
  };
}

sub _collect_pages {
  my ( $self, $first_status, $next_method ) = @_;
  my @pages = @{ $first_status->{data} || [] };
  my $next = $first_status->{next};
  my $last_status = $first_status;
  return Future->done({ %$first_status, data => \@pages }) unless $next;
  my $current = $next;
  my $loop_f = repeat {
    my $url = $current;
    $self->$next_method($url)->on_done(sub {
      my ( $s ) = @_;
      $last_status = $s;
      push @pages, @{ $s->{data} || [] };
      $current = $s->{next};
    });
  } while => sub { defined $current };
  return $loop_f->then(sub {
    Future->done({
      %$first_status,
      data   => \@pages,
      status => $last_status->{status},
    });
  });
}

sub _collect_crawl_pages { $_[0]->_collect_pages($_[1], 'crawl_status_next') }
sub _collect_batch_pages { $_[0]->_collect_pages($_[1], 'batch_scrape_status_next') }

# Apply is_failure classification to a collected crawl/batch result,
# producing { data, failed, raw_data, stats } from raw `data`.
sub _split_pages {
  my ( $self, $result ) = @_;
  my $fc = $self->firecrawl;
  my @raw = @{ $result->{data} || [] };
  my @ok;
  my @failed;
  for my $page (@raw) {
    if ( $fc->is_failure->($page) ) {
      my $meta = $page->{metadata} || {};
      push @failed, {
        url        => $meta->{sourceURL} // $meta->{url},
        statusCode => $meta->{statusCode},
        error      => $fc->scrape_error($page),
        page       => $page,
      };
    }
    else {
      push @ok, $page;
    }
  }
  return {
    %$result,
    data     => \@ok,
    failed   => \@failed,
    raw_data => \@raw,
    stats    => {
      ok     => scalar @ok,
      failed => scalar @failed,
      total  => scalar @raw,
    },
  };
}


sub crawl_and_collect {
  my ( $self, %args ) = @_;
  my $interval = delete $args{poll_interval};
  $self->crawl(%args)->then(sub {
    my ( $job ) = @_;
    my $id = $job->{id} or return Future->fail(
      WWW::Firecrawl::Error->new( type => 'api', message => "crawl returned no id" ),
      'firecrawl',
    );
    $self->_poll_until_done(
      status   => sub { $self->crawl_status($id) },
      interval => $interval,
    )
    ->then(sub { $self->_collect_crawl_pages($_[0]) })
    ->then(sub { Future->done( $self->_split_pages($_[0]) ) });
  });
}

sub batch_scrape_and_wait {
  my ( $self, %args ) = @_;
  my $interval = delete $args{poll_interval};
  $self->batch_scrape(%args)->then(sub {
    my ( $job ) = @_;
    my $id = $job->{id} or return Future->fail(
      WWW::Firecrawl::Error->new( type => 'api', message => "batch_scrape returned no id" ),
      'firecrawl',
    );
    $self->_poll_until_done(
      status   => sub { $self->batch_scrape_status($id) },
      interval => $interval,
    )
    ->then(sub { $self->_collect_batch_pages($_[0]) })
    ->then(sub { Future->done( $self->_split_pages($_[0]) ) });
  });
}

# Start extract → poll until done → return the final payload.
sub extract_and_wait {
  my ( $self, %args ) = @_;
  my $interval = delete $args{poll_interval};
  $self->extract(%args)->then(sub {
    my ( $job ) = @_;
    my $id = $job->{id} or return Future->fail("extract returned no id");
    $self->_poll_until_done(
      status   => sub { $self->extract_status($id) },
      interval => $interval,
    );
  });
}

# Start agent → poll until done.
sub agent_and_wait {
  my ( $self, %args ) = @_;
  my $interval = delete $args{poll_interval};
  $self->agent(%args)->then(sub {
    my ( $job ) = @_;
    my $id = $job->{id} or return Future->fail("agent returned no id");
    $self->_poll_until_done(
      status   => sub { $self->agent_status($id) },
      interval => $interval,
    );
  });
}

sub scrape_many {
  my ( $self, $urls, %common ) = @_;
  croak "scrape_many: first arg must be arrayref of URLs" unless ref $urls eq 'ARRAY';
  my $fc = $self->firecrawl;
  my @futures = map {
    my $url = $_;
    $self->scrape( url => $url, %common )->then(
      sub {
        my $data = $_[0];
        if ( $fc->is_failure->($data) ) {
          my $err = WWW::Firecrawl::Error->new(
            type => 'page',
            message => 'Firecrawl scrape failed: ' . ($fc->scrape_error($data) // 'unknown'),
            data => $data,
            status_code => $fc->scrape_status($data),
            url => $url,
          );
          return Future->done({ url => $url, failed => { url => $url, error => $err } });
        }
        return Future->done({ url => $url, ok => { url => $url, data => $data } });
      },
      sub {
        my ( $err ) = @_;
        my $e = ref $err && $err->isa('WWW::Firecrawl::Error')
          ? $err
          : WWW::Firecrawl::Error->new( type => 'api', message => "$err", url => $url );
        return Future->done({ url => $url, failed => { url => $url, error => $e } });
      },
    );
  } @$urls;
  return Future->wait_all(@futures)->then(sub {
    my @resolved = map { $_->get } @_;
    my @ok     = map { $_->{ok}     } grep { exists $_->{ok}     } @resolved;
    my @failed = map { $_->{failed} } grep { exists $_->{failed} } @resolved;
    Future->done({
      ok => \@ok,
      failed => \@failed,
      stats => { ok => scalar @ok, failed => scalar @failed, total => scalar @$urls },
    });
  });
}

sub retry_failed_pages {
  my ( $self, $result, %scrape_opts ) = @_;
  my @urls = map { $_->{url} } @{ $result->{failed} || [] };
  return $self->scrape_many( \@urls, %scrape_opts );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Firecrawl - IO::Async Firecrawl v2 client with flow helpers

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use IO::Async::Loop;
  use Net::Async::Firecrawl;

  my $loop = IO::Async::Loop->new;
  my $fc = Net::Async::Firecrawl->new(
    base_url      => 'http://localhost:3002',  # or https://api.firecrawl.dev
    api_key       => 'fc-...',                 # optional for self-hosted
    poll_interval => 3,
  );
  $loop->add($fc);

  # Single scrape
  my $doc = $fc->scrape( url => 'https://example.com', formats => ['markdown'] )->get;

  # Crawl a site, poll to completion, collect all paginated pages, split by is_failure.
  my $result = $fc->crawl_and_collect(
    url   => 'https://example.com',
    limit => 100,
  )->get;
  # $result->{data}     — ok pages only
  # $result->{failed}   — [{ url, statusCode, error, page }, ...]
  # $result->{raw_data} — all pages in original order
  # $result->{stats}    — { ok, failed, total }

  # Batch scrape, waits for all results.
  my $batch = $fc->batch_scrape_and_wait(
    urls    => [ 'https://a', 'https://b' ],
    formats => ['markdown'],
  )->get;

  # Structured extraction.
  my $extract = $fc->extract_and_wait(
    urls   => [ 'https://example.com/*' ],
    prompt => 'extract pricing and product names',
  )->get;

  # Concurrent per-URL scrape (partial-success).
  my $many = $fc->scrape_many(
    [qw( https://a https://b https://c )],
    formats => ['markdown'],
  )->get;
  # $many->{ok}     — [{ url, data }, ...]
  # $many->{failed} — [{ url, error }, ...]   — $error is a WWW::Firecrawl::Error

  # Retry the failed URLs from a prior crawl/batch.
  my $retried = $fc->retry_failed_pages($result, formats => ['markdown'])->get;

=head1 DESCRIPTION

L<IO::Async>-flavoured client for the Firecrawl v2 API. Wraps
L<WWW::Firecrawl>'s request builders and response parsers, dispatches through
L<Net::Async::HTTP>, and returns L<Future> objects.

Every endpoint exposed by L<WWW::Firecrawl> is available here as a
Future-returning method with identical argument signatures. On top of that,
high-level I<flow> helpers automate the start-job → poll → collect-pages
pattern common to crawl, batch-scrape, extract, and agent operations —
including partial-success splitting by the classification policy of the
underlying L<WWW::Firecrawl>.

=head1 CONSTRUCTOR PARAMETERS

=over 4

=item * C<base_url>, C<api_key>, C<api_version> — forwarded to L<WWW::Firecrawl>.

=item * C<firecrawl> — pass a pre-built L<WWW::Firecrawl> instance (overrides the above three).

=item * C<http> — pass a pre-built L<Net::Async::HTTP> (otherwise one is created and parented to this notifier).

=item * C<poll_interval> — seconds between status polls for flow helpers (default 3).

=item * C<delay_sub> — optional CodeRef that returns a L<Future> for inter-attempt and polling delays. If omitted, C<< $loop->delay_future >> is used. Mainly a test hook.

=back

Retry attributes (C<max_attempts>, C<retry_backoff>, C<retry_statuses>,
C<on_retry>) and classification attributes (C<is_failure>, C<failure_codes>,
C<strict>) live on the underlying L<WWW::Firecrawl>. Pass them to this
constructor or build the L<WWW::Firecrawl> instance yourself and pass it as
C<firecrawl>.

=head1 ERROR HANDLING

Every failure path resolves as C<< Future->fail($error, 'firecrawl', $attempt?) >>
where C<$error> is a L<WWW::Firecrawl::Error> object (stringifies to its
message). C<< $f->failure >> returns C<< ($error, 'firecrawl', $attempt?) >>.

Five error types (same model as L<WWW::Firecrawl>):

=over 4

=item * C<transport> — Firecrawl unreachable. Retried automatically up to C<max_attempts>.

=item * C<api> — Firecrawl returned non-2xx or C<< {success: false} >>. Retried only for C<retry_statuses> (default 429/502/503/504).

=item * C<job> — A flow reported C<< status: failed >> or C<< status: cancelled >>. Never retried — always propagates as Future fail.

=item * C<scrape> — Single-scrape's target URL was classified as failed (only raised when C<strict> is on).

=item * C<page> — A target URL inside a flow (C<scrape_many>, or a failed entry within crawl/batch) was classified as failed. Surfaced in C<failed[]>, not thrown.

=back

Classic usage:

  $fc->scrape( url => $u )->then(sub {
    my $data = shift;
    ...
  })->else(sub {
    my ( $err ) = @_;
    if ($err->is_transport) { ... }
    elsif ($err->is_job)    { ... }
    else                    { warn "firecrawl: $err"; Future->fail($err) }
  });

=head2 scrape

=head2 crawl

=head2 crawl_status

=head2 crawl_cancel

=head2 crawl_errors

=head2 crawl_active

=head2 crawl_params_preview

=head2 map

=head2 search

=head2 batch_scrape

=head2 batch_scrape_status

=head2 batch_scrape_cancel

=head2 batch_scrape_errors

=head2 extract

=head2 extract_status

=head2 agent

=head2 agent_status

=head2 agent_cancel

=head2 browser_create

=head2 browser_list

=head2 browser_delete

=head2 browser_execute

=head2 scrape_execute

=head2 scrape_browser_stop

=head2 credit_usage

=head2 credit_usage_historical

=head2 token_usage

=head2 token_usage_historical

=head2 queue_status

=head2 activity

One Future-returning method per L<WWW::Firecrawl> endpoint, same argument
signature. Resolves to the parsed payload on success. See
L<WWW::Firecrawl> for per-endpoint details.

=head2 crawl_status_next($next_url)

=head2 batch_scrape_status_next($next_url)

Follow a pagination URL from a previous status response.

=head2 crawl_and_collect(%crawl_args)

Fires C<crawl>, polls C<crawl_status> every C<poll_interval> seconds until
the job reports C<completed> (C<failed>/C<cancelled> fail the Future with
C<type=job>), walks the C<next> pagination chain, classifies each collected
page via the underlying L<WWW::Firecrawl>'s C<is_failure>, and resolves to:

  {
    status      => 'completed',
    id          => $job_id,
    creditsUsed => ...,
    data        => [ ok_page,   ... ],   # ok only
    failed      => [ { url, statusCode, error, page }, ... ],
    raw_data    => [ page, ... ],         # all, original order
    stats       => { ok, failed, total },
  }

=head2 batch_scrape_and_wait(%batch_args)

Same contract as C<crawl_and_collect> but against the batch-scrape endpoints.
Same return shape.

=head2 extract_and_wait(%extract_args)

Starts an extract job and resolves once C<extract_status> reports C<completed>.
Fails (C<type=job>) on C<failed>/C<cancelled>. Returns the final status hash.

=head2 agent_and_wait(%agent_args)

Like C<extract_and_wait>, for agent jobs.

=head2 scrape_many(\@urls, %common_scrape_args)

Fires a C<scrape> per URL concurrently. Resolves to:

  {
    ok     => [ { url, data }, ... ],
    failed => [ { url, error }, ... ],     # error is a WWW::Firecrawl::Error
    stats  => { ok, failed, total },
  }

The outer Future never fails for per-URL failures (transport, api, or
target-level). It only fails for local errors (e.g. not added to a loop).

=head2 retry_failed_pages($result, %scrape_opts)

Takes a result from C<crawl_and_collect> / C<batch_scrape_and_wait> /
C<scrape_many> and re-scrapes the URLs in C<< $result->{failed} >> via
C<scrape_many>. Returns a Future of the standard C<< { ok, failed, stats } >>
hashref.

=head2 do_request($http_request)

Low-level: dispatch an arbitrary L<HTTP::Request> (typically one built via
C<< $self->firecrawl->foo_request >>) through the underlying L<Net::Async::HTTP>
with retry applied. Returns a Future of L<HTTP::Response>.

=head2 firecrawl

The underlying L<WWW::Firecrawl> instance.

=head2 http

The underlying L<Net::Async::HTTP> instance (lazily built and parented to
this notifier).

=head2 poll_interval

Read/write accessor for the default poll interval (seconds) used by flow
helpers.

=head1 SEE ALSO

L<WWW::Firecrawl>, L<IO::Async>, L<Net::Async::HTTP>, L<Future>,
L<https://firecrawl.dev>, L<https://docs.firecrawl.dev/api-reference/v2-introduction>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-firecrawl/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
