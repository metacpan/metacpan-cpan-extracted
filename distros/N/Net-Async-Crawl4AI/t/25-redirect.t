#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTTP::Response;
use JSON::MaybeXS qw( encode_json );
use IO::Async::Loop;
use Future;

use Net::Async::Crawl4AI;

# Redirects are refused on the async transport, like the sync client's
# max_redirect => 0: a 3xx reaches the shared parser and becomes an api error
# instead of being followed.

{
  package Test::RedirectingHTTP;
  use Future;
  # Mimics Net::Async::HTTP: a GET/HEAD 3xx with a Location is followed (the
  # next queued response stands in for the redirect target) unless the call
  # passes max_redirects => 0. Like Net::Async::HTTP, the request is attached
  # to the response.
  sub new { my ( $class, @resp ) = @_; bless { q => [ @resp ], args => [] }, $class }
  sub do_request {
    my ( $self, %args ) = @_;
    push @{ $self->{args} }, {%args};
    my $redirects = defined $args{max_redirects} ? $args{max_redirects} : 3;
    my $res = shift @{ $self->{q} } or return Future->fail("connect: connection refused\n");
    while ( $res->is_redirect && $redirects-- > 0
      && $args{request}->method =~ /^(?:GET|HEAD)$/ && $res->header('Location') ) {
      $self->{followed}++;
      $res = shift @{ $self->{q} } or return Future->fail("connect: connection refused\n");
    }
    $res->request( $args{request} );
    return Future->done($res);
  }
  sub args { $_[0]->{args} }
  sub followed { $_[0]->{followed} // 0 }
}

sub found {
  HTTP::Response->new( 302, 'Found', [ Location => 'http://elsewhere.example/' ], '' );
}

sub ok_json {
  my ( $data ) = @_;
  HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ], encode_json($data) );
}

my $loop = IO::Async::Loop->new;

sub crawler {
  my ( $http ) = @_;
  my $c = Net::Async::Crawl4AI->new(
    base_url => 'http://x', http => $http,
    delay_sub => sub { Future->done },
  );
  $loop->add($c);
  return $c;
}

subtest 'every request is sent with max_redirects => 0' => sub {
  my $http = Test::RedirectingHTTP->new( ok_json( { status => 'ok' } ) );
  crawler($http)->health->get;
  is scalar @{ $http->args }, 1, 'one request';
  is $http->args->[0]{max_redirects}, 0, 'max_redirects => 0 passed to do_request';
};

subtest 'job_status: a 302 fails the Future with type=api, status_code 302' => sub {
  my $http = Test::RedirectingHTTP->new(
    found(),
    ok_json( { status => 'COMPLETED', result => { results => [] } } ),
  );
  my $f = crawler($http)->job_status('abc');
  $loop->await($f);
  ok $f->is_failed, 'future failed instead of following the redirect';
  is $http->followed, 0, 'redirect not followed';
  my ( $err, $category ) = $f->is_failed ? $f->failure : ();
  isa_ok $err, 'WWW::Crawl4AI::Error';
  ok $err && $err->is_api, 'type=api';
  is $err && $err->status_code, 302, 'status_code 302';
  like $err && $err->message, qr/HTTP 302: Found \(GET \/crawl\/job\/abc\)/,
    'message names the status, the method and the path';
  is $category, 'crawl4ai', 'failure category crawl4ai';
  is scalar @{ $http->args }, 1, 'a 302 is not retried';
};

subtest 'health: a 302 resolves 0' => sub {
  my $http = Test::RedirectingHTTP->new( found(), ok_json( { status => 'ok' } ) );
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  my $f = crawler($http)->health;
  $loop->await($f);
  ok $f->is_done, 'health never fails';
  is $f->get, 0, 'redirect reads as unhealthy';
  is $http->followed, 0, 'redirect not followed';
  is scalar @warnings, 1, 'one health warning';
  like $warnings[0], qr/\Acrawl4ai health check failed: .*302/, 'it names the 302';
};

subtest 'health: a non-2xx resolves 0, never fails' => sub {
  my $http = Test::RedirectingHTTP->new(
    HTTP::Response->new( 500, 'Internal Server Error', [ 'Content-Type' => 'text/plain' ], 'boom' ),
  );
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  my $f = crawler($http)->health;
  $loop->await($f);
  ok $f->is_done, 'health never fails';
  is $f->get, 0, '500 reads as unhealthy';
  is scalar @warnings, 1, 'one health warning';
  like $warnings[0], qr/\Acrawl4ai health check failed: .*500/, 'it names the 500';
};

done_testing;
