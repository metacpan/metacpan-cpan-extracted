#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Test::More;
use Plack::Test;
use Plack::Builder;
use Plack::Middleware::Debug::DBIC::QueryLog;
use Plack::Middleware::DBIC::QueryLog;
use HTTP::Request::Common qw(GET);
use Scalar::Util qw(refaddr);
use Data::Dump ();

ok my $app = sub {
  my $env = shift;
  my $querylog = Plack::Middleware::DBIC::QueryLog->get_querylog_from_env($env);
  my %tests = (
    key_exists => ($querylog ? 1:0),
    refaddr => refaddr($querylog),
    isa => ref($querylog),
  );

  [200, ['Content-Type' =>'text/application'], [Data::Dump::dump %tests]];
}, 'Got a sample plack application';

$app = builder {
  enable 'Debug', panels =>['DBIC::QueryLog'];
  $app;
};

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
