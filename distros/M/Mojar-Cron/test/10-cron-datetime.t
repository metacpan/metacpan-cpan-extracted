use Mojo::Base -strict;
use Test::More;

use Mojar::Cron::Datetime;

my $dt;

subtest q{Basics} => sub {
  is $Mojar::Cron::Datetime::Max{weekday}, 6, 'Max weekday from hash';
  is $Mojar::Cron::Datetime::Max[5], 6, 'Max weekday from array';
};

subtest q{Constructors} => sub {
  ok $dt = Mojar::Cron::Datetime->new, 'new';
  ok $dt = Mojar::Cron::Datetime->now, 'now';
  ok $dt = $dt->new, 'clone';
};

subtest q{Strings} => sub {
  my $a = '2012-02-29 23:59:59';
  ok $dt = $dt->from_string($a), 'from_string';
  is $dt->to_string, $a, 'from_string then to_string roundtrip';
};

sub check_normalise {
  my ($in, $expected) = @_;
  my $datetime = Mojar::Cron::Datetime->from_string($in);
  is $datetime->to_string, $expected, "from_string $in";
  $datetime->normalise;
  is $datetime->to_string, $expected, "normalise $in";
}

subtest q{normalise} => sub {
  check_normalise('2012-01-01 00:00:00', '2012-01-01 00:00:00');
  check_normalise('2010-01-19 00:00:00', '2010-01-19 00:00:00');
  check_normalise('2012-02-29 23:59:59', '2012-02-29 23:59:59');
  check_normalise('2012-02-30 23:59:59', '2012-03-01 23:59:59');
};

subtest q{weekday} => sub {
  ok $dt = Mojar::Cron::Datetime->from_string('2012-02-29 00:30:00'),
      'from_string';
  is $dt->weekday, 3, 'expected weekday';

  ok $dt = Mojar::Cron::Datetime->new(0, 30, 0, 28, 1, 112), 'new';
  is $dt->[3], 28, 'raw';
  is $dt->weekday, 3, 'expected weekday';
  is $dt->[3], 28, 'not mutated by weekday';
  is $dt->new->weekday, 3, 'expected weekday (clone)';
  is $dt->[3], 28, 'not mutated by clone';

  ok $dt->[3] += 3, 'incr day';
  is $dt->[3], 31, 'raw';
  is $dt->weekday, 6, 'expected weekday';
  is $dt->[3], 31, 'not mutated by weekday';
  is $dt->new->weekday, 6, 'expected weekday (clone)';
  is $dt->[3], 31, 'not mutated by clone';
};

done_testing();
