#!/usr/bin/perl -w

use strict;

use Test::More tests => 183;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
  use_ok('Rose::DB::Object::Manager');
  use_ok('Rose::DB::Object::ConventionManager');
  use_ok('Rose::DB::Object::ConventionManager::Null');
}

#
# related_table_to_class
#

my $cm = Rose::DB::Object::ConventionManager->new;

is($cm->related_table_to_class('prices', 'My::Product'), 'My::Price', 'related_table_to_class 1');
is($cm->related_table_to_class('big_hats', 'A::B::FooBar'), 'A::B::BigHat', 'related_table_to_class 2');
is($cm->related_table_to_class('a1_steaks', 'Meat'), 'A1Steak', 'related_table_to_class 3');

#
# table_to_class
#

is($cm->table_to_class('products', 'My::'), 'My::Product', 'table_to_class 1');
is($cm->table_to_class('products'), 'Product', 'table_to_class 2');
is($cm->table_to_class('big_hats', 'My::'), 'My::BigHat', 'table_to_class 3');
is($cm->table_to_class('my5_hat_pig'), 'My5HatPig', 'table_to_class 4');

#
# singular_to_plural
#

is($cm->singular_to_plural('box'), 'boxes', 'singular_to_plural 1');
is($cm->singular_to_plural('dress'), 'dresses', 'singular_to_plural 2');
is($cm->singular_to_plural('ceres'), 'cereses', 'singular_to_plural 3');
is($cm->singular_to_plural('daisy'), 'daisies', 'singular_to_plural 4');
is($cm->singular_to_plural('dogs'), 'dogs', 'singular_to_plural 5');
is($cm->singular_to_plural('product'), 'products', 'singular_to_plural 6');

#
# plural_to_singular
#

is($cm->plural_to_singular('daisies'), 'daisy', 'plural_to_singular 1');
is($cm->plural_to_singular('dresses'), 'dress', 'plural_to_singular 2');
is($cm->plural_to_singular('dress'), 'dress', 'plural_to_singular 3');
is($cm->plural_to_singular('products'), 'product', 'plural_to_singular 4');

#
# is_singleton
#

my $cm1 = Rose::DB::Object::ConventionManager::Null->new;
my $cm2 = Rose::DB::Object::ConventionManager::Null->new;

is($cm1, $cm2, 'null singleton');

#
# auto_manager_*
#

is($cm->auto_manager_base_class, 'Rose::DB::Object::Manager', 'auto_manager_base_class');
is($cm->auto_manager_class_name('My::Object'), 'My::Object::Manager', 'auto_manager_class_name');

AUTO_MANAGER_CLASS_TEST:
{
  package My::Dog;
  @My::Dog::ISA = 'Rose::DB::Object';

  my $dog_cm = My::Dog->meta->convention_manager;

  package main;
  is($dog_cm->auto_manager_class_name, 'My::Dog::Manager', 'auto_manager_base_class no args');
  is($dog_cm->auto_manager_base_name, 'dogs', 'auto_manager_base_name with no args');
  is($dog_cm->auto_manager_base_name('products'), 'products', 'auto_manager_base_name with table');
  is($dog_cm->auto_manager_base_name('dogs', 'My::Dog'), 'dogs', 'auto_manager_base_name with table and class');
}

is($cm->auto_manager_method_name('doesntmatter'), undef, 'auto_manager_method_name');

#
# auto_table
#

my %Expect_Table =
(
  'OtherObject'          => 'other_objects',
  'My::OtherObject'      => 'other_objects',
  'My::Other::Object'    => 'objects',
  'Other123Object'       => 'other123_objects',
  'My::Other123Object'   => 'other123_objects',
  'My::Other::123Object' => '123_objects',
  'Mess2'                => 'mess2s',
  'Mess'                 => 'messes',
  'My::Mess'             => 'messes',
  'My::Other::Mess'      => 'messes',
  'Box'                  => 'boxes',
  'My::Box'              => 'boxes',
  'My::Other::Box'       => 'boxes',
);

