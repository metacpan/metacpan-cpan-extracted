#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

BEGIN { use_ok('MooseX::BuildArgs') }

{
    package MyClass;
    use Moose;

    use MooseX::BuildArgs;
    use Moose::Util::TypeConstraints;

    subtype 'Bar',
        as 'HashRef',
        where { exists $_->{bar} };

    coerce 'Bar',
        from 'Str',
        via { { bar=>$_ } };

    has foo => ( is=>'ro', isa=>'Str', default=>2 );
    has bar => ( is=>'ro', isa=>'Bar', coerce=>1 );
    has baz => ( is=>'ro', isa=>'Str', lazy_build=>1 );
    sub _build_baz { 64 }
}

{
    my $obj = MyClass->new();

    is_deeply(
        $obj->build_args(),
        {},
        'build_args is empty with no arguments passed',
    );
}

{
    my $obj = MyClass->new( foo=>32, bar=>'blue' );

    is_deeply(
        $obj->build_args(),
        { foo=>32, bar=>'blue' },
        'build_args recorded arguments and pre-coercion values',
    );

    is_deeply(
        $obj->bar(),
        { bar=>'blue' },
        'coercion is working (sanity check)',
    );
}

{
    package MyRole;
    use Moose::Role;
    use MooseX::BuildArgs;
}

{
    package MyClass2;
    use Moose;
    with 'MyRole';
}

{
    my $obj = MyClass2->new( foo=>55, bar=>'baz' );
    is_deeply(
        $obj->build_args(),
        { foo=>55, bar=>'baz' },
        'works with roles too',
    );
}

done_testing;
