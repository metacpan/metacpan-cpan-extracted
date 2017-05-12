#!/usr/bin/perl -w

use strict;

use Test::More tests => 125;

BEGIN
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
  use_ok('Rose::DB::Object::MakeMethods::Generic');
  use_ok('Rose::DB::Object::MakeMethods::Pg');
}

use Rose::DB::Object::Constants qw(STATE_SAVING);

my $p = Person->new() || ok(0);
ok(ref $p && $p->isa('Person'), 'Construct object (no init)');

#
# scalar
#

is($p->scalar('foo'), 'foo', 'scalar get_set 1');
is($p->scalar, 'foo', 'scalar get_set 2');

is($p->set_scalar('bar'), 'bar', 'scalar set 1');
eval { $p->set_scalar() };
ok($@,  'scalar set 2');
is($p->get_scalar, 'bar', 'scalar get');

#
# character
#

is($p->character('booga'), 'boog', 'character get_set 1');
is($p->character, 'boog', 'character get_set 2');
eval { $p->character_die('booga') };
ok($@, 'character_die get_set 1');

is($p->set_character('woo'), 'woo ', 'character set 1');
eval { $p->set_character() };
ok($@,  'character set 2');
is($p->get_character, 'woo ', 'character get');

#
# varchar
#

is($p->varchar('booga'), 'boog', 'varchar get_set 1');
is($p->varchar, 'boog', 'varchar get_set 2');
eval { $p->varchar_die('booga') };
ok($@, 'varchar_die get_set 1');

is($p->set_varchar('woo'), 'woo', 'varchar set 1');
eval { $p->set_varchar() };
ok($@,  'varchar set 2');
is($p->get_varchar, 'woo', 'varchar get');

#
# These tests require a connected Rose::DB
#

our $db_type;

eval
{
  require Rose::DB;

  foreach my $type (qw(pg mysql informix))
  {  
    Rose::DB->default_type($type);
    my $db = Rose::DB->new();

    $db->raise_error(0);
    $db->print_error(0);

    my $ret;

    eval { $ret = $db->connect };

    if($ret && !$@)
    {
      $db_type = $type;
      last;
    }
  }

  die unless(defined $db_type);
};