foreach my $pkg (sort keys %Expect_Table)
{
  no strict 'refs';
  @{"${pkg}::ISA"} = qw(Rose::DB::Object);
  *{"${pkg}::init_db"} = sub { Rose::DB->new('pg') };
  is($pkg->meta->table, $Expect_Table{$pkg}, "auto_table $pkg");
}

SKIP:
{
  eval "require Lingua::EN::Inflect";

  skip('missing Lingua::EN::Inflect 1.89', 19)
    if($@ || $Lingua::EN::Inflect::VERSION != 1.89);

  %Expect_Table =
  (
    'OtherPerson'          => 'other_people',
    'My::Person'           => 'people',
    'My::Other::Person'    => 'people',
    'Other123Person'       => 'other123_people',
    'My::Other123Person'   => 'other123_people',
    'My::Other::123Person' => '123_people',
    'MyMess2'              => 'my_mess2s',
    'My2Mess'              => 'my2_messes',
    'My2::Mess'            => 'messes',
    'My2::Other::Mess'     => 'messes',
    'Deer'                 => 'deer',
    'My::Deer'             => 'deer',
    'My::Other::Deer'      => 'deer',
    'Alumnus'              => 'alumni',
    'My::Alumnus'          => 'alumni',
    'My::Other::Alumnus'   => 'alumni',
    'pBox'                 => 'p_boxes',
    'My::pBox'             => 'p_boxes',
    'My::Other::pBox'      => 'p_boxes',
  );

  foreach my $pkg (sort keys %Expect_Table)
  {
    no strict 'refs';
    @{"${pkg}::ISA"} = qw(Rose::DB::Object);
    *{"${pkg}::init_db"} = sub { Rose::DB->new('pg') };
    $pkg->meta->convention_manager->singular_to_plural_function(\&Lingua::EN::Inflect::PL_N);
    is($pkg->meta->table, $Expect_Table{$pkg}, "auto_table en $pkg");
  }
}

My::OtherObject->meta->columns
(
  name => { type => 'varchar'},
  k1   => { type => 'int' },
  k2   => { type => 'int' },
  k3   => { type => 'int' },
);

My::OtherObject->meta->primary_key_columns([ qw(k1 k2 k3) ]);

My::OtherObject->meta->initialize;

#
# auto_table_name
#

AUTO_TABLE:
{
  package My::AutoTable;
  @My::AutoTable::ISA = ('Rose::DB::Object');
  My::AutoTable->meta->convention_manager->tables_are_singular(1);
  Test::More::is(My::AutoTable->meta->table, 'auto_table', 'auto_table_name() singular');
  My::AutoTable->meta->convention_manager->tables_are_singular(0);
  My::AutoTable->meta->table(undef);
  Test::More::is(My::AutoTable->meta->table, 'auto_tables', 'auto_table_name() plural');
}

#
# auto_primary_key_columns
#

PK_ID:
{
  package My::PKClass1;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }

  __PACKAGE__->meta->columns
  (
    'name',
    'id',
    'object_id',
  );

  my @columns = __PACKAGE__->meta->primary_key_column_names;
  Test::More::ok(@columns == 1 && $columns[0] eq 'id', 'auto_primary_key_column_names id');
}

PK_OBJECT_ID:
{
  package My::PK::OtherObject;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }

  __PACKAGE__->meta->columns
  (
    'name',
    'other_object_id',
  );

  my @columns = __PACKAGE__->meta->primary_key_column_names;
  Test::More::ok(@columns == 1 && $columns[0] eq 'other_object_id', 'auto_primary_key_column_names other_object_id');
}

