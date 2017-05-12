use Mojo::Base -strict;
use Test::More;

use Mojar::Cron;
use Mojar::Cron::Datetime;

my $cron;
subtest q{new} => sub {
  ok $cron = Mojar::Cron->new(min => 10, hour => 3, day => 15, month => 2),
      'new from attributes';
  is_deeply [ map $cron->$_, qw(sec min hour day month weekday is_local) ],
            [[0], [10], [3], [14], [1], undef, undef],
            'internal values agree (attributes)';

  ok $cron = Mojar::Cron->new(parts => [20, 10, undef, undef, 2],
      is_local => 1), 'new from parts';
  is_deeply [ map $cron->$_, qw(sec min hour day month weekday is_local) ],
            [[0], [20], [10], undef, undef, [2], 1],
            'internal values agree (parts)';

  ok $cron = Mojar::Cron->new(pattern => '* * 1 */3 *', is_local => 0),
      'new from pattern';
  is_deeply [ map $cron->$_, qw(sec min hour day month weekday is_local) ],
            [[0], undef, undef, [0], [0,3,6,9], undef, 0],
            'internal values agree (pattern)';
};

# Zero cron (*-01-01 00:00:00 Sun)
my $cron_str = '0 0 1 1 0';
subtest qq{Cron rec $cron_str} => sub {
  $cron = Mojar::Cron->new(pattern => $cron_str);

  is_deeply [ map $cron->$_, qw( sec min hour day month weekday ) ],
            [[0], [0], [0], [0], [0], [0]],
            "Attributes for cron: $cron_str";
};

# Unrestricted (every min)
$cron_str = '* * * * *';
subtest qq{Cron rec $cron_str} => sub {
  $cron = Mojar::Cron->new(pattern => $cron_str);

  is_deeply [ map $cron->$_, qw( sec min hour day month weekday ) ],
            [[0], undef, undef, undef, undef, undef],
            "Attributes for cron: $cron_str";
};

# Unrestricted (every sec)
$cron_str = '* * * * * *';
subtest qq{Cron rec $cron_str} => sub {
  $cron = Mojar::Cron->new(pattern => $cron_str);

  is_deeply [ map $cron->$_, qw( sec min hour day month weekday ) ],
            [undef, undef, undef, undef, undef, undef],
            "Attributes for cron: $cron_str";
};

done_testing();
