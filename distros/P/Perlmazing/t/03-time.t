use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 3;
use Perlmazing;

my $time = time;
my $core_time = CORE::time();

is (($core_time == int($core_time)), 1, 'core time is correct');
is (($time >= ($core_time - 1) and $time <= ($core_time + 1)), 1, 'time is good');
is ((length($time) >= (length($core_time) + 2) and substr($time, length($core_time), 2) =~ /^\.\d$/), 1, 'time has nanoseconds');