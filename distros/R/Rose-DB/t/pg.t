#!/usr/bin/perl -w

use strict;

use Rose::DateTime::Util qw(parse_date);

BEGIN
{
  require Test::More;
  eval { require DBD::Pg };

  if($@)
  {
    Test::More->import(skip_all => 'Missing DBD::Pg');
  }
  else
  {
    Test::More->import(tests => 287);
  }
}

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB');
}

Rose::DB->default_domain('test');
Rose::DB->default_type('pg');

my $db = Rose::DB->new();

ok(ref $db && $db->isa('Rose::DB'), 'new()');

SKIP:
{
  skip("Could not connect to db", 15)  unless(have_db('pg'));

  my $dbh = $db->dbh;

  ok($dbh, 'dbh() 1');

  ok($db->has_dbh, 'has_dbh() 1');

  my $db2 = Rose::DB->new();

  $db2->dbh($dbh);

  foreach my $field (qw(dsn driver database host port username password))
  { 
    is($db2->$field(), $db->$field(), "$field()");
  }

  # In DBD::Pg 3.5.0 and later, the default is -1 instead of false
  ok((!$db->pg_enable_utf8 || $db->pg_enable_utf8 == -1), 'pg_enable_utf8 default');

  $db->pg_enable_utf8(1);

  ok($db->pg_enable_utf8 && $db->dbh->{'pg_enable_utf8'}, 'pg_enable_utf8 true');

  SEQUENCE_PREP:
  {
    my $dbh = $db->dbh;
    local $dbh->{'PrintError'} = 0;
    local $dbh->{'RaiseError'} = 0;
    $dbh->do('DROP SEQUENCE rose_db_sequence_test');
  }

  $dbh->do('CREATE SEQUENCE rose_db_sequence_test MINVALUE 5');

  ok($db->sequence_exists('rose_db_sequence_test'), 'sequence_exists 1');
  ok(!$db->sequence_exists('rose_db_sequence_testx'), 'sequence_exists 2');
  is($db->current_value_in_sequence('rose_db_sequence_test'), 5, 'current_value_in_sequence 1');
  is($db->next_value_in_sequence('rose_db_sequence_test'), 5, 'next_value_in_sequence 1');
  is($db->current_value_in_sequence('rose_db_sequence_test'), 5, 'current_value_in_sequence 2');
  is($db->next_value_in_sequence('rose_db_sequence_test'), 6, 'next_value_in_sequence 2');
  is($db->current_value_in_sequence('rose_db_sequence_test'), 6, 'current_value_in_sequence 3');

  $dbh->do('DROP SEQUENCE rose_db_sequence_test');
  $db->disconnect;
  $db2->disconnect;
}

$db = Rose::DB->new();

$db->sslmode('allow');
is($db->dsn, 'dbi:Pg:dbname=test;host=localhost;sslmode=allow', 'sslmode()');

$db->options('opts');
is($db->dsn, 'dbi:Pg:dbname=test;host=localhost;options=opts;sslmode=allow', 'options()');

$db->service('srv');
is($db->dsn, 'dbi:Pg:dbname=test;host=localhost;options=opts;service=srv;sslmode=allow', 'service()');

$db = Rose::DB->new();

ok(ref $db && $db->isa('Rose::DB'), "new()");

$db->init_db_info;

ok($db->supports_limit_with_offset, 'supports_limit_with_offset');

ok($db->validate_timestamp_keyword('now'), 'validate_timestamp_keyword (now)');
ok($db->validate_timestamp_keyword('infinity'), 'validate_timestamp_keyword (infinity)');
ok($db->validate_timestamp_keyword('-infinity'), 'validate_timestamp_keyword (-infinity)');
ok($db->validate_timestamp_keyword('epoch'), 'validate_timestamp_keyword (epoch)');
ok($db->validate_timestamp_keyword('today'), 'validate_timestamp_keyword (today)');
ok($db->validate_timestamp_keyword('tomorrow'), 'validate_timestamp_keyword (tomorrow)');
ok($db->validate_timestamp_keyword('yesterday'), 'validate_timestamp_keyword (yesterday)');
ok($db->validate_timestamp_keyword('allballs'), 'validate_timestamp_keyword (allballs)');

