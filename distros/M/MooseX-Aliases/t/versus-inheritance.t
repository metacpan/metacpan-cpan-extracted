#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 12;
use Test::Moose;

{
    package Parent;
    use Moose;
    use MooseX::Aliases;
    sub method1 { "A" }
    alias method2 => "method1";
}

{
    package Child1;
    use Moose;
    extends "Parent";
    sub method1 { "B" }
}

{
    package Child2;
    use Moose;
    extends "Parent";
    sub method2 { "C" }
}

with_immutable {

    is( 'Parent'->method1, 'A' );
    is( 'Parent'->method2, 'A' );
    is( 'Child1'->method1, 'B' );
    is( 'Child1'->method2, 'B' );
    is( 'Child2'->method1, 'A' );
    is( 'Child2'->method2, 'C' );

} qw( Parent Child1 Child2 );
