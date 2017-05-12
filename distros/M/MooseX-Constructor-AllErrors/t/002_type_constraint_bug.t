#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;
use Test::Fatal;
use Test::Moose;

{
    use Moose::Util::TypeConstraints;

    subtype 'ShortStr', as 'Str', where { length($_) < 3 };

    no Moose::Util::TypeConstraints;
}

{
    package Foo;
    use Moose;
    use MooseX::Constructor::AllErrors;
    has short_str => (
        is  => 'ro',
        isa => 'ShortStr',
    );
}

{
    package Bar;
    use Moose;
    has short_str => (
        is  => 'ro',
        isa => 'ShortStr',
    );
}

with_immutable
{
    ok ! exception {
        Bar->new( short_str => 'a')
    }, 'Instance of Test Class without MooseX::Constructor::AllErrors lives';

    ok exception {
        Bar->new( short_str => 'aaaaaaaa' );
    }, '... and dies with incorrect input ( Type Constraint is effective )';

    ok ! exception {
        Foo->new( short_str => 'a')
    }, 'Instance of Test Class WITH MooseX::Constructor::AllErrors lives';
}
qw(Foo Bar);
