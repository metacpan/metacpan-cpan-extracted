#!/usr/bin/perl -w

use strict;

use Rose::DateTime::Util qw(parse_date);

BEGIN
{
  require Test::More;
  eval { require DBD::Oracle };

  if($@)
  {
    Test::More->import(skip_all => 'Missing DBD::Oracle');
  }
  else
  {
    Test::More->import(tests => 80);
  }
}

BEGIN
{
  require 't/test-lib.pl';
  use_ok('Rose::DB');
}

Rose::DB->default_domain('test');
Rose::DB->default_type('oracle');

# Note: $db here is of type Rose::DB::Oracle.

my $db = Rose::DB->new();

ok(ref $db && $db->isa('Rose::DB'), 'new()');

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

$db->keyword_function_calls(1);
is($db->parse_boolean('Foo(Bar)'), 'Foo(Bar)', 'parse_boolean (Foo(Bar))');
$db->keyword_function_calls(0);

foreach my $val (qw(t 1 true True T y Y yes Yes))
{
  is($db->format_boolean($db->parse_boolean($val)), 't', "format_boolean ($val)");
}

foreach my $val (qw(f 0 false False F n N no No))
{
  is($db->format_boolean($db->parse_boolean($val)), 'f', "format_boolean ($val)");
}

is($db->auto_quote_column_name('foo_bar_123'), 'foo_bar_123', 'auto_quote_column_name 1');
is($db->auto_quote_column_name('claim#'), '"CLAIM#"', 'auto_quote_column_name 2');
is($db->auto_quote_column_name('foo-bar'), '"FOO-BAR"', 'auto_quote_column_name 3');

is($db->parse_date('2002-12-31'), parse_date('12/31/2002'),  "parse_date() 1");
is($db->parse_date('2002-12-31 12:34'), parse_date('12/31/2002 12:34'),  "parse_date() 2");

is($db->parse_datetime('2002-12-31 12:34:56'), parse_date('12/31/2002 12:34:56'),  "parse_datetime() 1");
is($db->parse_datetime('2002-12-31 12:34:56.0'), parse_date('12/31/2002 12:34:56'),  "parse_datetime() 2");

is($db->parse_timestamp('2002-12-31 12:34:56'), parse_date('12/31/2002 12:34:56'),  "parse_timestamp() 1");
is($db->parse_timestamp('2002-12-31 12:34:56.0'), parse_date('12/31/2002 12:34:56'),  "parse_timestamp() 2");
is($db->parse_timestamp('2002-12-31 12:34:56.123'), parse_date('12/31/2002 12:34:56.123'),  "parse_timestamp() 3");
is($db->parse_timestamp('2002-12-31 12:34:56.123456789'), parse_date('12/31/2002 12:34:56.123456'),  "parse_timestamp() 4");

like($db->parse_timestamp_with_time_zone('2002-12-31 12:34:56 -0500')->time_zone->name, qr/^-0*50*$/,  "parse_timestamp_with_time_zone() 1");
like($db->parse_timestamp_with_time_zone('2002-12-31 12:34:56.0 -0500')->time_zone->name, qr/^-0*50*$/,  "parse_timestamp_with_time_zone() 2");
like($db->parse_timestamp_with_time_zone('2002-12-31 12:34:56.123 -0500')->time_zone->name, qr/^-0*50*$/,  "parse_timestamp_with_time_zone() 3");
like($db->parse_timestamp_with_time_zone('2002-12-31 12:34:56.123456789 -0500')->time_zone->name, qr/^-0*50*$/,  "parse_timestamp_with_time_zone() 4");

my $dbh;
eval { $dbh = $db->dbh };

SKIP:
{
  skip("Could not connect to db - $@", 16)  if($@);

  ok($dbh, 'dbh() 1');

  ok($db->has_dbh, 'has_dbh() 1');

  my $db2 = Rose::DB->new();

  $db2->dbh($dbh);

  foreach my $field (qw(dsn driver database host port username password))
  {
    is($db2->$field(), $db->$field(), "$field()");
  }

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
  is($db->next_value_in_sequence('rose_db_sequence_test'), 6, 'next_value_in_sequence 1');
  is($db->current_value_in_sequence('rose_db_sequence_test'), 6, 'current_value_in_sequence 2');
  is($db->next_value_in_sequence('rose_db_sequence_test'), 7, 'next_value_in_sequence 2');
  is($db->current_value_in_sequence('rose_db_sequence_test'), 7, 'current_value_in_sequence 3');

  $dbh->do('DROP SEQUENCE rose_db_sequence_test');

  $db->disconnect;
  $db2->disconnect;
}

$db = Rose::DB->new();

ok(ref $db && $db->isa('Rose::DB'), "new()");

$db->init_db_info;

Rose::DB->register_db
(
  domain => 'stub',
  type   => 'default',
  driver => 'oracle',
);

$db = Rose::DB->new
(
  domain => 'stub',
  type   => 'default',
  dsn    => "dbi:Oracle:mydb",
);

is($db->database, 'mydb', 'parse_dsn() 1');

SKIP:
{
  $db = Rose::DB->new;

  eval { $db->connect };
  skip("Could not connect to db 'test', 'oracle' - $@", 10)  if($@);
  $dbh = $db->dbh;

  is($db->domain, 'test', "domain()");
  is($db->type, 'oracle', "type()");

  is($db->print_error, $dbh->{'PrintError'}, 'print_error() 2');
  is($db->print_error, $db->connect_option('PrintError'), 'print_error() 3');

  is($db->null_date, '0000-00-00', "null_date()");
  is($db->null_datetime, '0000-00-00 00:00:00', "null_datetime()");

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

Rose::DB->register_db
(
  type     => 'dsn1',
  driver   => 'oracle',
  database => 'somedb',
);

is(Rose::DB->new('dsn1')->dsn, 'dbi:Oracle:somedb', 'dsn 1');

Rose::DB->register_db
(
  type     => 'dsn2',
  driver   => 'oracle',
  database => 'somedb',
  host     => 'somehost',
);

is(Rose::DB->new('dsn2')->dsn, 'dbi:Oracle:sid=somedb;host=somehost', 'dsn 2');

Rose::DB->register_db
(
  type     => 'dsn3',
  driver   => 'oracle',
  database => 'somedb',
  port     => 'someport',
);

is(Rose::DB->new('dsn3')->dsn, 'dbi:Oracle:sid=somedb;port=someport', 'dsn 3');

Rose::DB->register_db
(
  type     => 'dsn4',
  driver   => 'oracle',
  database => 'somedb',
  host     => 'somehost',
  port     => 'someport',
);

is(Rose::DB->new('dsn4')->dsn, 'dbi:Oracle:sid=somedb;host=somehost;port=someport', 'dsn 4');
