use Mojo::Base -strict;
use Test::More;

use Mojar::Cron::Util qw( utc_to_ts local_to_ts ts_to_utc ts_to_local
  local_to_utc utc_to_local normalise_utc normalise_local date_today date_next
  time_to_zero zero_to_time cron_to_zero zero_to_cron life_to_zero zero_to_life
  tz_offset
);
use Mojar::Cron::Datetime;

my ($dt, $es);

subtest q{Last second of Feb '12} => sub {
  ok $dt = Mojar::Cron::Datetime->new([59, 59, 23, 28, 01, 112]), 'new (Feb)';

  ok $es = utc_to_ts(zero_to_time @$dt), 'datetime -> epoch secs';

  ok my @lt = ts_to_local($es), 'timestamp -> local time';
  ok my @zero = time_to_zero(local_to_utc @lt), 'local time -> datetime';
  is_deeply [@zero], $dt, 'local -> utc -> datetime';

  is_deeply [ zero_to_life @zero ], [59, 59, 23, 29, 2, 2012, 3, 59, 0],
      'datetime -> real life';
};

subtest q{normalise_utc} => sub {
  my @date = (00, 00, 02, 31, 02, 2012);
  ok my @zero = life_to_zero(@date), 'real life -> datetime';
  is_deeply [ @zero ], [00, 00, 02, 30, 01, 112], 'correct parts';
  ok $dt = Mojar::Cron::Datetime->new(@zero), 'datetime constructed';

  $dt->[3] = 30; $dt->[4] = 1;
  is_deeply [ @$dt[0..5] ], [00, 00, 02, 30, 01, 112], 'before normalise';
  ok @$dt = time_to_zero(normalise_utc zero_to_time @$dt), 'normalise';
  is_deeply [ @$dt[0..5] ], [00, 00, 02, 01, 02, 112], 'after normalise';

  @$dt = (00, 00, 02, 29, 01, 112);
  is_deeply $dt, [00, 00, 02, 29, 01, 112], 'before normalise';
  ok @$dt = time_to_zero(normalise_utc zero_to_time @$dt), 'normalise';
  is_deeply [ @$dt[0..5] ], [00, 00, 02, 00, 02, 112], 'after normalise';
};

subtest q{date_} => sub {
  my @lt = localtime();
  ok date_today(), 'got date_today';
  is date_today(), Mojar::Cron::Datetime->now(1)->to_string('%Y-%m-%d'),
      'agrees with MCD';

  my @today;
  ok date_today() =~ /^(\d\d\d\d)-(\d\d)-(\d\d)$/, 'iso-ish format'
      and @today = ($1,$2,$3);
  cmp_ok $today[0], '==', (localtime)[5] + 1900, 'year is correct';
  cmp_ok $today[1], '==', (localtime)[4] + 1, 'month is correct';
  cmp_ok $today[2], '==', (localtime)[3], 'day is correct';

  is date_next('2015-01-31'), '2015-02-01', 'Jan rollover';
  is date_next('2015-02-28'), '2015-03-01', 'Feb rollover';
  is date_next('2015-12-31'), '2016-01-01', 'Dec rollover';
};

subtest q{_format_offset} => sub {
  is Mojar::Cron::Util::_format_offset(0), '+0000', 'no offset';
  is Mojar::Cron::Util::_format_offset(105), '+0145', 'pos offset';
  is Mojar::Cron::Util::_format_offset(-105), '-0145', 'neg offset';
  is Mojar::Cron::Util::_format_offset(-120), '-0200', 'neg offset';
};

subtest q{tz_offset format} => sub {
  like tz_offset(), qr/^.\d{4}$/, 'format now';
  like tz_offset(1410000000), qr/^.\d{4}$/, 'format 14';
  like tz_offset(1420000000), qr/^.\d{4}$/, 'format 15';
};

my $tzo;
eval {
  require POSIX;
  $tzo = POSIX::strftime('%z', localtime);
  $tzo =~ /^.\d{4}$/ or undef $tzo;
};
SKIP: {
  skip 'No reference value', 1 unless $tzo;  # eg Windows

subtest q{tz_offset actual} => sub {
  is tz_offset(), $tzo, 'actual local timezone offset';

  ok $tzo = POSIX::strftime('%z', localtime(1420000000));
  is tz_offset(1420000000), $tzo, 'winter time';

  ok $tzo = POSIX::strftime('%z', localtime(1410000000));
  is tz_offset(1410000000), $tzo, 'summer time';
};

};

done_testing();
