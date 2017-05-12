use strict;
use warnings;

use Test::More;
use PDL;
use PDL::DateTime;

my $start = ['1996-02-29T23:59:59.999999Z', '1899-12-31T23:59:59.999999Z'];

{
  my $dt = PDL::DateTime->new_from_datetime($start);
  is_deeply($dt->dt_add(year=>1)->dt_unpdl,        ['1997-02-28T23:59:59.999999','1900-12-31T23:59:59.999999'], "add(year       =>1     )");
  is_deeply($dt->dt_add(year=>4)->dt_unpdl,        ['2000-02-29T23:59:59.999999','1903-12-31T23:59:59.999999'], "add(year       =>4     )");
  is_deeply($dt->dt_add(year=>8)->dt_unpdl,        ['2004-02-29T23:59:59.999999','1907-12-31T23:59:59.999999'], "add(year       =>8     )");
  is_deeply($dt->dt_add(year=>104)->dt_unpdl,      ['2100-02-28T23:59:59.999999','2003-12-31T23:59:59.999999'], "add(year       =>104   )");
  is_deeply($dt->dt_add(month=>2)->dt_unpdl,       ['1996-04-29T23:59:59.999999','1900-02-28T23:59:59.999999'], "add(month      =>2     )");
  is_deeply($dt->dt_add(month=>3)->dt_unpdl,       ['1996-05-29T23:59:59.999999','1900-03-31T23:59:59.999999'], "add(month      =>3     )");
  is_deeply($dt->dt_add(month=>12345)->dt_unpdl,   ['3024-11-29T23:59:59.999999','2928-09-30T23:59:59.999999'], "add(month      =>12345 )");
  is_deeply($dt->dt_add(week=>2)->dt_unpdl,        ['1996-03-14T23:59:59.999999','1900-01-14T23:59:59.999999'], "add(week       =>2     )");
  is_deeply($dt->dt_add(week=>52)->dt_unpdl,       ['1997-02-27T23:59:59.999999','1900-12-30T23:59:59.999999'], "add(week       =>52    )");
  is_deeply($dt->dt_add(week=>123456)->dt_unpdl,   ['4362-03-29T23:59:59.999999','4266-01-28T23:59:59.999999'], "add(week       =>123456)");
  is_deeply($dt->dt_add(day=>2)->dt_unpdl,         ['1996-03-02T23:59:59.999999','1900-01-02T23:59:59.999999'], "add(day        =>2     )");
  is_deeply($dt->dt_add(hour=>2)->dt_unpdl,        ['1996-03-01T01:59:59.999999','1900-01-01T01:59:59.999999'], "add(hour       =>2     )");
  is_deeply($dt->dt_add(minute=>2)->dt_unpdl,      ['1996-03-01T00:01:59.999999','1900-01-01T00:01:59.999999'], "add(minute     =>2     )");
  is_deeply($dt->dt_add(second=>2)->dt_unpdl,      ['1996-03-01T00:00:01.999999','1900-01-01T00:00:01.999999'], "add(second     =>2     )");
  is_deeply($dt->dt_add(millisecond=>2)->dt_unpdl, ['1996-03-01T00:00:00.001999','1900-01-01T00:00:00.001999'], "add(millisecond=>2     )");
  is_deeply($dt->dt_add(microsecond=>2)->dt_unpdl, ['1996-03-01T00:00:00.000001','1900-01-01T00:00:00.000001'], "add(microsecond=>2     )");
}

