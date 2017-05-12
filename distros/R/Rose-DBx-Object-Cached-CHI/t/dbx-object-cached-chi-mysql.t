#!/usr/bin/perl -w

use strict;

use Test::More tests => 107;
$Rose::DBx::Object::Cached::CHI::USE_IN_SYNC = 1;

our($HAVE_MYSQL);

#
# Generic
#

foreach my $pair ((map { [ "2 $_", 2 ] } qw(s sec secs second seconds)),
                  (map { [ "2 $_", 2 * 60 ] } qw(m min mins minute minutes)),
                  (map { [ "2 $_", 2 * 60 * 60 ] } qw(h hr hrs hour hours)),
                  (map { [ "2 $_", 2 * 60 * 60 * 24 ] } qw(d day days)),
                  (map { [ "2 $_", 2 * 60 * 60 * 24 * 7 ] } qw(w wk wks week weeks)),
                  (map { [ "2 $_", 2 * 60 * 60 * 24 * 365 ] } qw(y yr yrs year years)))
{
  my($arg, $secs) = @$pair;
  MyCachedObject->meta->cached_objects_expire_in($arg);
  is(MyCachedObject->meta->cached_objects_expire_in, $secs, "cache_expires_in($arg) - generic");

  $arg =~ s/\s+//g;

  MyCachedObject->meta->cached_objects_expire_in($arg);
  is(MyCachedObject->meta->cached_objects_expire_in, $secs, "cache_expires_in($arg) - generic");
}

#
# MySQL
#