PK_SERIAL_ID:
{
  package My::PKSerial::OtherObject;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }

  __PACKAGE__->meta->columns
  (
    'pk'  => { type => 'serial' },
    'roo' => { type => 'serial' },
    'foo',
  );

  my @columns = __PACKAGE__->meta->primary_key_column_names;
  Test::More::ok(@columns == 1 && $columns[0] eq 'pk', 'auto_primary_key_column_names pk');
}

#
# auto_column_method_name
#

COLUMN_METHOD:
{
  package MyColumnCM;

  our @ISA = qw(Rose::DB::Object::ConventionManager);

  sub auto_column_method_name
  {
    my($self, $type, $column, $name, $object_class) = @_;
    return $column->is_primary_key_member ? $name : "x_${type}_$name";
  }

  package MyColumnObject;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  MyColumnObject->meta->convention_manager('MyColumnCM');
  __PACKAGE__->meta->columns(qw(id a b));  
  __PACKAGE__->meta->initialize;

  package main;
  my $o = MyColumnObject->new;
  ok($o->can('id'), 'auto_column_method_name 1');
  ok($o->can('x_get_set_a'), 'auto_column_method_name 2');
  ok($o->can('x_get_set_b'), 'auto_column_method_name 3');
  ok(!$o->can('a'), 'auto_column_method_name 4');
  ok(!$o->can('b'), 'auto_column_method_name 5');
}

#
# auto_foreign_key
#

FK1:
{
  package My::FK1::OtherObject;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id name));
  __PACKAGE__->meta->initialize;

  package My::FK1::Object;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id other_object_id));  
  __PACKAGE__->meta->foreign_keys(qw(other_object));
  __PACKAGE__->meta->initialize;
}

my $fk = My::FK1::Object->meta->foreign_key('other_object');
ok($fk, 'auto_foreign_key 1');
is($fk->class, 'My::FK1::OtherObject', 'auto_foreign_key 2');
my $kc = $fk->key_columns;
is(scalar keys %$kc, 1, 'auto_foreign_key 3');
is($kc->{'other_object_id'}, 'id', 'auto_foreign_key 4');

FK2:
{
  package My::FK2::OtherObj;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id name));
  __PACKAGE__->meta->initialize;

  package My::FK2::Object;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id other_object_id));  
  __PACKAGE__->meta->foreign_keys
  (
    other_object =>
    {
      class => 'My::FK2::OtherObj',
    }
  );

  __PACKAGE__->meta->initialize;
}

$fk = My::FK2::Object->meta->foreign_key('other_object');
ok($fk, 'auto_foreign_key 5');
is($fk->class, 'My::FK2::OtherObj', 'auto_foreign_key 6');
$kc = $fk->key_columns;
is(scalar keys %$kc, 1, 'auto_foreign_key 7');
is($kc->{'other_object_id'}, 'id', 'auto_foreign_key 8');

FK3:
{
  package My::FK3::OtherObj;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(eyedee => { type => 'serial' },  'name');
  __PACKAGE__->meta->initialize;

  package My::FK3::Object;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id other_obj_eyedee));  
  __PACKAGE__->meta->foreign_keys
  (
    other_obj =>
    {
      key_columns => { other_obj_eyedee => 'eyedee' },
    }
  );

  __PACKAGE__->meta->initialize;
}

$fk = My::FK3::Object->meta->foreign_key('other_obj');
ok($fk, 'auto_foreign_key 9');
is($fk->class, 'My::FK3::OtherObj', 'auto_foreign_key 10');
$kc = $fk->key_columns;
is(scalar keys %$kc, 1, 'auto_foreign_key 11');
is($kc->{'other_obj_eyedee'}, 'eyedee', 'auto_foreign_key 12');

FK4:
{
  package My::FK4::OtherObj;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(eyedee => { type => 'serial' },  'name');
  __PACKAGE__->meta->initialize;

  package My::FK4::Object;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id other_obj_eyedee));  
  __PACKAGE__->meta->foreign_keys(qw(other_obj));
  __PACKAGE__->meta->initialize;
}

