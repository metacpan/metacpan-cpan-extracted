use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 5;
use Perlmazing qw(:time);

# We need to do this to avoid $time and $core_time to be taken on two different seconds (it has happened on testers)
my $time = CORE::time;
while (1) {
  my $new_time = CORE::time;
  last if $new_time > $time; # A new second has arrived and we now have a full second to act on it
}
$time = time;
my $core_time = CORE::time;

is (($core_time == int($core_time)), 1, 'core time is correct');
is (($time >= ($core_time - 1) and $time <= ($core_time + 1)), 1, 'time is good');
is ((length($time) >= (length($core_time) + 2) and substr($time, length($core_time), 2) =~ /^\.\d$/), 1, 'time has nanoseconds');

my $localtime_ts = localtime_ts $time;
my $gmtime_ts = gmtime_ts $time;

is (($localtime_ts =~ /^\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2}\.\d{7}$/), 1, 'localtime_ts looks correct');
is (($gmtime_ts =~ /^\d{4}\-\d{2}\-\d{2} \d{2}:\d{2}:\d{2}\.\d{7}$/), 1, 'gmtime_ts looks correct');
