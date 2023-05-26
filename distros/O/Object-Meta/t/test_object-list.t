#!/usr/bin/perl

# @author Bodo (Hugo) Barwich
# @version 2023-05-20
# @package Test for the Object::Meta Module
# @subpackage test_object.t

# This Module runs tests on the Object::Meta::List Module
#
#---------------------------------
# Requirements:
# - The Perl Module "Object::Meta::Liist" must be installed
#



use warnings;
use strict;

use Cwd qw(abs_path);

use Test::More;

BEGIN
{
  use lib "lib";
  use lib "../lib";
}  #BEGIN

require_ok('Object::Meta::List');

use Object::Meta::List;



my $smodule = "";
my $spath = abs_path($0);


($smodule = $spath) =~ s/.*\/([^\/]+)$/$1/;
$spath =~ s/^(.*\/)$smodule$/$1/;


my $list = undef;
my $obj = undef;
my %obj1data = ('field1' => 'value1', 'field2' => 'value2', 'field3' => 'value3');
my %obj2data = ('field1' => 'value4', 'field2' => 'value5', 'field3' => 'value6');
my %obj3data = ('field1' => 'value7', 'field2' => 'value8', 'field3' => 'value9');
my %obj1meta = ('indexfield' => 'field1', 'updated' => 'new');
my %obj2meta = ('indexfield' => 'field1', 'updated' => 'new');
my %obj3meta = ('indexfield' => 'field1', 'updated' => 'new');

subtest 'Constructor' => sub {

  #------------------------
  #Test: 'Constructor'

  subtest 'empty list' => sub {
    $list = Object::Meta::List->new();

    is(ref $list, 'Object::Meta::List', "List 'Object::Meta::List': created correctly");

    is( $list->getMetaObjectCount(), 0, "List is empty as expected" );
    is( $list->getMetaObject(0), undef, "Object with Index '0': does not exist as expected" );
  };
};

subtest 'Add Objects' => sub {

  #------------------------
  #Test: 'Constructor'

  subtest 'Add Objects as Hash' => sub {
    $list = Object::Meta::List->new();

    is(ref $list, 'Object::Meta::List', "List 'Object::Meta::List': created correctly");

    is( $list->getMetaObjectCount(), 0, "List is empty as expected" );
    is( $list->getMetaObject(0), undef, "Object with Index '0': does not exist as expected" );

    $list->Add(%obj1data);
    $list->Add(%obj2data);
    $list->Add(%obj3data);

    is( $list->getMetaObjectCount(), 3, "List has 3 Objects" );

    $obj = $list->getMetaObject(0);

    isnt( $obj, undef, "Object with Index '0': is set" );
    is( ref $obj, 'Object::Meta', "Object with Index '0': is an 'Object::Meta'" );
  };
  subtest 'Add Objects as Object::Meta' => sub {
    $list = Object::Meta::List->new();

    is(ref $list, 'Object::Meta::List', "List 'Object::Meta::List': created correctly");

    is( $list->getMetaObjectCount(), 0, "List is empty as expected" );
    is( $list->getMetaObject(0), undef, "Object with Index '0': does not exist as expected" );

    $obj = Object::Meta->new(%obj1data);

    $obj->setMeta(%obj1meta);

    $list->Add($obj);

    $obj = Object::Meta->new(%obj2data);

    $obj->setMeta(%obj2meta);

    $list->Add($obj);

    $obj = Object::Meta->new(%obj3data);

    $obj->setMeta(%obj3meta);

    $list->Add($obj);

    is( $list->getMetaObjectCount(), 3, "List has 3 Objects" );

    $obj = $list->getMetaObject(0);

    isnt( $obj, undef, "Object with Index '0': is set" );
    is( ref $obj, 'Object::Meta', "Object with Index '0': is an 'Object::Meta'" );
  };
  subtest 'Add Objects by the ID Value' => sub {
    $list = Object::Meta::List->new();

    is(ref $list, 'Object::Meta::List', "List 'Object::Meta::List': created correctly");

    is( $list->getMetaObjectCount(), 0, "List is empty as expected" );
    is( $list->getMetaObject(0), undef, "Object with Index '0': does not exist as expected" );

    # Create an Index with the setIndexField() method
    $list->setIndexField('field1');

    is( $list->getIndexField(), 'field1', "Index Field 'field1' as expected" );

    $list->Add('value1');
    $list->Add('value4');
    $list->Add('value7');

    is( $list->getMetaObjectCount(), 3, "List has 3 Objects" );
    is( $list->getIdxMetaObjectCount(), 3, "Indexed Objects: Count '3'" );

    $obj = $list->getMetaObject(0);

    isnt( $obj, undef, "Object with Index '0': is set" );
    is( ref $obj, 'Object::Meta', "Object with Index '0': is an 'Object::Meta'" );
    is( $obj->get('field1', ''), 'value1', "Object Field 'field1' is created with Value 'value1'" );
    is( $obj->getIndexValue(), 'value1', "Object Index Value: is 'value1'" );
  };
};