SKIP:
{
  skip("Can't connect to db", 99)  if($@);

  #
  # boolean
  #

  is($p->boolean('true'), 1, 'boolean get_set 1');
  is($p->boolean, 1, 'boolean get_set 2');

  is($p->set_boolean('F'), 0, 'boolean set 1');
  eval { $p->set_boolean() };
  ok($@,  'boolean set 2');
  is($p->get_boolean, 0, 'boolean get');

  $p = Person->new(sql_is_happy => 1);
  ok(ref $p && $p->isa('Person'), 'boolean 1');

  is($p->sql_is_happy, 1, 'boolean 2');

  foreach my $val (qw(t true True TRUE T y Y yes Yes YES 1 1.0 1.00))
  {
    eval { $p->sql_is_happy($val) };
    ok(!$@ && $p->sql_is_happy, "boolean true '$val'");
  }

  foreach my $val (qw(f false False FALSE F n N no No NO 0 0.0 0.00))
  {
    eval { $p->sql_is_happy($val) };
    ok(!$@ && !$p->sql_is_happy, "boolean false '$val'");
  }

  #
  # date
  #

  is($p->date('12/24/1980')->ymd, '1980-12-24', 'date get_set 1');
  is($p->date->ymd, '1980-12-24', 'date get_set 2');

  is($p->set_date('1980-12-25')->ymd, '1980-12-25', 'date set 1');
  eval { $p->set_date() };
  ok($@,  'date set 2');
  is($p->get_date->ymd, '1980-12-25', 'date get');

  $p = Person->new(sql_date_birthday => '12/24/1980 1:00');
  ok(ref $p && $p->isa('Person'), 'date 1');

  is($p->sql_date_birthday->ymd, '1980-12-24', 'date 2');

  is($p->sql_date_birthday(truncate => 'month')->ymd, '1980-12-01', 'date truncate');

  is($p->sql_date_birthday(format => '%B'), 'December', 'date format');

  $p->sql_date_birthday('12/24/1980 1:00:01');

  is($p->sql_date_birthday->ymd, '1980-12-24', 'date 4');

  is($p->sql_date_birthday_def->ymd, '2002-01-01', 'date 5');

  $p->sql_date_birthday('now');

  if($db_type eq 'pg')
  {
    is($p->sql_date_birthday, 'now', 'date now');
  }
  else
  {
    ok($p->sql_date_birthday =~ /^2/, 'date now');
  }

  $p->sql_date_birthday('infinity');
  is($p->sql_date_birthday(format => ''), 'infinity', 'date infinity');

  $p->sql_date_birthday('-infinity');
  is($p->sql_date_birthday(format => ''), '-infinity', 'date -infinity');

  eval { $p->sql_date_birthday('asdf') };
  ok($@, 'Invalid date');

  #
  # datetime
  #

  is($p->datetime('12/24/1980 12:34:56')->strftime('%Y-%m-%d %H:%M:%S'), 
                  '1980-12-24 12:34:56', 'datetime get_set 1');
  is($p->datetime->strftime('%Y-%m-%d %H:%M:%S'), '1980-12-24 12:34:56', 'datetime get_set 2');

  is($p->set_datetime('1980-12-25 12:30:50')->strftime('%Y-%m-%d %H:%M:%S'),
                      '1980-12-25 12:30:50', 'datetime set 1');
  eval { $p->set_datetime() };
  ok($@,  'datetime set 2');
  is($p->get_datetime->strftime('%Y-%m-%d %H:%M:%S'), '1980-12-25 12:30:50', 'datetime get');

  $p = Person->new(sql_datetime_birthday => '12/24/1980 1:00');
  ok(ref $p && $p->isa('Person'), 'datetime 1');

  is($p->sql_datetime_birthday->strftime('%Y-%m-%d %H:%M:%S'), 
     '1980-12-24 01:00:00', 'datetime 2');

  is($p->sql_datetime_birthday(truncate => 'month')->strftime('%Y-%m-%d %H:%M:%S'),
     '1980-12-01 00:00:00', 'datetime truncate');

  $p->sql_datetime_birthday('12/24/1980 1:00:01');

  is($p->sql_datetime_birthday->strftime('%Y-%m-%d %H:%M:%S'), 
     '1980-12-24 01:00:01', 'datetime 4');

  is($p->sql_datetime_birthday_def->strftime('%Y-%m-%d %H:%M:%S'),
     '2002-01-02 00:00:00', 'datetime 5');

  eval { $p->sql_datetime_birthday('asdf') };
  ok($@, 'Invalid datetime');

  #
  # timestamp
  #

  is($p->timestamp('12/24/1980 12:34:56')->strftime('%Y-%m-%d %H:%M:%S'), 
                  '1980-12-24 12:34:56', 'timestamp get_set 1');
  is($p->timestamp->strftime('%Y-%m-%d %H:%M:%S'), '1980-12-24 12:34:56', 'timestamp get_set 2');

  is($p->set_timestamp('1980-12-25 12:30:50')->strftime('%Y-%m-%d %H:%M:%S'), 
                       '1980-12-25 12:30:50', 'timestamp set 1');
  eval { $p->set_timestamp() };
  ok($@,  'timestamp set 2');
  is($p->get_timestamp->strftime('%Y-%m-%d %H:%M:%S'), '1980-12-25 12:30:50', 'timestamp get');

  $p = Person->new(sql_timestamp_birthday => '12/24/1980 1:00');
  ok(ref $p && $p->isa('Person'), 'timestamp 1');

  is($p->sql_timestamp_birthday->strftime('%Y-%m-%d %H:%M:%S'), 
     '1980-12-24 01:00:00', 'timestamp 2');

  is($p->sql_timestamp_birthday(truncate => 'month')->strftime('%Y-%m-%d %H:%M:%S'),
     '1980-12-01 00:00:00', 'timestamp truncate');

  $p->sql_timestamp_birthday('12/24/1980 1:00:01');

  is($p->sql_timestamp_birthday->strftime('%Y-%m-%d %H:%M:%S'), 
     '1980-12-24 01:00:01', 'timestamp 4');

  is($p->sql_timestamp_birthday_def->strftime('%Y-%m-%d %H:%M:%S'),
     '2002-01-03 00:00:00', 'timestamp 5');

  eval { $p->sql_timestamp_birthday('asdf') };
  ok($@, 'Invalid timestamp');

  #
  # bitfield
  #

  if($p->db->driver eq 'pg')
  {
    is($p->bitfield(2)->to_Bin, '00000000000000000000000000000010', 'bitfield get_set 1');
    is($p->bitfield->to_Bin, '00000000000000000000000000000010', 'bitfield get_set 2');

    is($p->set_bitfield(1010)->to_Bin, '00000000000000000000000000001010', 'bitfield set 1');
    eval { $p->set_bitfield() };
    ok($@,  'bitfield set 2');
    is($p->get_bitfield->to_Bin, '00000000000000000000000000001010', 'bitfield get');

    $p->sql_bits(2);
    is($p->sql_bits()->to_Bin, '00000000000000000000000000000010', 'bitfield() 2');
    $p->sql_bits(1010);
    is($p->sql_bits()->to_Bin, '00000000000000000000000000001010', 'bitfield() 1010');
    $p->sql_bits(5.0);
    is($p->sql_bits()->to_Bin, '00000000000000000000000000000101', 'bitfield() 5.0');

    ok($p->sql_bits_intersects('100'), 'bitfield() intsersects 1');
    ok(!$p->sql_bits_intersects('1000'), 'bitfield() intsersects 2');

    $p->sql_8bits(2);
    is($p->sql_8bits()->to_Bin, '00000010', 'bitfield(8) 2');
    $p->sql_8bits(1010);
    is($p->sql_8bits()->to_Bin,  '00001010', 'bitfield(8) 1010');
    $p->sql_8bits(5.0);
    is($p->sql_8bits()->to_Bin, '00000101', 'bitfield(8) 5.0');

    is($p->sql_5bits3()->to_Bin, '00011', 'bitfield(5) default');
    $p->sql_5bits3(2);
    is($p->sql_5bits3()->to_Bin, '00010', 'bitfield(5) 2');
    $p->sql_5bits3(1010);
    is($p->sql_5bits3()->to_Bin, '01010', 'bitfield(5) 1010');
    $p->sql_5bits3(5.0);
    is($p->sql_5bits3()->to_Bin, '00101', 'bitfield(5) 5.0');
  }
  else
  {
    SKIP:
    {
      skip("Not connected to PostgreSQL", 17);
    }
  }

  #
  # array
  #

  if($p->db->driver eq 'pg')
  {
    local $p->{STATE_SAVING()} = 1;
    $p->sql_array(-1, 2.5, 3);
    is($p->sql_array, '{-1,2.5,3}', 'array 1');

    $p->sql_array([ 'a' .. 'c' ]);
    is($p->sql_array, '{"a","b","c"}', 'array 2');

    is($p->array(-1, 2.5, 3), '{-1,2.5,3}', 'array get_set 1');
    is($p->array, '{-1,2.5,3}', 'array get_set 2');

    is($p->set_array([ 'a' .. 'c' ]), '{"a","b","c"}', 'array set 1');
    eval { $p->set_array() };
    ok($@,  'array set 2');
    is($p->get_array, '{"a","b","c"}', 'array get');
  }
  else
  {
    SKIP:
    {
      skip("Not connected to PostgreSQL", 7);
    }
  }

  #
  # set
  #

  if($p->db->driver eq 'informix')
  {
    local $p->{STATE_SAVING()} = 1;
    is($p->set(-1, 2.5, 3), 'SET{-1,2.5,3}', 'set get_set 1');
    is($p->set, 'SET{-1,2.5,3}', 'set get_set 2');

    is($p->set_set([ 'a' .. 'c' ]), q(SET{'a','b','c'}), 'set set 1');
    eval { $p->set_set() };
    ok($@,  'set set 2');
    is($p->get_set, q(SET{'a','b','c'}), 'set get');
  }
  else
  {
    SKIP:
    {
      skip("Not connected to Informix", 5);
    }
  }
}

