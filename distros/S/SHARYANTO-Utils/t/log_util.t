#!perl

use 5.010;
use strict;
use warnings;
use experimental 'smartmatch';

use Test::More 0.96;

use SHARYANTO::Log::Util qw(@log_levels $log_levels_re);

ok('warn'  ~~ @log_levels);
ok('debug' =~ $log_levels_re);

ok('foo'   !~~ @log_levels);
ok('foo'   !~  $log_levels_re);

DONE_TESTING:
done_testing();
