package Net::Async::Crawl4AI;
# ABSTRACT: IO::Async Crawl4AI client with an async strategy chain
use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Carp qw( croak );
use Scalar::Util qw( blessed );
use Time::HiRes ();
use URI ();
use WWW::Crawl4AI ();
use WWW::Crawl4AI::Request ();
use WWW::Crawl4AI::Result ();
use WWW::Crawl4AI::Error ();
use Net::Async::HTTP ();
use Future ();
use Future::Utils qw( repeat fmap_void );

our $VERSION = '0.001';


# Keys forwarded straight to the underlying WWW::Crawl4AI orchestrator.
my @WWW_KEYS = qw(
  base_url api_token cloakbrowser_url proxy_url callback
  fallback timeout min_markdown client
);

sub _init {
  my ( $self, $args ) = @_;
  $self->SUPER::_init($args);
  $self->{crawl4ai} = delete $args->{crawl4ai} if exists $args->{crawl4ai};
  $self->{crawl4ai} ||= WWW::Crawl4AI->new(
    map { exists $args->{$_} ? ( $_ => delete $args->{$_} ) : () } @WWW_KEYS
  );
  $self->{poll_interval} = exists $args->{poll_interval} ? delete $args->{poll_interval} : 2;
  $self->{http}      = delete $args->{http};
  $self->{delay_sub} = delete $args->{delay_sub};
  return;
}

sub configure_unknown {
  my ( $self, %args ) = @_;
  delete @args{ @WWW_KEYS, qw( crawl4ai poll_interval http delay_sub ) };
  return unless %args;
  croak "Unknown configuration keys: " . join( ',', sort keys %args );
}

sub crawl4ai          { $_[0]->{crawl4ai} }


sub client            { $_[0]->{crawl4ai}->client }


sub poll_interval     { @_ > 1 ? ( $_[0]->{poll_interval} = $_[1] ) : $_[0]->{poll_interval} }


sub available_backends { $_[0]->{crawl4ai}->available_backends }


sub http {
  my ( $self ) = @_;
  return $self->{http} if $self->{http};
  my $http = Net::Async::HTTP->new(
    user_agent               => $self->client->user_agent_string,
    max_connections_per_host => 4,
  );
  $self->add_child($http);
  return $self->{http} = $http;
}


sub _add_to_loop {
  my ( $self, $loop ) = @_;
  $self->SUPER::_add_to_loop($loop);
  $self->http;  # build + parent the Net::Async::HTTP child eagerly
}

#----------------------------------------------------------------------
# Request dispatch + retry (Future-based mirror of the client's policy)
#----------------------------------------------------------------------

sub _delay_future {
  my ( $self, $seconds ) = @_;
  return $self->{delay_sub}->($seconds) if $self->{delay_sub};
  return $self->loop->delay_future( after => $seconds );
}

sub do_request {
  my ( $self, $request, $backend ) = @_;
  croak "do_request requires an HTTP::Request" unless $self->client->is_request($request);
  return $self->_do_request_with_retry( $request, $backend, 1 );
}


sub _retry_delay {
  my ( $self, $attempt, $response ) = @_;
  my $backoff = $self->client->retry_backoff;
  my $delay = $backoff->[ $attempt - 1 ] // $backoff->[-1] // 1;
  if ( $response && ( my $ra = $response->header('Retry-After') ) ) {
    $delay = $ra if $ra =~ /^\d+$/;
  }
  return $delay;
}

