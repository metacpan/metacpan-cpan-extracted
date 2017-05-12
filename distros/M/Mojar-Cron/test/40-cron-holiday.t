use Mojo::Base -strict;
use Test::More;

use Mojar::Cron::Holiday;

my $h;  # holiday object

subtest q{new} => sub {
  ok $h = Mojar::Cron::Holiday->new, 'new';
  ok ! $h->holiday, 'omitted date';
  ok ! $h->holiday('2014-01-01'), 'omitted setup';
};

subtest q{via attribute} => sub {
  ok $h->holidays({'2014-01-01' => 1, '2014-05-05' => 1, '2014-05-26' => 1,
      '2014-12-24' => 1, '2014-12-25' => 1}), 'set attribute';
  for my $date (qw(2014-01-01 2014-05-05 2014-05-26 2014-12-24 2014-12-25)) {
    ok $h->holiday($date), 'marked holiday';
  }
  for my $date (qw(2014-01-02 2014-05-04 2014-05-06 2014-12-23 2014-12-26)) {
    ok ! $h->holiday($date), 'marked non-holiday';
  }
};

subtest q{via method} => sub {
  ok delete $h->{holidays}, 'reset attribute';
  for my $date (qw(2014-01-01 2014-05-05 2014-05-26 2014-12-24 2014-12-25)) {
    ok ref($h->holiday($date => 1)), 'set holiday';
  }
  for my $date (qw(2014-01-02 2014-05-04 2014-05-06 2014-12-23 2014-12-26)) {
    ok ref($h->holiday($date => 0)), 'set non-holiday';
  }
  for my $date (qw(2014-01-01 2014-05-05 2014-05-26 2014-12-24 2014-12-25)) {
    ok $h->holiday($date), 'marked holiday';
  }
  for my $date (qw(2014-01-02 2014-05-04 2014-05-06 2014-12-23 2014-12-26)) {
    ok ! $h->holiday($date), 'marked non-holiday';
  }
};

subtest q{via method with bundle} => sub {
  ok delete $h->{holidays}, 'reset attribute';
  ok $h->holiday([qw(2014-01-01 2014-05-05 2014-05-26)] => 1),
      'set holiday';
  ok $h->holiday([qw(2014-01-02 2014-05-04 2014-05-26)] => 0),
      'set non-holiday';
  for my $date (qw(2014-01-01 2014-05-05)) {
    ok $h->holiday($date), 'marked holiday';
  }
  for my $date (qw(2014-01-02 2014-05-04 2014-05-26)) {
    ok ! $h->holiday($date), 'marked non-holiday';
  }
};

subtest q{with linked} => sub {
  ok my $national = Mojar::Cron::Holiday->new(holidays => {
    '2016-01-01' => 1,
    '2016-01-04' => 1,
    '2016-03-25' => 1,
    '2016-05-02' => 1,
    '2016-05-30' => 1,
    '2016-08-01' => 1,
    '2016-11-30' => 1,
    '2016-12-26' => 1,
    '2016-12-27' => 1
  }), 'set national dates';
  ok my $regional = Mojar::Cron::Holiday->new(linked => $national, holidays => {
    '2016-01-04' => 0,
    '2016-03-28' => 1,
    '2016-08-01' => 0,
    '2016-08-29' => 1,
    '2016-11-30' => 0
  }), 'overrode with local variations';

  ok $national->holiday('2016-01-04'), 'base';
  ok ! $regional->holiday('2016-01-04'), 'overridden';

  ok ! $national->holiday('2016-03-28'), 'base';
  ok $regional->holiday('2016-03-28'), 'local';

  ok ! $national->holiday('2016-02-14'), 'base';
  ok ! $regional->holiday('2016-02-14'), 'not set';

  is $national->next_holiday('2016-08-02'), '2016-11-30', 'national';
  is $regional->next_holiday('2016-08-02'), '2016-08-29', 'regional';
};

subtest q{next_holiday} => sub {
  ok $h->next_holiday('2012-06-06'), 'found something';
  is $h->next_holiday('2014-01-01'), '2014-01-01', 'expected holiday';
  is $h->next_holiday('2014-01-02'), '2014-05-05', 'expected holiday';
  is $h->next_holiday('2014-02-28'), '2014-05-05', 'expected holiday';
  ok ! $h->next_holiday('2014-12-27'), 'no more holidays';
};

done_testing();
