#!/usr/bin/perl -w

use strict;

use Rose::DateTime::Util qw(parse_date);

BEGIN
{
  require Test::More;
  eval { require DBD::MariaDB };

  if($@)
  {
    Test::More->import(skip_all => 'Missing DBD::MariaDB');
  }
  else
  {
    Test::More->import(tests => 107);
  }
}

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB');
}

My::DB2->default_domain('test');
My::DB2->default_type('mariadb');

my $db = My::DB2->new();

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
    is($db2->$field(), $db->$field(), "$field()");
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

ok(!$db->validate_datetime_keyword($rand), "validate_datetime_keyword ($rand)");

ok(!$db->validate_date_keyword($rand), "validate_date_keyword ($rand)");

ok($db->validate_date_keyword('0000-00-00'), "validate_date_keyword (0000-00-00)");

ok($db->validate_datetime_keyword('0000-00-00 00:00:00'), "validate_datetime_keyword (0000-00-00 00:00:00)");
ok($db->validate_datetime_keyword('0000-00-00 00:00:00'), "validate_datetime_keyword (0000-00-00 00:00:00)");

ok($db->validate_timestamp_keyword('0000-00-00 00:00:00'), "validate_timestamp_keyword (0000-00-00 00:00:00)");
ok($db->validate_timestamp_keyword('00000000000000'), "validate_timestamp_keyword (00000000000000)");

ok(!$db->validate_time_keyword($rand), "validate_time_keyword ($rand)");

foreach my $name (qw(date datetime timestamp))
{
  my $method = "validate_${name}_keyword";

  ok(!$db->$method('Foo(Bar)'), "$method (Foo(Bar)) 1");
  $db->keyword_function_calls(1);
  ok($db->$method('Foo(Bar)'), "$method (Foo(Bar)) 2");
  $db->keyword_function_calls(0);

  foreach my $value (qw(now() curtime() curdate() sysdate() current_time 
                        current_time() current_date current_date()
                        current_timestamp current_timestamp()))
  {
    my $new_value = $value;
    my $i = int(rand(length($new_value) - 3)); # 3 = 1 + 2 (for possible parens)
    substr($new_value, $i, 1) = uc substr($new_value, $i, 1);
    ok($db->$method($new_value), "$method ($new_value)");
  }
}

is($db->format_array([ 'a', 'b' ]), q({"a","b"}), 'format_array() 1');
is($db->format_array('a', 'b'), q({"a","b"}), 'format_array() 2');

eval { $db->format_array('x' x 300) };
ok($@, 'format_array() 3');

