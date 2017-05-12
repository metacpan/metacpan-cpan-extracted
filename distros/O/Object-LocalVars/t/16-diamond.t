#!/usr/bin/perl
use strict;
use warnings;
use blib;  

use Test::More;
use t::Common;
use Object::LocalVars qw();
use Scalar::Util qw( refaddr );
use Data::Dumper qw(Dumper);

# work around win32 console buffering
Test::More->builder->failure_output(*STDOUT) 
    if ($^O eq 'MSWin32' && $ENV{HARNESS_VERBOSE});

my $class       = "t::Object::Complete::Diamond";

plan tests => TC() + 3;

my $o = test_constructor($class);

my $expected_after_new = {
    grandparent => 1,
    leftparent  => 1,
    rightparent => 1,
    diamond     => 1,
};

my $expected_after_destroy = {
    grandparent => 0,
    leftparent  => 0,
    rightparent => 0,
    diamond     => 0,
};

SKIP: {
    skip "because we don't have a $class object", 3 
        unless $o;
    
    # Check that constructors called only once around diamond
    is_deeply($o->report_counts, $expected_after_new, 
        "constructors only called once" )
        or diag "Got:\n" . Dumper($class->report_counts);

    # Check proper destruction
    my $addr = refaddr( $o );
    $o = undef;
    ok( ! defined $o, "releasing object reference" );
    is_deeply($class->report_counts, $expected_after_destroy, 
        "destructors only called once" )
        or diag "Got:\n" . Dumper($class->report_counts);

}




