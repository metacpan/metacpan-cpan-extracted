#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_SUCCESS: 'have $my_object->get_bar() = 22' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object->get_bar() = 44' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object->double_bar_return() = 88' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object->get_bar() = 44' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object_subclass->get_bar() = 23' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object_subclass->get_bax() = 123' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object_subclass->get_bax() = 369' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object_subclass->triple_bax_return() = 1107' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object_subclass->get_bax() = 369' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object_subclass->multiply_bax_return(2) = 738' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object_subclass->get_bax() = 369' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object_subclass->multiply_bax_return(20) = 1107' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object_subclass->get_bax() = 369' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object_subclass2->get_bar() = 33' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object_subclass2->get_bax() = 88' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object_subclass2->get_bax() = 264' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object_subclass2->triple_bax_return() = 792' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object_subclass2->get_bax() = 264' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object_subclass2->multiply_bax_return(2) = 528' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object_subclass2->get_bax() = 264' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object_subclass2->multiply_bax_return(20) = 792' >>>
# <<< EXECUTE_SUCCESS: 'have $my_object_subclass2->get_bax() = 264' >>>

# [[[ HEADER ]]]
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils
## no critic qw(ProhibitMultiplePackages ProhibitReusedNames ProhibitPackageVars)  # USER DEFAULT 8: allow additional packages

# [[[ INCLUDES ]]]
use Perl::Types::Test::OO::MyClass00Good;

# [[[ OPERATIONS ]]]

# class example

my Perl::Types::Test::OO::MyClass00Good $my_object = Perl::Types::Test::OO::MyClass00Good->new({bar => 22});

print 'have $my_object->get_bar() = ', $my_object->get_bar(), "\n";

$my_object->double_bar_save();
print 'have $my_object->get_bar() = ', $my_object->get_bar(), "\n";

print 'have $my_object->double_bar_return() = ', $my_object->double_bar_return(), "\n";
print 'have $my_object->get_bar() = ', $my_object->get_bar(), "\n";

# subclass example 1

my Perl::Types::Test::OO::MySubclass00Good $my_object_subclass = Perl::Types::Test::OO::MySubclass00Good->new();

print 'have $my_object_subclass->get_bar() = ', $my_object_subclass->get_bar(), "\n";
print 'have $my_object_subclass->get_bax() = ', $my_object_subclass->get_bax(), "\n";

$my_object_subclass->triple_bax_save();
print 'have $my_object_subclass->get_bax() = ', $my_object_subclass->get_bax(), "\n";

print 'have $my_object_subclass->triple_bax_return() = ', $my_object_subclass->triple_bax_return(), "\n";
print 'have $my_object_subclass->get_bax() = ', $my_object_subclass->get_bax(), "\n";

print 'have $my_object_subclass->multiply_bax_return(2) = ', $my_object_subclass->multiply_bax_return(2), "\n";
print 'have $my_object_subclass->get_bax() = ', $my_object_subclass->get_bax(), "\n";

print 'have $my_object_subclass->multiply_bax_return(20) = ', $my_object_subclass->multiply_bax_return(20), "\n";
print 'have $my_object_subclass->get_bax() = ', $my_object_subclass->get_bax(), "\n";

# subclass example 2

my Perl::Types::Test::OO::MySubclass00Good $my_object_subclass2 = Perl::Types::Test::OO::MySubclass00Good->new({bar => 33, bax => 88});

print 'have $my_object_subclass2->get_bar() = ', $my_object_subclass2->get_bar(), "\n";
print 'have $my_object_subclass2->get_bax() = ', $my_object_subclass2->get_bax(), "\n";

$my_object_subclass2->triple_bax_save();
print 'have $my_object_subclass2->get_bax() = ', $my_object_subclass2->get_bax(), "\n";

print 'have $my_object_subclass2->triple_bax_return() = ', $my_object_subclass2->triple_bax_return(), "\n";
print 'have $my_object_subclass2->get_bax() = ', $my_object_subclass2->get_bax(), "\n";

print 'have $my_object_subclass2->multiply_bax_return(2) = ', $my_object_subclass2->multiply_bax_return(2), "\n";
print 'have $my_object_subclass2->get_bax() = ', $my_object_subclass2->get_bax(), "\n";

print 'have $my_object_subclass2->multiply_bax_return(20) = ', $my_object_subclass2->multiply_bax_return(20), "\n";
print 'have $my_object_subclass2->get_bax() = ', $my_object_subclass2->get_bax(), "\n";

