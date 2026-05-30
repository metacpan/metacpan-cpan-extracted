#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTTP::Response;
use JSON::MaybeXS qw( encode_json );
use IO::Async::Loop;
use Future;

use Net::Async::Crawl4AI;

{
  package Test::ScriptedHTTP;
  use Future;
  sub new { my ( $class, @resp ) = @_; bless { q => [ @resp ], log => [] }, $class }
  sub do_request {
    my ( $self, %args ) = @_;
    push @{ $self->{log} }, $args{request};
    my $next = shift @{ $self->{q} };
    # Empty queue simulates a Net::Async::HTTP transport failure: a failed
    # Future, not a synchronous die.
    return Future->fail("connect: connection refused\n") unless $next;
    return Future->done($next);
  }
  sub log { $_[0]->{log} }
}

sub ok_md {
  HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ],
    encode_json( { markdown => 'OK' } ) );
}

sub err { HTTP::Response->new( $_[0], 'err', [ 'Content-Type' => 'text/plain' ], 'nope' ) }

my $loop = IO::Async::Loop->new;

subtest '429 -> 200 retries with backoff delay' => sub {
  my $http = Test::ScriptedHTTP->new( err(429), ok_md() );
  my @delays;
  my $c = Net::Async::Crawl4AI->new(
    base_url  => 'http://x',
    http      => $http,
    delay_sub => sub { push @delays, $_[0]; Future->done },
  );
  $loop->add($c);
  my $md = $c->md('https://x')->get;
  is $md, 'OK', 'recovered after retry';
  is_deeply \@delays, [1], 'one backoff delay of 1s';
  is scalar @{ $http->log }, 2, 'two HTTP attempts';
};

subtest 'exhausted retries fail Future with type=api' => sub {
  my $http = Test::ScriptedHTTP->new( err(503), err(503), err(503) );
  my $c = Net::Async::Crawl4AI->new(
    base_url => 'http://x', http => $http,
    delay_sub => sub { Future->done },
  );
  $loop->add($c);
  my @failure = $c->md('https://x')->failure;
  ok $failure[0], 'future failed';
  isa_ok $failure[0], 'WWW::Crawl4AI::Error';
  ok $failure[0]->is_api, 'type=api';
  is $failure[0]->status_code, 503, 'status_code carried';
  is scalar @{ $http->log }, 3, 'three attempts';
};

subtest 'Retry-After honoured in async path' => sub {
  my $http = Test::ScriptedHTTP->new(
    HTTP::Response->new( 429, 'rl', [ 'Content-Type' => 'text/plain', 'Retry-After' => 5 ], '' ),
    ok_md(),
  );
  my @delays;
  my $c = Net::Async::Crawl4AI->new(
    base_url => 'http://x', http => $http,
    delay_sub => sub { push @delays, $_[0]; Future->done },
  );
  $loop->add($c);
  $c->md('https://x')->get;
  is_deeply \@delays, [5], 'Retry-After overrode backoff';
};

subtest 'transport failure retried then fails type=transport' => sub {
  my $http = Test::ScriptedHTTP->new();    # empty -> do_request dies (transport)
  my @delays;
  my $c = Net::Async::Crawl4AI->new(
    base_url => 'http://x', http => $http,
    delay_sub => sub { push @delays, $_[0]; Future->done },
  );
  $loop->add($c);
  my @failure = $c->md('https://x')->failure;
  isa_ok $failure[0], 'WWW::Crawl4AI::Error';
  ok $failure[0]->is_transport, 'type=transport';
  is $failure[0]->attempt, 3, 'attempt count carried';
  is_deeply \@delays, [ 1, 2 ], 'two backoff delays before giving up';
};

done_testing;
