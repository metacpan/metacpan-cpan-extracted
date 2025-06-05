#!/usr/bin/env perl

# [[[ PREPROCESSOR ]]]
# <<< EXECUTE_ERROR: 'ERROR EIV01' >>>
# <<< EXECUTE_ERROR: 'integer value expected but non-integer value found' >>>
# <<< EXECUTE_ERROR: 'in variable $multiplier from subroutine multiply_bax_FG()' >>>

# [[[ HEADER ]]]
use strict;
use warnings;
use types;
our $VERSION = 0.001_000;

# [[[ CRITICS ]]]
## no critic qw(ProhibitUselessNoCritic ProhibitMagicNumbers RequireCheckedSyscalls)  # USER DEFAULT 1: allow numeric values & print operator
## no critic qw(RequireInterpolationOfMetachars)  # USER DEFAULT 2: allow single-quoted control characters & sigils

# [[[ INCLUDES ]]]
use Perl::Types::Test::Subclass::MySubclassersFG_Good;

# [[[ OPERATIONS ]]]

# class subtype tests

my arrayref::Perl::Types::Test::Subclass::MySubclassersFG_Good $foo_a = [];
my hashref::Perl::Types::Test::Subclass::MySubclassersFG_Good $foo_h = {};
my arrayref::Perl::Types::Test::Subclass::MySubclasserF_Good $bar_a = [];
my hashref::Perl::Types::Test::Subclass::MySubclasserF_Good $bar_h = {};
my arrayref::Perl::Types::Test::Subclass::MySubclasserG_Good $bat_a = [];
my hashref::Perl::Types::Test::Subclass::MySubclasserG_Good $bat_h = {};
print 'no errors', "\n";

# class default constructor tests

my Perl::Types::Test::Subclass::MySubclassersFG_Good $my_fg = Perl::Types::Test::Subclass::MySubclassersFG_Good->new();
my Perl::Types::Test::Subclass::MySubclasserF_Good $my_f = Perl::Types::Test::Subclass::MySubclasserF_Good->new();
my Perl::Types::Test::Subclass::MySubclasserG_Good $my_g = Perl::Types::Test::Subclass::MySubclasserG_Good->new();

# class default properties tests

print 'have $my_fg->get_bax() = ', $my_fg->get_bax(), "\n";
print 'have $my_f->get_bax() = ', $my_f->get_bax(), "\n";
print 'have $my_f->get_xab() = ', $my_f->get_xab(), "\n";
print 'have $my_g->get_bax() = ', $my_g->get_bax(), "\n";
print 'have $my_g->get_xab() = ', $my_g->get_xab(), "\n";
print 'have $my_g->get_xba() = ', $my_g->get_xba(), "\n";

$my_fg->set_bax(111);
$my_f->set_bax(222);
$my_g->set_bax(333);

print 'have $my_fg->get_bax() = ', $my_fg->get_bax(), "\n";
print 'have $my_f->get_bax() = ', $my_f->get_bax(), "\n";
print 'have $my_g->get_bax() = ', $my_g->get_bax(), "\n";

# subroutine & class method tests

print 'calling $my_fg->multiply_bax_FG(22)...', "\n";
$my_fg->multiply_bax_FG(22);
print 'have $my_fg->get_bax() = ', $my_fg->get_bax(), "\n";
print 'have Perl::Types::Test::Subclass::MySubclassersFG_Good::multiply_return_FG(11, 22) = ', Perl::Types::Test::Subclass::MySubclassersFG_Good::multiply_return_FG(11, 22), "\n";

print 'calling $my_f->multiply_bax_FG(22)...', "\n";
$my_f->multiply_bax_FG(22);
print 'have $my_f->get_bax() = ', $my_f->get_bax(), "\n";
#print 'have Perl::Types::Test::Subclass::MySubclasserF_Good::multiply_return_FG(11, 22) = ', Perl::Types::Test::Subclass::MySubclasserF_Good::multiply_return_FG(11, 22), "\n";  # ERROR HERE, MOVE TO EXPORTER EXAMPLE

print 'calling $my_f->multiply_bax_F(-1)...', "\n";
$my_f->multiply_bax_F(-1);
print 'have $my_f->get_bax() = ', $my_f->get_bax(), "\n";
print 'have Perl::Types::Test::Subclass::MySubclasserF_Good::multiply_return_F(-11, 22) = ', Perl::Types::Test::Subclass::MySubclasserF_Good::multiply_return_F(-11, 22), "\n";

print 'calling $my_g->multiply_bax_FG(q{howdy})...', "\n";
$my_g->multiply_bax_FG(q{howdy});
print 'have $my_g->get_bax() = ', $my_g->get_bax(), "\n";
#print 'have Perl::Types::Test::Subclass::MySubclasserG_Good::multiply_return_FG(11, 22) = ', Perl::Types::Test::Subclass::MySubclasserG_Good::multiply_return_FG(11, 22), "\n";  # ERROR HERE, MOVE TO EXPORTER EXAMPLE

print 'calling $my_g->multiply_bax_F(-1)...', "\n";
$my_g->multiply_bax_F(-1);
print 'have $my_g->get_bax() = ', $my_g->get_bax(), "\n";
#print 'have Perl::Types::Test::Subclass::MySubclasserG_Good::multiply_return_F(-11, 22) = ', Perl::Types::Test::Subclass::MySubclasserG_Good::multiply_return_F(-11, 22), "\n";  # ERROR HERE, MOVE TO EXPORTER EXAMPLE

print 'calling $my_g->multiply_bax_G(-2)...', "\n";
$my_g->multiply_bax_G(-2);
print 'have $my_g->get_bax() = ', $my_g->get_bax(), "\n";
print 'have Perl::Types::Test::Subclass::MySubclasserG_Good::multiply_return_G(-11, 33) = ', Perl::Types::Test::Subclass::MySubclasserG_Good::multiply_return_G(-11, 33), "\n";

print 'still no errors', "\n";

