#!/usr/bin/perl -w

use strict;

BEGIN { $ENV{'ROSE_DB_KEYWORD_FUNCTION_CALLS'} = 1 }

use Rose::DateTime::Util qw(parse_date);

BEGIN
{
  require Test::More;
  require 't/test-lib.pl';

  if(have_db('sqlite_admin'))
  {
    Test::More->import(tests => 60);
  }
  else
  {
    Test::More->import(skip_all =>  'DBD::SQLite unavailable or broken');    
  }
}

use_ok('Rose::DB');

My::DB2->default_domain('test');
My::DB2->default_type('sqlite_admin');

is(My::DB2->default_keyword_function_calls, 1, 'default_keyword_function_calls 2');

my $db = My::DB2->new();

is($db->keyword_function_calls, 1, 'keyword_function_calls 1');
My::DB2->default_keyword_function_calls(0);
$db->keyword_function_calls(0);

ok(ref $db && $db->isa('Rose::DB'), 'new()');

my $dbh;
eval { $dbh = $db->dbh };

SKIP:
{
  skip("Could not connect to db - $@", 9)  if($@);

  ok($dbh, 'dbh() 1');

  ok($db->has_dbh, 'has_dbh() 1');

  my $db2 = My::DB2->new();

  $db2->dbh($dbh);

  foreach my $field (qw(dsn driver database host port username password))
  { 
    is($db2->$field() || '', $db->$field() || '', "$field()");
  }

  $db->disconnect;
  $db2->disconnect;
}

$db = My::DB2->new();

ok(ref $db && $db->isa('Rose::DB'), "new()");

$db->init_db_info;

ok($db->supports_limit_with_offset, 'supports_limit_with_offset');

my @letters = ('a' .. 'z', 'A' .. 'Z', 0 .. 9);
my $rand;

$rand .= $letters[int rand(@letters)] for(1 .. int(rand(20)));
$rand = 'default'  unless(defined $rand); # got under here once!

ok(!$db->validate_timestamp_keyword($rand), "validate_timestamp_keyword ($rand)");

$db->keyword_function_calls(1);
is($db->format_timestamp('Foo(Bar)'), 'Foo(Bar)', 'format_timestamp (Foo(Bar))');
$db->keyword_function_calls(0);

ok(!$db->validate_datetime_keyword($rand), "validate_datetime_keyword ($rand)");

$db->keyword_function_calls(1);
is($db->format_datetime('Foo(Bar)'), 'Foo(Bar)', 'format_datetime (Foo(Bar))');
$db->keyword_function_calls(0);

ok(!$db->validate_date_keyword($rand), "validate_date_keyword ($rand)");

$db->keyword_function_calls(1);
is($db->format_date('Foo(Bar)'), 'Foo(Bar)', 'format_date (Foo(Bar))');
$db->keyword_function_calls(0);

ok(!$db->validate_time_keyword($rand), "validate_time_keyword ($rand)");

$db->keyword_function_calls(1);
is($db->format_time('Foo(Bar)'), 'Foo(Bar)', 'format_time (Foo(Bar))');
$db->keyword_function_calls(0);

is($db->format_array([ 'a', 'b' ]), q({"a","b"}), 'format_array() 1');
is($db->format_array('a', 'b'), q({"a","b"}), 'format_array() 2');

eval { $db->format_array('x' x 300) };
ok($@, 'format_array() 3');