subtest 'Create Index' => sub {

  #------------------------
  #Test: 'Indices'

  subtest 'primary index with set method' => sub {
    $list = Object::Meta::List->new();

    is(ref $list, 'Object::Meta::List', "List 'Object::Meta::List': created correctly");

    is( $list->getMetaObjectCount(), 0, "List is empty as expected" );
    is( $list->getMetaObject(0), undef, "Object with Index '0': does not exist as expected" );

	  # Create an Index by setting Field Name
	  $list->setIndexField('field1');

	  is( $list->getIndexField(), 'field1', "Index Field 'field1' as expected" );
  };
  subtest 'create index with create method' => sub {
    $list = Object::Meta::List->new();

    is(ref $list, 'Object::Meta::List', "List 'Object::Meta::List': created correctly");

    is( $list->getMetaObjectCount(), 0, "List is empty as expected" );
    is( $list->getMetaObject(0), undef, "Object with Index '0': does not exist as expected" );

    # Create an Index dirrectly with the createIndex() method
    $list->createIndex('indexname' => 'primary', 'checkfield' => 'field1');

    is( $list->getIndexField(), 'field1', "Index Field 'field1' as expected" );

    $list->Add(%obj1data);
    $list->Add(%obj2data);
    $list->Add(%obj3data);

    is( $list->getMetaObjectCount(), 3, "List has 3 Objects" );
    is( $list->getIdxMetaObjectCount(), 3, "Indexed Objects: Count '3'" );
  };
  subtest 'create index with fix value' => sub {
    $list = Object::Meta::List->new();

    is(ref $list, 'Object::Meta::List', "List 'Object::Meta::List': created correctly");

    is( $list->getMetaObjectCount(), 0, "List is empty as expected" );
    is( $list->getMetaObject(0), undef, "Object with Index '0': does not exist as expected" );

    # Create an Index with the setIndexField() method
    $list->setIndexField('field1');

    # Create an Index dirrectly with the createIndex() method
    $list->createIndex('indexname' => 'new', 'checkfield' => 'updated', 'checkvalue' => 'new', 'meta' => 1);

    # Primary Index was created automatically
    is( $list->getIndexField(), 'field1', "Index Field 'field1' as expected" );

    $obj = Object::Meta->new(%obj1data);

    $obj->setMeta(%obj1meta);

    $list->Add($obj);

    $obj = Object::Meta->new(%obj2data);

    $list->Add($obj);

    $obj = Object::Meta->new(%obj3data);

    $list->Add($obj);

    is( $list->getIdxMetaObjectCount(), 3, "Indexed Objects: Count '3'" );
    is( $list->getIdxMetaObjectCount('new'), 1, "Objects with Meta Field 'new': Count '1'" );
  };
  subtest 'get index value array' => sub {
    $list = Object::Meta::List->new();

    is(ref $list, 'Object::Meta::List', "List 'Object::Meta::List': created correctly");

    is( $list->getMetaObjectCount(), 0, "List is empty as expected" );
    is( $list->getMetaObject(0), undef, "Object with Index '0': does not exist as expected" );

    # Create an Index with the setIndexField() method
    $list->setIndexField('field1');

    # Create an Index dirrectly with the createIndex() method
    $list->createIndex('indexname' => 'new', 'checkfield' => 'updated', 'checkvalue' => 'new', 'meta' => 1);

    # Primary Index was created automatically
    is( $list->getIndexField(), 'field1', "Index Field 'field1' as expected" );

    $obj = Object::Meta->new(%obj1data);

    $obj->setMeta(%obj1meta);

    $list->Add($obj);

    $obj = Object::Meta->new(%obj2data);

    $list->Add($obj);

    $obj = Object::Meta->new(%obj3data);

    $list->Add($obj);

    is( $list->getIdxMetaObjectCount(), 3, "Indexed Objects: Count '3'" );
    is( $list->getIdxMetaObjectCount('new'), 1, "Objects with Meta Field 'new': Count '1'" );

    my @arridxvls = $list->getIdxValueArray();
    my $objcnt = 0;

    is( ref(\@arridxvls), 'ARRAY', "List of Indexed Values is an Array");

    foreach (@arridxvls) {
    	$obj = $list->getIdxMetaObject($_);

      $objcnt++ if(defined $obj && $obj->getIndexValue() eq $_);

	    isnt( $obj, undef, "Object with Indexed Value '$_': is set" );
	    is( ref $obj, 'Object::Meta', "Object with Indexed Value '$_': is an 'Object::Meta'" );
	    is( $obj->get('field1', ''), $_, "Object Field 'field1' is created with Value '$_'" );
	    is( $obj->getIndexValue(), $_, "Object Index Value: is '$_'" );
    }

    is( scalar(@arridxvls), $objcnt, "All Indexed Values correspond to Objects" );

    @arridxvls = $list->getIdxValueArray('new');

    is( ref(\@arridxvls), 'ARRAY', "List of Indexed Values 'new' is an Array");
    is( $arridxvls[0], 'value1', "Indexed Values 'new' [0]: Value 'value1'" );
  };
};