my $a = $db->parse_array(q({"a","b","\\""}));

ok(@$a == 3 && $a->[0] eq 'a' && $a->[1] eq 'b' &&  $a->[2] eq '"', 'parse_array() 1');

is($db->format_set([ 'a', 'b' ]), 'a,b', 'format_set() 1');
is($db->format_set('a', 'b'), 'a,b', 'format_set() 2');

eval { $db->format_set('a', undef) };
ok($@ =~ /undefined/i, 'format_set() 3');

eval { $db->format_set([ 'a', undef ]) };
ok($@ =~ /undefined/i, 'format_set() 4');

my $s = $db->parse_set('a,b');

ok(@$s == 2 && $s->[0] eq 'a' && $s->[1] eq 'b', 'parse_set() 1');

SKIP:
{
  unless(have_db('mariadb'))
  {
    skip("MariaDB connection tests", 28);
  }

  eval { $db->connect };
  skip("Could not connect to db 'test', 'mariadb' - $@", 28)  if($@);
  $dbh = $db->dbh;

  is($db->domain, 'test', "domain()");
  is($db->type, 'mariadb', "type()");

  is($db->print_error, $dbh->{'PrintError'}, 'print_error() 2');
  is($db->print_error, $db->connect_option('PrintError'), 'print_error() 3');

  is($db->null_date, '0000-00-00', "null_date()");
  is($db->null_datetime, '0000-00-00 00:00:00', "null_datetime()");

  is($db->format_date(parse_date('12/31/2002', 'floating')), '2002-12-31', "format_date() floating");
  is($db->format_datetime(parse_date('12/31/2002 12:34:56', 'floating')), '2002-12-31 12:34:56', "format_datetime() floating");

  is($db->format_timestamp(parse_date('12/31/2002 12:34:56', 'floating')), '2002-12-31 12:34:56', "format_timestamp() floating");

  if($db->database_version >= 5_000_003)
  {
    is($db->format_bitfield($db->parse_bitfield('1010')),
       q(b'1010'), "format_bitfield() 1");

    is($db->format_bitfield($db->parse_bitfield(q(B'1010'))),
       q(b'1010'), "format_bitfield() 2");

    is($db->format_bitfield($db->parse_bitfield(2), 4),
       q(b'0010'), "format_bitfield() 3");

    is($db->format_bitfield($db->parse_bitfield('0xA'), 4),
       q(b'1010'), "format_bitfield() 4");  
  }
  else
  {
    is($db->format_bitfield($db->parse_bitfield('1010')),
       q(10), "format_bitfield() 1");

    is($db->format_bitfield($db->parse_bitfield(q(B'1010'))),
       q(10), "format_bitfield() 2");

    is($db->format_bitfield($db->parse_bitfield(2), 4),
       q(2), "format_bitfield() 3");

    is($db->format_bitfield($db->parse_bitfield('0xA'), 4),
       q(10), "format_bitfield() 4");
  }

  #is($db->autocommit + 0, $dbh->{'AutoCommit'} + 0, 'autocommit() 1');

  $db->autocommit(1);

  is($db->autocommit + 0, 1, 'autocommit() 2');
  is($dbh->{'AutoCommit'} + 0, 1, 'autocommit() 3');

  $db->autocommit(0);

  is($db->autocommit + 0, 0, 'autocommit() 4');
  is($dbh->{'AutoCommit'} + 0, 0, 'autocommit() 5');

  my $dbh_copy = $db->retain_dbh;

  $db->disconnect;

  # https://metacpan.org/pod/DBD::MariaDB#DATABASE-HANDLES
  foreach my $attr (qw(mariadb_auto_reconnect mariadb_use_result mariadb_bind_type_guessing))
  {
    $db = My::DB2->new($attr => 1);
    is($db->$attr(), 1, "$attr 1");
    $db->connect;

    SKIP:
    {
      if($attr eq 'mariadb_auto_reconnect') # can't read back the others?
      {
        is($db->$attr(), 1, "$attr 2");
        is($db->dbh->{$attr}, 1, "$attr 3");
      }
      else { SKIP: { skip("$attr dbh read-back", 2) } }
    }
  }

  TEST:
  {
    my $dbh = My::DB2->new->retain_dbh;
    $db = My::DB2->new(dbh => $dbh);
  }

  $db->retain_dbh;
  $db->release_dbh;

  ok($db->{'dbh'}{'Active'}, 'retain stuffed dbh');

  $db->connect;

  if($db->isa('My::DB2'))
  {
    $My::DB2::Called{'init_dbh'} = 0;
    $db = My::DB2->new('mariadb');
    $db->dbh;
    is($My::DB2::Called{'init_dbh'}, 1, 'SUPER:: from driver');
  }
  else
  {
    SKIP: { skip('SUPER:: from driver tests', 1) }
  }
}

$db->dsn('dbi:MariaDB:dbname=dbfoo;host=hfoo;port=pfoo');

#ok(!defined($db->database) || $db->database eq 'dbfoo', 'dsn() 1');
#ok(!defined($db->host) || $db->host eq 'hfoo', 'dsn() 2');
#ok(!defined($db->port) || $db->port eq 'port', 'dsn() 3');

eval { $db->dsn('dbi:Pg:dbname=dbfoo;host=hfoo;port=pfoo') };

ok($@ || $DBI::VERSION <  1.43, 'dsn() driver change');

My::DB2->register_db
(
  domain => 'stub',
  type   => 'default',
  driver => 'MariaDB',
);

$db = My::DB2->new
(
  domain => 'stub',
  type   => 'default',
  dsn    => "dbi:MariaDB:mydb",
);

is($db->database, 'mydb', 'parse_dsn() 1');

sub lookup_ip
{
  my($name) = shift;

  my $address = (gethostbyname($name))[4] or return 0;

  my @octets = unpack("CCCC", $address);

  return 0  unless($name && @octets);
  return join('.', @octets), "\n";
}

(my $version = $DBI::VERSION) =~ s/_//g;

if(have_db('mariadb') && $version >= 1.24)
{
  my $x = 0;

  my $handler = sub { $x++; die "Error: $x" };

  My::DB2->register_db(
    type   => 'error_handler',
    driver => 'mariadb',
    print_error  => 0,
    raise_error  => 1,
    handle_error => $handler,
    username     => 'test',
  );

  $db = My::DB2->new('error_handler');

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
