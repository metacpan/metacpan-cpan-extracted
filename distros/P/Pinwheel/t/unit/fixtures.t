#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 13;

use Pinwheel::Fixtures;


sub fake_hash
{
    return 0;
}


# String hashing
{
    my ($identify);

    $identify = \&Pinwheel::Fixtures::identify;

    is(&$identify(''), 1119235827);
    is(&$identify('a'), 703514648);
    is(&$identify('ab'), 1736856511);
    is(&$identify('abc'), 622741395);
    is(&$identify('abcd'), 1525030821);
    is(&$identify('helloworld' x 3), 2039034227);

    # Hash calculations are cached
    { no warnings 'redefine'; *Pinwheel::Fixtures::_hash = \&fake_hash }
    is(&$identify('abcd'), 1525030821);
    { no warnings 'redefine'; *Pinwheel::Fixtures::_hash = $identify }

    fake_hash(); # (satisfy Devel::Cover)
}

# Fixture helper functions
{
    Pinwheel::Fixtures::_prepare_helpers();
    is_deeply($Pinwheel::Fixtures::helpers, {});

    {
        package Pinwheel::Helpers::Fixtures;
        our @EXPORT_OK = qw(one two);
        sub one { 'ONE' }
        sub two { 'TWO' }
    }

    Pinwheel::Fixtures::_prepare_helpers();
    is_deeply([sort keys %$Pinwheel::Fixtures::helpers], ['one', 'two']);

    @Pinwheel::Helpers::Fixtures::EXPORT_OK = qw(one three);
    Pinwheel::Fixtures::_prepare_helpers();
    is_deeply([sort keys %$Pinwheel::Fixtures::helpers], ['one']);

    @Pinwheel::Helpers::Fixtures::EXPORT_OK = qw(one two three);
    Pinwheel::Fixtures::_prepare_helpers();
    is_deeply([sort keys %$Pinwheel::Fixtures::helpers], ['one', 'two']);

    is($Pinwheel::Fixtures::helpers->{one}(), 'ONE');
    is($Pinwheel::Fixtures::helpers->{two}(), 'TWO');
}
