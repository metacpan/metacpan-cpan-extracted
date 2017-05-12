#!/usr/bin/perl -w

use strict;

use Rose::DateTime::Util qw(parse_date);

BEGIN
{
  require Test::More;
  eval { require DBD::Informix };

  if($@)
  {
    Test::More->import(skip_all => 'Missing DBD::Informix');
  }
  else
  {
    Test::More->import(tests => 134);
  }
}

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB');
}

My::DB2->default_domain('test');
My::DB2->default_type('informix');

my $db = My::DB2->new();

ok(ref $db && $db->isa('Rose::DB'), 'new()');

my $dbh;
eval { $dbh = $db->dbh };

SKIP:
{
  skip("Could not connect to db - $@", 8)  if($@);

  ok($dbh, 'dbh() 1');

  ok($db->has_dbh, 'has_dbh() 1');

  my $db2 = My::DB2->new();

  $db2->dbh($dbh);

  foreach my $field (qw(dsn driver database username password))
  { 
    is($db2->$field(), $db->$field(), "$field()");
  }

  ok(defined $db->supports_limit_with_offset, 'supports_limit_with_offset');

  $db->disconnect;
  $db2->disconnect;
}

$db = My::DB2->new();

ok(ref $db && $db->isa('Rose::DB'), "new()");

$db->init_db_info;

ok($db->validate_timestamp_keyword('today'), 'validate_timestamp_keyword (today)');
ok($db->validate_timestamp_keyword('current'), 'validate_timestamp_keyword (current)');
ok($db->validate_timestamp_keyword('current year to second'), 'validate_timestamp_keyword (current year to second)');
ok($db->validate_timestamp_keyword('current year to minute'), 'validate_timestamp_keyword (current year to minute)');
ok($db->validate_timestamp_keyword('current year to hour'), 'validate_timestamp_keyword (current year to hour)');
ok($db->validate_timestamp_keyword('current year to day'), 'validate_timestamp_keyword (current year to day)');
ok($db->validate_timestamp_keyword('current year to month'), 'validate_timestamp_keyword (current year to month)');
ok($db->validate_timestamp_keyword('current year to fraction(1)'), 'validate_timestamp_keyword (current year to fraction(1))');
ok($db->validate_timestamp_keyword('current year to fraction(5)'), 'validate_timestamp_keyword (current year to fraction(5))');
ok(!$db->validate_timestamp_keyword('current year to fraction(6)'), 'validate_timestamp_keyword (current year to fraction(6))');
ok(!$db->validate_timestamp_keyword('now'), 'validate_timestamp_keyword (!now)');
$db->keyword_function_calls(1);
ok($db->validate_timestamp_keyword('Foo(Bar)'), 'validate_timestamp_keyword (Foo(Bar))');
$db->keyword_function_calls(0);

is($db->format_timestamp('current'), 'current', 'format_timestamp (current)');
is($db->format_timestamp('current year to fraction(1)'), 'current year to fraction(1)', 'format_timestamp (current year to fraction(1))');
is($db->format_timestamp('current year to fraction(5)'), 'current year to fraction(5)', 'format_timestamp (current year to fraction(5))');
$db->keyword_function_calls(1);
is($db->format_timestamp('Foo(Bar)'), 'Foo(Bar)', 'format_timestamp (Foo(Bar))');
$db->keyword_function_calls(0);

ok($db->validate_datetime_keyword('today'), 'validate_datetime_keyword (today)');
ok($db->validate_datetime_keyword('current year to second'), 'validate_datetime_keyword (current year to second)');
ok($db->validate_datetime_keyword('current year to minute'), 'validate_datetime_keyword (current year to minute)');
ok($db->validate_datetime_keyword('current year to hour'), 'validate_datetime_keyword (current year to hour)');
ok($db->validate_datetime_keyword('current year to day'), 'validate_datetime_keyword (current year to day)');
ok($db->validate_datetime_keyword('current year to month'), 'validate_datetime_keyword (current year to month)');
ok($db->validate_datetime_keyword('current'), 'validate_datetime_keyword current');
ok(!$db->validate_datetime_keyword('now'), 'validate_datetime_keyword (!now)');
$db->keyword_function_calls(1);
ok($db->validate_datetime_keyword('Foo(Bar)'), 'validate_datetime_keyword (Foo(Bar))');
$db->keyword_function_calls(0);