is($db->format_timestamp('now'), 'now', 'format_timestamp (now)');
is($db->format_timestamp('infinity'), 'infinity', 'format_timestamp (infinity)');
is($db->format_timestamp('-infinity'), '-infinity', 'format_timestamp (-infinity)');
is($db->format_timestamp('epoch'), 'epoch', 'format_timestamp (epoch)');
is($db->format_timestamp('today'), 'today', 'format_timestamp (today)');
is($db->format_timestamp('tomorrow'), 'tomorrow', 'format_timestamp (tomorrow)');
is($db->format_timestamp('yesterday'), 'yesterday', 'format_timestamp (yesterday)');
is($db->format_timestamp('allballs'), 'allballs', 'format_timestamp (allballs)');

ok($db->validate_datetime_keyword('now'), 'validate_datetime_keyword (now)');
ok($db->validate_datetime_keyword('infinity'), 'validate_datetime_keyword (infinity)');
ok($db->validate_datetime_keyword('-infinity'), 'validate_datetime_keyword (-infinity)');
ok($db->validate_datetime_keyword('epoch'), 'validate_datetime_keyword (epoch)');
ok($db->validate_datetime_keyword('today'), 'validate_datetime_keyword (today)');
ok($db->validate_datetime_keyword('tomorrow'), 'validate_datetime_keyword (tomorrow)');
ok($db->validate_datetime_keyword('yesterday'), 'validate_datetime_keyword (yesterday)');
ok($db->validate_datetime_keyword('allballs'), 'validate_datetime_keyword (allballs)');

is($db->format_datetime('now'), 'now', 'format_datetime (now)');
is($db->format_datetime('infinity'), 'infinity', 'format_datetime (infinity)');
is($db->format_datetime('-infinity'), '-infinity', 'format_datetime (-infinity)');
is($db->format_datetime('epoch'), 'epoch', 'format_datetime (epoch)');
is($db->format_datetime('today'), 'today', 'format_datetime (today)');
is($db->format_datetime('tomorrow'), 'tomorrow', 'format_datetime (tomorrow)');
is($db->format_datetime('yesterday'), 'yesterday', 'format_datetime (yesterday)');
is($db->format_datetime('allballs'), 'allballs', 'format_datetime (allballs)');

ok($db->validate_date_keyword('now'), 'validate_date_keyword (now)');
ok($db->validate_date_keyword('epoch'), 'validate_date_keyword (epoch)');
ok($db->validate_date_keyword('today'), 'validate_date_keyword (today)');
ok($db->validate_date_keyword('tomorrow'), 'validate_date_keyword (tomorrow)');
ok($db->validate_date_keyword('yesterday'), 'validate_date_keyword (yesterday)');

is($db->format_date('now'), 'now', 'format_date (now)');
is($db->format_date('epoch'), 'epoch', 'format_date (epoch)');
is($db->format_date('today'), 'today', 'format_date (today)');
is($db->format_date('tomorrow'), 'tomorrow', 'format_date (tomorrow)');
is($db->format_date('yesterday'), 'yesterday', 'format_date (yesterday)');

ok($db->validate_time_keyword('now'), 'validate_time_keyword (now)');
ok($db->validate_time_keyword('allballs'), 'validate_time_keyword (allballs)');

is($db->format_time('now'), 'now', 'format_time (now)');
is($db->format_time('allballs'), 'allballs', 'format_time (allballs)');

is($db->parse_boolean('t'), 1, 'parse_boolean (t)');
is($db->parse_boolean('true'), 1, 'parse_boolean (true)');
is($db->parse_boolean('y'), 1, 'parse_boolean (y)');
is($db->parse_boolean('yes'), 1, 'parse_boolean (yes)');
is($db->parse_boolean('1'), 1, 'parse_boolean (1)');
is($db->parse_boolean('TRUE'), 'TRUE', 'parse_boolean (TRUE)');

is($db->parse_boolean('f'), 0, 'parse_boolean (f)');
is($db->parse_boolean('false'), 0, 'parse_boolean (false)');
is($db->parse_boolean('n'), 0, 'parse_boolean (n)');
is($db->parse_boolean('no'), 0, 'parse_boolean (no)');
is($db->parse_boolean('0'), 0, 'parse_boolean (0)');
is($db->parse_boolean('FALSE'), 'FALSE', 'parse_boolean (FALSE)');

