#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

BEGIN { use_ok('MooseX::ExtraArgs') }

{
    package MyClass;
    use Moose;

    use MooseX::ExtraArgs;

    has foo => ( is=>'ro', isa=>'Str' );
}

{
    my $obj = MyClass->new();

    is_deeply(
        $obj->extra_args(),
        {},
        'extra_args is empty with no arguments passed',
    );
}

{
    my $obj = MyClass->new( foo=>32 );

    is_deeply(
        $obj->extra_args(),
        {},
        'extra_args is empty with when only known arguments are passed',
    );
}

{
    my $obj = MyClass->new( foo=>32, bar=>23 );

    is_deeply(
        $obj->extra_args(),
        { bar => 23 },
        'extra_args contains an unknown argument',
    );
}

{
    package MyRole;
    use Moose::Role;
    use MooseX::ExtraArgs;
}

{
    package MyClass2;
    use Moose;

    with 'MyRole';

    has foo => ( is=>'ro', isa=>'Str' );
}

{
    my $obj = MyClass2->new( foo=>55, bar=>'baz' );
    is_deeply(
        $obj->extra_args(),
        { bar=>'baz' },
        'works with roles too',
    );
}

done_testing;
