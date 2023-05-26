#!/usr/bin/perl

# @author Bodo (Hugo) Barwich
# @version 2023-05-07
# @package Test for the Object::Meta Module
# @subpackage test_object.t

# This Module runs tests on the Object::Meta Module
#
#---------------------------------
# Requirements:
# - The Perl Module "Object::Meta" must be installed
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

require_ok('Object::Meta');

use Object::Meta;



my $smodule = "";
my $spath = abs_path($0);


($smodule = $spath) =~ s/.*\/([^\/]+)$/$1/;
$spath =~ s/^(.*\/)$smodule$/$1/;


my $obj = undef;
my %objdata = ('field1' => 'value1', 'field2' => 'value2', 'field3' => 'value3');
my %objmetadata = ('indexfield' => 'field1', 'updated' => 'new');

subtest 'Constructors' => sub {

	#------------------------
	#Test: 'Constructors'

  subtest 'empty object' => sub {
	  $obj = Object::Meta->new();

	  is(ref $obj, 'Object::Meta', "object 'Object::Meta': created correctly");

    is( $obj->get('field1', ''), '', "Field 'field1': does not exist as expected" );
  };
  subtest 'object from data' => sub {
	  $obj = Object::Meta->new(%objdata);

	  is(ref $obj, 'Object::Meta', "object 'Object::Meta': created correctly");

	  foreach (keys %objdata) {
	    is( $obj->get($_, ''), $objdata{$_}, "Field '$_': added correctly" );
	  }
  };
};

subtest 'Set Data' => sub {

  #------------------------
  #Test: 'Set Data'

  subtest 'object set data' => sub {
    $obj = Object::Meta->new();

    is(ref $obj, 'Object::Meta', "object 'Object::Meta': created correctly");

    $obj->set(%objdata);

    foreach (keys %objdata) {
      is( $obj->get($_, ''), $objdata{$_}, "Field '$_': added correctly" );
    }
  };
};

subtest 'Set Meta Data' => sub {

  #------------------------
  #Test: 'Set Meta Data'

  subtest 'object set meta data' => sub {
    $obj = Object::Meta->new();

    is(ref $obj, 'Object::Meta', "object 'Object::Meta': created correctly");

    $obj->setMeta(%objmetadata);

    is( $obj->getIndexField(), 'field1', "Index Field 'field1': set correctly" );
    is( $obj->getMeta('updated'), 'new', "Meta Field 'updated': with getMeta() method retrieved correctly" );
    is( $obj->get('updated', '', 1), 'new', "Meta Field 'updated': with get() method retrieved correctly" );

  };
  subtest 'object id field' => sub {
    $obj = Object::Meta->new();

    is(ref $obj, 'Object::Meta', "object 'Object::Meta': created correctly");

    $obj->setIndexField('field1');

    $obj->set(%objdata);

    foreach (keys %objdata) {
      is( $obj->get($_, ''), $objdata{$_}, "Field '$_': added correctly" );
    }

    is( $obj->getIndexValue(), 'value1', "Index Value for 'field1': retrieved correctly" );
  };
};


done_testing();
