#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 8;
use Test::Moose;

{
    package Class1;
    use Moose;
    use MooseX::Aliases;
    sub method1 { "A" }
    alias method2 => "method1";
    around method1 => sub { "B" };
}

{
    package Class2;
    use Moose;
    use MooseX::Aliases;
    sub method1 { "A" }
    alias method2 => "method1";
    around method2 => sub { "B" };
}

with_immutable {

    is( 'Class1'->method1, 'B' );
    is( 'Class1'->method2, 'B' );
    is( 'Class2'->method1, 'A' );
    is( 'Class2'->method2, 'B' );

} qw( Class1 Class2 );
