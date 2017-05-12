#!/usr/bin/perl
use strict;
use warnings;
use blib;  

use Test::More;
use Test::Exception;
use t::Common;

# work around win32 console buffering
Test::More->builder->failure_output(*STDOUT) 
    if ($^O eq 'MSWin32' && $ENV{HARNESS_VERBOSE});

my $class1 = "t::Object::Methods";
my $class2 = "t::Object::Complete";
my $class3 = "t::Object::Morbid";

# methods: fcn, args arrayref, result

plan tests => 3 * TC() + 4;

my $o = test_constructor($class1);
my $p = test_constructor($class2);
my $r = test_constructor($class3);

SKIP: {
    skip "because we don't have a $class1 object", 4 unless $o;
    skip "because we don't have a $class2 object", 4 unless $p;
    skip "because we don't have a $class3 object", 4 unless $r;
    my ($pkg1, undef, undef, $subr1 ) = $o->report_caller;
    my ($pkg2, undef, undef, $subr2 ) = $p->report_caller;
    
    is_deeply( [ $pkg1, $subr1 ], [ "main", undef ],
        "propertyless-object methods get correct caller()" );
    is_deeply( [ $pkg2, $subr2 ], [ "main", undef ],
        "propertied-object methods get correct caller()" );
    eval { $r->do_croak };
    my $err = $@;
    # doing these without Test::Exception to ensure the uplevels aren't
    # screwy
    like( $err, qr/07-uplevel\.t/, "croak finds correct caller()");
    eval { $r->do_croak_removed }; 
    $err = $@;
    like( $err, qr/07-uplevel\.t/, "croak finds correct caller()");
}


