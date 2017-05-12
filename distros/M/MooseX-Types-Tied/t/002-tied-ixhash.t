#!/usr/bin/env perl
#
# This file is part of MooseX-Types-Tied
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use strict;
use warnings;

use Test::More;
use Test::Exception;

{
    package TestClass;

    use Moose;
    use MooseX::Types::Tied::Hash::IxHash ':all';

    has ixhash   => (is =>'rw', isa => IxHash);
    has coercing => (is =>'rw', isa => IxHash, coerce => 1);

}

{
    package Test::Tie::Hash;
    use base 'Tie::Hash';

    sub TIEHASH { bless \(my $x), $_[0] }
}

my $foo = TestClass->new();

tie my %hash,   'Test::Tie::Hash';
tie my %ixhash, 'Tie::IxHash';

dies_ok  { $foo->ixhash(\%hash)   } 'IxHash NOK';
dies_ok  { $foo->ixhash({})       } 'IxHash NOK';
lives_ok { $foo->ixhash(\%ixhash) } 'IxHash OK';

# coercions
dies_ok  { $foo->coercing( { one => 1 } ) } 'Does NOT coerce from hashref';
lives_ok { $foo->coercing( [ one => 1 ] ) } 'Coerces from arrayref';

ok(defined tied %{ $foo->coercing }, 'coerced value is tied');

done_testing;
