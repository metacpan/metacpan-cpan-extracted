#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTTP::Response;
use JSON::MaybeXS qw( encode_json );
use IO::Async::Loop;
use Future;

use Net::Async::Firecrawl;

{
  package Test::ScriptedHTTP;
  sub new {
    my ( $class, @resp ) = @_;
    return bless { q => [ @resp ], log => [] }, $class;
  }
  sub do_request {
    my ( $self, %args ) = @_;
    push @{ $self->{log} }, $args{request};
    my $next = shift @{ $self->{q} };
    die "scripted HTTP exhausted\n" unless $next;
    return Future->done($next);
  }
  sub log { $_[0]->{log} }
}

sub ok_scrape_response {
  HTTP::Response->new( 200, 'OK', [ 'Content-Type'=>'application/json' ],
    encode_json({ success => JSON::MaybeXS::true(), data => { markdown => 'OK' } }),
  );
}

sub err { HTTP::Response->new( $_[0], 'err', [ 'Content-Type'=>'text/plain' ], 'nope' ) }

my $loop = IO::Async::Loop->new;

subtest '429 -> 200 retries with delay' => sub {
  my $http = Test::ScriptedHTTP->new( err(429), ok_scrape_response() );
  my @delays;
  my $fc = Net::Async::Firecrawl->new(
    base_url => 'http://x',
    http => $http,
    delay_sub => sub { my $d = shift; push @delays, $d; Future->done },
  );
  $loop->add($fc);
  my $data = $fc->scrape( url => 'https://x' )->get;
  is $data->{markdown}, 'OK';
  is_deeply \@delays, [ 1 ];
  is scalar @{ $http->log }, 2;
};

subtest 'exhausted attempts fails Future with type=api' => sub {
  my $http = Test::ScriptedHTTP->new( err(503), err(503), err(503) );
  my $fc = Net::Async::Firecrawl->new(
    base_url => 'http://x', http => $http,
    delay_sub => sub { Future->done },
  );
  $loop->add($fc);
  my $f = $fc->scrape( url => 'https://x' );
  my @failure = $f->failure;
  ok $failure[0], 'future failed';
  isa_ok $failure[0], 'WWW::Firecrawl::Error';
  ok $failure[0]->is_api;
  is $failure[0]->status_code, 503;
  is $failure[0]->attempt, 3;
};

subtest 'Retry-After honored in async path' => sub {
  my $http = Test::ScriptedHTTP->new(
    HTTP::Response->new( 429, 'rl', [ 'Content-Type'=>'text/plain', 'Retry-After' => 5 ], '' ),
    ok_scrape_response(),
  );
  my @delays;
  my $fc = Net::Async::Firecrawl->new(
    base_url => 'http://x', http => $http,
    delay_sub => sub { push @delays, $_[0]; Future->done },
  );
  $loop->add($fc);
  $fc->scrape( url => 'https://x' )->get;
  is_deeply \@delays, [ 5 ];
};

done_testing;