{
  my $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_add(year=>1); is_deeply($dt->dt_unpdl,        [ '1997-02-28T23:59:59.999999', '1900-12-31T23:59:59.999999'], "inplace->add(year=>1)");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_add(year=>4); is_deeply($dt->dt_unpdl,        [ '2000-02-29T23:59:59.999999', '1903-12-31T23:59:59.999999'], "inplace->add(year=>4)");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_add(year=>8); is_deeply($dt->dt_unpdl,        [ '2004-02-29T23:59:59.999999', '1907-12-31T23:59:59.999999'], "inplace->add(year=>8)");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_add(year=>104); is_deeply($dt->dt_unpdl,      [ '2100-02-28T23:59:59.999999', '2003-12-31T23:59:59.999999'], "inplace->add(year=>104)");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_add(month=>2); is_deeply($dt->dt_unpdl,       [ '1996-04-29T23:59:59.999999', '1900-02-28T23:59:59.999999'], "inplace->add(month=>2)");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_add(month=>3); is_deeply($dt->dt_unpdl,       [ '1996-05-29T23:59:59.999999', '1900-03-31T23:59:59.999999'], "inplace->add(month=>3)");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_add(month=>12345); is_deeply($dt->dt_unpdl,   [ '3024-11-29T23:59:59.999999', '2928-09-30T23:59:59.999999'], "inplace->add(month=>12345)");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_add(week=>2); is_deeply($dt->dt_unpdl,        [ '1996-03-14T23:59:59.999999', '1900-01-14T23:59:59.999999'], "inplace->add(week=>2)");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_add(week=>52); is_deeply($dt->dt_unpdl,       [ '1997-02-27T23:59:59.999999', '1900-12-30T23:59:59.999999'], "inplace->add(week=>52)");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_add(week=>123456); is_deeply($dt->dt_unpdl,   [ '4362-03-29T23:59:59.999999', '4266-01-28T23:59:59.999999'], "inplace->add(week=>123456)");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_add(day=>2); is_deeply($dt->dt_unpdl,         [ '1996-03-02T23:59:59.999999', '1900-01-02T23:59:59.999999'], "inplace->add(day=>2)");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_add(hour=>2); is_deeply($dt->dt_unpdl,        [ '1996-03-01T01:59:59.999999', '1900-01-01T01:59:59.999999'], "inplace->add(hour=>2)");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_add(minute=>2); is_deeply($dt->dt_unpdl,      [ '1996-03-01T00:01:59.999999', '1900-01-01T00:01:59.999999'], "inplace->add(minute=>2)");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_add(second=>2); is_deeply($dt->dt_unpdl,      [ '1996-03-01T00:00:01.999999', '1900-01-01T00:00:01.999999'], "inplace->add(second=>2)");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_add(millisecond=>2); is_deeply($dt->dt_unpdl, [ '1996-03-01T00:00:00.001999', '1900-01-01T00:00:00.001999'], "inplace->add(millisecond=>2)");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_add(microsecond=>2); is_deeply($dt->dt_unpdl, [ '1996-03-01T00:00:00.000001', '1900-01-01T00:00:00.000001'], "inplace->add(microsecond=>2)");
}

{
  my $dt = PDL::DateTime->new_from_datetime(['7604-01-03T00:00:00.000001Z', '1972-01-10T00:00:00.000001Z']);
  is_deeply($dt->dt_add(year       =>-1    )->dt_unpdl, ['7603-01-03T00:00:00.000001','1971-01-10T00:00:00.000001'], "add(year       =>-1    )");
  is_deeply($dt->dt_add(year       =>-4    )->dt_unpdl, ['7600-01-03T00:00:00.000001','1968-01-10T00:00:00.000001'], "add(year       =>-4    )");
  is_deeply($dt->dt_add(year       =>-8    )->dt_unpdl, ['7596-01-03T00:00:00.000001','1964-01-10T00:00:00.000001'], "add(year       =>-8    )");
  is_deeply($dt->dt_add(year       =>-104  )->dt_unpdl, ['7500-01-03T00:00:00.000001','1868-01-10T00:00:00.000001'], "add(year       =>-104  )");
  is_deeply($dt->dt_add(month      =>-2    )->dt_unpdl, ['7603-11-03T00:00:00.000001','1971-11-10T00:00:00.000001'], "add(month      =>-2    )");
  is_deeply($dt->dt_add(month      =>-3    )->dt_unpdl, ['7603-10-03T00:00:00.000001','1971-10-10T00:00:00.000001'], "add(month      =>-3    )");
  is_deeply($dt->dt_add(month      =>-12345)->dt_unpdl, ['6575-04-03T00:00:00.000001','0943-04-10T00:00:00.000001'], "add(month      =>-12345)");
  is_deeply($dt->dt_add(week       =>-2    )->dt_unpdl, ['7603-12-20T00:00:00.000001','1971-12-27T00:00:00.000001'], "add(week       =>-2    )");
  is_deeply($dt->dt_add(week       =>-52   )->dt_unpdl, ['7603-01-04T00:00:00.000001','1971-01-11T00:00:00.000001'], "add(week       =>-52   )");
  is_deeply($dt->dt_add(week       =>-12345)->dt_unpdl, ['7367-05-30T00:00:00.000001','1735-06-06T00:00:00.000001'], "add(week       =>-12345)");
  is_deeply($dt->dt_add(day        =>-2    )->dt_unpdl, ['7604-01-01T00:00:00.000001','1972-01-08T00:00:00.000001'], "add(day        =>-2    )");
  is_deeply($dt->dt_add(hour       =>-2    )->dt_unpdl, ['7604-01-02T22:00:00.000001','1972-01-09T22:00:00.000001'], "add(hour       =>-2    )");
  is_deeply($dt->dt_add(minute     =>-2    )->dt_unpdl, ['7604-01-02T23:58:00.000001','1972-01-09T23:58:00.000001'], "add(minute     =>-2    )");
  is_deeply($dt->dt_add(second     =>-2    )->dt_unpdl, ['7604-01-02T23:59:58.000001','1972-01-09T23:59:58.000001'], "add(second     =>-2    )");
  is_deeply($dt->dt_add(millisecond=>-2    )->dt_unpdl, ['7604-01-02T23:59:59.998001','1972-01-09T23:59:59.998001'], "add(millisecond=>-2    )");
  is_deeply($dt->dt_add(microsecond=>-2    )->dt_unpdl, ['7604-01-02T23:59:59.999999','1972-01-09T23:59:59.999999'], "add(microsecond=>-2    )");
}

