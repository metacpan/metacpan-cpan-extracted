use Mojo::Base -strict;
use Test::More;

use Mojar::Cron;

local *expand = \&Mojar::Cron::expand;

subtest q{expand} => sub {
  is_deeply expand(sec => undef), undef, 'sec=undef';
  is_deeply expand(sec => '*'), undef, 'sec=*';
  is_deeply expand(sec => '0'), [0], 'sec=0';
  is_deeply expand(sec => '*/10'), [0, 10, 20, 30, 40, 50], 'sec=*/10';
  is_deeply expand(sec => '3-5,7-9'), [3, 4, 5, 7, 8, 9], 'sec=3-5,7-9';
  is_deeply expand(sec => '3-21/5'), [3, 8, 13, 18], 'sec=3-21/5';

  is_deeply expand(day => undef), undef, 'day=undef';
  is_deeply expand(day => '1'), [0], 'day=1';
  is_deeply expand(day => '*/5'), [0, 5, 10, 15, 20, 25, 30], 'day=*/5';

  is_deeply expand(month => 'jan'), [0], 'month=jan';
  is_deeply expand(month => 'mar-sep'), [2 .. 8], 'month=mar-sep';
  is_deeply expand(month => '4'), [3], 'month=4';
  is_deeply expand(month => '*/4'), [0, 4, 8], 'month=*/4';

  is_deeply expand(weekday => undef), undef, 'weekday=undef';
  is_deeply expand(weekday => 0), [0], 'weekday=0';
  is_deeply expand(weekday => '2'), [2], 'weekday=2 (string)';
  is_deeply expand(weekday => 7), [0], 'weekday=7';
  is_deeply expand(weekday => 'sun'), [0], 'weekday=sun';
  is_deeply expand(weekday => 'wed'), [3], 'weekday=wed';
  is_deeply expand(weekday => 'mon-fri'), [1 .. 5], 'weekday=mon-fri';
  is_deeply expand(weekday => 'sat-sun'), [0, 6], 'weekday=sat-sun';
  is_deeply expand(weekday => '5-7'), [0, 5, 6], 'weekday=5-7';
  is_deeply expand(weekday => 'thu-sun'), [0, 4, 5, 6], 'weekday=thu-sun';
  is_deeply expand(weekday => 'fri-sat,sun-mon'), [0, 1, 5, 6], 'weekday=fri-mon';
};

done_testing();
