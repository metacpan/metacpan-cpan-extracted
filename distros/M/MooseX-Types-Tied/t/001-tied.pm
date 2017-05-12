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

use Tie::Array;
use Tie::Hash;

{
    package TestClass;

    use Moose;
    use MooseX::Types::Tied ':all';

    no strict 'refs';
    has lc($_) => (is => 'rw', isa => &$_())
        for qw{ Tied TiedHash TiedArray TiedHandle };
}

{
    package Test::Tie::Hash;
    use base 'Tie::Hash';

    sub TIEHASH { bless \(my $x), $_[0] }
}
{
    package Test::Tie::Array;
    use base 'Tie::Array';

    sub TIEARRAY { bless \(my $x), $_[0] }
}
{
    package Test::Tie::Scalar;
    use base 'Tie::Scalar';

    sub TIESCALAR { bless \(my $x), $_[0] }
    sub FETCH { 1 }
}
{
    package Test::Tie::Handle;
    use base 'Tie::Handle';

    sub TIEHANDLE { bless \(my $x), $_[0] }
    sub READ { }
}

my $foo = TestClass->new();

{
    tie my %hash, 'Test::Tie::Hash';
    lives_ok { $foo->tiedhash(\%hash) } 'TieHash OK';
    dies_ok  { $foo->tiedhash({}) }     'TieHash NOK';
}

{
    tie my @array, 'Test::Tie::Array';
    lives_ok { $foo->tiedarray(\@array) } 'TieArray OK';
    dies_ok  { $foo->tiedarray([]) }      'TieArray NOK';
}

{
    tie my $scalar, 'Test::Tie::Scalar';
    my $untied = 1;
    lives_ok { $foo->tied(\$scalar) } 'TieScalar OK';
    dies_ok  { $foo->tied(\$untied) } 'TieScalar NOK';
}

{
    my $tied = \*DATA;
    tie $$tied, 'Test::Tie::Handle';
    my $untied = \*STDOUT;
    lives_ok { $foo->tiedhandle($tied)   } 'TieHandle OK';
    dies_ok  { $foo->tiedhandle($untied) } 'TieHandle NOK';
}

done_testing;

__DATA__

Nothing to see here, move along...