ok(!$db->validate_boolean_keyword('Foo(Bar)'), 'validate_boolean_keyword (Foo(Bar))');
$db->keyword_function_calls(1);
is($db->parse_boolean('Foo(Bar)'), 'Foo(Bar)', 'parse_boolean (Foo(Bar))');
$db->keyword_function_calls(0);

foreach my $name (qw(date datetime time timestamp))
{
  my $method = "validate_${name}_keyword";

  ok(!$db->$method('Foo(Bar)'), "$method (Foo(Bar)) 1");
  $db->keyword_function_calls(1);
  ok($db->$method('Foo(Bar)'), "$method (Foo(Bar)) 2");
  $db->keyword_function_calls(0);


  foreach my $value (qw(current_date current_time current_time()
                        current_time(1) current_timestamp
                        current_timestamp() current_timestamp(2)
                        localtime localtime() localtime(3)
                        localtimestamp localtimestamp()
                        localtimestamp(4) now now() timeofday()))
  {
    my $new_value = $value;
    my $i = int(rand(length($new_value) - 3)); # 3 = 1 + 2 (for possible parens)
    substr($new_value, $i, 1) = uc substr($new_value, $i, 1);
    ok($db->$method($new_value), "$method ($new_value)");
  }
}

# Interval values

isa_ok($db->parse_interval('00:00:00'), 'DateTime::Duration');

SKIP:
{
  if($DateTime::Format::Pg::VERSION < 0.16011)
  {
    skip('interval tests - DateTime::Format::Pg version too low', 35);
  }

  my @Intervals = 
  (
    '+0::'               => '@ 0',
    '1 D'                => '@ 1 days',
    '-1 d 2 s'           => '@ -1 days 2 seconds',
    '-1 y 2 mons  3 d'   => '@ -10 months 3 days',
    '-1 y 2 mons -3 d'   => '@ -10 months -3 days',

    '5 h -208 m -495 s'  => '@ 92 minutes -495 seconds',
    '-208 m -495 s'      => '@ -208 minutes -495 seconds',
    '5 h 208 m 495 s'    => '@ 508 minutes 495 seconds',

    '1 d 2 d'   => undef,

    '1 ys 2 h 3 m 4 s'  => undef,

    '1 mil 2 c 3 dec 4 y 5 mon 1 w -1 d 7 h 8 m 9 s' => 
      '@ 14813 months 6 days 428 minutes 9 seconds',

    '-1 mil -2 c -3 dec -4 y -5 mon -1 w 1 d -7 h -8 m -9 s' => 
      '@ -14813 months -6 days -428 minutes -9 seconds',

    '-1 mil -2 c -3 dec -4 y -5 mon -1 w 1 d -7 h -8 m -9 s ago' => 
      '@ 14813 months 6 days 428 minutes 9 seconds',

    '1 mils 2 cents 3 decs 4 years 5 mons 1 weeks -1 days 7 hours 8 mins 9 secs' => 
      '@ 14813 months 6 days 428 minutes 9 seconds',
    '1 millenniums 2 centuries 3 decades 4 years 5 months 1 weeks -1 days 7 hours 8 minutes 9 seconds' => 
      '@ 14813 months 6 days 428 minutes 9 seconds',

    '1 mil -1 d ago'     => '@ -12000 months 1 days',
    '1 mil ago -1 d ago' => '@ -12000 months 1 days',
  );

  my %Alt_Intervals =
  (
    '+0::'               => '',
    '-0:1:'              => '-00:01:00',
    '2:'                 => '02:00:00',
    '1 D'                => '1 day',
    '-1 d 2 s'           => '-1 days +00:00:02',
    '-1 y 2 mons  3 d'   => '-10 mons +3 days',
    '-1 y 2 mons -3 d'   => '-10 mons -3 days',

    '5 h -208 m -495 s' => '01:23:45',
    '-208 m -495 s'     => '-03:36:15',
    '5 h 208 m 495 s'   => '08:36:15',

    '1 d 2 d'   => undef,

    '1 ys 2 h 3 m 4 s'  => undef,
    '1s ago'            => undef,

    '1 mil 2 c 3 dec 4 y 5 mon 1 w -1 d 7 h 8 m 9 s'             => '1234 years 5 mons 6 days 07:08:09',
    '-1 mil -2 c -3 dec -4 y -5 mon -1 w 1 d -7 h -8 m -9 s'     => '-1234 years -5 mons -6 days -07:08:09',
    '-1 mil -2 c -3 dec -4 y -5 mon -1 w 1 d -7 h -8 m -9 s ago' => '1234 years 5 mons 6 days 07:08:09',

    '1 mils 2 cents 3 decs 4 years 5 mons 1 weeks -1 days 7 hours 8 mins 9 secs' => '1234 years 5 mons 6 days 07:08:09',

    '1 millenniums 2 centuries 3 decades 4 years 5 months 1 weeks -1 days 7 hours 8 minutes 9 seconds' =>
        '1234 years 5 mons 6 days 07:08:09',

    '1 mil -1 d ago'     => '-1000 years +1 day',
    '1 mil ago -1 d ago' => '-1000 years +1 day',
  );

  my $i = 0;

  while($i < @Intervals)
  {
    my($val, $formatted) = ($Intervals[$i], $Intervals[$i + 1]);
    $i += 2;

    my $d = $db->parse_interval($val, 'preserve');

    is($db->format_interval($d), $formatted, "parse_interval ($val)");  
    my $alt_d = $db->parse_interval($Alt_Intervals{$val}, 'preserve');

    ok((!defined $d && !defined $alt_d) || DateTime::Duration->compare($d, $alt_d) == 0, "parse_interval alt check $i ($val)");
  }

  $db->keyword_function_calls(1);
  is($db->parse_interval('foo()'), 'foo()', 'parse_interval (foo())');
  $db->keyword_function_calls(0);
}

