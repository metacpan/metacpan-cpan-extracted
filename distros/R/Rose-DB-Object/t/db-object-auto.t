#!/usr/bin/perl -w

use strict;

use Test::More tests => 275;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
  use_ok('Rose::DB::Object::Metadata::Auto::Generic');
}

our($PG_HAS_CHKPASS, $HAVE_PG, $HAVE_MYSQL, $HAVE_INFORMIX);

#
# PostgreSQL
#

SKIP: foreach my $db_type (qw(pg pg_with_schema))
{
  skip("PostgreSQL tests", 140)  unless($HAVE_PG);

  OVERRIDE_OK:
  {
    no warnings;
    *MyPgObject::init_db = sub {  Rose::DB->new($db_type) };
  }

  my $o = MyPgObject->new(name => 'John', 
                          k1   => 1,
                          k2   => undef,
                          k3   => 3);

  ok(ref $o && $o->isa('MyPgObject'), "new() 1 - $db_type");

  $o->flag2('TRUE');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(7);

  $o->dp(37.3960614524039);
  $o->f8(37.3960614524039);

  ok($o->save, "save() 1 - $db_type");

  is($o->id, 1, "auto-generated primary key - $db_type");

  ok($o->load, "load() 1 - $db_type");

  eval { $o->name('C' x 50) };
  ok($@, "varchar overflow fatal - $db_type");

  $o->name('John');

  $o->code('A');
  is($o->code, 'A     ', "character padding - $db_type");

  eval { $o->code('C' x 50) };
  ok($@, "character overflow fatal - $db_type");
  $o->code('C' x 6);

  my $ouk = MyPgObject->new(k1 => 1,
                            k2 => undef,
                            k3 => 3);

  ok($ouk->load, "load() uk 1 - $db_type");
  ok(!$ouk->not_found, "not_found() uk 1 - $db_type");

  is($ouk->id, 1, "load() uk 2 - $db_type");
  is($ouk->name, 'John', "load() uk 3 - $db_type");

  ok($ouk->save, "save() uk 1 - $db_type");

  my $o2 = MyPgObject->new(id => $o->id);

  ok(ref $o2 && $o2->isa('MyPgObject'), "new() 2 - $db_type");

  is($o2->bits->to_Bin, '00101', "bits() (bitfield default value) - $db_type");

  ok($o2->load, "load() 2 - $db_type");
  ok(!$o2->not_found, "not_found() 1 - $db_type");

  is($o2->name, $o->name, "load() verify 1 - $db_type");
  is($o2->date_created, $o->date_created, "load() verify 2 - $db_type");
  is($o2->last_modified, $o->last_modified, "load() verify 3 - $db_type");
  is($o2->status, "act'ive", "load() verify 4 (default value) - $db_type");
  is($o2->flag, 1, "load() verify 5 (default boolean value) - $db_type");
  is($o2->flag2, 1, "load() verify 6 (boolean value) - $db_type");
  is($o2->save_col, 7, "load() verify 7 (aliased column) - $db_type");
  is($o2->start->ymd, '1980-12-24', "load() verify 8 (date value) - $db_type");

  is($o2->bits->to_Bin, '00101', "load() verify 9 (bitfield value) - $db_type");

  my $clone = $o2->clone;
  ok($o2->start eq $clone->start, "clone() 1 - $db_type");
  $clone->start->set(year => '1960');
  ok($o2->start ne $clone->start, "clone() 2 - $db_type");

  $o2->name('John 2');
  $o2->start('5/24/2001');

  sleep(1); # keep the last modified dates from being the same

  $o2->last_modified('now');
  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");

  is($o2->date_created, $o->date_created, "save() verify 1 - $db_type");
  ok($o2->last_modified ne $o->last_modified, "save() verify 2 - $db_type");
  is($o2->start->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");

  my $o3 = MyPgObject->new();

  my $db = $o3->db or die $o3->error;

  ok(ref $db && $db->isa('Rose::DB'), "db() - $db_type");

  is($db->dbh, $o3->dbh, "dbh() - $db_type");

  my $o4 = MyPgObject->new(id => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  ok($o->load, "load() 4 - $db_type");

  SKIP:
  {
    if($PG_HAS_CHKPASS)
    {
      $o->{'password_encrypted'} = ':8R1Kf2nOS0bRE';

      ok($o->password_is('xyzzy'), "chkpass() 1 - $db_type");
      is($o->password, 'xyzzy', "chkpass() 2 - $db_type");

      $o->password('foobar');

      ok($o->password_is('foobar'), "chkpass() 3 - $db_type");
      is($o->password, 'foobar', "chkpass() 4 - $db_type");

      ok($o->save, "save() 3 - $db_type");
    }
    else
    {
      skip("chkpass tests", 5);
    }
  }

  my $o5 = MyPgObject->new(id => $o->id);

  ok($o5->load, "load() 5 - $db_type");

  SKIP:
  {
    if($PG_HAS_CHKPASS)
    {
      ok($o5->password_is('foobar'), "chkpass() 5 - $db_type");
      is($o5->password, 'foobar', "chkpass() 6 - $db_type"); 
    }
    else
    {
      skip("chkpass tests", 2);
    }
  }

  $o5->nums([ 4, 5, 6 ]);
  ok($o5->save, "save() 4 - $db_type");
  ok($o->load, "load() 6 - $db_type");

  is($o5->nums->[0], 4, "load() verify 10 (array value) - $db_type");
  is($o5->nums->[1], 5, "load() verify 11 (array value) - $db_type");
  is($o5->nums->[2], 6, "load() verify 12 (array value) - $db_type");

  my @a = $o5->nums;

  is($a[0], 4, "load() verify 13 (array value) - $db_type");
  is($a[1], 5, "load() verify 14 (array value) - $db_type");
  is($a[2], 6, "load() verify 15 (array value) - $db_type");
  is(@a, 3, "load() verify 16 (array value) - $db_type");

  ok($o->delete, "delete() - $db_type");

  $o = MyPgObject->new(name => 'John', id => 9);
  $o->save_col(22);
  ok($o->save, "save() 4 - $db_type");
  $o->save_col(50);
  ok($o->save, "save() 5 - $db_type");

  $ouk = MyPgObject->new(save_col => 50);
  ok($ouk->load, "load() aliased unique key - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, "alias_column() nonesuch - $db_type");

  # This is okay now
  #eval { $o->meta->alias_column(id => 'foo') };
  #ok($@, "alias_column() primary key - $db_type");

  $o = MyPgObject->new(id => 777);

  $o->meta->error_mode('fatal');

  $o->dbh->{'PrintError'} = 0;

  eval { $o->load };
  ok($@ && $o->not_found, "load() not found fatal - $db_type");

  $o->id('abc');

  eval { $o->load };
  ok($@ && !$o->not_found, "load() fatal - $db_type");

  eval { $o->save };
  ok($@, "save() fatal - $db_type");

  $o->meta->error_mode('return');

  #
  # Test code generation
  #

  my $chkpass = $PG_HAS_CHKPASS ? "  password      => { type => 'chkpass' },\n" : '';

  is(MyPgObject->meta->perl_columns_definition(braces => 'bsd', indent => 2),
     <<"EOF", "perl_columns_definition 1 - $db_type");
__PACKAGE__->meta->columns
(
  id            => { type => 'integer', not_null => 1, sequence => 'rose_db_object_test_seq' },
  k1            => { type => 'integer' },
  k2            => { type => 'integer' },
  k3            => { type => 'integer' },
$chkpass  name          => { type => 'varchar', length => 32, not_null => 1 },
  code          => { type => 'character', length => 6 },
  flag          => { type => 'boolean', default => 'true', not_null => 1 },
  flag2         => { type => 'boolean' },
  status        => { type => 'varchar', default => 'act\\'ive', length => 32 },
  bits          => { type => 'bitfield', bits => 5, default => '00101', not_null => 1 },
  start         => { type => 'date', default => '1980-12-24' },
  save          => { type => 'integer', alias => 'save_col' },
  nums          => { type => 'array' },
  dp            => { type => 'double precision' },
  f8            => { type => 'double precision' },
  last_modified => { type => 'timestamp' },
  date_created  => { type => 'timestamp' },
);
EOF

  $chkpass = $PG_HAS_CHKPASS ? "    password      => { type => 'chkpass' },\n" : '';

  is(MyPgObject->meta->perl_columns_definition(braces => 'k&r', indent => 4),
     <<"EOF", "perl_columns_definition 2 - $db_type");
__PACKAGE__->meta->columns(
    id            => { type => 'integer', not_null => 1, sequence => 'rose_db_object_test_seq' },
    k1            => { type => 'integer' },
    k2            => { type => 'integer' },
    k3            => { type => 'integer' },
$chkpass    name          => { type => 'varchar', length => 32, not_null => 1 },
    code          => { type => 'character', length => 6 },
    flag          => { type => 'boolean', default => 'true', not_null => 1 },
    flag2         => { type => 'boolean' },
    status        => { type => 'varchar', default => 'act\\'ive', length => 32 },
    bits          => { type => 'bitfield', bits => 5, default => '00101', not_null => 1 },
    start         => { type => 'date', default => '1980-12-24' },
    save          => { type => 'integer', alias => 'save_col' },
    nums          => { type => 'array' },
    dp            => { type => 'double precision' },
    f8            => { type => 'double precision' },
    last_modified => { type => 'timestamp' },
    date_created  => { type => 'timestamp' },
);
EOF

  $chkpass = $PG_HAS_CHKPASS ? "    password      => { type => 'chkpass' },\n" : '';

  is(MyPgObject->meta->perl_columns_definition,
     <<"EOF", "perl_columns_definition 3 - $db_type");
__PACKAGE__->meta->columns(
    id            => { type => 'integer', not_null => 1, sequence => 'rose_db_object_test_seq' },
    k1            => { type => 'integer' },
    k2            => { type => 'integer' },
    k3            => { type => 'integer' },
$chkpass    name          => { type => 'varchar', length => 32, not_null => 1 },
    code          => { type => 'character', length => 6 },
    flag          => { type => 'boolean', default => 'true', not_null => 1 },
    flag2         => { type => 'boolean' },
    status        => { type => 'varchar', default => 'act\\'ive', length => 32 },
    bits          => { type => 'bitfield', bits => 5, default => '00101', not_null => 1 },
    start         => { type => 'date', default => '1980-12-24' },
    save          => { type => 'integer', alias => 'save_col' },
    nums          => { type => 'array' },
    dp            => { type => 'double precision' },
    f8            => { type => 'double precision' },
    last_modified => { type => 'timestamp' },
    date_created  => { type => 'timestamp' },
);
EOF

  is(MyPgObject->meta->perl_unique_keys_definition,
     <<'EOF', "perl_unique_keys_definition 1 - $db_type");
__PACKAGE__->meta->unique_keys(
    [ 'k1', 'k2', 'k3' ],
    [ 'save' ],
);
EOF

  my($v1, $v2, $v3) = split(/\./, $DBD::Pg::VERSION);

  if(($v1 >= 2 && $v2 >= 19) || $v1 > 2)
  {
    is(MyPgObject->meta->perl_unique_keys_definition(style => 'object', braces => 'bsd', indent => 2),
      <<'EOF', "perl_unique_keys_definition 2 - $db_type");
__PACKAGE__->meta->unique_keys
(
  Rose::DB::Object::Metadata::UniqueKey->new(name => 'rose_db_object_test_k1_k2_k3_key', columns => [ 'k1', 'k2', 'k3' ]),
  Rose::DB::Object::Metadata::UniqueKey->new(name => 'rose_db_object_test_save_key', columns => [ 'save' ]),
);
EOF
  }
  else
  {
    is(MyPgObject->meta->perl_unique_keys_definition(style => 'object', braces => 'bsd', indent => 2),
      <<'EOF', "perl_unique_keys_definition 2 - $db_type");
__PACKAGE__->meta->unique_keys
(
  Rose::DB::Object::Metadata::UniqueKey->new(name => 'rose_db_object_test_k1_key', columns => [ 'k1', 'k2', 'k3' ]),
  Rose::DB::Object::Metadata::UniqueKey->new(name => 'rose_db_object_test_save_key', columns => [ 'save' ]),
);
EOF
  }

  is(MyPgObject->meta->perl_primary_key_columns_definition,
     qq(__PACKAGE__->meta->primary_key_columns([ 'id' ]);\n),
     "perl_primary_key_columns_definition - $db_type");
}

#
# MySQL
#

SKIP: foreach my $db_type ('mysql')
{
  skip("MySQL tests", 67)  unless($HAVE_MYSQL);

  Rose::DB->default_type($db_type);

  my $o = MyMySQLObject->new(name => 'John',
                             k1   => 1,
                             k2   => undef,
                             k3   => 3);

  ok(ref $o && $o->isa('MyMySQLObject'), "new() 1 - $db_type");

  $o->flag2('true');
  $o->date_created('now');
  $o->last_modified($o->date_created);
  $o->save_col(22);

  ok($o->save, "save() 1 - $db_type");
  ok($o->load, "load() 1 - $db_type");

  is(ref $o->dt_default, 'DateTime', "now() default - $db_type");

  eval { $o->name('C' x 50) };
  ok($@, "varchar overflow fatal - $db_type");

  $o->name('John');

  $o->code('A');
  is($o->code, 'A     ', "character padding - $db_type");

  eval { $o->code('C' x 50) };
  ok($@, "character overflow fatal - $db_type");
  $o->code('C' x 6);

  is($o->enums, 'foo', "enum 1 - $db_type");
  eval { $o->enums('blee') };
  ok($@, "enum 2 - $db_type");

  $o->enums('bar');

  my $ouk = MyMySQLObject->new(k1 => 1,
                               k2 => undef,
                               k3 => 3);

  ok($ouk->load, "load() uk 1 - $db_type");
  ok(!$ouk->not_found, "not_found() uk 1 - $db_type");

  is($ouk->id, 1, "load() uk 2 - $db_type");
  is($ouk->name, 'John', "load() uk 3 - $db_type");

  ok($ouk->save, "save() uk 1 - $db_type");

  my $o2 = MyMySQLObject->new(id => $o->id);

  ok(ref $o2 && $o2->isa('MyMySQLObject'), "new() 2 - $db_type");

  is($o2->bits->to_Bin, '00101', "bits() (bitfield default value) - $db_type");

  ok($o2->load, "load() 2 - $db_type");
  ok(!$o2->not_found, "not_found() 1 - $db_type");

  is($o2->name, $o->name, "load() verify 1 - $db_type");
  is($o2->date_created, $o->date_created, "load() verify 2 - $db_type");
  is($o2->last_modified, $o->last_modified, "load() verify 3 - $db_type");
  is($o2->status, "act'ive", "load() verify 4 (default value) - $db_type");
  is($o2->flag, 1, "load() verify 5 (default boolean value) - $db_type");
  is($o2->flag2, 1, "load() verify 6 (boolean value) - $db_type");
  is($o2->save_col, 22, "load() verify 7 (aliased column) - $db_type");
  is($o2->start->ymd, '1980-12-24', "load() verify 8 (date value) - $db_type");

  is($o2->bits->to_Bin, '00101', "load() verify 9 (bitfield value) - $db_type");

  my $clone = $o2->clone;
  ok($o2->start eq $clone->start, "clone() 1 - $db_type");
  $clone->start->set(year => '1960');
  ok($o2->start ne $clone->start, "clone() 2 - $db_type");

  $o2->name('John 2');
  $o2->start('5/24/2001');

  sleep(1); # keep the last modified dates from being the same

  $o2->last_modified('now');
  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");

  is($o2->date_created, $o->date_created, "save() verify 1 - $db_type");
  ok($o2->last_modified ne $o->last_modified, "save() verify 2 - $db_type");
  is($o2->start->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");

  my $o3 = MyMySQLObject->new();

  my $db = $o3->db or die $o3->error;

  ok(ref $db && $db->isa('Rose::DB'), "db() - $db_type");

  is($db->dbh, $o3->dbh, "dbh() - $db_type");

  my $o4 = MyMySQLObject->new(id => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  $o->nums([ 4, 5, 6, 'aaa', '"\\"' ]);

  ok($o->save, "save() 3 - $db_type");
  ok($o->load, "load() 4 - $db_type");

  is($o->nums->[0], 4, "load() verify 10 (array value) - $db_type");
  is($o->nums->[1], 5, "load() verify 11 (array value) - $db_type");
  is($o->nums->[2], 6, "load() verify 12 (array value) - $db_type");
  is($o->nums->[3], 'aaa', "load() verify (string in array value) - $db_type");
  is($o->nums->[4], '"\\"', "load() verify (escapes in array value) - $db_type");

  my @a = $o->nums;

  is($a[0], 4, "load() verify 13 (array value) - $db_type");
  is($a[1], 5, "load() verify 14 (array value) - $db_type");
  is($a[2], 6, "load() verify 15 (array value) - $db_type");
  is(@a, 5, "load() verify 16 (array value) - $db_type");

  ok($o->delete, "delete() - $db_type");

  $o = MyMySQLObject->new(name => 'John', id => 9);
  $o->save_col(22);

  ok($o->save, "save() 4 - $db_type");
  $o->save_col(50);
  ok($o->save, "save() 5 - $db_type");

  $ouk = MyMySQLObject->new(save_col => 50);
  ok($ouk->load, "load() aliased unique key - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, "alias_column() nonesuch - $db_type");

  # This is okay now
  #eval { $o->meta->alias_column(id => 'foo') };
  #ok($@, "alias_column() primary key - $db_type");

  $o = MyMySQLObject->new(id => 777);

  $o->meta->error_mode('fatal');

  $o->dbh->{'PrintError'} = 0;

  eval { $o->load };
  ok($@ && $o->not_found, "load() not found fatal - $db_type");

  my $old_table = $o->meta->table;
  $o->meta->table('nonesuch');

  eval { $o->load };
  ok($@ && !$o->not_found, "load() fatal - $db_type");

  eval { $o->save };
  ok($@, "save() fatal - $db_type");

  $o->meta->table($old_table);  
  $o->meta->error_mode('return');

  $o = MyMPKMySQLObject->new(name => 'John');

  ok($o->save, "save() 1 multi-value primary key with generated values - $db_type");

  is($o->k1, 1, "save() verify 1 multi-value primary key with generated values - $db_type");
  is($o->k2, 2, "save() verify 2 multi-value primary key with generated values - $db_type");

  $o = MyMPKMySQLObject->new(name => 'Alex');

  ok($o->save, "save() 2 multi-value primary key with generated values - $db_type");

  is($o->k1, 3, "save() verify 3 multi-value primary key with generated values - $db_type");
  is($o->k2, 4, "save() verify 4 multi-value primary key with generated values - $db_type");

  $o = MyMySQLObject->new;
  is($o->enums, 'foo', "enum undef 1 - $db_type");

  $o->meta->column('enums')->default(undef);  
  $o->meta->make_column_methods(replace_existing => 1);

  $o->enums(undef);
  is($o->enums, undef, "enum undef 2 - $db_type");
}

#
# Informix
#

SKIP: foreach my $db_type ('informix')
{
  skip("Informix tests", 66)  unless($HAVE_INFORMIX);

  Rose::DB->default_type($db_type);

  my $o = MyInformixObject->new(name => 'John', 
                                id   => 1,
                                k1   => 1,
                                k2   => undef,
                                k3   => 3);

  ok(ref $o && $o->isa('MyInformixObject'), "new() 1 - $db_type");

  $o->meta->allow_inline_column_values(1);

  $o->flag2('true');
  $o->date_created('current year to fraction(5)');
  $o->last_modified($o->date_created);
  $o->save_col(22);

  my $dt = DateTime->now(time_zone => 'floating');
  $dt->set_nanosecond(123456789);

  $o->frac($dt->clone);
  $o->frac1($dt->clone);
  $o->frac2($dt->clone);
  $o->frac3($dt->clone);
  $o->frac4($dt->clone);
  $o->frac5($dt->clone);

  ok($o->save, "save() 1 - $db_type");
  ok($o->load, "load() 1 - $db_type");

  $o->htmin('8:01:12pm');
  $o->htsec('5:56:55.1234am');
  $o->htfr1('13:45:56.59999');
  $o->htfr5('01:02:03.123456');

  $o->save;
  $o->load;

  is($o->htmin, '20:01:00', "datetime hour to minute - $db_type");
  is($o->htsec, '05:56:55', "datetime hour to second - $db_type");
  is($o->htfr1, '13:45:56.5', "datetime hour to fraction(1) - $db_type");
  is($o->htfr5, '01:02:03.12345', "datetime hour to fraction(5) - $db_type");

  is(ref $o->other_date, 'DateTime', 'other_date 1');
  is(ref $o->other_datetime, 'DateTime', 'other_datetime 1');

  eval { $o->name('C' x 50) };
  ok($@, "varchar overflow fatal - $db_type");

  $o->name('John');

  $o->code('A');
  is($o->code, 'A     ', "character padding - $db_type");

  eval { $o->code('C' x 50) };
  ok($@, "character overflow fatal - $db_type");
  $o->code('C' x 6);

  my $ouk = MyInformixObject->new(k1 => 1,
                                  k2 => undef,
                                  k3 => 3);

  ok($ouk->load, "load() uk 1 - $db_type");
  ok(!$ouk->not_found, "not_found() uk 1 - $db_type");

  is($ouk->id, 1, "load() uk 2 - $db_type");
  is($ouk->name, 'John', "load() uk 3 - $db_type");

  ok($ouk->save, "save() uk 1 - $db_type");

  my $o2 = MyInformixObject->new(id => $o->id);

  ok(ref $o2 && $o2->isa('MyInformixObject'), "new() 2 - $db_type");

  is($o2->bits->to_Bin, '00101', "bits() (bitfield default value) - $db_type");

  ok($o2->load, "load() 2 - $db_type");
  ok(!$o2->not_found, "not_found() 1 - $db_type");

  is($o2->name, $o->name, "load() verify 1 - $db_type");
  is($o2->date_created, $o->date_created, "load() verify 2 - $db_type");
  is($o2->last_modified, $o->last_modified, "load() verify 3 - $db_type");
  is($o2->status, "act'ive", "load() verify 4 (default value) - $db_type");
  is($o2->flag, 1, "load() verify 5 (default boolean value) - $db_type");
  is($o2->flag2, 1, "load() verify 6 (boolean value) - $db_type");
  is($o2->save_col, 22, "load() verify 7 (aliased column) - $db_type");
  is($o2->start->ymd, '1980-12-24', "load() verify 8 (date value) - $db_type");

  is($o2->bits->to_Bin, '00101', "load() verify 9 (bitfield value) - $db_type");

  my $clone = $o2->clone;
  ok($o2->start eq $clone->start, "clone() 1 - $db_type");
  $clone->start->set(year => '1960');
  ok($o2->start ne $clone->start, "clone() 2 - $db_type");

  $o2->name('John 2');
  $o2->start('5/24/2001');

  sleep(1); # keep the last modified dates from being the same

  $o2->last_modified('current year to second');
  ok($o2->save, "save() 2 - $db_type");
  ok($o2->load, "load() 3 - $db_type");

  is($o2->date_created, $o->date_created, "save() verify 1 - $db_type");
  ok($o2->last_modified ne $o->last_modified, "save() verify 2 - $db_type");
  is($o2->start->ymd, '2001-05-24', "save() verify 3 (date value) - $db_type");

  my $o3 = MyInformixObject->new();

  my $db = $o3->db or die $o3->error;

  ok(ref $db && $db->isa('Rose::DB'), "db() - $db_type");

  is($db->dbh, $o3->dbh, "dbh() - $db_type");

  my $o4 = MyInformixObject->new(id => 999);
  ok(!$o4->load(speculative => 1), "load() nonexistent - $db_type");
  ok($o4->not_found, "not_found() 2 - $db_type");

  $o->nums([ 4, 5, 6 ]);
  $o->names([ qw(a b 3.1) ]);

  ok($o->save, "save() 3 - $db_type");
  ok($o->load, "load() 4 - $db_type");

  is($o->nums->[0], 4, "load() verify 10 (array value) - $db_type");
  is($o->nums->[1], 5, "load() verify 11 (array value) - $db_type");
  is($o->nums->[2], 6, "load() verify 12 (array value) - $db_type");

  $o->nums(7, 8, 9);

  my @a = $o->nums;

  is($a[0], 7, "load() verify 13 (array value) - $db_type");
  is($a[1], 8, "load() verify 14 (array value) - $db_type");
  is($a[2], 9, "load() verify 15 (array value) - $db_type");
  is(@a, 3, "load() verify 16 (array value) - $db_type");

  is($o->names->[0], 'a', "load() verify 10 (set value) - $db_type");
  is($o->names->[1], 'b', "load() verify 11 (set value) - $db_type");
  is($o->names->[2], '3.1', "load() verify 12 (set value) - $db_type");

  $o->names('c', 'd', '4.2');

  @a = $o->names;

  is($a[0], 'c', "load() verify 13 (set value) - $db_type");
  is($a[1], 'd', "load() verify 14 (set value) - $db_type");
  is($a[2], '4.2', "load() verify 15 (set value) - $db_type");
  is(@a, 3, "load() verify 16 (set value) - $db_type");

  ok($o->delete, "delete() - $db_type");

  $o = MyInformixObject->new(name => 'John', id => 9);

  $o->flag2('true');
  $o->date_created('current year to fraction(5)');
  $o->last_modified($o->date_created);
  $o->save_col(22);

  ok($o->save, "save() 4 - $db_type");
  $o->save_col(50);

  ok($o->save, "save() 5 - $db_type");

  $ouk = MyInformixObject->new(save_col => 50);
  ok($ouk->load, "load() aliased unique key - $db_type");

  eval { $o->meta->alias_column(nonesuch => 'foo') };
  ok($@, "alias_column() nonesuch - $db_type");

  # This is okay now
  #eval { $o->meta->alias_column(id => 'foo') };
  #ok($@, "alias_column() primary key - $db_type");

  $o = MyInformixObject->new(id => 777);

  $o->meta->error_mode('fatal');

  $o->dbh->{'PrintError'} = 0;

  eval { $o->load };
  ok($@ && $o->not_found, "load() not found fatal - $db_type");

  $o->id('abc');

  eval { $o->load };
  ok($@ && !$o->not_found, "load() fatal - $db_type");

  eval { $o->save };
  ok($@, "save() fatal - $db_type");

  $o->meta->error_mode('return'); 
}

BEGIN
{
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
    our $HAVE_PG = 1;

    # Drop existing table and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE Rose_db_object_test CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_test CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_chkpass_test');
      $dbh->do('DROP SEQUENCE Rose_db_object_test_seq');
      $dbh->do('DROP SEQUENCE Rose_db_object_private.Rose_db_object_test_seq');
      $dbh->do('CREATE SCHEMA Rose_db_object_private');
    }

    our $PG_HAS_CHKPASS = pg_has_chkpass();

    $dbh->do('CREATE SEQUENCE Rose_db_object_test_seq');

    my $pg_vers = $dbh->{'pg_server_version'};
    my $active = $pg_vers >= 80100 ? q('act''ive') : q('act\'ive');

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test
(
  id             INT DEFAULT nextval('Rose_db_object_test_seq') NOT NULL PRIMARY KEY,
  k1             INT,
  k2             INT,
  k3             INT,
  @{[ $PG_HAS_CHKPASS ? 'password CHKPASS,' : '' ]}
  name           VARCHAR(32) NOT NULL,
  code           CHAR(6),
  flag           BOOLEAN NOT NULL DEFAULT 't',
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT $active,
  bits           BIT(5) NOT NULL DEFAULT B'00101',
  start          DATE DEFAULT '1980-12-24',
  save           INT,
  nums           INT[],
  dp             DOUBLE PRECISION,
  f8             FLOAT8,
  last_modified  TIMESTAMP,
  date_created   TIMESTAMP,

  UNIQUE(save),
  UNIQUE(k1, k2, k3)
)
EOF

    $dbh->do('CREATE SEQUENCE Rose_db_object_private.Rose_db_object_test_seq');

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_private.Rose_db_object_test
(
  id             INT DEFAULT nextval('Rose_db_object_test_seq') NOT NULL PRIMARY KEY,
  k1             INT,
  k2             INT,
  k3             INT,
  @{[ $PG_HAS_CHKPASS ? 'password CHKPASS,' : '' ]}
  name           VARCHAR(32) NOT NULL,
  code           CHAR(6),
  flag           BOOLEAN NOT NULL DEFAULT 't',
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT $active,
  bits           BIT(5) NOT NULL DEFAULT B'00101',
  start          DATE DEFAULT '1980-12-24',
  save           INT,
  nums           INT[],
  dp             DOUBLE PRECISION,
  f8             FLOAT8,
  last_modified  TIMESTAMP,
  date_created   TIMESTAMP,

  UNIQUE(save),
  UNIQUE(k1, k2, k3)
)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyPgObject;

    use Rose::DB::Object::Helpers qw(clone);

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('pg') }

    MyPgObject->meta->table('Rose_db_object_test');

    MyPgObject->meta->auto_initialize;

    package MyPgObjectEvalTest;
    our @ISA = qw(Rose::DB::Object);
    sub init_db { Rose::DB->new('pg') }

    eval 'package MyPgObjectEvalTest; ' . MyPgObject->meta->perl_columns_definition;
    Test::More::ok(!$@, 'perl_columns_definition eval - pg');

    eval 'package MyPgObjectEvalTest; ' . MyPgObject->meta->perl_unique_keys_definition;
    Test::More::ok(!$@, 'perl_unique_keys_definition eval 1 - pg');

    eval 'package MyPgObjectEvalTest; ' . MyPgObject->meta->perl_unique_keys_definition(style => 'object');
    Test::More::ok(!$@, 'perl_unique_keys_definition eval 2 - pg');

    eval 'package MyPgObjectEvalTest; ' . MyPgObject->meta->perl_primary_key_columns_definition;
    Test::More::ok(!$@, 'perl_primary_key_columns_definition eval - pg');
  }

  #
  # MySQL
  #

  my $db_version;

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
      $dbh->do('DROP TABLE Rose_db_object_test');
      $dbh->do('DROP TABLE Rose_db_object_test2');
    }

    # MySQL 5.0.3 or later has a completely stupid "native" BIT type
    # which we want to avoid because DBI's column_info() method prints
    # a warning when it encounters such a column.
    my $bit_col = 
      ($db_version >= 5_000_003) ?
        q(bits  TINYINT(1) NOT NULL DEFAULT '00101') :
        q(bits  BIT(5) NOT NULL DEFAULT '00101');

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test
(
  id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  k1             INT,
  k2             INT,
  k3             INT,
  name           VARCHAR(32) NOT NULL,
  code           CHAR(6),
  flag           TINYINT(1) NOT NULL DEFAULT 1,
  flag2          TINYINT(1),
  status         VARCHAR(32) DEFAULT 'act''ive',
  $bit_col,
  nums           VARCHAR(255),
  start          DATE DEFAULT '1980-12-24',
  save           INT,
  enums          ENUM ('foo', 'bar', 'baz') DEFAULT 'foo',
  dt_default     TIMESTAMP DEFAULT NOW(),
  last_modified  TIMESTAMP,
  date_created   DATETIME,

  UNIQUE(save),
  UNIQUE(k1, k2, k3)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test2
(
  k1             INT NOT NULL,
  k2             INT NOT NULL,
  name           VARCHAR(32),

  UNIQUE(k1, k2)
)
EOF

    $dbh->disconnect;

    package MyMySQLMeta;
    our @ISA = qw(Rose::DB::Object::Metadata);
    MyMySQLMeta->column_type_class(int => 'Rose::DB::Object::Metadata::Column::Varchar');

    # Create test subclass

    package MyMySQLObject;

    use Rose::DB::Object::Helpers qw(clone);

    our @ISA = qw(Rose::DB::Object);

    sub meta_class { 'MyMySQLMeta' }
    sub init_db { Rose::DB->new('mysql') }

    MyMySQLObject->meta->allow_inline_column_values(1);

    MyMySQLObject->meta->table('Rose_db_object_test');

    MyMySQLObject->meta->columns(MyMySQLObject->meta->auto_generate_columns);

    # Account for bugs in DBD::mysql's column_info implementation

    # CHAR(6) column shows up as VARCHAR(6) 
    MyMySQLObject->meta->column(code => { type => 'char', length => 6 });

    # BIT(5) column shows up as TINYINT(1)
    MyMySQLObject->meta->column(bits => { type => 'bitfield', bits => 5, default => 101 });

    # BOOLEAN column shows up as TINYINT(1) even if you use the 
    # BOOLEAN keyword (which is not supported prior to MySQL 4.1,
    # so we're actually using TINYINT(1) in the definition above)
    MyMySQLObject->meta->column(flag  => { type => 'boolean', default => 1 });
    MyMySQLObject->meta->column(flag2 => { type => 'boolean' });

    # No native support for array types in MySQL
    MyMySQLObject->meta->column(nums => { type => 'array' });

    # Test preservation of existing columns
    MyMySQLObject->meta->delete_column('k3');
    MyMySQLObject->meta->auto_init_columns;

    Test::More::is(MyMySQLObject->meta->column('k3')->type, 'varchar', 'custom column class - mysql');
    Test::More::ok(MyMySQLObject->meta->isa('MyMySQLMeta'), 'metadata subclass - mysql');

    MyMySQLObject->meta->primary_key_columns(MyMySQLObject->meta->auto_retrieve_primary_key_column_names);

    MyMySQLObject->meta->add_unique_key('save');
    MyMySQLObject->meta->auto_init_unique_keys;

    MyMySQLObject->meta->initialize;

    package MyMPKMySQLObject;

    use Rose::DB::Object;
    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('mysql') }

    MyMPKMySQLObject->meta->table('Rose_db_object_test2');

    MyMPKMySQLObject->meta->columns(MyMPKMySQLObject->meta->auto_generate_columns);

    # Not-null int columns default to 0 even if you do not set a default.
    # MySQL sucks.
    MyMPKMySQLObject->meta->column('k1')->default(undef);
    MyMPKMySQLObject->meta->column('k2')->default(undef);

    MyMPKMySQLObject->meta->primary_key_columns('k1', 'k2');

    MyMPKMySQLObject->meta->initialize;

    my $i = 1;

    MyMPKMySQLObject->meta->primary_key_generator(sub
    {
      my($meta, $db) = @_;

      my $k1 = $i++;
      my $k2 = $i++;

      return $k1, $k2;
    });
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
    our $HAVE_INFORMIX = 1;

    # Drop existing table and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE Rose_db_object_test CASCADE');
      $dbh->do('DROP TABLE Rose_db_object_test2 CASCADE');
    }

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test
(
  id             SERIAL NOT NULL PRIMARY KEY,
  k1             INT,
  k2             INT,
  k3             INT,
  name           VARCHAR(32) NOT NULL,
  code           CHAR(6),
  flag           BOOLEAN DEFAULT 't'  NOT NULL,
  flag2          BOOLEAN,
  status         VARCHAR(32) DEFAULT 'act''ive',
  bits           VARCHAR(5) DEFAULT '00101' NOT NULL,
  nums           VARCHAR(255),
  start          DATE DEFAULT '12/24/1980',
  save           INT,
  names          SET(VARCHAR(64) NOT NULL),
  last_modified  DATETIME YEAR TO FRACTION(5),
  date_created   DATETIME YEAR TO FRACTION(5),
  other_date     DATE DEFAULT TODAY,
  other_datetime DATETIME YEAR TO FRACTION(5) DEFAULT CURRENT YEAR TO FRACTION(5),
  frac           DATETIME YEAR TO FRACTION,
  frac1          DATETIME YEAR TO FRACTION(1),
  frac2          DATETIME YEAR TO FRACTION(2),
  frac3          DATETIME YEAR TO FRACTION(3),
  frac4          DATETIME YEAR TO FRACTION(4),
  frac5          DATETIME YEAR TO FRACTION(5),
  htmin          DATETIME HOUR TO MINUTE,
  htsec          DATETIME HOUR TO SECOND,
  htfr1          DATETIME HOUR TO FRACTION(1),
  htfr5          DATETIME HOUR TO FRACTION(5)
)
EOF

    $dbh->do(<<"EOF");
CREATE UNIQUE INDEX Rose_db_object_test_k1_idx ON Rose_db_object_test (k1, k2, k3);
EOF

    $dbh->do(<<"EOF");
CREATE UNIQUE INDEX Rose_db_object_test_save_idx ON Rose_db_object_test (save);
EOF

    $dbh->do(<<"EOF");
CREATE TABLE Rose_db_object_test2
(
  k1    INT NOT NULL,
  k2    INT NOT NULL,
  name  VARCHAR(32)
)
EOF

    $dbh->do(<<"EOF");
ALTER TABLE Rose_db_object_test2 ADD CONSTRAINT PRIMARY KEY (k1, k2)
EOF

    $dbh->disconnect;

    # Create test subclass

    package MyMPKInformixObject;

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('informix') }

    MyMPKInformixObject->meta->table('Rose_db_object_test2');

    MyMPKInformixObject->meta->auto_init_primary_key_columns;

    my @pk = MyMPKInformixObject->meta->primary_key_columns;
    Test::More::is_deeply(\@pk, [ qw(k1 k2) ], 'auto_init_primary_key_columns - informix');

    package MyInformixObject;

    use Rose::DB::Object::Helpers qw(clone);

    our @ISA = qw(Rose::DB::Object);

    sub init_db { Rose::DB->new('informix') }

    MyInformixObject->meta->table('Rose_db_object_test');

    MyInformixObject->meta->columns(MyInformixObject->meta->auto_generate_columns);

    # No native support for bit types in Informix
    MyInformixObject->meta->column(bits => { type => 'bitfield', bits => 5, default => 101 });

    # No native support for array types in Informix
    MyInformixObject->meta->column(nums => { type => 'array' });

    MyInformixObject->meta->auto_init_primary_key_columns;
    MyInformixObject->meta->auto_init_unique_keys;

    MyInformixObject->meta->prepare_options({ ix_CursorWithHold => 1 });    

    MyInformixObject->meta->initialize;
  }
}

END
{
  # Delete test table

  if($HAVE_PG)
  {
    # PostgreSQL
    my $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_test CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_private.Rose_db_object_test CASCADE');
    $dbh->do('DROP SEQUENCE Rose_db_object_test_seq');
    $dbh->do('DROP SEQUENCE Rose_db_object_private.Rose_db_object_test_seq');
    $dbh->do('DROP SCHEMA Rose_db_object_private CASCADE');

    $dbh->disconnect;
  }

  if($HAVE_MYSQL)
  {
    # MySQL
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_test CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_test2 CASCADE');

    $dbh->disconnect;
  }

  if($HAVE_INFORMIX)
  {
    # Informix
    my $dbh = Rose::DB->new('informix_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE Rose_db_object_test CASCADE');
    $dbh->do('DROP TABLE Rose_db_object_test2 CASCADE');

    $dbh->disconnect;
  }
}
