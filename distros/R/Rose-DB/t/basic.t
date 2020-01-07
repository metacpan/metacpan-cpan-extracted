#!/usr/bin/perl -w

use strict;

use FindBin qw($Bin);

use Test::More tests => 209;

BEGIN
{
  use_ok('Rose::DB');
  use_ok('Rose::DB::Registry');
  use_ok('Rose::DB::Registry::Entry');
  use_ok('Rose::DB::Constants');

  require 't/test-lib.pl';

  is(Rose::DB::Constants::IN_TRANSACTION(), -1, 'Rose::DB::Constants::IN_TRANSACTION');
  Rose::DB::Constants->import('IN_TRANSACTION');

  # Default
  Rose::DB->register_db(
    domain   => 'default',
    type     => 'default',
    driver   => 'Pg',
    database => 'test',
    host     => 'localhost',
    username => 'postgres',
    password => '',
  );

  # Main
  Rose::DB->register_db(
    domain   => 'test',
    type     => 'default',
    driver   => 'Pg',
    database => 'test',
    host     => 'localhost',
    username => 'postgres',
    password => '',
  );

  # Aux
  Rose::DB->register_db(
    domain   => 'test',
    type     => 'aux',
    driver   => 'Pg',
    database => 'test',
    host     => 'localhost',
    username => 'postgres',
    password => '',
  );

  # Generic
  Rose::DB->register_db(
    domain   => 'test',
    type     => 'generic',
    driver   => 'NoneSuch',
    database => 'test',
    host     => 'localhost',
    username => 'someuser',
    password => '',
  );

  # Alias
  Rose::DB->alias_db(source => { domain => 'test',  type => 'aux'  },
                     alias  => { domain => 'atest', type => 'aaux' });

  package MyPgClass;
  @MyPgClass::ISA = qw(Rose::DB::Pg);
  sub format_date { die "boo!" }
}

my $sqlite_ok = have_db('sqlite_admin');

is_deeply(scalar Rose::DB->registry->registered_domains, 
          [ qw(atest catalog_test default test) ], 'registered_domains()');

is_deeply(scalar Rose::DB->registry->registered_types('test'), 
          [ qw(aux default generic informix informix_admin  mariadb mariadb_admin 
              mysql mysql_admin oracle oracle_admin pg pg_admin pg_with_schema),
               ($sqlite_ok ? qw(sqlite sqlite_admin) : ()) ],
          'registered_types()');

# Lame arbitrary test of one dump attr
my $dump = Rose::DB->registry->dump;
is($dump->{'test'}{'aux'}{'username'}, 'postgres', 'dump() 1');

is(IN_TRANSACTION, -1, 'IN_TRANSACTION');

is(Rose::DB->default_keyword_function_calls, 0, 'default_keyword_function_calls 1');
Rose::DB->default_keyword_function_calls(1);
is(Rose::DB->default_keyword_function_calls, 1, 'default_keyword_function_calls 2');

my $db = Rose::DB->new;

is($db->keyword_function_calls, 1, 'keyword_function_calls 1');

$db = Rose::DB->new;

is($db->keyword_function_calls, 1, 'keyword_function_calls 2');

is(Rose::DB->default_domain, 'test', 'default_domain() 1');
is(Rose::DB->default_type, 'default', 'default_type() 1');

ok(Rose::DB->db_exists('default'), 'db_exists() 1');
ok(!Rose::DB->db_exists('defaultx'), 'db_exists() 2');

ok(Rose::DB->db_exists(type => 'default'), 'db_exists() 3');
ok(!Rose::DB->db_exists(type => 'defaultx'), 'db_exists() 4');

ok(Rose::DB->db_exists(type => 'default', domain => 'test'), 'db_exists() 3');
ok(!Rose::DB->db_exists(type => 'defaultx', domain => 'testx'), 'db_exists() 4');

ok(!Rose::DB->db_exists(type => 'defaultx', domain => 'test'), 'db_exists() 3');

Rose::DB->error('foo');

is(Rose::DB->error, 'foo', 'error() 2');

$db->error('bar');

is(Rose::DB->error, 'bar', 'error() 3');
is($db->error, 'bar', 'error() 4');

eval { $db = Rose::DB->new };
ok(!$@, 'Valid type and domain');

Rose::DB->default_domain('foo');

is(Rose::DB->default_domain, 'foo', 'default_domain() 2');

eval { $db = Rose::DB->new };
ok($@, 'Invalid domain');

Rose::DB->default_domain('test');
Rose::DB->default_type('bar');

