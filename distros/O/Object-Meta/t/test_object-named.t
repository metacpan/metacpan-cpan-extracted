#!/usr/bin/perl

# @author Bodo (Hugo) Barwich
# @version 2026-01-25
# @package Test for the Object::Meta::Named Module
# @subpackage t/test_object-named.t

# This Module runs tests on the Object::Meta::Named Module
#
#---------------------------------
# Requirements:
# - The Perl Module "Object::Meta::Named" must be installed
#

use warnings;
use strict;

use Cwd         qw(abs_path);
use Digest::MD5 qw(md5_hex);

use Test::More;

BEGIN {
    use lib "lib";
    use lib "../lib";
}    #BEGIN

require_ok('Object::Meta::Named');

use Object::Meta::Named;

my $smodule = "";
my $spath   = abs_path($0);

( $smodule = $spath ) =~ s/.*\/([^\/]+)$/$1/;
$spath =~ s/^(.*\/)$smodule$/$1/;

my $obj         = undef;
my %objdata     = ( 'name'    => 'object1', 'field1' => 'value1', 'field2' => 'value2', 'field3' => 'value3' );
my $objhash     = md5_hex('object1');

subtest 'Constructors' => sub {

    #------------------------
    #Test: 'Constructors'

    subtest 'empty object' => sub {
        $obj = Object::Meta::Named->new();

        is( ref $obj, 'Object::Meta::Named', "object 'Object::Meta::Named': created correctly" );

        is( $obj->getIndexField(),     'hash', "Field 'hash': is index field as expected" );
        is( $obj->get( 'field1', '' ), '',     "Field 'field1': does not exist as expected" );
    };
    subtest 'object from data' => sub {
        $obj = Object::Meta::Named->new(%objdata);

        is( ref $obj, 'Object::Meta::Named', "object 'Object::Meta::Named': created correctly" );

        is( $obj->getIndexField(), 'hash',   "Field 'hash': is index field as expected" );
        is( $obj->getIndexValue(), $objhash, "Field 'hash': has the index value" );

        foreach ( keys %objdata ) {
            is( $obj->get( $_, '' ), $objdata{$_}, "Field '$_': added correctly" );
        }
    };
    subtest 'object from name' => sub {
        my $obj2hash = md5_hex('object2');

        $obj = Object::Meta::Named->new( 'name' => 'object2' );

        is( ref $obj, 'Object::Meta::Named', "object 'Object::Meta::Named': created correctly" );

        is( $obj->getName(),       'object2', "Field 'name': set correctly" );
        is( $obj->getIndexValue(), $obj2hash, "Field 'hash': has the index value" );
    };
};

subtest 'Set Name' => sub {

    #------------------------
    #Test: 'Set Name'

    subtest 'object set data' => sub {
        $obj = Object::Meta::Named->new();

        is( ref $obj, 'Object::Meta::Named', "object 'Object::Meta::Named': created correctly" );

        $obj->set(%objdata);

        is( $obj->getName(),       'object1', "Field 'name': set correctly" );
        is( $obj->getIndexValue(), $objhash,  "Field 'hash': has the index value" );

        foreach ( keys %objdata ) {
            is( $obj->get( $_, '' ), $objdata{$_}, "Field '$_': added correctly" );
        }
    };
    subtest 'object set name' => sub {
        my $obj3hash = md5_hex('object3');

        $obj = Object::Meta::Named->new();

        is( ref $obj, 'Object::Meta::Named', "object 'Object::Meta::Named': created correctly" );

        $obj->setName('object3');

        is( $obj->getName(),       'object3', "Field 'name': set correctly" );
        is( $obj->getIndexValue(), $obj3hash, "Field 'hash': has the index value" );
    };
};

done_testing();