ok($db->validate_datetime_year_to_fraction_keyword('today'), 'validate_datetime_year_to_fraction_keyword (today)');
ok($db->validate_datetime_year_to_fraction_keyword('current'), 'validate_timestamp_keyword (current)');
ok($db->validate_datetime_year_to_fraction_keyword('current year to second'), 'validate_timestamp_keyword (current year to second)');
ok($db->validate_datetime_year_to_fraction_keyword('current year to minute'), 'validate_timestamp_keyword (current year to minute)');
ok($db->validate_datetime_year_to_fraction_keyword('current year to hour'), 'validate_timestamp_keyword (current year to hour)');
ok($db->validate_datetime_year_to_fraction_keyword('current year to day'), 'validate_timestamp_keyword (current year to day)');
ok($db->validate_datetime_year_to_fraction_keyword('current year to month'), 'validate_timestamp_keyword (current year to month)');
ok($db->validate_datetime_year_to_fraction_keyword('current year to fraction(1)'), 'validate_timestamp_keyword (current year to fraction(1))');
ok($db->validate_datetime_year_to_fraction_keyword('current year to fraction(5)'), 'validate_timestamp_keyword (current year to fraction(5))');
ok(!$db->validate_datetime_year_to_fraction_keyword('current year to fraction(6)'), 'validate_timestamp_keyword (current year to fraction(6))');
ok(!$db->validate_datetime_year_to_fraction_keyword('now'), 'validate_timestamp_keyword (!now)');
$db->keyword_function_calls(1);
ok($db->validate_datetime_year_to_fraction_keyword('Foo(Bar)'), 'validate_timestamp_keyword (Foo(Bar))');
$db->keyword_function_calls(0);

ok($db->validate_datetime_year_to_minute_keyword('today'), 'validate_datetime_year_to_minute_keyword (today)');
ok($db->validate_datetime_year_to_minute_keyword('current'), 'validate_datetime_year_to_minute_keyword current');
ok($db->validate_datetime_year_to_minute_keyword('current year to second'), 'validate_datetime_year_to_minute_keyword current year to second');
ok($db->validate_datetime_year_to_minute_keyword('current year to minute'), 'validate_datetime_year_to_minute_keyword current year to minute');
ok($db->validate_datetime_year_to_minute_keyword('current year to hour'), 'validate_datetime_year_to_minute_keyword (current year to hour)');
ok($db->validate_datetime_year_to_minute_keyword('current year to day'), 'validate_datetime_year_to_minute_keyword (current year to day)');
ok($db->validate_datetime_year_to_minute_keyword('current year to month'), 'validate_datetime_year_to_minute_keyword (current year to month)');
$db->keyword_function_calls(1);
ok($db->validate_datetime_year_to_minute_keyword('Foo(Bar)'), 'validate_datetime_year_to_minute_keyword (Foo(Bar))');
$db->keyword_function_calls(0);

ok($db->validate_datetime_year_to_month_keyword('today'), 'validate_datetime_year_to_month_keyword (today)');
ok($db->validate_datetime_year_to_month_keyword('current'), 'validate_datetime_year_to_month_keyword current');
ok($db->validate_datetime_year_to_month_keyword('current year to second'), 'validate_datetime_year_to_month_keyword current year to second');
ok($db->validate_datetime_year_to_month_keyword('current year to minute'), 'validate_datetime_year_to_month_keyword current year to minute');
ok($db->validate_datetime_year_to_month_keyword('current year to hour'), 'validate_datetime_year_to_month_keyword (current year to hour)');
ok($db->validate_datetime_year_to_month_keyword('current year to day'), 'validate_datetime_year_to_month_keyword (current year to day)');
ok($db->validate_datetime_year_to_month_keyword('current year to month'), 'validate_datetime_year_to_month_keyword (current year to month)');
$db->keyword_function_calls(1);
ok($db->validate_datetime_year_to_month_keyword('Foo(Bar)'), 'validate_datetime_year_to_month_keyword (Foo(Bar))');
$db->keyword_function_calls(0);

