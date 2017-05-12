#!/usr/bin/perl -w

use strict;

use Test::More tests => 36;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
  use_ok('Rose::DB::Object::Metadata');
}

my $meta = Rose::DB::Object::Metadata->new(class => 'MyDBObject');
my $meta2 = Rose::DB::Object::Metadata->for_class('MyDBObject');

is(ref $meta, 'Rose::DB::Object::Metadata', 'new()');
is(ref $meta2, 'Rose::DB::Object::Metadata', 'for_class');

is($meta, $meta2, 'new() & for_class()');

#$meta->schema('priv');
$meta->table('mytable');

#is($meta->schema, 'priv', 'schema()');
is($meta->table, 'mytable', 'table()');

is($meta->fq_table_sql(MyDBObject->init_db), 'rose_db_object_private.mytable', 'fq_table_sql()');

$meta->columns
(
  'name',
  id       => { primary_key => 1 },
  password => { type => 'chkpass' },
  flag     => { type => 'boolean', default => 1 },
  flag2    => { type => 'boolean' },
  status   => { default => 'active' },
  start    => { type => 'date', default => '12/24/1980' },
  save     => { type => 'scalar' },
  nums     => { type => 'array' },
  bits     => { type => 'bitfield', bits => 5, default => 101 },
  date_created  => { type => 'timestamp' },
);

is($meta->first_column->name, 'name', 'first_column 1');

$meta->add_columns(
  Rose::DB::Object::Metadata::Column::Timestamp->new(
    name => 'last_modified'));

ok(!$meta->column('foo'), 'column()');
$meta->add_column('foo');
ok($meta->column('foo'), 'add_column()');

$meta->add_columns('bar', baz => { type => 'bitfield', bits => 10 });
ok($meta->column('bar'), 'add_columns() 1');
ok($meta->column('baz'), 'add_columns() 2');

eval { $meta->initialize(preserve_existing => 1) };
ok($@, 'initialize() reserved method');

is($meta->column_aliases, undef, 'column_aliases() 1');
my $aliases = $meta->column_aliases;
is($aliases, undef, 'column_aliases() 3');

$meta->alias_column(save => 'save_col');
$meta->initialize(preserve_existing => 1);

is($meta->class_for(table => 'mytable'), 'MyDBObject', 
  'class_for() as object method');

is(Rose::DB::Object::Metadata->class_for(table => 'mytable'), 'MyDBObject', 
  'class_for() as class method');

is(join(',', sort $meta->column_names), 'bar,baz,bits,date_created,flag,flag2,foo,id,last_modified,name,nums,password,save,start,status', 'column_names');

$aliases = $meta->column_aliases;

is(join(',', sort keys %$aliases), 'save', 'column_aliases() 3');
is($aliases->{'save'}, 'save_col', 'column_aliases() 4');

my $methods = $meta->column_rw_method_names;

is(join(',', sort @$methods), 'bar,baz,bits,date_created,flag,flag2,foo,id,last_modified,name,nums,password,save_col,start,status', 'column_rw_method_names()');

eval { $meta->convention_manager('nonesuch') };
ok($@, 'convention_manager nonesuch');

$meta->convention_manager('null');

is(ref $meta->convention_manager, 'Rose::DB::Object::ConventionManager::Null', 
  'convention_manager null');

my $class = ref $meta;

is($class->convention_manager_class('default'), 'Rose::DB::Object::ConventionManager', 
   'convention_manager default');

$class->convention_manager_class(foo => 'bar');
$class->convention_manager_class(default => 'Rose::DB::Object::ConventionManager::Null');

is($class->convention_manager_class('foo'), 'bar', 'convention_manager bar');

$class->delete_convention_manager_class('foo');

ok(!defined $class->convention_manager_class('foo'), 'delete_convention_manager_class');

is(ref $class->init_convention_manager, 'Rose::DB::Object::ConventionManager::Null', 
   'init_convention_manager');

$meta = MyDBOBjectCustom->meta;
$meta->init_auto_helper;
eval { $meta->make_column_methods() };
ok($@ =~ /^Yay!/, 'custom meta override');

# default_manager_base_class

is($meta->default_manager_base_class, 'Rose::DB::Object::Manager', 'default_manager_base_class object 1');
is(ref($meta)->default_manager_base_class, 'Rose::DB::Object::Manager', 'default_manager_base_class class 1');

$meta->default_manager_base_class('Foo');

is($meta->default_manager_base_class, 'Foo', 'default_manager_base_class object 2');
is(ref($meta)->default_manager_base_class, 'Rose::DB::Object::Manager', 'default_manager_base_class class 2');

$meta->default_manager_base_class(undef);
ref($meta)->default_manager_base_class('Bar');

is($meta->default_manager_base_class, 'Bar', 'default_manager_base_class object 3');
is(ref($meta)->default_manager_base_class, 'Bar', 'default_manager_base_class class 3');

$meta->default_manager_base_class('Blee');

is($meta->default_manager_base_class, 'Blee', 'default_manager_base_class object 4');
is(ref($meta)->default_manager_base_class, 'Bar', 'default_manager_base_class class 4');

BEGIN
{
  package MyDBObject;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg_with_schema') }

  package MyDBObject::Metadata;
  our @ISA = qw(Rose::DB::Object::Metadata);
  sub make_column_methods { die "Yay!" }

  package MyDBObject::Base;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg_with_schema') }
  sub meta_class { 'MyDBObject::Metadata' }

  package MyDBOBjectCustom;
  our @ISA = qw(MyDBObject::Base);
}


1;