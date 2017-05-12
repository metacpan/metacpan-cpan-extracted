#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Fatal;
use Plack::Middleware::Debug::DBIC::QueryLog;

ok my $app = sub { [200, ['Content-Type' => 'text/plain'], ['Hello!']] },
  'made a plack compatible application';

is(
  exception { $app = Plack::Middleware::Debug::DBIC::QueryLog->wrap($app) },
  undef,
  'No errors wrapping the application',
);

done_testing();