ok($db->validate_datetime_year_to_second_keyword('today'), 'validate_datetime_year_to_second_keyword (today)');
ok($db->validate_datetime_year_to_second_keyword('current'), 'validate_datetime_year_to_second_keyword current');
ok($db->validate_datetime_year_to_second_keyword('current year to second'), 'validate_datetime_year_to_second_keyword current year to second');
ok($db->validate_datetime_year_to_second_keyword('current year to minute'), 'validate_datetime_year_to_second_keyword current year to minute');
ok($db->validate_datetime_year_to_second_keyword('current year to hour'), 'validate_datetime_year_to_second_keyword (current year to hour)');
ok($db->validate_datetime_year_to_second_keyword('current year to day'), 'validate_datetime_year_to_second_keyword (current year to day)');
ok($db->validate_datetime_year_to_second_keyword('current year to month'), 'validate_datetime_year_to_second_keyword (current year to month)');
$db->keyword_function_calls(1);
ok($db->validate_datetime_year_to_second_keyword('Foo(Bar)'), 'validate_datetime_year_to_second_keyword (Foo(Bar))');
$db->keyword_function_calls(0);

is($db->format_datetime('current'), 'current', 'format_datetime current');
ok($db->validate_datetime_year_to_second_keyword('current year to second'), 'validate_datetime_year_to_second_keyword current year to second');
ok($db->validate_datetime_year_to_second_keyword('current year to minute'), 'validate_datetime_year_to_second_keyword current year to minute');
ok($db->validate_datetime_year_to_second_keyword('current year to hour'), 'validate_datetime_year_to_second_keyword (current year to hour)');
ok($db->validate_datetime_year_to_second_keyword('current year to day'), 'validate_datetime_year_to_second_keyword (current year to day)');
ok($db->validate_datetime_year_to_second_keyword('current year to month'), 'validate_datetime_year_to_second_keyword (current year to month)');
$db->keyword_function_calls(1);
is($db->format_datetime('Foo(Bar)'), 'Foo(Bar)', 'format_datetime (Foo(Bar))');
$db->keyword_function_calls(0);

ok($db->validate_date_keyword('today'), 'validate_date_keyword (today)');
ok($db->validate_date_keyword('current'), 'validate_date_keyword current');
ok(!$db->validate_date_keyword('now'), 'validate_date_keyword (!now)');

is($db->format_date('current'), 'current', 'format_date (current)');
$db->keyword_function_calls(1);
is($db->format_date('Foo(Bar)'), 'Foo(Bar)', 'format_date (Foo(Bar))');
$db->keyword_function_calls(0);

#ok($db->validate_time_keyword('current'), 'validate_time_keyword current');

#is($db->format_time('current'), 'current', 'format_time (current)');
$db->keyword_function_calls(1);
is($db->format_time('Foo(Bar)'), 'Foo(Bar)', 'format_time (Foo(Bar))');
$db->keyword_function_calls(0);

is($db->format_array([ 'a', 'b' ]), q({"a","b"}), 'format_array() 1');
is($db->format_array('a', 'b'), q({"a","b"}), 'format_array() 2');

eval { $db->format_array('x' x 300) };
ok($@, 'format_array() 3');

eval { $db->format_array('a', undef) };
ok($@ =~ /undefined/i, 'format_array() 4');

eval { $db->format_array([ 'a', undef ]) };
ok($@ =~ /undefined/i, 'format_array() 5');

my $a = $db->parse_array(q({"a","b"}));

is($db->format_set([ 'a', 'b' ]), q(SET{'a','b'}), 'format_set() 1');
is($db->format_set('a', 'b'), q(SET{'a','b'}), 'format_set() 2');

eval { $db->format_set('a', undef) };
ok($@ =~ /undefined/i, 'format_set() 3');

eval { $db->format_set([ 'a', undef ]) };
ok($@ =~ /undefined/i, 'format_set() 4');

my $s = $db->parse_set(q(SET{'a','b'}));

ok(@$s == 2 && $s->[0] eq 'a' && $s->[1] eq 'b', 'parse_set() 1');

$s = $db->parse_set(q(SET{'4     '}));
ok(@$s == 1 && $s->[0] eq '4     ', 'parse_set() 2');

$s = $db->parse_set(q(SET{'4     '}), { value_type => 'integer' });
ok(@$s == 1 && $s->[0] eq '4', 'parse_set() 3');

