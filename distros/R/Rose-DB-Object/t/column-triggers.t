#!/usr/bin/perl -w

use strict;

use Test::More tests => 284;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
  use_ok('Rose::DB::Object::Manager');
  use_ok('Rose::DateTime::Util');
}

use Rose::DateTime::Util qw(parse_date);

our(%Have, $Did_Setup, %Temp);

#
# Setup
#

SETUP:
{
  package MyObject;

  our @ISA = qw(Rose::DB::Object);

  MyObject->meta->table('Rose_db_object_test');

  MyObject->meta->columns
  (
    id       => { primary_key => 1, not_null => 1 },
    name     => { type => 'varchar', length => 32, on_set => sub { die "foo" },
                  on_get => [  sub { die "bar" }, sub { die "baz" } ] },
    code     => { type => 'varchar', length => 32 },
    start    => { type => 'date', default => '12/24/1980' },
    ended    => { type => 'scalar', default => '11/22/2003' },
    date_created => { type => 'timestamp' },
  );

  foreach my $column (MyObject->meta->columns)
  {
    $column->add_auto_method_types(qw(get set));
    $column->method_name('get' => 'xget_' . $column->name);
    $column->method_name('set' => 'xset_' . $column->name);
  }

  my $column = MyObject->meta->column('name');

  foreach my $event (qw(on_set on_get on_load on_save inflate deflate))
  {
    $column->add_trigger($event => sub { die "foo" })  unless($event eq 'on_set');

    unless($event eq 'on_get')
    {
      $column->add_trigger($event => sub { die "bar" });
      $column->add_trigger($event => sub { die "baz" });
    }
  }

  $column->delete_triggers('on_set');

  Test::More::ok(!defined $column->triggers('on_set'), 'delete_triggers 1');
  Test::More::ok(defined $column->triggers('on_get'), 'delete_triggers 2');

  $column->delete_triggers;

  my $i = 2;

  foreach my $event (qw(on_set on_get on_load on_save inflate deflate))
  {
    $i++;
    Test::More::ok(!defined $column->triggers($event), "delete_triggers $i");
  }

  # 0: die
  $column->add_trigger(event => 'on_get', 
                       name  => 'die',
                       code  => sub { die "blah" });

  # 1: die, dyn
  $column->add_trigger(event => 'on_get', 
                       code => sub { $Temp{'get'}{'name'} = shift->name });

  # XXX: This relies on knowledge of how generate_trigger_name() works
  my $dyn_name = "dyntrig_${$}_19"; 

  # 0: warn, die, dyn
  $column->add_trigger(event => 'on_get', 
                       name  => 'warn',
                       code  => sub { warn "boo" },
                       position => 'first');

  Test::More::is($column->trigger_index('on_get', 'warn'), 0, 'trigger_index 1');
  Test::More::is($column->trigger_index('on_get', 'die'), 1, 'trigger_index 2');
  Test::More::is($column->trigger_index('on_get', $dyn_name), 2, 'trigger_index 3');

  $column->delete_trigger(event => 'on_get',
                          name  => 'die');

  Test::More::is($column->trigger_index('on_get', 'warn'), 0, 'trigger_index 4');
  Test::More::is($column->trigger_index('on_get', $dyn_name), 1, 'trigger_index 5');

  $column->delete_trigger(event => 'on_get',
                          name  => 'warn');

  Test::More::is($column->trigger_index('on_get', $dyn_name), 0, 'trigger_index 6');

  my $indexes = $column->trigger_indexes('on_get');
  Test::More::is(keys %$indexes, 1, 'trigger_indexes 1');
  my $triggers = $column->triggers('on_get');
  Test::More::is(scalar @$triggers, 1, 'triggers 1');

  $column->add_trigger(event => 'on_set', 
                       code => sub { $Temp{'set'}{'name'} = shift->name });

  $column->add_trigger(on_load => sub { $Temp{'on_load'}{'name'} = shift->name });
  $column->add_trigger(on_save => sub { $Temp{'on_save'}{'name'} = shift->name });

  $column->add_trigger(inflate => sub {no warnings 'uninitialized';  $Temp{'inflate'}{'name'} = shift->name });
  $column->add_trigger(deflate => sub { no warnings 'uninitialized'; $Temp{'deflate'}{'name'} = uc $_[1] });

  $column = MyObject->meta->column('code');

  $column->add_trigger(inflate => sub { no warnings 'uninitialized'; lc $_[1] });
  $column->add_trigger(deflate => sub { no warnings 'uninitialized'; uc $_[1] });

  $column = MyObject->meta->column('start');

  $column->add_trigger(inflate => sub { ref $_[1] ? $_[1]->add(days => 1) : $_[1] });
  $column->add_trigger(deflate => sub 
  { 
    if(ref $_[1])
    {
      $_[1]->subtract(days => 1);
      return $_[0]->db->format_date($_[1]);
    }

    return $_[1];
  });

  $column->add_trigger(on_set => sub { shift->name('start set') });
  $column->add_trigger(on_get => sub { shift->name('start get') });

  $column = MyObject->meta->column('ended');

  $column->add_trigger(inflate => sub
  {
    # Handle older MySQL version of timestamp values
    if(defined $_[1])
    {
      $_[1] =~ s/^(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)$/$1-$2-$3 $2:$5:$6/;
    }

    defined $_[1] ? (Rose::DateTime::Util::parse_date($_[1]) || $_[0]->db->parse_date($_[1])) : undef 
  });

  $column->add_trigger(deflate => sub 
  {
    defined $_[1] ? $_[0]->db->format_date(Rose::DateTime::Util::parse_date($_[1]) || 
                                           $_[0]->db->parse_date($_[1])) : undef 
  });

  # Test built-in triggers

  # 0: die
  $column->add_builtin_trigger(event => 'on_get', 
                               name  => 'die',
                               code  => sub { die "blah" });

  # 1: die, dyn
  $column->add_builtin_trigger(event => 'on_get', 
                               code => sub { $Temp{'bi'}{'get'}{'name'} = shift->name });

  # This relies on knowledge of how generate_trigger_name() works
  $dyn_name = "dyntrig_${$}_33"; 

  # 0: warn, die, dyn
  $column->add_builtin_trigger(event => 'on_get', 
                               name  => 'warn',
                               code  => sub { warn "boo" },
                               position => 'first');

  Test::More::is($column->builtin_trigger_index('on_get', 'warn'), 0, 'builtin_trigger_index 1');
  Test::More::is($column->builtin_trigger_index('on_get', 'die'), 1, 'builtin_trigger_index 2');
  Test::More::is($column->builtin_trigger_index('on_get', $dyn_name), 2, 'builtin_trigger_index 3');

  $column->delete_builtin_trigger(event => 'on_get',
                                  name  => 'die');

  Test::More::is($column->builtin_trigger_index('on_get', 'warn'), 0, 'builtin_trigger_index 4');
  Test::More::is($column->builtin_trigger_index('on_get', $dyn_name), 1, 'builtin_trigger_index 5');

  $column->delete_builtin_trigger(event => 'on_get',
                                  name  => 'warn');

  Test::More::is($column->builtin_trigger_index('on_get', $dyn_name), 0, 'builtin_trigger_index 6');

  $indexes = $column->builtin_trigger_indexes('on_get');
  Test::More::is(keys %$indexes, 1, 'builtin_trigger_indexes 1');

  $triggers = $column->builtin_triggers('on_get');
  Test::More::is(scalar @$triggers, 1, 'builtin_triggers 1');

  $column->add_builtin_trigger(event => 'on_set', 
                       code => sub { $Temp{'bi'}{'set'}{'name'} = shift->name });

  $column->add_builtin_trigger(on_load => sub { $Temp{'bi'}{'on_load'}{'name'} = shift->name });
  $column->add_builtin_trigger(on_save => sub { $Temp{'bi'}{'on_save'}{'name'} = shift->name });

  $column->add_builtin_trigger(inflate => sub { $Temp{'bi'}{'inflate'}{'name'} = shift->name });
  $column->add_builtin_trigger(deflate => sub { $Temp{'bi'}{'deflate'}{'name'} = uc $_[1] });

  $column->delete_builtin_triggers;

  $i = 0;

  foreach my $event (qw(on_set on_get on_load on_save inflate deflate))
  {
    $i++;
    $indexes = $column->builtin_trigger_indexes($event);
    Test::More::is(keys %$indexes, 0, "delete_builtin_triggers $i");

    $i++;
    $triggers = $column->builtin_triggers($event);
    Test::More::ok(!defined $triggers, "delete_builtin_triggers $i");
  }
}

