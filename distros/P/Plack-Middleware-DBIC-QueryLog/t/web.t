#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Plack::Test;
use Plack::Middleware::DBIC::QueryLog;
use HTTP::Request::Common qw(GET);
use Scalar::Util qw(refaddr);
use Data::Dump ();

ok my $app = sub {
  my $env = shift;
  my $querylog = $env->{+Plack::Middleware::DBIC::QueryLog::PSGI_KEY};
  my %tests = (
    key_exists => ($querylog ? 1:0),
    refaddr => refaddr($querylog),
    isa => ref($querylog),
  );

  [200, [], [Data::Dump::dump %tests]];
}, 'Got a sample plack application';

ok $app = Plack::Middleware::DBIC::QueryLog->wrap($app), 
  'Wrapped application with middleware';

test_psgi $app, sub {
  my $cb = shift;
  my $last_refaddr;
  for (0..1) {
    my %data = eval $cb->(GET '/')->content;

    ok $data{key_exists},
      'got PSGI_KEY';

    is $data{isa}, 'DBIx::Class::QueryLog',
      'Correct default querylog instance';

    if($last_refaddr) {
      isnt $last_refaddr, $data{refaddr},
        'Verify we get a new querylog each time';
    } else {
      $last_refaddr = $data{refaddr};
    }
  }
};

done_testing; 