is(Rose::DB->default_type, 'bar', 'default_type() 2');

eval { $db = Rose::DB->new };
ok($@, 'Invalid type');

is(Rose::DB->driver_class('Pg'), 'Rose::DB::Pg', 'driver_class() 1');
is(Rose::DB->driver_class('xxx'), undef, 'driver_class() 2');

Rose::DB->driver_class(Pg => 'MyPgClass');
is(Rose::DB->driver_class('Pg'), 'MyPgClass', 'driver_class() 3');

$db = Rose::DB->new(type => 'aux', database => 'xyzzy');

is($db->database, 'xyzzy', 'override on new() 1');

$db = Rose::DB->new(type => 'aux', dsn => 'dbi:Pg:host=foo;database=bar');

is($db->dsn, 'dbi:Pg:host=foo;database=bar', 'override on new() 2');

$db = Rose::DB->new('aux');

ok($db->isa('MyPgClass'), 'new() single arg');

is($db->error('foo'), 'foo', 'subclass 1');
is($db->error, 'foo', 'subclass 2');

eval { $db->format_date('123') };
ok($@ =~ /^boo!/, 'driver_class() 4');

is(Rose::DB->default_connect_option('AutoCommit'), 1, "default_connect_option('AutoCommit')");
is(Rose::DB->default_connect_option('RaiseError'), 1, "default_connect_option('RaiseError')");
is(Rose::DB->default_connect_option('PrintError'), 1, "default_connect_option('PrintError')");
is(Rose::DB->default_connect_option('ChopBlanks'), 1, "default_connect_option('ChopBlanks')");
is(Rose::DB->default_connect_option('Warn'), 0, "default_connect_option('Warn')");

my $options = Rose::DB->default_connect_options;

is(ref $options, 'HASH', 'default_connect_options() 1');
is(join(',', sort keys %$options), 'AutoCommit,ChopBlanks,PrintError,RaiseError,Warn',
  'default_connect_options() 2');

Rose::DB->default_connect_options(a => 1, b => 2);

is(Rose::DB->default_connect_option('a'), 1, "default_connect_option('a')");
is(Rose::DB->default_connect_option('b'), 2, "default_connect_option('b')");

Rose::DB->default_connect_options({ c => 3, d => 4 });

is(Rose::DB->default_connect_option('c'), 3, "default_connect_option('c') 1");
is(Rose::DB->default_connect_option('d'), 4, "default_connect_option('d') 1");

my $keys = join(',', sort keys %{$db->default_connect_options});

$db->default_connect_options(zzz => 'bar');

my $keys2 = join(',', sort keys %{$db->default_connect_options});

is($keys2, "$keys,zzz", 'default_connect_options() 1');

$db->default_connect_options({ zzz => 'bar' });

$keys2 = join(',', sort keys %{$db->default_connect_options});

is($keys2, 'zzz', 'default_connect_options() 2');

$keys = join(',', sort keys %{$db->connect_options});

$db->connect_options(zzzz => 'bar');

$keys2 = join(',', sort keys %{$db->connect_options});

is($keys2, "$keys,zzzz", 'connect_option() 1');

$db->connect_options({ zzzz => 'bar' });

$keys2 = join(',', sort keys %{$db->connect_options});

is($keys2, 'zzzz', 'connect_option() 2');

$db->dsn('dbi:Pg:dbname=dbfoo;host=hfoo;port=pfoo');

#ok(!defined($db->database) || $db->database eq 'dbfoo', 'dsn() 1');
#ok(!defined($db->host) || $db->host eq 'hfoo', 'dsn() 2');
#ok(!defined($db->port) || $db->port eq 'port', 'dsn() 3');

eval { $db->dsn('dbi:mysql:dbname=dbfoo;host=hfoo;port=pfoo') };

ok($@ || $DBI::VERSION <  1.43, 'dsn() driver change');

$db = Rose::DB->new(domain  => 'test', type  => 'aux');
my $adb = Rose::DB->new(domain  => 'atest', type  => 'aaux');

is($db->class, 'Rose::DB', 'class() 1');

foreach my $attr (qw(domain type driver database username password 
                     connect_options post_connect_sql))
{
  is($db->username, $adb->username, "alias $attr()");
}

Rose::DB->modify_db(domain   => 'test', 
                    type     => 'aux', 
                    username => 'blargh',
                    connect_options => { Foo => 1 });

$db->init_db_info(refresh => 1);
$adb->init_db_info(refresh => 1);