my $a = $db->parse_array(q({"a","b","\\""}));

ok(@$a == 3 && $a->[0] eq 'a' && $a->[1] eq 'b' &&  $a->[2] eq '"', 'parse_array() 1');

SKIP:
{
  eval { $db->connect };
  skip("Could not connect to db 'test', 'sqlite' - $@", 18)  if($@);
  $dbh = $db->dbh;

  is($db->domain, 'test', "domain()");
  is($db->type, 'sqlite_admin', "type()");

  is($db->print_error, $dbh->{'PrintError'}, 'print_error() 2');
  is($db->print_error, $db->connect_option('PrintError'), 'print_error() 3');

  is($db->null_date, '0000-00-00', "null_date()");
  is($db->null_datetime, '0000-00-00 00:00:00', "null_datetime()");

  is($db->format_date(parse_date('12/31/2002', 'floating')), '2002-12-31', "format_date() floating");
  is($db->format_datetime(parse_date('12/31/2002 12:34:56', 'floating')), '2002-12-31 12:34:56', "format_datetime() floating");

  is($db->format_timestamp(parse_date('12/31/2002 12:34:56.123456789', 'floating')), '2002-12-31 12:34:56.123456789', "format_timestamp() floating");
  #is($db->format_time(parse_date('12/31/2002 12:34:56', 'floating')), '12:34:56', "format_time() floating");

  is($db->format_bitfield($db->parse_bitfield('1010')),
     q(b'1010'), "format_bitfield() 1");

  is($db->format_bitfield($db->parse_bitfield(q(B'1010'))),
     q(b'1010'), "format_bitfield() 2");

  is($db->format_bitfield($db->parse_bitfield(2), 4),
     q(b'0010'), "format_bitfield() 3");

  is($db->format_bitfield($db->parse_bitfield('0xA'), 4),
     q(b'1010'), "format_bitfield() 4");

  #is($db->autocommit + 0, $dbh->{'AutoCommit'} + 0, 'autocommit() 1');

  $db->autocommit(1);

  is($db->autocommit + 0, 1, 'autocommit() 2');
  is($dbh->{'AutoCommit'} + 0, 1, 'autocommit() 3');

  $db->autocommit(0);

  is($db->autocommit + 0, 0, 'autocommit() 4');
  is($dbh->{'AutoCommit'} + 0, 0, 'autocommit() 5');

  my $dbh_copy = $db->retain_dbh;

  $db->disconnect;

  if($db->isa('My::DB2'))
  {
    $My::DB2::Called{'init_dbh'} = 0;
    $db = My::DB2->new('sqlite');
    $db->dbh;
    is($My::DB2::Called{'init_dbh'}, 1, 'SUPER:: from driver');
  }
  else
  {
    SKIP: { skip('SUPER:: from driver tests', 1) }
  }
}

$db->dsn('dbi:SQLite:dbname=dbfoo');

#ok(!defined($db->database) || $db->database eq 'dbfoo', 'dsn() 1');
#ok(!defined($db->host) || $db->host eq 'hfoo', 'dsn() 2');
#ok(!defined($db->port) || $db->port eq 'port', 'dsn() 3');

eval { $db->dsn('dbi:Pg:dbname=dbfoo') };

ok($@ || $DBI::VERSION <  1.43, 'dsn() driver change');

My::DB2->register_db(
  domain      => My::DB2->default_domain,
  type        => 'nonesuch',
  driver      => 'SQLITE',
  database    => '/tmp/rdbo_does_not_exist.db',
  auto_create => 0,
);

if((! -e '/tmp/rdbo_does_not_exist.db') || unlink('/tmp/rdbo_does_not_exist.db'))
{
  $db = My::DB2->new('nonesuch');

  eval { $db->connect };

  ok($@ =~ /^Refus/, 'nonesuch database');
}
else
{
  ok(1, "could not unlink /tmp/rdbo_does_not_exist.db - $!");
}

(my $version = $DBI::VERSION) =~ s/_//g;

if($version >= 1.24)
{
  my $x = 0;
  my $handler = sub { $x++ };

  My::DB2->register_db(
    type   => 'error_handler',
    driver => 'sqlite',
    print_error    => 0,
    raise_error    => 1,
    handle_error   => $handler,
    sqlite_unicode => 1,
  );

  $db = My::DB2->new('error_handler');

  ok($db->raise_error, 'raise_error 1');
  ok(!$db->print_error, 'print_error 1');
  is($db->handle_error, $handler, 'handle_error 1');

  $db->connect;

  ok($db->raise_error, 'raise_error 2');
  ok(!$db->print_error, 'print_error 2');
  is($db->handle_error, $handler, 'handle_error 2');

  eval { $db->dbh->prepare('select nonesuch from ?') };

  ok($@, 'handle_error 3');
  is($x, 1, 'handle_error 4');

  eval { $db->dbh->prepare('select nonesuch from ?') };

  is($x, 2, 'handle_error 5');

  ok($db->sqlite_unicode, 'sqlite_unicode 1');
  ok($db->dbh->{'sqlite_unicode'}, 'sqlite_unicode 2');

  $db->sqlite_unicode(0);

  ok(!$db->sqlite_unicode, 'sqlite_unicode 3');
  ok(!$db->dbh->{'sqlite_unicode'}, 'sqlite_unicode 4');
}
else
{
  SKIP: { skip("HandleError tests (DBI $DBI::VERSION)", 13) }
}