#
# Tests
#

my @dbs = qw(mysql pg pg_with_schema informix sqlite);
eval { require List::Util };
@dbs = List::Util::shuffle(@dbs)  unless($@);
#@dbs = qw(informix sqlite mysql pg_with_schema  pg);

foreach my $db_type (@dbs)
{
  SKIP:
  {
    skip("$db_type tests", 49)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  Rose::DB->default_type($db_type);

  unless($Did_Setup++)
  {
    MyObject->meta->initialize;
  }

  ##
  ## Run tests
  ##

  %Temp = ();

  #
  # name
  #

  my $o = MyObject->new;

  is($o->name('Fred'), 'Fred', "on_set return 1 - $db_type");
  is($Temp{'set'}{'name'}, 'Fred', "on_set 1 - $db_type");
  is(keys %Temp, 1, "on_set 2 - $db_type");
  %Temp = ();

  is($o->xset_name('Fred'), 'Fred', "on_set return 2 - $db_type");
  is($Temp{'set'}{'name'}, 'Fred', "on_set 3 - $db_type");
  is(keys %Temp, 1, "on_set 4 - $db_type");
  %Temp = ();

  my $name = $o->xget_name;
  is($Temp{'get'}{'name'}, 'Fred', "on_get 1 - $db_type");
  is($Temp{'inflate'}{'name'}, 'Fred', "on_get 2 - $db_type");
  is(keys %Temp, 2, "on_get 3 - $db_type");
  %Temp = ();

  $name = $o->name;
  is($Temp{'get'}{'name'}, 'Fred', "on_get 4 - $db_type");
  is(keys %Temp, 1, "on_get 5 - $db_type");
  %Temp = ();

  $name = $o->xget_name;
  is($Temp{'get'}{'name'}, 'Fred', "on_get 6 - $db_type");
  is(keys %Temp, 1, "on_get 7 - $db_type");
  %Temp = ();

  #local $Rose::DB::Object::Debug = 1;

  $o->save;
  is($Temp{'on_save'}{'name'}, 'FRED', "on_save 1 - $db_type");
  is($Temp{'deflate'}{'name'}, 'FRED', "on_save 2 - $db_type");
  is(keys %Temp, 2, "on_save 3 - $db_type");
  %Temp = ();

  $o->load;
  is($Temp{'on_load'}{'name'}, 'FRED', "on_load 1 - $db_type");
  is(keys %Temp, 1, "on_load 2 - $db_type");
  %Temp = ();

  is($o->name, 'FRED', "deflate 1 - $db_type");
  is($Temp{'get'}{'name'}, 'FRED', "on_get 8 - $db_type");
  is($Temp{'inflate'}{'name'}, 'FRED', "on_get 9 - $db_type");
  is(keys %Temp, 2, "on_get 10 - $db_type");
  %Temp = ();

  $o->name('Fred');
  is($Temp{'set'}{'name'}, 'Fred', "on_set 5 - $db_type");
  is(keys %Temp, 1, "on_set 6 - $db_type");
  %Temp = ();

  MyObject->meta->column('name')->add_trigger(
    event => 'inflate',
    name  => 'lc_inflate',
    code  => sub { $Temp{'lc_inflate'}{'name'} = lc shift->name });

  is($o->name, 'fred', "inflate 1 - $db_type");
  is($Temp{'get'}{'name'}, 'fred', "inflate 2 - $db_type");
  is($Temp{'inflate'}{'name'}, 'Fred', "inflate 3 - $db_type");
  is($Temp{'lc_inflate'}{'name'}, 'fred', "inflate 4 - $db_type");
  is(keys %Temp, 3, "inflate 5 - $db_type");
  %Temp = ();

  $o = MyObject->new();
  $o->meta->add_unique_keys('name');
  $o->name('FRED');
  $o->load(speculative => 1);
  isnt($Temp{'on_save'}{'name'}, 'FRED', "on_load/on_save mix - $db_type");

  #
  # code
  #

  $o = MyObject->new(name => 'foo', code => 'Abc');

  is($o->code, 'abc', "inflate/deflate 1 - $db_type");

  $o->save;

  my $sth = $o->db->dbh->prepare(
    'SELECT code FROM ' . $o->meta->fq_table_sql($o->db) . ' WHERE id = ?');

  $sth->execute($o->id);
  my $code = $sth->fetchrow_array;
  $sth->finish;

  is($code, 'ABC', "inflate/deflate 2 - $db_type");

  is($o->code, 'abc', "inflate/deflate 3 - $db_type");
  is($o->xget_code, 'abc', "inflate/deflate 4 - $db_type");

  #
  # start
  #

  $o->start('2002-10-20');
  is($o->name, 'start set',  "start 1 - $db_type");

  $o->save;

  is($o->name, 'start set',  "start 2 - $db_type");

  $sth = $o->db->dbh->prepare(
    'SELECT start FROM ' . $o->meta->fq_table_sql($o->db) . ' WHERE id = ?');

  $sth->execute($o->id);
  my $start = $sth->fetchrow_array;
  $sth->finish;

  $start = parse_date($start);

  is($start->ymd, '2002-10-19', "start 3 - $db_type");

  is($o->start->ymd, '2002-10-20', "start 4 - $db_type");
  is($o->name, 'start get',  "start 5 - $db_type");

  $o->load;

  is($o->start->ymd, '2002-10-20', "start 6 - $db_type");

  $start = $o->start(truncate => 'month');
  is($start->ymd, '2002-10-01', "start 7 - $db_type");

  $start = $o->start(format => '%B %E %Y');
  is($start, 'October 20th 2002', "start 8 - $db_type");

  #
  # ended
  #

  $o = MyObject->new;

  is($o->ended->ymd, '2003-11-22', "ended 1 - $db_type");
  $o->ended('1999-09-10');

  is($o->ended->ymd, '1999-09-10', "ended 2 - $db_type");

  $o->save;

  $o = MyObject->new(id => $o->id);
  $o->load;

  is($o->ended->ymd, '1999-09-10', "ended 3 - $db_type");

  $o->ended('2/3/2004');
  is($o->ended->ymd, '2004-02-03', "ended 4 - $db_type");

  $o->ended(DateTime->new(year => 1980, month => 5, day => 20));
  is($o->ended->ymd, '1980-05-20', "ended 5 - $db_type");

  $o->meta->column('ended')->disable_triggers;
  $o->ended('2/13/2004');
  is($o->ended, '2/13/2004', "disable_triggers - $db_type");

  $o->meta->column('ended')->enable_triggers;
  $o->ended('2/3/2003');
  is($o->ended->ymd, '2003-02-03', "enable_triggers - $db_type");

  #
  # Clean-up
  #

  MyObject->meta->column('name')->delete_trigger(event => 'inflate',
                                                 name  => 'lc_inflate');
}

BEGIN
{
  our %Have;

  #
  # PostgreSQL
  #

  my $dbh;

  eval 
  {
    $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;
  };

  if(!$@ && $dbh)
  {
    $Have{'pg'} = 1;
    $Have{'pg_with_schema'} = 1;

    # Drop existing tables and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE Rose_db_object_test CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_test CASCADE');
      $dbh->do('DROP SCHEMA Rose_db_object_private CASCADE');
      $dbh->do('CREATE SCHEMA Rose_db_object_private');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test
(
  id             SERIAL NOT NULL PRIMARY KEY,
  name           VARCHAR(32) NOT NULL,
  code           VARCHAR(32),
  start          DATE NOT NULL DEFAULT '1980-12-24',
  ended          TIMESTAMP,
  date_created   TIMESTAMP
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.Rose_db_object_test
(
  id             SERIAL NOT NULL PRIMARY KEY,
  name           VARCHAR(32) NOT NULL,
  code           VARCHAR(32),
  start          DATE NOT NULL DEFAULT '1980-12-24',
  ended          TIMESTAMP,
  date_created   TIMESTAMP
)
EOF

    $dbh->disconnect;
  }

  #
  # MySQL
  #

  eval 
  {
    my $db = Rose::DB->new('mysql_admin');
    $dbh = $db->retain_dbh or die Rose::DB->error;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE Rose_db_object_test CASCADE');
    }
  };

  if(!$@ && $dbh)
  {
    $Have{'mysql'} = 1;

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test
(
  id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name           VARCHAR(32) NOT NULL,
  code           VARCHAR(32),
  start          DATE NOT NULL DEFAULT '1980-12-24',
  ended          TIMESTAMP,
  date_created   TIMESTAMP
)
EOF

    $dbh->disconnect;
  }

  #
  # Informix
  #

  eval
  {
    $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;
  };

  if(!$@ && $dbh)
  {
    $Have{'informix'} = 1;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE Rose_db_object_test CASCADE');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test
(
  id             SERIAL NOT NULL PRIMARY KEY,
  name           VARCHAR(32) NOT NULL,
  code           VARCHAR(32),
  start          DATE DEFAULT '12/24/1980' NOT NULL,
  ended          DATE,
  date_created   DATETIME YEAR TO SECOND
)
EOF

    $dbh->disconnect;
  }

  #
  # SQLite
  #

  eval
  {
    $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;
  };

  if(!$@ && $dbh)
  {
    $Have{'sqlite'} = 1;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE Rose_db_object_test');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test
(
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  name           VARCHAR(32) NOT NULL,
  code           VARCHAR(32),
  start          DATE DEFAULT '1980-12-24' NOT NULL,
  ended          DATE,
  date_created   DATETIME
)
EOF

    $dbh->disconnect;
  }
}

END
{
  # Delete test table

  if($Have{'pg'})
  {
    # PostgreSQL
    my $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_test CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_test CASCADE');
    $dbh->do('DROP SCHEMA Rose_db_object_private CASCADE');

    $dbh->disconnect;
  }

  if($Have{'mysql'})
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_test CASCADE');

    $dbh->disconnect;
  }

  if($Have{'informix'})
  {
    # Informix
    my $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_test CASCADE');

    $dbh->disconnect;
  }

  if($Have{'sqlite'})
  {
    # Informix
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_test');

    $dbh->disconnect;
  }
}