SKIP: foreach my $db_type ('mysql')
{
  skip("MySQL tests", 50)  unless($HAVE_MYSQL);

  Rose::DB->default_type($db_type);

  my $opk = MyMySQLObject->new(name => 'John', id => 199);

  $opk->remember_by_primary_key;

  $opk = MyMySQLObject->new(name => 'John');
  ok(!$opk->load(speculative => 1), "remember_by_primary_key() 1 - $db_type");

  $opk = MyMySQLObject->new(id => 199);
  ok($opk->load(speculative => 1), "remember_by_primary_key() 2 - $db_type");

  $opk->forget;

  my $of = MyMySQLObject->new(name => 'John');

  ok(ref $of && $of->isa('MyMySQLObject'), "cached new() 1 - $db_type");


  ok($of->save, 'save() 1');

  my $of2 = MyMySQLObject->new(id => $of->id);

  ok(ref $of2 && $of2->isa('MyMySQLObject'), "cached new() 2 - $db_type");

  ok($of2->load, "cached load() - $db_type");

  is($of2->name, $of->name, 'load() verify 1');

  my $of3 = MyMySQLObject->new(id => $of2->id);

  ok(ref $of3 && $of3->isa('MyMySQLObject'), "cached new() 3 - $db_type");

  ok($of3->load, "cached load() - $db_type");

  is($of3->name, $of2->name, "cached load() verify 2 - $db_type");

  ok($of3->is_cache_in_sync, "is_cache_in_sync verify 1 - $db_type");
  ok($of2->is_cache_in_sync, "is_cache_in_sync verify 2 - $db_type");
  ok($of->is_cache_in_sync, "is_cache_in_sync verify 3 - $db_type");


  my $ouk = MyMySQLObject->new(name => $of->name);

  ok($ouk->load, "cached load() unique key - $db_type");

  ok($ouk->is_cache_in_sync, "is_cache_in_sync verify 4 - $db_type");


  ok($of->forget, 'forget()');


  # Standard tests

  my $o = MyMySQLObject->new(name => 'John x');

  ok(ref $o && $o->isa('MyMySQLObject'), "new() 1 - $db_type");

  $o->flag2('true');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(22);

  ok($o->save, "save() 1 - $db_type");
  ok($o->load, "load() 1 - $db_type");

  my $o2 = MyMySQLObject->new(id => $o->id);

  ok(ref $o2 && $o2->isa('MyMySQLObject'), "new() 2 - $db_type");


  ok($o2->load, "load() 2 - $db_type");
  ok(!$o2->not_found, "not_found() 1 - $db_type");

  is($o2->name, $o->name, "load() verify 1 - $db_type");
  is($o2->date_created, $o->date_created, "load() verify 2 - $db_type");
  is($o2->last_modified, $o->last_modified, "load() verify 3 - $db_type");
  is($o2->status, 'active', "load() verify 4 (default value) - $db_type");
  is($o2->flag, 1, "load() verify 5 (default boolean value) - $db_type");
  is($o2->flag2, 1, "load() verify 6 (boolean value) - $db_type");
  is($o2->save_col, 22, "load() verify 7 (aliased column) - $db_type");
  is($o2->start->ymd, '1980-12-24', "load() verify 8 (date value) - $db_type");

  is($o2->start->ymd, '1980-12-24', "load() verify 8 (date value) - $db_type");
  $o2->bits(undef);

  $o2->name('John 2');
  $o2->start('5/24/2001');

  sleep(1); # keep the last modified dates from being the same

  $o2->last_modified('now');
  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");
 
  ok(!$o->is_cache_in_sync, "is_cache_in_sync verify 2 - $db_type");
  ok($o->load, "load() 4 - $db_type");

  is($o2->date_created, $o->date_created, "save() verify 1 - $db_type");
  ok($o2->last_modified eq $o->last_modified, "save() verify 2 - $db_type");
  is($o2->start->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");

  my $o3 = MyMySQLObject->new();

  my $db = $o3->db or die $o3->error;

  ok(ref $db && $db->isa('Rose::DB'), "db() - $db_type");

  is($db->dbh, $o3->dbh, "dbh() - $db_type");

  my $o4 = MyMySQLObject->new(id => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  ok($o->delete, "delete() - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, 'alias_column() nonesuch');

  $o = MyMySQLObject->new(name => 'John');

  ok($o->load, "load() forget 1 - $db_type");

  $o->forget;

  $o2 = MyMySQLObject->new(name => 'John');
  ok($o2->load, "load() forget 2 - $db_type");

  ok($o ne $o2, "load() forget 3 - $db_type");

  $o->meta->clear_object_cache;

  FORGET_ALL_MYSQL:
  {
    no warnings;
#Replace    is(scalar keys %MyMySQLObject::Objects_By_Id, 0, "clear_object_cache() 1 - $db_type");
#Replace    is(scalar keys %MyMySQLObject::Objects_By_Key, 0, "clear_object_cache() 2 - $db_type");
#Replace    is(scalar keys %MyMySQLObject::Objects_Keys, 0, "clear_object_cache() 3 - $db_type");
  }

  my $id = $o->id;

  # Cache expiration with primary key
  MyMySQLObject->meta->cached_objects_expire_in('5 seconds');
  $o = MyMySQLObject->new(id => $id);
  $o->load or die $o->error;

#Replace  my $loaded = $MyMySQLObject::Objects_By_Id_Loaded{$id};

#Replace  is($MyMySQLObject::Objects_By_Id_Loaded{$id}, $loaded, "cache_expires_in pk 1 - $db_type");
  $o->load or die $o->error;
#Replace  is($MyMySQLObject::Objects_By_Id_Loaded{$id}, $loaded, "cache_expires_in pk 2 - $db_type");
  sleep(5);
  $o->load or die $o->error;
#Replace  ok($MyMySQLObject::Objects_By_Id_Loaded{$id} != $loaded, "cache_expires_in pk 3 - $db_type");

  # Cache expiration with unique key
  MyMySQLObject->meta->cached_objects_expire_in('5 seconds');
  $o = MyMySQLObject->new(name => 'John');
  $o->load or die $o->error;

#Replace  $loaded = $MyMySQLObject::Objects_By_Key_Loaded{'name'}{'John'};

#Replace  is($MyMySQLObject::Objects_By_Key_Loaded{'name'}{'John'}, $loaded, "cache_expires_in uk 1 - $db_type");

  $o->load or die $o->error;
  my $o_created_at = $o->{__xrdbopriv_chi_created_at};
#Replace  is($MyMySQLObject::Objects_By_Key_Loaded{'name'}{'John'}, $loaded, "cache_expires_in uk 2 - $db_type");
  sleep(1);
  $o->load or die $o->error;
  my $o_created_at_check1 = $o->{__xrdbopriv_chi_created_at};
  ok($o_created_at_check1 == $o_created_at, "create_at() 1 - $db_type"); 

  sleep(5);
  $o->load or die $o->error;
  my $o_created_at_check2 = $o->{__xrdbopriv_chi_created_at};
  ok($o_created_at_check2 != $o_created_at, "create_at() 2 - $db_type");  
    
#Replace  ok($MyMySQLObject::Objects_By_Key_Loaded{'name'}{'John'} != $loaded, "cache_expires_in uk 3 - $db_type");
}


BEGIN
{

  require 't/test-lib.pl';
  use_ok('Rose::DBx::Object::Cached::CHI');


  #
  # Generic
  #

  GENERIC:
  {
    package MyCachedObject;
    our @ISA = qw(Rose::DBx::Object::Cached::CHI);
  }

  #
  # MySQL
  #

  my $db_version;

  my $dbh;

  eval
  {
    my $db = Rose::DB->new('mysql_admin');
    $dbh = $db->retain_dbh() or die Rose::DB->error;
    $db_version = $db->database_version;
  };

  if(!$@ && $dbh)
  {
    our $HAVE_MYSQL = 1;

    # Drop existing table and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rose_db_object_test');
    }

    # MySQL 5.0.3 or later has a completely stupid "native" BIT type
    my $bit_col = 
      ($db_version >= 5_000_003) ?
        q(bits  BIT(5) NOT NULL DEFAULT B'00101') :
        q(bits  BIT(5) NOT NULL DEFAULT '00101');

    $dbh->do(<<"EOF");
CREATE TABLE rose_db_object_test
(
  id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name           VARCHAR(32) NOT NULL,
  flag           TINYINT(1) NOT NULL,
  flag2          TINYINT(1),
  status         VARCHAR(32) DEFAULT 'active',
  $bit_col,
  start          DATE,
  save           INT,
  last_modified  TIMESTAMP NOT NULL,
  date_created   DATETIME,

  UNIQUE(name)
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyMySQLObject;

    our @ISA = qw(Rose::DBx::Object::Cached::CHI);

    sub init_db { Rose::DB->new('mysql') }

    MyMySQLObject->meta->allow_inline_column_values(1);

    MyMySQLObject->meta->table('rose_db_object_test');

    MyMySQLObject->meta->columns
    (
      'name',
      id       => { primary_key => 1 },
      flag     => { type => 'boolean', default => 1 },
      flag2    => { type => 'boolean' },
      status   => { default => 'active' },
      start    => { type => 'date', default => '12/24/1980' },
      save     => { type => 'scalar' },
      bits     => { type => 'bitfield', bits => 5, default => 101 },
      last_modified => { type => 'timestamp' },
      date_created  => { type => 'datetime' },
    );

    eval { MyMySQLObject->meta->initialize };
    Test::More::ok($@, 'meta->initialize() reserved method');

    MyMySQLObject->meta->add_unique_key('name');

    MyMySQLObject->meta->alias_column(save => 'save_col');
    MyMySQLObject->meta->initialize(preserve_existing => 1);

#Replace    Test::More::ok(MyMySQLObject->meta->method_name_is_reserved('remember', 'MyMySQLObject'), 'reserved method: remember');
#Replace    Test::More::ok(MyMySQLObject->meta->method_name_is_reserved('forget', 'MyMySQLObject'), 'reserved method: forget');
  }


}

END
{
  # Delete test table

  if($HAVE_MYSQL)
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rose_db_object_test');

    $dbh->disconnect;
  }

}

