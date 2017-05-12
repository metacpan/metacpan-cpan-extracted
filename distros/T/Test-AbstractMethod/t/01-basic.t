#!perl

use strict;

use Test::More tests => 7;
use Test::Builder::Tester;

BEGIN { use_ok("Test::AbstractMethod"); }

test_out("ok 1 - instance method");
call_abstract_method_ok("MyPackage", "my_method", "instance method");
test_test("Passing instance methods");

test_out("ok 1 - class method");
call_abstract_class_method_ok("MyPackage", "my_method", "class method");
test_test("Passing class methods");

test_out("ok 1 - function");
call_abstract_function_ok("MyPackage", "my_method", "function");
test_test("Passing functions");

test_out("not ok 1 - instance method");
test_fail(+1);
call_abstract_method_ok("MyPackage", "my_other_method", "instance method");
test_test("Failing instance methods");

test_out("not ok 1 - class method");
test_fail(+1);
call_abstract_class_method_ok("MyPackage", "my_other_method", "class method");
test_test("Failing class methods");

test_out("not ok 1 - function");
test_fail(+1);
call_abstract_function_ok("MyPackage", "my_other_method", "function");
test_test("Failing function");

package MyPackage;

sub my_method {
    my $self = shift;
    $self = ref $self || $self;
    die "my_method() should not be called as a function" if !$self;
    die "Class '$self' does not override my_method()";
}

sub my_other_method {
}