{
  my $dt = PDL::DateTime->new_from_datetime($start);
  is_deeply($dt->dt_align('year')->dt_unpdl        , [ '1996-01-01',              '1899-01-01'],              "truncate('year')");
  is_deeply($dt->dt_align('month')->dt_unpdl       , [ '1996-02-01',              '1899-12-01'],              "truncate('month')");
  is_deeply($dt->dt_align('week')->dt_unpdl        , [ '1996-02-26',              '1899-12-25'],              "truncate('week')");
  is_deeply($dt->dt_align('day')->dt_unpdl         , [ '1996-02-29',              '1899-12-31'],              "truncate('day')");
  is_deeply($dt->dt_align('hour')->dt_unpdl        , [ '1996-02-29T23:00',        '1899-12-31T23:00'],        "truncate('hour')");
  is_deeply($dt->dt_align('minute')->dt_unpdl      , [ '1996-02-29T23:59',        '1899-12-31T23:59'],        "truncate('minute')");
  is_deeply($dt->dt_align('second')->dt_unpdl      , [ '1996-02-29T23:59:59',     '1899-12-31T23:59:59'],     "truncate('second')");
  is_deeply($dt->dt_align('millisecond')->dt_unpdl , [ '1996-02-29T23:59:59.999', '1899-12-31T23:59:59.999'], "truncate('millisecond')");
}

{
  my $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_align('year')        ; is_deeply($dt->dt_unpdl, [ '1996-01-01',                 '1899-01-01'],                 "inplace->truncate('year')");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_align('month')       ; is_deeply($dt->dt_unpdl, [ '1996-02-01',                 '1899-12-01'],                 "inplace->truncate('month')");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_align('week')        ; is_deeply($dt->dt_unpdl, [ '1996-02-26',                 '1899-12-25'],                 "inplace->truncate('week')");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_align('day')         ; is_deeply($dt->dt_unpdl, [ '1996-02-29',                 '1899-12-31'],                 "inplace->truncate('day')");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_align('hour')        ; is_deeply($dt->dt_unpdl, [ '1996-02-29T23:00',           '1899-12-31T23:00'],           "inplace->truncate('hour')");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_align('minute')      ; is_deeply($dt->dt_unpdl, [ '1996-02-29T23:59',           '1899-12-31T23:59'],           "inplace->truncate('minute')");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_align('second')      ; is_deeply($dt->dt_unpdl, [ '1996-02-29T23:59:59',        '1899-12-31T23:59:59'],        "inplace->truncate('second')");
  $dt = PDL::DateTime->new_from_datetime($start);
  $dt->inplace->dt_align('millisecond') ; is_deeply($dt->dt_unpdl, [ '1996-02-29T23:59:59.999',    '1899-12-31T23:59:59.999'],    "inplace->truncate('millisecond')");
}

{
  my $dt = PDL::DateTime->new_from_datetime($start);
  is_deeply($dt->dt_unpdl , [ '1996-02-29T23:59:59.999999', '1899-12-31T23:59:59.999999'], "dt_at/dt_set");
  is($dt->dt_at(0), '1996-02-29T23:59:59.999999', "dt_at/1");
  $dt->dt_set(0,    '1970-01-01T19:19:19.191919');
  is($dt->dt_at(0), '1970-01-01T19:19:19.191919', "dt_at/2");
  $dt->dt_set(0,    '0001-01-01T19:19:19.191919');
  is($dt->dt_at(0), '0001-01-01T19:19:19.191919', "dt_at/3");
  $dt->dt_set(0,    '4567-05-19T19:19:19.191919');
  is($dt->dt_at(0), '4567-05-19T19:19:19.191919', "dt_at/4");
  $dt->dt_set(0,    '9999-05-19T19:19:19.191919');
  is($dt->dt_at(0), '9999-05-19T19:19:19.191919', "dt_at/5");
}

{
  my $dt1 = PDL::DateTime->new_from_datetime(['9999-01-01T00:00:00.000001Z', '1000-01-01T00:00:00.000001Z']);
  my $dt2 = PDL::DateTime->new($dt1);
  my $dt3 = $dt1->copy;
  #XXX-FIXME is(ref $dt3, 'PDL::DateTime');
  is_deeply($dt1->unpdl, $dt2->unpdl);
  is_deeply($dt1->unpdl, $dt3->unpdl);
  ok(all($dt1 == $dt2));
  ok(all($dt1 == $dt3));
  like("$dt1", qr/^\s*\Q[ 9999-01-01T00:00:00.000001 1000-01-01T00:00:00.000001 ]\E\s*$/);
}

#XXX-TODO
# dt_add: combined e.g. $dt->dt_add(year=>1, month=>2)

done_testing;