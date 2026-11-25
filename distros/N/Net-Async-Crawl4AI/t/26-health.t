#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTTP::Request;
use HTTP::Response;
use JSON::MaybeXS qw( encode_json );
use IO::Async::Loop;
use Future;

use Net::Async::Crawl4AI;

# health never fails, but a failed check warns once, single line, exactly like
# the sync WWW::Crawl4AI::Client::health: 'crawl4ai health check failed: <reason>'.

{
  package Test::HealthHTTP;
  use Future;
  # Plays the queued answers in order: an HTTP::Response resolves, a string
  # fails the Future like a Net::Async::HTTP transport error.
  sub new { my ( $class, @q ) = @_; bless { q => [ @q ], calls => 0 }, $class }
  sub do_request {
    my ( $self, %args ) = @_;
    $self->{calls}++;
    my $next = shift @{ $self->{q} };
    return Future->fail($next) unless ref $next;
    $next->request( $args{request} );
    return Future->done($next);
  }
  sub calls { $_[0]->{calls} }
}

delete local @ENV{qw( CLOAKBROWSER_CDP_URL CRAWL4AI_PROXY_URL CRAWL4AI_API_TOKEN )};
my $loop = IO::Async::Loop->new;

sub crawler {
  my ( @q ) = @_;
  my $http = Test::HealthHTTP->new(@q);
  my $c = Net::Async::Crawl4AI->new(
    base_url => 'http://x', http => $http,
    delay_sub => sub { Future->done },
  );
  $loop->add($c);
  return ( $c, $http );
}

# Run health, return ( $future, @warnings ).
sub health_warnings {
  my ( $c ) = @_;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  my $f = $c->health;
  $loop->await($f);
  return ( $f, @warnings );
}

sub check_one_warning {
  my ( $name, $warnings, $like ) = @_;
  is scalar @$warnings, 1, $name . ': exactly one warning';
  my $w = $warnings->[0] // '';
  like $w, qr/\Acrawl4ai health check failed: /, $name . ': prefixed like the sync client';
  like $w, qr/\A[^\n]*\n\z/, $name . ': a single line';
  like $w, $like, $name . ': carries the reason';
}

subtest 'healthy 200 resolves 1, warns nothing' => sub {
  my ( $c ) = crawler(
    HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ], encode_json( { status => 'ok' } ) ),
  );
  my ( $f, @w ) = health_warnings($c);
  ok $f->is_done, 'done';
  is $f->get, 1, 'healthy';
  is scalar @w, 0, 'no warning' or diag explain \@w;
};

subtest '500 resolves 0 and warns once' => sub {
  my ( $c ) = crawler(
    HTTP::Response->new( 500, 'Internal Server Error', [ 'Content-Type' => 'text/plain' ], 'boom' ),
  );
  my ( $f, @w ) = health_warnings($c);
  ok $f->is_done, 'never fails';
  is $f->get, 0, 'unhealthy';
  check_one_warning( '500', \@w, qr/HTTP 500: Internal Server Error \(GET \/health\)\n\z/ );
};

subtest '302 resolves 0 and warns once' => sub {
  my ( $c ) = crawler(
    HTTP::Response->new( 302, 'Found', [ Location => 'http://elsewhere.example/' ], '' ),
  );
  my ( $f, @w ) = health_warnings($c);
  ok $f->is_done, 'never fails';
  is $f->get, 0, 'unhealthy';
  check_one_warning( '302', \@w, qr/HTTP 302: Found \(GET \/health\)\n\z/ );
};

subtest 'transport failure resolves 0 and warns once, trace stripped' => sub {
  my $trace = "connect: connection refused\n at Some/Module.pm line 42.\n\tmore trace\n";
  my ( $c, $http ) = crawler( ($trace) x 3 );
  my ( $f, @w ) = health_warnings($c);
  ok $f->is_done, 'never fails';
  is $f->get, 0, 'unhealthy';
  is $http->calls, 3, 'transport retries ran first, warned only after the last';
  check_one_warning( 'transport', \@w, qr/transport error: connect: connection refused\n\z/ );
};

subtest 'empty reason resolves 0 without a warning' => sub {
  my $c = Net::Async::Crawl4AI->new( base_url => 'http://x', delay_sub => sub { Future->done } );
  $loop->add($c);
  my @w;
  local $SIG{__WARN__} = sub { push @w, $_[0] };
  $c->_warn_health_failure('');
  $c->_warn_health_failure(undef);
  $c->_warn_health_failure("  \n trailing");
  is scalar @w, 0, 'nothing to say, nothing warned' or diag explain \@w;
};

done_testing;