#
# chkpass
#

$p->{'password_encrypted'} = ':8R1Kf2nOS0bRE';

ok($p->password_is('xyzzy'), 'chkpass() 1');
is($p->password, 'xyzzy', 'chkpass() 2');

eval { $p->set_password() };
ok($@, 'chkpass() 3');

$p->set_password('foobar');

ok($p->password_is('foobar'), 'chkpass() 4');
is($p->get_password, 'foobar', 'chkpass() 5');

BEGIN
{
  Rose::DB->default_type('mysql');

  package Person;

  use strict;

  @Person::ISA = qw(Rose::DB::Object);

  Person->meta->columns
  (
    sql_date_birthday          => { type => 'date' },
    sql_date_birthday_def      => { type => 'date' },
    sql_datetime_birthday      => { type => 'datetime' },
    sql_datetime_birthday_def  => { type => 'datetime' },
    sql_timestamp_birthday     => { type => 'timestamp' },
    sql_timestamp_birthday_def => { type => 'timestamp' },

    sql_is_happy  => { type => 'boolean' },
    sql_bool      => { type => 'boolean' },
    sql_bool_def1 => { type => 'boolean' },

    sql_bits   => { type => 'bitfield' },
    sql_8bits  => { type => 'bitfield', bits => 8 },
    sql_5bits3 => { type => 'bitfield', bits => 5 },

    sql_array  => { type => 'array' },
  );

  my $meta = Person->meta;

  Rose::DB::Object::MakeMethods::Date->make_methods
  (
    { target_class => 'Person' },
    date        => [ 'sql_date_birthday' => { column => $meta->column('sql_date_birthday') } ],
    date        => [ 'sql_date_birthday_def' => { default => '1/1/2002', 
                      column => $meta->column('sql_date_birthday_def') } ],
    datetime    => [ 'sql_datetime_birthday' => { column => $meta->column('sql_datetime_birthday') } ],
    datetime    => [ 'sql_datetime_birthday_def' => { default => '1/2/2002',
                      column => $meta->column('sql_datetime_birthday_def') } ],
    timestamp   => [ 'sql_timestamp_birthday' => { column => $meta->column('sql_timestamp_birthday') } ],
    timestamp   => [ 'sql_timestamp_birthday_def' => { default => '1/3/2002',
                     column => $meta->column('sql_timestamp_birthday_def') } ],

    date =>
    [
     'date',
      get_date => { interface => 'get', hash_key => 'date' },
      set_date => { interface => 'set', hash_key => 'date' },
    ],

    datetime =>
    [
     'datetime',
      get_datetime => { interface => 'get', hash_key => 'datetime' },
      set_datetime => { interface => 'set', hash_key => 'datetime' },
    ],

    timestamp =>
    [
     'timestamp',
      get_timestamp => { interface => 'get', hash_key => 'timestamp' },
      set_timestamp => { interface => 'set', hash_key => 'timestamp' },
    ],
  );

  Rose::DB::Object::MakeMethods::Generic->make_methods
  (
    { target_class => 'Person' },
    scalar =>
    [
      'scalar',
      get_scalar => { interface => 'get', hash_key => 'scalar' },
      set_scalar => { interface => 'set', hash_key => 'scalar' },
    ],

    character => 
    [
      character     => { length => 4, overflow => 'truncate' },
      character_die => { length => 4, overflow => 'fatal' },
      get_character => { interface => 'get', hash_key => 'character', length => 4 },
      set_character => { interface => 'set', hash_key => 'character', length => 4 },
    ],

    varchar => 
    [
      varchar     => { length => 4, overflow => 'truncate' },
      varchar_die => { length => 4, overflow => 'fatal' },
      get_varchar => { interface => 'get', hash_key => 'varchar', length => 4 },
      set_varchar => { interface => 'set', hash_key => 'varchar', length => 4 },
    ],

    boolean => 
    [
      'boolean',
      get_boolean => { interface => 'get', hash_key => 'boolean' },
      set_boolean => { interface => 'set', hash_key => 'boolean' },
    ],

    boolean => [ 'sql_is_happy' => { column => $meta->column('sql_is_happy') } ],

    boolean =>
    [
      sql_bool      => { column => $meta->column('sql_bool') },
      sql_bool_def1 => { default => 1, column => $meta->column('sql_bool_def1') },
    ],

    bitfield => 
    [
      'sql_bits' => { with_intersects => 1, column => $meta->column('sql_bits') },

      'bitfield',
      get_bitfield => { interface => 'get', hash_key => 'bitfield' },
      set_bitfield => { interface => 'set', hash_key => 'bitfield' },
    ],

    bitfield =>
    [
      sql_8bits  => { bits => 8, column => $meta->column('sql_8bits') },
      sql_5bits3 => { bits => 5, default => '00011', column => $meta->column('sql_5bits3') },
    ],

    array => [ 'sql_array' => { column => $meta->column('sql_array') } ],

    array =>
    [
      'array',
      get_array => { interface => 'get', hash_key => 'array' },
      set_array => { interface => 'set', hash_key => 'array' },
    ],

    set =>
    [
      'set',
      get_set => { interface => 'get', hash_key => 'set' },
      set_set => { interface => 'set', hash_key => 'set' },
    ],
  );

  use Rose::DB::Object::MakeMethods::Pg
  (
    chkpass => 
    [
      'password',
      'get_password' => { interface => 'get', hash_key => 'password' },
      'set_password' => { interface => 'set', hash_key => 'password' },
    ],
  );

  sub db
  {
    my $self = shift;
    return $self->{'db'}  if($self->{'db'});
    $self->{'db'} = Rose::DB->new();
    $self->{'db'}->connect or die $self->{'db'}->error;
    return $self->{'db'};
  }

  sub _loading { 0 }
}
