#!/usr/bin/env perl
use Perl::Types;
use strict;
use warnings;

#use Perl::Type::GMPInteger;

use Perl::Type::GMPInteger_cpp;
Perl::Type::GMPInteger_cpp::cpp_load();

use Data::Dumper;
print Dumper( \%main:: );
#print Dumper(\%Perl::Type::GMPInteger_cpp::);  # BOILERPLATE
#print Dumper(\%Perl::Type::GMPInteger::);  # EMPTY
#print Dumper(\%Perl__Type__GMPInteger::);  # EMPTY

#use perlgmp;
#my gmp_integer $tmp1 = gmp_integer->new();
#gmp_init_set_nonsigned_integer( $tmp1->{value}, 1234567890 );


use Math::BigInt lib => 'GMP';
my $tmp1 = Math::BigInt->new(1234567890);
print 'in gmp_symtab_dump.pl, have gmp_integer_typetest0() = ' . "\n" . gmp_integer_typetest0() . "\n";
print 'in gmp_symtab_dump.pl, have gmp_integer_to_integer($tmp1->{value}) = ' . "\n" . gmp_integer_to_integer($tmp1->{value}) . "\n";