# Time vaues

my $tc;

ok($tc = $db->parse_time('12:34:56.123456789'), 'parse time 12:34:56.123456789');
is($tc->as_string, '12:34:56.123456789', 'check time 12:34:56.123456789');
is($db->format_time($tc), '12:34:56.123456789', 'format time 12:34:56.123456789');

ok($tc = $db->parse_time('12:34:56.123456789 pm'), 'parse time 12:34:56.123456789 pm');
is($tc->as_string, '12:34:56.123456789', 'check time 12:34:56.123456789 pm');
is($db->format_time($tc), '12:34:56.123456789', 'format time 12:34:56.123456789 pm');

ok($tc = $db->parse_time('12:34:56. A.m.'), 'parse time 12:34:56. A.m.');
is($tc->as_string, '00:34:56', 'check time 12:34:56 am');
is($db->format_time($tc), '00:34:56', 'format time 12:34:56 am');

ok($tc = $db->parse_time('12:34:56 pm'), 'parse time 12:34:56 pm');
is($tc->as_string, '12:34:56', 'check time 12:34:56 pm');
is($db->format_time($tc), '12:34:56', 'format time 12:34:56 pm');

ok($tc = $db->parse_time('2:34:56 pm'), 'parse time 2:34:56 pm');
is($tc->as_string, '14:34:56', 'check time 14:34:56 pm');
is($db->format_time($tc), '14:34:56', 'format time 14:34:56 pm');

ok($tc = $db->parse_time('2:34 pm'), 'parse time 2:34 pm');
is($tc->as_string, '14:34:00', 'check time 2:34 pm');
is($db->format_time($tc), '14:34:00', 'format time 2:34 pm');

ok($tc = $db->parse_time('2 pm'), 'parse time 2 pm');
is($tc->as_string, '14:00:00', 'check time 2 pm');
is($db->format_time($tc), '14:00:00', 'format time 2 pm');

ok($tc = $db->parse_time('3pm'), 'parse time 3pm');
is($tc->as_string, '15:00:00', 'check time 3pm');
is($db->format_time($tc), '15:00:00', 'format time 3pm');

ok($tc = $db->parse_time('4 p.M.'), 'parse time 4 p.M.');
is($tc->as_string, '16:00:00', 'check time 4 p.M.');
is($db->format_time($tc), '16:00:00', 'format time 4 p.M.');