is($db->username, $adb->username, "alias username() mod");
is($db->connect_options->{'Foo'}, $adb->connect_options->{'Foo'}, "alias connect_options() mod");

$db = Rose::DB->new('generic');

ok($db->isa('Rose::DB::Generic'), 'generic class');

is($db->dsn, 'dbi:NoneSuch:dbname=test;host=localhost', 'generic dsn');

ok(!$db->has_dbh, 'has_dbh() 1');

#
# Registry tests
#

my $reg = Rose::DB->registry;

ok($reg->isa('Rose::DB::Registry'), 'registry');

my $entry = $reg->entry(domain => 'test', type => 'aux');

ok($entry->isa('Rose::DB::Registry::Entry'), 'registry entry 1');

foreach my $param (qw(autocommit database domain driver dsn host password port
                      print_error raise_error handle_error server_time_zone schema
                      type username connect_options pre_disconnect_sql 
                      post_connect_sql))
{
  eval { $entry->$param() };

  ok(!$@, "entry $param()");
}

my $host     = $entry->host;
my $database = $entry->database;

Rose::DB->modify_db(domain => 'test', type => 'aux', host => 'foo', database => 'bar');

is($entry->host, 'foo', 'entry modify_db() 1');
is($entry->database, 'bar', 'entry modify_db() 2');

is($entry->connect_option('RaiseError') || 0, 0, 'entry connect_option() 1');
$entry->connect_option('RaiseError' => 1);
is($entry->connect_option('RaiseError'), 1, 'entry connect_option() 2');

$entry->pre_disconnect_sql(qw(sql1 sql2));
my $sql = $entry->pre_disconnect_sql;
ok(@$sql == 2 && $sql->[0] eq 'sql1' && $sql->[1] eq 'sql2', 'entry pre_disconnect_sql() 1');

$entry->post_connect_sql(qw(sql3 sql4));
$sql = $entry->post_connect_sql;
ok(@$sql == 2 && $sql->[0] eq 'sql3' && $sql->[1] eq 'sql4', 'entry post_connect_sql() 1');

$entry->raise_error(0);
is($entry->connect_option('RaiseError'), 0, 'entry raise_error() 1');

$entry->print_error(1);
is($entry->connect_option('PrintError'), 1, 'entry print_error() 1');

$entry->autocommit(1);
is($entry->connect_option('AutoCommit'), 1, 'entry autocommit() 1');

my $handler = sub { 123 };
$entry->handle_error($handler);
is($entry->connect_option('HandleError'), $handler, 'entry handle_error() 1');

{
  package MyTest::DB;
  our @ISA = qw(Rose::DB);
  MyTest::DB->use_private_registry;
  MyTest::DB->default_type('dt');
  MyTest::DB->default_domain('dd');
  MyTest::DB->register_db(driver => 'sqlite');
}

$db = MyTest::DB->new;

is($db->type, 'dt', 'default type 1');
is($db->domain, 'dd', 'default domain 1');

{
  package MyTest::DB2;
  our @ISA = qw(Rose::DB);
  MyTest::DB2->default_type('xdt');
  MyTest::DB2->default_domain('xdd');

  MyTest::DB2->register_db(driver => 'sqlite');
}

$db = MyTest::DB2->new;

is($db->type, 'xdt', 'default type 2');
is($db->domain, 'xdd', 'default domain 2');

my @Intervals =
(
  '+0::'               => '',
  '-0:1:'              => '-00:01:00',
  '2:'                 => '02:00:00',
  '1 D'                => '1 day',
  '-1 d 2 s'           => '-1 days +00:00:02',
  '-1 y 3 h -57 M 4 s' => '-1 years +02:03:04',
  '-1 y 2 mons  3 d'   => '-10 mons +3 days',
  '-1 y 2 mons -3 d'   => '-10 mons -3 days',

  '5 h -208 m -495 s' => '01:23:45',
  '-208 m -495 s'     => '-03:36:15',
  '5 h 208 m 495 s'   => '08:36:15',

  ':'         => undef,
  '::'        => undef,
  '123:456:'  => undef,
  '1:-2:3'    => undef,
  '1:2:-3'    => undef,
  '1 h 1:1:1' => undef,
  '1 d 2 d'   => undef,
  '1: 2:'     => undef,
  '1 s 2:'    => undef,

  '1 ys 2 h 3 m 4 s'  => undef,
  '1 y s 2 h 3 m 4 s' => undef,
  '1 ago'             => undef,
  '1s ago'            => undef,
  '1 s agos'          => undef,
  '1 m ago ago 1 s'   => undef,
  '1 m ago1 s'        => undef,
  '1 m1 s'            => undef,

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
  my($val, $formatted) = ($Intervals[$i++], $Intervals[$i++]);

  is($db->format_interval($db->parse_interval($val)), $formatted, "parse_interval ($val)");
}

