#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use IO::Async::Loop;
use Future;
use HTTP::Response;
use JSON::MaybeXS qw( encode_json );
use URI;

use Net::Async::WebSearch;
use Net::Async::WebSearch::Provider::Google;

# Scripted HTTP double for the Google CSE endpoint. Serves a synthetic result
# pool of `pool` items, honouring the `start`/`num` query params exactly the way
# the real API does (<=10 per call, `start` 1-based). Logs every request so the
# paging behaviour can be asserted. `fail_at_start` makes one page return 500.
{
  package Test::WS::GoogleHTTP;
  use Future;
  use HTTP::Response;
  use JSON::MaybeXS qw( encode_json );
  use URI;
  sub new {
    my ( $class, %args ) = @_;
    bless {
      pool          => $args{pool}          || 0,
      fail_at_start => $args{fail_at_start},
      log           => [],
    }, $class;
  }
  sub log { $_[0]->{log} }
  # Notifier plumbing the orchestrator pokes at when a mock http is injected.
  sub configure {}
  sub configure_unknown {}
  sub add_child {}
  sub remove_child {}
  sub _add_to_loop {}
  sub _remove_from_loop {}
  sub parent { }
  sub loop { }
  sub notifier_name { 'mock' }

  sub do_request {
    my ( $self, %args ) = @_;
    my $req = $args{request};
    my $uri = URI->new( $req->uri.'' );
    my %q   = $uri->query_form;
    push @{ $self->{log} }, {
      start => $q{start}, num => $q{num}, q => $q{q}, url => $uri.'',
    };

    if ( defined $self->{fail_at_start}
      && defined $q{start} && $q{start} == $self->{fail_at_start} ) {
      my $res = HTTP::Response->new(
        500, 'Server Error', [ 'Content-Type' => 'application/json' ], '{}',
      );
      $res->request($req);
      return Future->done($res);
    }

    my $start = $q{start} || 1;
    my $num   = $q{num}   || 10;
    my @items;
    for my $i ( $start .. $start + $num - 1 ) {
      last if $i > $self->{pool};
      push @items, {
        link        => "https://example.com/r$i",
        title       => "Result $i",
        snippet     => "snippet $i",
        displayLink => 'example.com',
      };
    }
    my $body = encode_json( @items ? { items => \@items } : {} );
    my $res = HTTP::Response->new(
      200, 'OK', [ 'Content-Type' => 'application/json' ], $body,
    );
    $res->request($req);
    return Future->done($res);
  }
}

sub make_provider {
  Net::Async::WebSearch::Provider::Google->new( api_key => 'K', cx => 'CX' );
}

subtest 'limit <= 10 makes a single call sized to the limit' => sub {
  my $mock = Test::WS::GoogleHTTP->new( pool => 100 );
  my $out  = make_provider()->search( $mock, 'perl', { limit => 5 } )->get;

  is scalar @{ $mock->log }, 1, 'one HTTP call';
  is $mock->log->[0]{start}, 1, 'start=1';
  is $mock->log->[0]{num},   5, 'num sized to the limit';
  is scalar @$out, 5, 'five results';
  is_deeply [ map { $_->rank } @$out ], [ 1 .. 5 ], 'ranks 1..5';
};

subtest 'default limit of 10 is a single 10-wide call' => sub {
  my $mock = Test::WS::GoogleHTTP->new( pool => 100 );
  my $out  = make_provider()->search( $mock, 'perl', {} )->get;

  is scalar @{ $mock->log }, 1, 'one HTTP call';
  is $mock->log->[0]{num}, 10, 'num=10';
  is scalar @$out, 10, 'ten results';
};

subtest 'limit > 10 pages over start until the limit is met' => sub {
  my $mock = Test::WS::GoogleHTTP->new( pool => 100 );
  my $out  = make_provider()->search( $mock, 'perl', { limit => 25 } )->get;

  is scalar @{ $mock->log }, 3, 'three HTTP calls for 25 results';
  is_deeply [ map { $_->{start} } @{ $mock->log } ], [ 1, 11, 21 ],
    'start walks 1,11,21';
  is_deeply [ map { $_->{num} } @{ $mock->log } ], [ 10, 10, 5 ],
    'last page sized to the remaining 5 — limit not overshot';

  is scalar @$out, 25, 'exactly 25 results merged';
  is_deeply [ map { $_->rank } @$out ], [ 1 .. 25 ],
    'continuous rank across page boundaries';
  my @urls = map { $_->url } @$out;
  is_deeply [ @urls ], [ map { "https://example.com/r$_" } 1 .. 25 ],
    'pages concatenated in order, no duplicates or gaps';
  is scalar( keys %{ { map { $_ => 1 } @urls } } ), 25, 'all urls unique';
};

subtest 'stops early when the upstream runs dry before the limit' => sub {
  my $mock = Test::WS::GoogleHTTP->new( pool => 13 );
  my $out  = make_provider()->search( $mock, 'perl', { limit => 50 } )->get;

  is scalar @$out, 13, 'only the 13 available results returned';
  is_deeply [ map { $_->{start} } @{ $mock->log } ], [ 1, 11, 14 ],
    'paged until an empty page signalled exhaustion';
  is_deeply [ map { $_->rank } @$out ], [ 1 .. 13 ], 'ranks 1..13';
};

subtest 'never pages past the CSE 100-result ceiling' => sub {
  my $mock = Test::WS::GoogleHTTP->new( pool => 500 );
  my $out  = make_provider()->search( $mock, 'perl', { limit => 150 } )->get;

  is scalar @$out, 100, 'capped at 100 despite limit=150 and a deep pool';
  is scalar @{ $mock->log }, 10, 'ten pages of ten';
  my $max_start = ( sort { $b <=> $a } map { $_->{start} } @{ $mock->log } )[0];
  is $max_start, 91, 'deepest start is 91';
  ok !( grep { $_->{start} + $_->{num} - 1 > 100 } @{ $mock->log } ),
    'no request reaches beyond result #100';
};

subtest 'an HTTP error on a later page fails the whole search' => sub {
  my $mock = Test::WS::GoogleHTTP->new( pool => 100, fail_at_start => 11 );
  my $f    = make_provider()->search( $mock, 'perl', { limit => 25 } );
  ok $f->is_ready, 'future settled (mock responds synchronously)';
  my $err  = $f->failure;
  ok $err, 'search future failed';
  like $err, qr/google: HTTP 500/, 'HTTP status surfaced from the failing page';
  is scalar @{ $mock->log }, 2, 'stopped after the failing page (no further paging)';
};

subtest 'more than 10 Google hits survive the collect-mode merge' => sub {
  my $loop = IO::Async::Loop->new;
  my $mock = Test::WS::GoogleHTTP->new( pool => 100 );
  my $ws   = Net::Async::WebSearch->new( http => $mock );
  $loop->add($ws);
  $ws->add_provider( make_provider() );

  # per_provider_limit drives how many Google is asked for; limit trims the
  # merged list. Both must exceed 10 to prove paging reaches the caller.
  my $out = $ws->search(
    query => 'perl', only => ['google'],
    limit => 25, per_provider_limit => 25,
  )->get;
  is scalar @{ $out->{results} }, 25, '25 merged results reach the caller';
  is scalar @{ $out->{errors} },  0, 'no provider errors';
  ok $out->{results}[0]->score > 0, 'RRF score assigned in collect mode';
};

done_testing;