sub _do_request_with_retry {
  my ( $self, $request, $backend, $attempt ) = @_;
  my $client = $self->client;
  my $max    = $client->max_attempts;
  return $self->http->do_request( request => $request, fail_on_error => 0 )->then(
    sub {
      my ( $response ) = @_;
      return Future->done($response) if $response->is_success;
      my $code      = $response->code;
      my $retryable = $client->_retry_status_set->{$code};
      if ( $retryable && $attempt < $max ) {
        my $delay = $self->_retry_delay( $attempt, $response );
        $client->on_retry->( $attempt, $delay, $response ) if $client->on_retry;
        return $self->_delay_future($delay)
          ->then( sub { $self->_do_request_with_retry( $request, $backend, $attempt + 1 ) } );
      }
      # Non-retryable / exhausted non-2xx: hand the response back so the
      # endpoint's parser raises the proper api error (with status_code).
      return Future->done($response);
    },
    sub {
      my ( $err ) = @_;    # transport-level failure from Net::Async::HTTP
      if ( $attempt < $max ) {
        my $delay = $self->_retry_delay( $attempt, undef );
        $client->on_retry->( $attempt, $delay, $err ) if $client->on_retry;
        return $self->_delay_future($delay)
          ->then( sub { $self->_do_request_with_retry( $request, $backend, $attempt + 1 ) } );
      }
      return Future->fail(
        WWW::Crawl4AI::Error->new(
          type        => 'transport',
          message     => "Crawl4AI transport error: $err",
          status_code => 0,
          backend     => $backend,
          attempt     => $attempt,
        ),
        'crawl4ai',
      );
    },
  );
}

# Dispatch $http_req, then run $parse->($response). Parser exceptions become a
# failed Future carrying a WWW::Crawl4AI::Error.
sub _parsed {
  my ( $self, $http_req, $parse, $backend ) = @_;
  return $self->do_request( $http_req, $backend )->then( sub {
    my ( $res ) = @_;
    my $out = eval { $parse->($res) };
    if ( my $e = $@ ) {
      my $err = ( blessed($e) && $e->isa('WWW::Crawl4AI::Error') )
        ? $e
        : WWW::Crawl4AI::Error->new(
            type => 'api', message => "$e", response => $res, backend => $backend );
      return Future->fail( $err, 'crawl4ai' );
    }
    return Future->done($out);
  } );
}

#----------------------------------------------------------------------
# Low-level Future endpoints
#----------------------------------------------------------------------

sub crawl_once {
  my ( $self, $request, $backend ) = @_;
  my $client = $self->client;
  return $self->_parsed(
    $client->crawl_request($request),
    sub { $client->parse_crawl_response( $_[0], $backend ) },
    $backend,
  );
}


sub md {
  my ( $self, $url, %opts ) = @_;
  my $client  = $self->client;
  my $request = ( blessed($url) && $url->isa('WWW::Crawl4AI::Request') )
    ? $url
    : WWW::Crawl4AI::Request->new( urls => $url, %opts );
  return $self->_parsed(
    $client->md_request($request),
    sub { $client->parse_md_response( $_[0] ) },
  );
}


sub job_submit {
  my ( $self, $request ) = @_;
  my $client = $self->client;
  return $self->_parsed(
    $client->job_submit_request($request),
    sub { $client->parse_job_submit_response( $_[0] ) },
  );
}


sub job_status {
  my ( $self, $task_id ) = @_;
  my $client = $self->client;
  return $self->_parsed(
    $client->job_status_request($task_id),
    sub { $client->parse_job_status_response( $_[0] ) },
  );
}


sub health {
  my ( $self ) = @_;
  my $client = $self->client;
  return $self->do_request( $client->health_request )->then(
    sub { Future->done( $client->parse_health_response( $_[0] ) ? 1 : 0 ) },
    sub { Future->done(0) },
  );
}


sub screenshot {
  my ( $self, $url, %opts ) = @_;
  my $client = $self->client;
  return $self->_parsed(
    $client->screenshot_request( $url, %opts ),
    sub { $client->parse_screenshot_response( $_[0] ) },
  );
}


sub pdf {
  my ( $self, $url, %opts ) = @_;
  my $client = $self->client;
  return $self->_parsed(
    $client->pdf_request( $url, %opts ),
    sub { $client->parse_pdf_response( $_[0] ) },
  );
}

sub html {
  my ( $self, $url ) = @_;
  my $client = $self->client;
  return $self->_parsed(
    $client->html_request($url),
    sub { $client->parse_html_response( $_[0] ) },
  );
}

sub execute_js {
  my ( $self, $url, $scripts ) = @_;
  my $client = $self->client;
  return $self->_parsed(
    $client->execute_js_request( $url, $scripts ),
    sub { $client->parse_execute_js_response( $_[0] ) },
  );
}