MyTest::DB2->max_interval_characters(1);

eval { $db->format_interval($db->parse_interval('1 day ago')) };
ok($@, 'max_interval_characters 1');

ok(Rose::DB->max_interval_characters != MyTest::DB2->max_interval_characters, 'max_interval_characters 2');

$db->keyword_function_calls(1);
is($db->parse_interval('foo()'), 'foo()', 'parse_interval (foo())');
$db->keyword_function_calls(0);

MyTest::DB2->max_interval_characters(255);

my $d = $db->parse_interval('1 year 0.000003 seconds');

is($d->nanoseconds, 3000, 'nanoseconds 1');

is($db->format_interval($d), '1 year 00:00:00.000003000', 'nanoseconds 2');

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

if(have_db('sqlite'))
{
  Rose::DB->register_db
  (
    domain => 'handel',
    type   => 'default',
    driver => 'SQLite',
  );

  $db = Rose::DB->new
  (
    domain => 'handel',
    type   => 'default',
    dsn    => "dbi:SQLite:dbname=$Bin/sqlite.db",
  );

  my $dbh = $db->dbh;

  is($db->dsn, "dbi:SQLite:dbname=$Bin/sqlite.db", 'dsn preservation 1');

  $db = Rose::DB->new
  (
    domain   => 'handel',
    type     => 'default',
    database => "$Bin/sqlitex.db",
  );

  $dbh = $db->dbh;

  is($db->dsn, "dbi:SQLite:dbname=$Bin/sqlitex.db", 'dsn preservation 2');

  unlink("$Bin/sqlite.db");
  unlink("$Bin/sqlitex.db");
}
else
{
  ok(1, 'skipping - dsn preservation requires sqlite 1');
  ok(1, 'skipping - dsn preservation requires sqlite 2');
}

#
# Registry entry tests
#

my @entry;

$i = 1;

foreach my $attr (sort(Rose::DB::Registry::Entry::_attrs(type => 'scalar')))
{
  push(@entry, $attr => ($attr eq 'driver' || $attr eq 'dbi_driver' ? 'sqlite' :  $i++));
}

foreach my $attr (sort(Rose::DB::Registry::Entry::_attrs(type => 'boolean')))
{
  push(@entry, $attr => $i++ % 2);
}

foreach my $attr (sort(Rose::DB::Registry::Entry::_attrs(type => 'hash')))
{
  push(@entry, $attr => { $i++ => $i++ });
}

foreach my $attr (sort(Rose::DB::Registry::Entry::_attrs(type => 'array')))
{
  push(@entry, $attr => [ $i++ ]);
}

$entry = Rose::DB::Registry::Entry->new(@entry);

$dump = $entry->dump;

is_deeply($dump, { @entry }, 'dump entry');

if(have_db('mysql'))
{
  my %mysql_entry = map { $_ => $dump->{$_} } grep { /^mysql_/ } keys %$dump;

  Rose::DB->register_db(
    domain   => 'abc',
    type     => 'def',
    driver   => 'mysql',
    database => 'test',
    %mysql_entry);

  my $db = Rose::DB->new(domain => 'abc', type => 'def');

  foreach my $attr (grep { /^mysql_/ } keys %$dump)
  {
    is($db->$attr(), $dump->{$attr}, "entry attr - $attr");
  }
}
else
{
  my $count = grep { /^mysql_/ } keys %$dump;
  SKIP: { skip('mysql entry tests', $count) }
}

if(have_db('sqlite'))
{
  {
      package My::DBX;
  
      use base 'Rose::DB';
  
      My::DBX->register_db(
          driver => 'SQLite',
      );  
  
      My::DBX->default_connect_options( { RaiseError => 0, } );
  }
  
  my $db1 = My::DBX->new;
  ok(!$db1->dbh->{RaiseError}, 'RaiseError false');
  
  my $db2 = My::DBX->new(raise_error => 1);
  ok($db2->dbh->{RaiseError}, 'RaiseError true');
  
  my $db3 = My::DBX->new;
  ok(!$db3->dbh->{RaiseError}, 'RaiseError false');
}
else
{
  SKIP: { skip('connect option tests that require DBD::SQLite', 3) }
}