$fk = My::FK4::Object->meta->foreign_key('other_obj');
ok($fk, 'auto_foreign_key 13');
is($fk->class, 'My::FK4::OtherObj', 'auto_foreign_key 14');
$kc = $fk->key_columns;
is(scalar keys %$kc, 1, 'auto_foreign_key 15');
is($kc->{'other_obj_eyedee'}, 'eyedee', 'auto_foreign_key 16');

#
# auto_relationship
#

# one to one

OTO1:
{
  package My::OTO1::OtherObject;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id name));
  __PACKAGE__->meta->initialize;

  package My::OTO1::Object;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id other_object_id));  
  __PACKAGE__->meta->relationships(other_object => 'one to one');
  __PACKAGE__->meta->initialize;
}

my $rel = My::OTO1::Object->meta->relationship('other_object');
ok($rel, 'auto_relationship one to one 1');
is($rel->class, 'My::OTO1::OtherObject', 'auto_relationship one to one 2');
$cm = $rel->column_map;
is(scalar keys %$cm, 1, 'auto_relationship one to one 3');
is($cm->{'other_object_id'}, 'id', 'auto_relationship one to one 4');

OTO2:
{
  package My::OTO2::OtherObj;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id name));
  __PACKAGE__->meta->initialize;

  package My::OTO2::Object;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id other_object_id));  
  __PACKAGE__->meta->relationships
  (
    other_object =>
    {
      type  => 'one to one',
      class => 'My::OTO2::OtherObj',
    }
  );

  __PACKAGE__->meta->initialize;
}

$rel = My::OTO2::Object->meta->relationship('other_object');
ok($rel, 'auto_relationship one to one 5');
is($rel->class, 'My::OTO2::OtherObj', 'auto_relationship one to one 6');
$cm = $rel->column_map;
is(scalar keys %$cm, 1, 'auto_relationship one to one 7');
is($cm->{'other_object_id'}, 'id', 'auto_relationship one to one 8');

OTO3:
{
  package My::OTO3::OtherObj;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(eyedee => { type => 'serial' },  'name');
  __PACKAGE__->meta->initialize;

  package My::OTO3::Object;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id other_obj_id));  
  __PACKAGE__->meta->relationships
  (
    other_obj =>
    {
      type => 'one to one',
      column_map => { other_obj_id => 'eyedee' },
    }
  );

  __PACKAGE__->meta->initialize;
}

$rel = My::OTO3::Object->meta->relationship('other_obj');
ok($rel, 'auto_relationship one to one 9');
is($rel->class, 'My::OTO3::OtherObj', 'auto_relationship one to one 10');
$cm = $rel->column_map;
is(scalar keys %$cm, 1, 'auto_relationship one to one 11');
is($cm->{'other_obj_id'}, 'eyedee', 'auto_relationship one to one 12');

OTO4:
{
  package My::OTO4::OtherObj;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(eyedee => { type => 'serial' },  'name');
  __PACKAGE__->meta->initialize;

  package My::OTO4::Object;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id other_obj_eyedee));  
  __PACKAGE__->meta->relationships
  (
    other_obj => { type => 'one to one' }
  );

  __PACKAGE__->meta->initialize;
}

$rel = My::OTO4::Object->meta->relationship('other_obj');
ok($rel, 'auto_relationship one to one 13');
is($rel->class, 'My::OTO4::OtherObj', 'auto_relationship one to one 14');
$cm = $rel->column_map;
is(scalar keys %$cm, 1, 'auto_relationship one to one 15');
is($cm->{'other_obj_eyedee'}, 'eyedee', 'auto_relationship one to one 16');

# many to one

MTO1:
{
  package My::MTO1::OtherObject;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id name));
  __PACKAGE__->meta->initialize;

  package My::MTO1::Object;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id other_object_id));  
  __PACKAGE__->meta->relationships(other_object => 'many to one');
  __PACKAGE__->meta->initialize;
}