SKIP:
{
  eval { $db->connect };
  skip("Could not connect to db 'test', 'informix' - $@", 37)  if($@);
  $dbh = $db->dbh;

  is($db->domain, 'test', "domain()");
  is($db->type, 'informix', "type()");

  is($db->print_error, $dbh->{'PrintError'}, 'print_error() 2');
  is($db->print_error, $db->connect_option('PrintError'), 'print_error() 3');

  is($db->null_date, '0000-00-00', "null_date()");
  is($db->null_datetime, '0000-00-00 00:00:00', "null_datetime()");

  is($db->format_date(parse_date('2002-12-31', 'floating')), '12/31/2002', "format_date() floating");
  is($db->format_datetime(parse_date('12/31/2002 12:34:56', 'floating')), '2002-12-31 12:34:56', "format_datetime() floating");

  my $dt = $db->parse_datetime_year_to_second('12/31/2002 12:34:56.123456789');
  is($dt->nanosecond, 0, 'parse_datetime_year_to_second()');

  $dt = $db->parse_datetime_year_to_minute('12/31/2002 12:34:56');
  is($dt->second, 0, 'parse_datetime_year_to_minute()');

  is($db->format_datetime_year_to_second(parse_date('12/31/2002 12:34:56', 'floating')), '2002-12-31 12:34:56', "format_datetime_year_to_second() floating");
  is($db->format_datetime_year_to_minute(parse_date('12/31/2002 12:34:56', 'floating')), '2002-12-31 12:34', "format_datetime_year_to_minute() floating");
  is($db->format_datetime_year_to_month(parse_date('12/31/2002 12:34:56', 'floating')), '2002-12', "format_datetime_year_to_month() floating");

  is($db->format_timestamp(parse_date('12/31/2002 12:34:56.12345', 'floating')), '2002-12-31 12:34:56.12345', "format_timestamp() floating");
  #is($db->format_time(parse_date('12/31/2002 12:34:56', 'floating')), '12:34:56', "format_datetime() floating");

  is($db->format_bitfield($db->parse_bitfield('1010')),
     q(1010), "format_bitfield() 1");

  is($db->format_bitfield($db->parse_bitfield(q(B'1010'))),
     q(1010), "format_bitfield() 2");

  is($db->format_bitfield($db->parse_bitfield(2), 4),
     q(0010), "format_bitfield() 3");

  is($db->format_bitfield($db->parse_bitfield('0xA'), 4),
     q(1010), "format_bitfield() 4");

  my $str = $db->format_array([ 'a' .. 'c' ]);
  is($str, '{"a","b","c"}', 'format_array() 1');

  my $ar = $db->parse_array($str);
  ok(ref $ar eq 'ARRAY' && $ar->[0] eq 'a' && $ar->[1] eq 'b' && $ar->[2] eq 'c',
     'parse_array() 1');

  $str = $db->format_array($ar);
  is($str, '{"a","b","c"}', 'format_array() 2');

  $str = $db->format_array([ 1, -2, 3.5 ]);
  is($str, '{1,-2,3.5}', 'format_array() 3');

  $ar = $db->parse_array($str);
  ok(ref $ar eq 'ARRAY' && $ar->[0] == 1 && $ar->[1] == -2 && $ar->[2] == 3.5,
     'parse_array() 2');

  $str = $db->format_array($ar);
  is($str, '{1,-2,3.5}', 'format_array() 4');

  $str = $db->format_array(1, -2, 3.5);
  is($str, '{1,-2,3.5}', 'format_array() 5');

  $ar = $db->parse_array($str);
  ok(ref $ar eq 'ARRAY' && $ar->[0] == 1 && $ar->[1] == -2 && $ar->[2] == 3.5,
     'parse_array() 3');

  is($db->format_boolean(1), 't', 'format_boolean (1)');
  is($db->format_boolean(0), 'f', 'format_boolean (0)');

  is($db->parse_boolean('t'), 1, 'parse_boolean (t)');
  is($db->parse_boolean('T'), 1, 'parse_boolean (T)');

  is($db->parse_boolean('f'), 0, 'parse_boolean (f)');
  is($db->parse_boolean('F'), 0, 'parse_boolean (F)');

  $db->keyword_function_calls(1);
  is($db->parse_boolean('Foo(Bar)'), 'Foo(Bar)', 'parse_boolean (Foo(Bar))');
  $db->keyword_function_calls(0);

  #is($db->autocommit + 0, $dbh->{'AutoCommit'} + 0, 'autocommit() 1');

  $db->autocommit(1);

  is($db->autocommit + 0, 1, 'autocommit() 2');
  is($dbh->{'AutoCommit'} + 0, 1, 'autocommit() 3');

  $db->autocommit(0);

  is($db->autocommit + 0, 0, 'autocommit() 4');
  is($dbh->{'AutoCommit'} + 0, 0, 'autocommit() 5');

  my $dbh_copy = $db->retain_dbh;

  $db->disconnect;
}

