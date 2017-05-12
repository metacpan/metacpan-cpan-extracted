use Mojo::Base -strict;
use Test::More;

use Mojar::Cron;
use Mojar::Cron::Datetime;

my ($cron, $dt, $t);
subtest q{setup} => sub {
  ok $cron = Mojar::Cron->new(pattern => '0 0 * * sat', is_local => 0),
      'new from pattern';
  is_deeply [ map $cron->$_, qw(sec min hour day month weekday is_local) ],
            [[0], [0], [0], undef, undef, [6], 0],
            'internal values agree (pattern)';

  # Build times based on 2012-01-28 00:00:01
  ok $dt = Mojar::Cron::Datetime->from_string('2012-01-28 00:00:01'),
      'set up datetime';
};

subtest q{satisfiable} => sub {
  is_deeply [ map $dt->[$_], 0 .. 4, 6 ],
            [1,0,0,27,00,6],
            '2012-01-28 00:01:00 Sat';

  ok $cron->satisfiable(4, $dt), 'satisfiable month';
  ok $cron->satisfiable(6, $dt), 'satisfiable weekday';
  ok $cron->satisfiable(2, $dt), 'satisfiable hour';
  ok $cron->satisfiable(1, $dt), 'satisfiable min';
  ok ! $cron->satisfiable(0, $dt), 'unsatisfiable sec';
  is_deeply [ map $dt->[$_], 0 .. 4, 6 ], [00,01,00,27,00,6],
      '2012-01-28 00:01:00 Sat';

  ok $cron->satisfiable(4, $dt), 'satisfiable month';
  ok $cron->satisfiable(6, $dt), 'satisfiable weekday';
  ok $cron->satisfiable(2, $dt), 'satisfiable hour';
  ok ! $cron->satisfiable(1, $dt), 'unsatisfiable min';
  is_deeply [ map $dt->[$_], 0 .. 4, 6 ], [00,00,01,27,00,6],
      '2012-01-28 01:00:00 Sat';

  ok $cron->satisfiable(4, $dt), 'satisfiable month';
  ok $cron->satisfiable(6, $dt), 'satisfiable weekday';
  ok ! $cron->satisfiable(2, $dt), 'unsatisfiable hour';
  is_deeply [ map $dt->[$_], 0 .. 4, 6 ], [00,00,00,28,00,0],
      '2012-01-29 00:00:00 Sun';

  ok $cron->satisfiable(4, $dt), 'satisfiable month';
  ok ! $cron->satisfiable(6, $dt), 'unsatisfiable weekday';
  is_deeply [ map $dt->[$_], 0 .. 4, 6 ], [00,00,00,00,01,6],
      '2012-02-01 00:00:00 Sat';

  ok $cron->satisfiable(4, $dt), 'satisfiable month';
  ok $cron->satisfiable(6, $dt), 'satisfiable weekday';
  ok $cron->satisfiable(2, $dt), 'satisfiable hour';
  ok $cron->satisfiable(1, $dt), 'satisfiable min';
  ok $cron->satisfiable(0, $dt), 'satisfiable sec';
  is_deeply [ map $dt->[$_], 0 .. 4, 6 ], [00,00,00,03,01,6],
      '2012-02-04 00:00:00 Sat';
};

subtest q{satisfiable2} => sub {
  ok $cron = Mojar::Cron->new(pattern => '1 2 3 4 5 6'), 'set up cron';
  ok $dt = Mojar::Cron::Datetime->from_string('2012-02-25 00:00:00'),
      'set up datetime';

  is_deeply [ map $dt->[$_], 0 .. 4, 6 ],
            [0,0,0,24,01,6],
            '2012-02-25 00:00:00 Sat';

  ok $cron->satisfiable(0, $dt), 'satisfiable sec';
  is_deeply [ map $dt->[$_], 0 .. 0 ], [1], 'sec';

  ok $cron->satisfiable(1, $dt), 'satisfiable min';
  is_deeply [ map $dt->[$_], 0 .. 1 ], [0,2], 'sec min';

  ok $cron->satisfiable(2, $dt), 'satisfiable hour';
  is_deeply [ map $dt->[$_], 0 .. 2 ], [0,0,3], 'sec min hour';

  ok $cron->satisfiable(4, $dt), 'satisfiable month';
  ok $cron->satisfiable(3, $dt), 'satisfiable day';
  ok $cron->satisfiable(2, $dt), 'satisfiable hour';
  ok $cron->satisfiable(1, $dt), 'satisfiable min';
  ok $cron->satisfiable(0, $dt), 'satisfiable sec';
  is_deeply [ map $dt->[$_], 0 .. 4, 6 ], [1,2,3,3,4,5],
      'sec min hour day month weekday';

  ok $cron->satisfiable(4, $dt), 'satisfiable month';
  ok $cron->satisfiable(6, $dt), 'satisfiable weekday';
  ok $cron->satisfiable(2, $dt), 'satisfiable hour';
  ok $cron->satisfiable(1, $dt), 'satisfiable min';
  ok $cron->satisfiable(0, $dt), 'satisfiable sec';
  is_deeply [ map $dt->[$_], 0 .. 4, 6 ], [1,2,3,4,4,6],
      'sec min hour day month weekday';
};

done_testing();