$rel = My::MTO1::Object->meta->relationship('other_object');
ok($rel, 'auto_relationship many to one 1');
is($rel->class, 'My::MTO1::OtherObject', 'auto_relationship many to one 2');
$cm = $rel->column_map;
is(scalar keys %$cm, 1, 'auto_relationship many to one 3');
is($cm->{'other_object_id'}, 'id', 'auto_relationship many to one 4');

MTO2:
{
  package My::MTO2::OtherObj;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id name));
  __PACKAGE__->meta->initialize;

  package My::MTO2::Object;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id other_object_id));  
  __PACKAGE__->meta->relationships
  (
    other_object =>
    {
      type  => 'many to one',
      class => 'My::MTO2::OtherObj',
    }
  );

  __PACKAGE__->meta->initialize;
}

$rel = My::MTO2::Object->meta->relationship('other_object');
ok($rel, 'auto_relationship many to one 5');
is($rel->class, 'My::MTO2::OtherObj', 'auto_relationship many to one 6');
$cm = $rel->column_map;
is(scalar keys %$cm, 1, 'auto_relationship many to one 7');
is($cm->{'other_object_id'}, 'id', 'auto_relationship many to one 8');

MTO3:
{
  package My::MTO3::OtherObj;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(eyedee => { type => 'serial' },  'name');
  __PACKAGE__->meta->initialize;

  package My::MTO3::Object;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id other_obj_id));  
  __PACKAGE__->meta->relationships
  (
    other_obj =>
    {
      type => 'many to one',
      column_map => { other_obj_id => 'eyedee' },
    }
  );

  __PACKAGE__->meta->initialize;
}

$rel = My::MTO3::Object->meta->relationship('other_obj');
ok($rel, 'auto_relationship many to one 9');
is($rel->class, 'My::MTO3::OtherObj', 'auto_relationship many to one 10');
$cm = $rel->column_map;
is(scalar keys %$cm, 1, 'auto_relationship many to one 11');
is($cm->{'other_obj_id'}, 'eyedee', 'auto_relationship many to one 12');

MTO4:
{
  package My::MTO4::OtherObj;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(eyedee => { type => 'serial' },  'name');
  __PACKAGE__->meta->initialize;

  package My::MTO4::Object;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id other_obj_eyedee));  
  __PACKAGE__->meta->relationships
  (
    other_obj => { type => 'many to one' }
  );

  __PACKAGE__->meta->initialize;
}

$rel = My::MTO4::Object->meta->relationship('other_obj');
ok($rel, 'auto_relationship many to one 13');
is($rel->class, 'My::MTO4::OtherObj', 'auto_relationship many to one 14');
$cm = $rel->column_map;
is(scalar keys %$cm, 1, 'auto_relationship many to one 15');
is($cm->{'other_obj_eyedee'}, 'eyedee', 'auto_relationship many to one 16');

# one to many

OTM1:
{
  package My::OTM1::OtherObject;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id name object_id));
  __PACKAGE__->meta->initialize;

  package My::OTM1::Object;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id name));  
  __PACKAGE__->meta->relationships(other_objects => 'one to many');
  __PACKAGE__->meta->initialize;
}

$rel = My::OTM1::Object->meta->relationship('other_objects');
ok($rel, 'auto_relationship one to many 1');
is($rel->class, 'My::OTM1::OtherObject', 'auto_relationship one to many 2');
$cm = $rel->column_map;
is(scalar keys %$cm, 1, 'auto_relationship one to many 3');
is($cm->{'id'}, 'object_id', 'auto_relationship one to many 4');

OTM2:
{
  package My::OTM2::OtherObj;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id name object_id));
  __PACKAGE__->meta->initialize;

  package My::OTM2::Object;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id name));  
  __PACKAGE__->meta->relationships
  (
    other_objects =>
    {
      type  => 'one to many',
      class => 'My::OTM2::OtherObj',
    }
  );

  __PACKAGE__->meta->initialize;
}