subtest 'Clear Objects' => sub {

  #------------------------
  #Test: 'Indices'

  subtest 'clear objects but keep indices' => sub {
    $list = Object::Meta::List->new();

    is(ref $list, 'Object::Meta::List', "List 'Object::Meta::List': created correctly");

    is( $list->getMetaObjectCount(), 0, "List is empty as expected" );
    is( $list->getMetaObject(0), undef, "Object with Index '0': does not exist as expected" );

    # Create an Index by setting Field Name
    $list->setIndexField('field1');

    is( $list->getIndexField(), 'field1', "Index Field 'field1' as expected" );

    $list->Add('value1');
    $list->Add('value4');
    $list->Add('value7');

    is( $list->getMetaObjectCount(), 3, "List has 3 Objects" );
    is( $list->getIdxMetaObjectCount(), 3, "Indexed Objects: Count '3'" );

    $list->Clear();

    is( $list->getMetaObjectCount(), 0, "List has 0 Objects" );
    is( $list->getIndexField(), 'field1', "Index Field 'field1' as expected" );
    is( $list->getIdxMetaObjectCount(), 0, "Indexed Objects: Count '0'" );

    $obj = $list->getIdxMetaObject('value4');

    is( $obj, undef, "Object with Indexed Value 'value4': is not set" );

    $list->Add('value2');
    $list->Add('value5');
    $list->Add('value8');

    is( $list->getMetaObjectCount(), 3, "List has 3 Objects" );
    is( $list->getIdxMetaObjectCount(), 3, "Indexed Objects: Count '3'" );

    $obj = $list->getIdxMetaObject('value8');

    isnt( $obj, undef, "Object with Indexed Value 'value8': is set" );
    is( ref $obj, 'Object::Meta', "Object with Indexed Value 'value8': is an 'Object::Meta'" );
    is( $obj->get('field1', ''), 'value8', "Object Field 'field1' is created with Value 'value8'" );
    is( $obj->getIndexValue(), 'value8', "Object Index Value: is 'value8'" );
  };
};

done_testing();
