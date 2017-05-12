#!/usr/bin/perl
use strict;
use warnings;
use blib;  

use Test::More; 
use Object::LocalVars qw(); 
use Scalar::Util qw( refaddr );
use t::Common;
# work around win32 console buffering
Test::More->builder->failure_output(*STDOUT) 
    if ($^O eq 'MSWin32' && $ENV{HARNESS_VERBOSE});

my $class = "t::Object::PropsOverload";
my @props = qw( name color );

plan tests => TC() + TA() * @props + 7;

my $o = test_constructor($class);

SKIP: {
    skip "because we don't have a $class object", TA() * @props +7 unless $o;
    {
        no strict 'refs';
        ok( defined *{"t::Object::PropsOverload::DATA::name"}{HASH},
            "object property 'name' initialized in the master data hash" );
        ok( defined *{"t::Object::PropsOverload::DATA::color"}{HASH},
            "object property 'color' initialized in the master data hash" );
    }
    test_accessors( $o, $_ ) for @props;

    my $addr = refaddr $o;

    ok( exists $t::Object::PropsOverload::DATA::name{$addr}, 
        "found object property 'name' data in the master data hash" );
    ok( exists $t::Object::PropsOverload::DATA::color{$addr}, 
        "found object property 'color' data in the master data hash" );
    $o = undef;
    ok( ! defined $o, "releasing object reference" );
    ok( ! exists $t::Object::PropsOverload::DATA::name{$addr}, 
        "... and object property 'name' data has been cleaned up" );
    ok( ! exists $t::Object::PropsOverload::DATA::color{$addr}, 
        "... and object property 'color' data has been cleaned up" );

}