$rel = My::OTM2::Object->meta->relationship('other_objects');
ok($rel, 'auto_relationship one to many 5');
is($rel->class, 'My::OTM2::OtherObj', 'auto_relationship one to many 6');
$cm = $rel->column_map;
is(scalar keys %$cm, 1, 'auto_relationship one to many 7');
is($cm->{'id'}, 'object_id', 'auto_relationship one to many 8');

OTM3:
{
  package My::OTM3::OtherObj;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(meyedee => { type => 'serial' },  'name', 'object_eyedee');
  __PACKAGE__->meta->initialize;

  package My::OTM3::Object;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(eyedee => { type => 'serial' }, 'name');  
  __PACKAGE__->meta->relationships
  (
    other_obj =>
    {
      type => 'one to many',
      column_map => { eyedee => 'object_eyedee' },
    }
  );

  __PACKAGE__->meta->initialize;
}

$rel = My::OTM3::Object->meta->relationship('other_obj');
ok($rel, 'auto_relationship one to many 9');
is($rel->class, 'My::OTM3::OtherObj', 'auto_relationship one to many 10');
$cm = $rel->column_map;
is(scalar keys %$cm, 1, 'auto_relationship one to many 11');
is($cm->{'eyedee'}, 'object_eyedee', 'auto_relationship one to many 12');

OTM4:
{
  package My::OTM4::OtherObj;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(meyedee => { type => 'serial' },  'name', 'object_eyedee');
  __PACKAGE__->meta->initialize;

  package My::OTM4::Object;
  our @ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(eyedee => { type => 'serial' }, 'name');
  __PACKAGE__->meta->relationships
  (
    other_objs => { type => 'one to many' }
  );

  __PACKAGE__->meta->initialize;
}

$rel = My::OTM4::Object->meta->relationship('other_objs');
ok($rel, 'auto_relationship one to many 13');
is($rel->class, 'My::OTM4::OtherObj', 'auto_relationship one to many 14');
$cm = $rel->column_map;
is(scalar keys %$cm, 1, 'auto_relationship one to many 15');
is($cm->{'eyedee'}, 'object_eyedee', 'auto_relationship one to many 16');

# many to many

my $i = 0;

my @map_classes =
qw(ObjectsOtherObjectsMap
   ObjectOtherObjectMap
   OtherObjectsObjectsMap
   OtherObjectObjectMap
   ObjectsOtherObjects
   ObjectOtherObjects
   OtherObjectsObjects
   OtherObjectObjects
   OtherObjectMap
   OtherObjectsMap
   ObjectMap
   ObjectsMap);

foreach my $class (@map_classes)
{
  $i++;

  my $defs=<<"EOF";
  package My::MTM${i}::$class;
  our \@ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id object_id other_object_id));

  package My::MTM${i}::OtherObject;
  our \@ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id name));
  __PACKAGE__->meta->initialize;

  package My::MTM${i}::Object;
  our \@ISA = qw(Rose::DB::Object);
  sub init_db { Rose::DB->new('pg') }
  __PACKAGE__->meta->columns(qw(id name));  

  My::MTM${i}::$class->meta->foreign_keys(qw(object other_object));
  My::MTM${i}::$class->meta->initialize;

  My::MTM${i}::Object->meta->relationships(other_objects => 'many to many');
  My::MTM${i}::Object->meta->initialize
EOF

  eval $defs;
  die $@  if($@);

  my $obj_class = "My::MTM${i}::Object";
  $rel = $obj_class->meta->relationship('other_objects');
  ok($rel, "auto_relationship many to many $i.1");
  is($rel->map_class, "My::MTM${i}::$class", "auto_relationship many to many $i.2");
  is($rel->map_from, 'object', "auto_relationship many to many $i.3");
  is($rel->map_to, 'other_object', "auto_relationship many to many $i.4");
}