sub llm {
  my ( $self, $url, $query, %opts ) = @_;
  my $client = $self->client;
  return $self->_parsed(
    $client->llm_request( $url, $query, %opts ),
    sub { $client->parse_llm_response( $_[0] ) },
  );
}

sub token {
  my ( $self, $email, %opts ) = @_;
  my $client = $self->client;
  return $self->_parsed(
    $client->token_request( $email, %opts ),
    sub { $client->parse_token_response( $_[0] ) },
  );
}

#----------------------------------------------------------------------
# Job flow helper
#----------------------------------------------------------------------

sub crawl_job_and_wait {
  my ( $self, $request, %opts ) = @_;
  my $interval = delete $opts{poll_interval};
  my $req = ( blessed($request) && $request->isa('WWW::Crawl4AI::Request') )
    ? $request
    : WWW::Crawl4AI::Request->new( urls => $request, %opts );
  return $self->job_submit($req)->then( sub {
    my ( $job ) = @_;
    $self->_poll_job( $job->{task_id}, $interval );
  } );
}


sub _poll_job {
  my ( $self, $task_id, $interval ) = @_;
  $interval = $self->poll_interval unless defined $interval;
  croak "not added to a loop yet" unless $self->loop || $self->{delay_sub};
  return repeat {
    $self->job_status($task_id)->then( sub {
      my ( $status ) = @_;
      return Future->done($status) if ( $status->{status} // '' ) eq 'COMPLETED';
      return $self->_delay_future($interval)->then( sub { Future->done($status) } );
    } );
  } until => sub {
    my ( $f ) = @_;
    return 1 if $f->is_failed;    # parser fails the Future on a FAILED job
    return ( $f->get->{status} // '' ) eq 'COMPLETED';
  };
}

#----------------------------------------------------------------------
# Async strategy chain — the headline async API
#----------------------------------------------------------------------

sub _elapsed { sprintf( '%.3f', Time::HiRes::time() - $_[0] ) + 0 }

# Run a single strategy asynchronously, resolving to a normalized page (or
# undef). crawl4ai-backed strategies dispatch through Net::Async::HTTP; the
# external_callback strategy hands the URL to the user coderef, which may return
# a hashref or a Future of one.
sub _run_strategy_future {
  my ( $self, $strategy, $url, %opts ) = @_;
  my $www = $self->crawl4ai;

  if ( $strategy->can('build_request') ) {
    my $req = $strategy->build_request( $www, $url, %opts );
    return $self->crawl_once( $req, $strategy->name )->then( sub { Future->done( $_[0]->[0] ) } );
  }

  if ( $strategy->name eq 'external_callback' ) {
    my $ret = $www->callback->( $url, %opts );
    my $normalize = sub {
      my ( $page ) = @_;
      return undef unless ref $page eq 'HASH';
      $page->{url}       //= $url;
      $page->{final_url} //= $page->{url};
      return $page;
    };
    return $ret->then( sub { Future->done( $normalize->( $_[0] ) ) } )
      if blessed($ret) && $ret->isa('Future');
    return Future->done( $normalize->($ret) );
  }

  # Any other custom strategy: run its sync crawl, allowing a Future return.
  my $page = $strategy->crawl( $www, $url, %opts );
  return $page if blessed($page) && $page->isa('Future');
  return Future->done($page);
}

sub crawl {
  my ( $self, @args ) = @_;
  my $www = $self->crawl4ai;
  my ( $url, %opts ) = $www->_normalize_args(@args);
  croak "crawl needs a url" unless defined $url && length $url;

  my $detect     = $www->_detect_opts(%opts);
  my @strategies = @{ $www->strategies };
  return Future->done( $www->_failed_result( $url, [] ) ) unless @strategies;

  my @attempts;
  my $i = 0;
  return (
    repeat {
      my $strategy = $strategies[ $i++ ];
      my $t0       = Time::HiRes::time();
      $self->_run_strategy_future( $strategy, $url, %opts )->then(
        sub {
          push @attempts, $www->_attempt_for( $strategy, $_[0], undef, _elapsed($t0), $detect );
          Future->done( $attempts[-1] );
        },
        sub {
          push @attempts, $www->_attempt_for( $strategy, undef, $_[0], _elapsed($t0), $detect );
          Future->done( $attempts[-1] );
        },
      );
    } while => sub {
      my $attempt = $_[0]->get;
      return 0 if $attempt->ok;
      return $i < @strategies ? 1 : 0;
    }
  )->then( sub {
    my ( $winner ) = grep { $_->ok } @attempts;
    return Future->done(
      $winner
      ? WWW::Crawl4AI::Result->from_attempt( $winner, attempts => \@attempts )
      : $www->_failed_result( $url, \@attempts )
    );
  } );
}


sub markdown { my ( $self, @args ) = @_; return $self->crawl(@args) }

sub deep_crawl {
  my ( $self, @args ) = @_;
  my $www = $self->crawl4ai;
  my ( $start, %opts ) = $www->_normalize_args(@args);
  croak "deep_crawl needs a url" unless defined $start && length $start;

  my $max_pages   = exists $opts{max_pages}   ? delete $opts{max_pages}   : 25;
  my $max_depth   = exists $opts{max_depth}   ? delete $opts{max_depth}   : 2;
  my $same_host   = exists $opts{same_host}   ? delete $opts{same_host}   : 1;
  my $concurrency = exists $opts{concurrency} ? delete $opts{concurrency} : 4;
  my $on_page     = delete $opts{on_page};
  my $url_filter  = delete $opts{url_filter};

  my $start_host;  # locked onto the host the start URL actually resolved to
  my %seen        = ( $www->_canon_url($start) => 1 );
  my $seq         = 0;
  my %collected;   # enqueue index => result, so the result list comes out in
                   # breadth-first order regardless of which order a concurrent
                   # frontier happens to complete in

  # Crawl one frontier level concurrently, gather the next level, recurse.
  my $process_level;
  $process_level = sub {
    my ( $frontier ) = @_;
    my $remaining = $max_pages - keys %collected;
    return Future->done unless @$frontier && $remaining > 0;
    # Trim to the budget up front so we never fire requests we'd only discard.
    $frontier = [ @{$frontier}[ 0 .. $remaining - 1 ] ] if @$frontier > $remaining;

    my @next;
    my $level = fmap_void {
      my ( $node ) = @_;
      $self->crawl( $node->{url}, %opts )->then( sub {
        my ( $result ) = @_;
        $collected{ $node->{seq} } = $result;
        $on_page->( $result, $node->{depth} ) if $on_page;
        # Take the host from the start URL's actual final_url (depth 0), so a
        # scheme-less start or a redirect to www. doesn't reject every link.
        $start_host //= lc( eval { URI->new( $result->final_url // $node->{url} )->host } // '' );
        if ( $node->{depth} < $max_depth && $result->ok ) {
          for my $url ( @{ $result->urls } ) {
            my $canon = $www->_canon_url($url);
            next if $seen{$canon}++;
            if ($same_host) {
              my $host = lc( eval { URI->new($url)->host } // '' );
              next unless $host eq $start_host;
            }
            next if $url_filter && !$url_filter->($url);
            push @next, { url => $url, depth => $node->{depth} + 1, seq => $seq++ };
          }
        }
        Future->done;
      } );
    } foreach => [ @$frontier ], concurrent => $concurrency;

    return $level->then( sub { $process_level->( \@next ) } );
  };

  my $f = $process_level->( [ { url => $start, depth => 0, seq => $seq++ } ] )
    ->then( sub { Future->done( [ @collected{ sort { $a <=> $b } keys %collected } ] ) } );
  $f->on_ready( sub { undef $process_level } );  # break the self-referential cycle
  return $f;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Crawl4AI - IO::Async Crawl4AI client with an async strategy chain

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use IO::Async::Loop;
  use Net::Async::Crawl4AI;

  my $loop = IO::Async::Loop->new;
  my $crawler = Net::Async::Crawl4AI->new(
    base_url         => 'http://localhost:11235',
    cloakbrowser_url => $ENV{CLOAKBROWSER_CDP_URL},   # optional
    poll_interval    => 2,
  );
  $loop->add($crawler);

  # Async strategy chain — escalates plain -> browser -> stealth -> ...
  my $result = $crawler->markdown('https://example.com')->get;
  say $result->markdown;
  say $result->backend;        # crawl4ai_plain / crawl4ai_stealth / ...
  say $result->attempts_json;

  # Low-level single crawl (no chain), returns all pages.
  my $pages = $crawler->crawl_once(
    WWW::Crawl4AI::Request->new( urls => 'https://example.com' )
  )->get;

  # Submit an async crawl job and poll it to completion.
  my $done = $crawler->crawl_job_and_wait('https://example.com')->get;
  # { status => 'COMPLETED', pages => [...], raw => {...} }

=head1 DESCRIPTION

L<IO::Async>-flavoured companion to L<WWW::Crawl4AI>. It wraps a
L<WWW::Crawl4AI> orchestrator, dispatches its request builders through
L<Net::Async::HTTP>, and returns L<Future> objects — including a fully
asynchronous run of the same B<visible strategy chain>.

The pure building blocks (request building, page normalization, content
classification via L<WWW::Crawl4AI::Detect>, and L<WWW::Crawl4AI::Attempt> /
L<WWW::Crawl4AI::Result> history) are shared with the synchronous
L<WWW::Crawl4AI>, so C<< $crawler->markdown(...)->get >> produces the same
L<WWW::Crawl4AI::Result> the sync facade would — only non-blocking.

B<Must C<< $loop->add($crawler) >> before use> — it is a
L<IO::Async::Notifier> subclass. Without this the internal
L<Net::Async::HTTP> has no loop and requests will hang.

=head2 Constructor parameters

  base_url, api_token, cloakbrowser_url, proxy_url, callback,
  fallback, timeout, min_markdown, client

All forwarded to the underlying L<WWW::Crawl4AI>. Or pass a pre-built instance
as C<< crawl4ai => $www >>.

Async-only keys: C<poll_interval>, C<http> (pre-built L<Net::Async::HTTP>),
C<delay_sub> (CodeRef → Future, for retry/poll delays; mainly a test hook).

The retry policy (C<max_attempts>, C<retry_backoff>, C<retry_statuses>,
C<on_retry>) lives on the underlying L<WWW::Crawl4AI::Client>.

=head2 Future contract

Endpoint Futures fail as C<< Future->fail($error, 'crawl4ai') >> where
C<$error> is a L<WWW::Crawl4AI::Error>. C<crawl>/C<markdown> never fail for
per-strategy errors: each failed strategy is an entry in the attempt history,
and an all-strategies-failed run resolves to a L<WWW::Crawl4AI::Result> with
C<< ok => 0 >>.

=head2 crawl4ai

The underlying L<WWW::Crawl4AI> orchestrator.

=head2 client

The underlying L<WWW::Crawl4AI::Client> (used for request builders, response
parsers and retry configuration).

=head2 poll_interval

Read/write accessor for the default job-status poll interval in seconds.

=head2 available_backends

Arrayref of backend names currently in the chain.

=head2 http

The underlying L<Net::Async::HTTP> (lazily built and parented to this notifier).

=head2 do_request

Low-level: dispatch an L<HTTP::Request> (typically built via
C<< $self->client->foo_request >>) through L<Net::Async::HTTP> with the retry
policy applied. Returns a Future of L<HTTP::Response>.

=head2 crawl_once

  $crawler->crawl_once($request, $backend?) → Future[\@pages]

Low-level single C<POST /crawl>. Resolves to the arrayref of normalized pages
(no chain, no classification). C<$request> is a L<WWW::Crawl4AI::Request> or a
payload hashref.

=head2 md

  $crawler->md($url_or_request, %opts) → Future[$markdown]

C<POST /md>. Resolves to the markdown payload.

=head2 job_submit

  $crawler->job_submit($request) → Future[{ task_id, raw }]

C<POST /crawl/job>. Resolves to C<< { task_id => ..., raw => {...} } >>.

=head2 job_status

  $crawler->job_status($task_id) → Future[{ status, pages, raw }]

C<GET /crawl/job/$task_id>. Resolves to C<< { status, pages, raw } >>; fails
with a C<type=job> L<WWW::Crawl4AI::Error> when the job reports C<FAILED>.

=head2 health

Resolves to 1 if the Crawl4AI server answers C<GET /health>, else 0. Never
fails.

=head2 screenshot

  $crawler->screenshot($url, wait_for => 2, wait_for_images => 1) → Future[$png_bytes]

=head2 pdf

  $crawler->pdf($url) → Future[$pdf_bytes]

=head2 html

  $crawler->html($url) → Future[$html]

=head2 execute_js

  $crawler->execute_js($url, $script_or_arrayref) → Future[\%page]

=head2 llm

  $crawler->llm($url, $query, %opts) → Future[$answer]

=head2 token

  $crawler->token($email) → Future[\%token]

Future-returning single-URL action endpoints, mirroring
L<WWW::Crawl4AI::Client>: C<screenshot>/C<pdf> resolve to raw bytes, C<html> to
the preprocessed HTML, C<execute_js> to a normalized page with C<js_result>,
C<llm> to an answer string (needs a server-side LLM provider), and C<token> to
a JWT hash. They do B<not> run the strategy chain.

=head2 crawl_job_and_wait

  $crawler->crawl_job_and_wait($url_or_request, %opts) → Future[\%status]

Submits a crawl job (C<POST /crawl/job>) and polls C<job_status> every
C<poll_interval> seconds (override per call with C<< poll_interval => N >>)
until it reports C<COMPLETED>. Resolves to the final status hash
(C<< { status, pages, raw } >>); fails with a C<type=job>
L<WWW::Crawl4AI::Error> on a failed job.

=head2 crawl

=head2 markdown

  my $result = $crawler->markdown('https://example.com')->get;
  my $result = $crawler->crawl( url => 'https://example.com' )->get;

Run the strategy chain asynchronously and resolve to a
L<WWW::Crawl4AI::Result>. Same chain, same result object as the synchronous
L<WWW::Crawl4AI/markdown>. Accepts a single positional URL or named arguments
with a C<url> key.

The Future never fails for per-strategy errors: each failed strategy is an
entry in the attempt history. An all-strategies-failed run resolves to a
C<Result> with C<< ok => 0 >>.

=head2 deep_crawl

  my $results = $crawler->deep_crawl('https://example.com')->get;
  my $results = $crawler->deep_crawl(
    'https://example.com',
    max_pages   => 50,
    max_depth   => 3,
    same_host   => 1,
    concurrency => 8,                                  # async-only
    url_filter  => sub { $_[0] !~ m{/login} },
    on_page     => sub { my ( $result, $depth ) = @_; ... },
    min_markdown => 200,            # any crawl() option is forwarded
  )->get;

Asynchronous breadth-first crawl that follows the
L<WWW::Crawl4AI::Result/urls> of each good page. Resolves to a Future of an
arrayref of L<WWW::Crawl4AI::Result> in breadth-first order: the start URL
first, then deeper pages grouped by depth (the list is reordered back to
enqueue order, so a faster page completing first does not jump the queue).
Same semantics as L<WWW::Crawl4AI/deep_crawl>, but each depth level's frontier
is crawled concurrently (up to C<concurrency>, default C<4>) instead of one
page at a time.

Options: C<max_pages> (default C<25>), C<max_depth> (default C<2>, start URL is
depth C<0>), C<same_host> (default true), C<concurrency> (default C<4>,
async-only), C<url_filter> (C<< ($url) -> bool >>), C<on_page>
(C<< ($result, $depth) >>). URLs are deduplicated with the fragment stripped.
Any remaining options are forwarded to each L</crawl>.

=head1 SEE ALSO

L<WWW::Crawl4AI>, L<WWW::Crawl4AI::Client>, L<WWW::Crawl4AI::Result>,
L<IO::Async>, L<Net::Async::HTTP>, L<Future>,
L<https://github.com/unclecode/crawl4ai>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-crawl4ai/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