ok($tc = $db->parse_time('24:00:00'), 'parse time 24:00:00');
is($tc->as_string, '24:00:00', 'check time 24:00:00');
is($db->format_time($tc), '24:00:00', 'format time 24:00:00');

ok($tc = $db->parse_time('24:00:00 PM'), 'parse time 24:00:00 PM');
is($tc->as_string, '24:00:00', 'check time 24:00:00 PM');
is($db->format_time($tc), '24:00:00', 'format time 24:00:00 PM');

ok($tc = $db->parse_time('24:00'), 'parse time 24:00');
is($tc->as_string, '24:00:00', 'check time 24:00');
is($db->format_time($tc), '24:00:00', 'format time 24:00');

ok(!defined $db->parse_time('24:00:00.000000001'), 'parse time fail 24:00:00.000000001');
ok(!defined $db->parse_time('24:00:01'), 'parse time fail 24:00:01');
ok(!defined $db->parse_time('24:01'), 'parse time fail 24:01');

SKIP:
{
  unless(have_db('pg'))
  {
    skip('pg tests', 48);
  }

  eval { $db->connect };
  skip("Could not connect to db 'test', 'pg' - $@", 43)  if($@);
  my $dbh = $db->dbh;

  is($db->domain, 'test', "domain()");
  is($db->type, 'pg', "type()");

  is($db->print_error, $dbh->{'PrintError'}, 'print_error() 2');
  is($db->print_error, $db->connect_option('PrintError'), 'print_error() 3');

  is($db->null_date, '0000-00-00', "null_date()");
  is($db->null_datetime, '0000-00-00 00:00:00', "null_datetime()");

  is($db->format_date(parse_date('12/31/2002', 'floating')), '2002-12-31', "format_date() floating");
  is($db->format_datetime(parse_date('12/31/2002 12:34:56.123456789', 'floating')), '2002-12-31 12:34:56.123456789', "format_datetime() floating");

  is($db->format_timestamp(parse_date('12/31/2002 12:34:56.12345', 'floating')), '2002-12-31 12:34:56.123450000', "format_timestamp() floating");
  is($db->format_datetime(parse_date('12/31/2002 12:34:56', 'floating')), '2002-12-31 12:34:56', "format_datetime() floating");

  $db->server_time_zone('UTC');

  is($db->format_date(parse_date('12/31/2002', 'UTC')), '2002-12-31', "format_date()");
  is($db->format_datetime(parse_date('12/31/2002 12:34:56', 'UTC')), '2002-12-31 12:34:56+0000', "format_datetime()");

  is($db->format_timestamp(parse_date('12/31/2002 12:34:56')), '2002-12-31 12:34:56', "format_timestamp()");
  is($db->format_datetime(parse_date('12/31/2002 12:34:56')), '2002-12-31 12:34:56', "format_datetime()");

  is($db->parse_date('12-31-2002'), parse_date('12/31/2002', 'UTC'),  "parse_date()");
  is($db->parse_datetime('2002-12-31 12:34:56'), parse_date('12/31/2002 12:34:56', 'UTC'),  "parse_datetime()");
  is($db->parse_timestamp('2002-12-31 12:34:56'), parse_date('12/31/2002 12:34:56', 'UTC'),  "parse_timestamp()");
  like($db->parse_timestamp_with_time_zone('2002-12-31 12:34:56-05')->time_zone->name, qr/^-0*50*$/,  "parse_timestamp_with_time_zone()");
  #is($db->parse_time('12:34:56'), parse_date('12/31/2002 12:34:56', 'UTC')->strftime('%H:%M:%S'),  "parse_time()");

  $db->european_dates(1);

  is($db->parse_date('31-12-2002'), parse_date('12/31/2002', 'UTC'),  "parse_date() european");
  is($db->parse_datetime('2002-12-31 12:34:56'), parse_date('12/31/2002 12:34:56', 'UTC'),  "parse_datetime() european");
  is($db->parse_timestamp('2002-12-31 12:34:56'), parse_date('12/31/2002 12:34:56', 'UTC'),  "parse_timestamp() european");

  is($db->format_bitfield($db->parse_bitfield('1010')),
     q(1010), "format_bitfield() 1");

  is($db->format_bitfield($db->parse_bitfield(q(B'1010'))),
     q(1010), "format_bitfield() 2");

  is($db->format_bitfield($db->parse_bitfield(2), 4),
     q(0010), "format_bitfield() 3");

  is($db->format_bitfield($db->parse_bitfield('0xA'), 4),
     q(1010), "format_bitfield() 4");

  my $str = $db->format_array([ undef, 'a' .. 'c' ]);
  is($str, '{NULL,"a","b","c"}', 'format_array() 1.0');

  $str = $db->format_array([ 'a' .. 'c' ]);
  is($str, '{"a","b","c"}', 'format_array() 2');

  my $str2 = $db->format_array([ [ 'a' .. 'c' ], [ 'd', 'e' ] ]);
  is($str2, '{{"a","b","c"},{"d","e"}}', 'format_array() 3');

  my $ar = $db->parse_array('[-3:3]={1,2,3}');
  ok(ref $ar eq 'ARRAY' && @$ar == 3 && $ar->[0] eq '1' && $ar->[1] eq '2' && $ar->[2] eq '3',
     'parse_array() 1');

  $ar = $db->parse_array('{NULL,"a","b"}');
  ok(ref $ar eq 'ARRAY' && !defined $ar->[0] && $ar->[1] eq 'a' && $ar->[2] eq 'b',
     'parse_array() 2');

  $ar = $db->parse_array('{"a",NULL}');
  ok(ref $ar eq 'ARRAY' && $ar->[0] eq 'a' && !defined $ar->[1],
     'parse_array() 3');

  $ar = $db->parse_array($str);
  ok(ref $ar eq 'ARRAY' && $ar->[0] eq 'a' && $ar->[1] eq 'b' && $ar->[2] eq 'c',
     'parse_array() 4');

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

  #is($db->autocommit + 0, $dbh->{'AutoCommit'} + 0, 'autocommit() 1');

  $db->autocommit(1);

  is($db->autocommit + 0, 1, 'autocommit() 2');
  is($dbh->{'AutoCommit'} + 0, 1, 'autocommit() 3');

  $db->autocommit(0);

  is($db->autocommit + 0, 0, 'autocommit() 4');
  is($dbh->{'AutoCommit'} + 0, 0, 'autocommit() 5');

  eval { $db->sequence_name(table => 'foo') };
  ok($@, 'auto_sequence_name() 1');

  eval { $db->sequence_name(column => 'bar') };
  ok($@, 'auto_sequence_name() 2');

  is($db->auto_sequence_name(table => 'foo.goo', column => 'bar'), 'foo.goo_bar_seq', 'auto_sequence_name() 3');

  my $dbh_copy = $db->retain_dbh;

  $db->disconnect;
}

