#!/usr/bin/env perl
use 5.008001;
use strictures 2;
use Test2::V0;

{
    package Foo;
    use 5.008001;
    use strictures 2;

    use Moo;
    with 'MooX::Rebuild';
    has get_bar => ( is=>'ro', init_arg=>'bar' );
    has baz => ( is=>'ro' );
}

my $orig = Foo->new( bar=>11, baz=>22 );

my $clone1 = $orig->rebuild();
is( $clone1->get_bar(), 11, 'cloned attribute with different init_arg' );
is( $clone1->baz(), 22, 'cloned attribute with same init_arg' );

my $clone2 = $orig->rebuild( baz=>33 );
is( $clone2->get_bar(), 11, 'cloned attribute with different init_arg' );
is( $clone2->baz(), 33, 'cloned attribute with same init_arg, but custom value' );

done_testing;
