#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;

{
    package MyClass;
    use Moose;
    use MooseX::SingleArg;

    single_arg 'arg2';

    has arg1 => (
        is  => 'ro',
        isa => 'Str',
    );

    has arg2 => (
        is  => 'ro',
        isa => 'Str',
    );
}

{
    my $obj = MyClass->new();
    is( $obj->arg1(), undef, '() sets arg1 to undef' );
    is( $obj->arg2(), undef, '() sets arg2 to undef' );
}

{
    my $obj = MyClass->new( arg1 => 123 );
    is( $obj->arg1(), 123, '(arg1 => 123) sets arg1 to 123' );
    is( $obj->arg2(), undef, '(arg1 => 123) sets arg2 to undef' );
}

{
    my $obj = MyClass->new( arg2 => 456 );
    is( $obj->arg1(), undef, '(arg2 => 456) sets arg1 to undef' );
    is( $obj->arg2(), 456, '(arg2 => 456) sets arg2 to 456' );
}

{
    my $obj = MyClass->new( arg1 => 123, arg2 => 456 );
    is( $obj->arg1(), 123, '(arg1 => 123, arg2 => 456) sets arg1 to 123' );
    is( $obj->arg2(), 456, '(arg1 => 123, arg2 => 456) sets arg2 to 456' );
}

{
    my $obj = MyClass->new( 789 );
    is( $obj->arg1(), undef, '( 789 ) sets arg1 to undef' );
    is( $obj->arg2(), 789, '( 789 ) sets arg2 to 789' );
}

{
    package MyRole;
    use Moose::Role;
    use MooseX::SingleArg;
    single_arg 'blah';
    has blah => (
        is => 'ro',
        isa => 'Str',
    );
}

{
    package MyClass2;
    use Moose;
    with 'MyRole';
}

{
    my $obj = MyClass2->new( 55 );
    is( $obj->blah(), 55, 'works with roles too' );
}

like(
    dies {
        package Broken;
        use Moose;
        use MooseX::SingleArg;
        single_arg 'foo';
        single_arg 'bar';
    },
    qr{single arg has already been declared},
    'declaring more than one single arg errors',
);

done_testing;
