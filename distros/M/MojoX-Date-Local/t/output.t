use Mojo::Base -strict;

use Test::More 1.302175;
use Mojo::Date;
use MojoX::Date::Local;
use POSIX qw(strftime);

my $test_tz = "America/Los_Angeles";

$ENV{TZ} = $test_tz;

my $epoch      = 784111777;
my $local_date = MojoX::Date::Local->new($epoch);
my $date_iso   = "1994-11-06T00:49:37-08:00";
is $local_date->to_datetime, $date_iso,
  "datetime should match RFC 3339 for system's current offset";

my $micro_epoch    = "$epoch.123";
my $micro_date     = MojoX::Date::Local->new($micro_epoch);
my $date_micro_iso = "1994-11-06T00:49:37.123-08:00";
is $micro_date->to_datetime, $date_micro_iso,
  "datetime extends to sub-seconds if included in epoch";

my @local_time = localtime $epoch;
my $default_formatted = strftime $MojoX::Date::Local::DEFAULT_FORMAT, @local_time;
is $local_date->format(), $default_formatted,
  "formatted MojoX::Date::Local should match strftime";

my $time_format = '%H:%M:%S';
my $time_formatted = strftime $time_format, @local_time;
is $local_date->format( $time_format ), $time_formatted,
  "custom format strings allowed";

done_testing();
