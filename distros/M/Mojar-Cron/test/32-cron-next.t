use Mojo::Base -strict;
use Test::More;

use Mojar::Cron;
use Mojar::Cron::Datetime;

# Build times based on 2012-01-01 00:00:00
my $base_time = Mojar::Cron::Datetime->from_string('2012-01-01 00:00:00')
    ->to_timestamp;
is $base_time, '1325376000', 'base time';

my $cron;
sub next_times {
  my ($cron_str, $qty) = @_;
  $cron = Mojar::Cron->new(pattern => $cron_str);
  my $time = $base_time;
  my @times;

  for (1 .. $qty) {
    $time = $cron->next($time);
    push @times, Mojar::Cron::Datetime->from_timestamp($time)->to_string;
  }

  return @times;
}

# Wild sec
is_deeply [next_times '* * * * * *', 3],
   [ '2012-01-01 00:00:01',
     '2012-01-01 00:00:02',
     '2012-01-01 00:00:03' ], 'every sec';

# Wild min
is_deeply [next_times '0 * * * * *', 3],
   [ '2012-01-01 00:01:00',
     '2012-01-01 00:02:00',
     '2012-01-01 00:03:00' ], 'every min';

# Stepped min
is_deeply [next_times '*/10 * * * *', 7],
   [ '2012-01-01 00:10:00',
     '2012-01-01 00:20:00',
     '2012-01-01 00:30:00',
     '2012-01-01 00:40:00',
     '2012-01-01 00:50:00',
     '2012-01-01 01:00:00',
     '2012-01-01 01:10:00' ], 'every 10 min';

# Stepped min, restricted hour
is_deeply [next_times '*/30 6 * * *', 5],
   [ '2012-01-01 06:00:00',
     '2012-01-01 06:30:00',
     '2012-01-02 06:00:00',
     '2012-01-02 06:30:00',
     '2012-01-03 06:00:00' ], 'every 30 min 6th hour';

# Day
is_deeply [next_times '0 0 31 * *', 7],
   [ '2012-01-31 00:00:00',
     '2012-03-31 00:00:00',
     '2012-05-31 00:00:00',
     '2012-07-31 00:00:00',
     '2012-08-31 00:00:00',
     '2012-10-31 00:00:00',
     '2012-12-31 00:00:00' ], 'midnight on 31st';

# Month
is_deeply [next_times '0 0 1 3 *', 3],
   [ '2012-03-01 00:00:00',
     '2013-03-01 00:00:00',
     '2014-03-01 00:00:00' ], 'yearly 1st Mar';

# Weekday
is_deeply [next_times '0 0 * * mon', 6],
   [ '2012-01-02 00:00:00',
     '2012-01-09 00:00:00',
     '2012-01-16 00:00:00',
     '2012-01-23 00:00:00',
     '2012-01-30 00:00:00',
     '2012-02-06 00:00:00' ], 'every Mon';

# Weekday (end of range)
is_deeply [next_times '0 0 * * sat', 5],
   [ '2012-01-07 00:00:00',
     '2012-01-14 00:00:00',
     '2012-01-21 00:00:00',
     '2012-01-28 00:00:00',
     '2012-02-04 00:00:00' ], 'every Sat';

# Weekday range
is_deeply [next_times '0 0 * * mon-fri', 6],
   [ '2012-01-02 00:00:00',
     '2012-01-03 00:00:00',
     '2012-01-04 00:00:00',
     '2012-01-05 00:00:00',
     '2012-01-06 00:00:00',
     '2012-01-09 00:00:00' ], 'Mon-Fri';

# Day & weekday
is_deeply [next_times '20 2 12 * tue', 8],
   [ '2012-01-03 02:20:00',
     '2012-01-10 02:20:00',
     '2012-01-12 02:20:00',
     '2012-01-17 02:20:00',
     '2012-01-24 02:20:00',
     '2012-01-31 02:20:00',
     '2012-02-07 02:20:00',
     '2012-02-12 02:20:00' ], '02:20 12th or Tuesday';

# Day range, restricted month
is_deeply [next_times '00 01 3-5 02 *', 4],
   [ '2012-02-03 01:00:00',
     '2012-02-04 01:00:00',
     '2012-02-05 01:00:00',
     '2013-02-03 01:00:00' ], '3-5 Feb';

# Rollover sec -> min
is_deeply [next_times '0-1 * * * * *', 4],
   [ '2012-01-01 00:00:01',
     '2012-01-01 00:01:00',
     '2012-01-01 00:01:01',
     '2012-01-01 00:02:00' ], 'rollover seconds';

# Rollover sec -> month
is_deeply [next_times '59 59 23 31 01,03 *', 3],
   [ '2012-01-31 23:59:59',
     '2012-03-31 23:59:59',
     '2013-01-31 23:59:59' ], 'last second of the month';

# Rollover sec -> year
is_deeply [next_times '59 59 23 31 12 *', 3],
   [ '2012-12-31 23:59:59',
     '2013-12-31 23:59:59',
     '2014-12-31 23:59:59' ], 'last second of the year';

# Stepped weekday, unrestricted day
is_deeply [next_times '00 00 03  *  * */5', 3],
   [ '2012-01-01 03:00:00',
     '2012-01-06 03:00:00',
     '2012-01-08 03:00:00' ], '3 am every 2 weekdays';

# Build times based on 2012-02-01 00:00:00
ok $base_time = Mojar::Cron::Datetime->from_string('2012-02-01 00:00:00')
    ->to_timestamp, 'use 2012-02-01';

# Stepped day, reset at month-end
is_deeply [next_times '00 00 03 */11  * *', 4],
   [ '2012-02-01 03:00:00',
     '2012-02-12 03:00:00',
     '2012-02-23 03:00:00',
     '2012-03-01 03:00:00' ], '3 am every 10 days';

# Restricted weekday & month
is_deeply [next_times '00 00 01  * 3,5 sat', 10],
   [ '2012-03-03 01:00:00',
     '2012-03-10 01:00:00',
     '2012-03-17 01:00:00',
     '2012-03-24 01:00:00',
     '2012-03-31 01:00:00',
     '2012-05-05 01:00:00',
     '2012-05-12 01:00:00',
     '2012-05-19 01:00:00',
     '2012-05-26 01:00:00',
     '2013-03-02 01:00:00' ], 'Sat in Jan & Mar';

done_testing();
