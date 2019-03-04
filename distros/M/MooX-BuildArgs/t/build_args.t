#!/usr/bin/env perl
use 5.008001;
use strictures 2;
use Test2::V0;

{
    package Foo;
    use 5.008001;
    use strictures 2;

    use Moo;
    with 'MooX::BuildArgs';
    has get_bar => ( is=>'ro', init_arg=>'bar' );
    has baz => ( is=>'ro' );
}

my $obj = Foo->new( bar=>11, baz=>22 );

is(
    $obj->build_args(),
    { bar=>11, baz=>22 },
);

done_testing;
