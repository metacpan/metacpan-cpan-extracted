#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Fatal;

use Plack::Middleware::Debug::Log4perl;

ok my $app = sub { [200, ['Content-Type' => 'text/plain'], ['Hello!']] },
  'made a plack compatible application';

is(
  exception { $app = Plack::Middleware::Debug::Log4perl->wrap($app) },
  undef,
  'No errors wrapping the application',
);

done_testing();