(my $version = $DBI::VERSION) =~ s/_//g;

if(have_db('pg') && $version >= 1.24)
{
  my $x = 0;
  my $handler = sub { $x++ };

  Rose::DB->register_db(
    type         => 'error_handler',
    driver       => 'pg',
    database     => 'test',
    host         => 'localhost',
    print_error  => 0,
    raise_error  => 1,
    handle_error => $handler,
  );

  $db = Rose::DB->new('error_handler');

  ok($db->raise_error, 'raise_error 1');
  ok(!$db->print_error, 'print_error 1');
  is($db->handle_error, $handler, 'handle_error 1');

  $db->connect;

  ok($db->raise_error, 'raise_error 2');
  ok(!$db->print_error, 'print_error 2');
  is($db->handle_error, $handler, 'handle_error 2');
  is($db->dbh->{'HandleError'}, $handler, 'HandleError 1');

  eval
  {
  	my $sth = $db->dbh->prepare('select nonesuch from ?');
  	$sth->execute;
  };

  ok($@, 'handle_error 3');
  is($x, 1, 'handle_error 4');

  eval
  {
  	my $sth = $db->dbh->prepare('select nonesuch from ?');
  	$sth->execute;
  };

  is($x, 2, 'handle_error 5');
}
else
{
  SKIP: { skip("HandleError tests (DBI $DBI::VERSION)", 10) }
}
