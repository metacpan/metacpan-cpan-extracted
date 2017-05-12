#!/usr/bin/perl

use strict;
use warnings;

#use lib 't/lib';

#use Moose ();
#use Moose::Util::TypeConstraints;
#use NoInlineAttribute;
use Test::Fatal;
use Test::More;
#use Test::Moose;

{
    my %handles = (
        abs         => 'abs',
        add         => 'add',
        inc         => [ add => 1 ],
        div         => 'div',
        cut_in_half => [ div => 2 ],
        mod         => 'mod',
        odd         => [ mod => 2 ],
        mul         => 'mul',
        set         => 'set',
        sub         => 'sub',
        dec         => [ sub => 1 ],
    );

    my $name = 'Foo1';

    sub build_class {
        my %attr = @_;

        my $class = $name++;

        my @traits = 'String';

        eval qq|
            package $class;

            use Moo;
            use MooX::HandlesVia;
            use MooX::Types::MooseLike::Base qw/Int/;

            has integer => (
                handles_via => 'Number',
                handles => \\%handles,
                is      => 'rw',
                isa     => Int,
                default => sub { 5 },
                clearer => '_clear_integer',
                %attr,
            );

            1;
        |;

        return ( $class, \%handles, \%attr );
    }
}

{
    run_tests(build_class);
    run_tests( build_class( lazy => 1 ) );
    run_tests( build_class( trigger => sub { } ) );
    #run_tests( build_class( no_inline => 1 ) );

    # Will force the inlining code to check the entire hashref when it is modified.
    #subtype 'MyInt', as 'Int', where { 1 };

    #run_tests( build_class( isa => 'MyInt' ) );

    #coerce 'MyInt', from 'Int', via { $_ };

    #run_tests( build_class( isa => 'MyInt', coerce => 1 ) );
}

sub run_tests {
    my ( $class, $handles, $attr) = @_;

    can_ok( $class, $_ ) for sort keys %{$handles};

    my $obj = $class->new;

    is( $obj->integer, 5, 'Default to five' );

    is( $obj->add(10), 15, 'add returns new value' );

    #is( $obj->integer, 15, 'Add ten for fithteen' );
    $obj->integer(15);

    #like( exception { $obj->add( 10, 2 ) }, qr/Cannot call add with more than 1 argument/, 'add throws an error when 2 arguments are passed' );

    is( $obj->sub(3), 12, 'sub returns new value' );
    $obj->integer(12);

    is( $obj->integer, 12, 'Subtract three for 12' );

    #like( exception { $obj->sub( 10, 2 ) }, qr/Cannot call sub with more than 1 argument/, 'sub throws an error when 2 arguments are passed' );

    #is( $obj->set(10), 10, 'set returns new value' );
    $obj->integer(10);

    is( $obj->integer, 10, 'Set to ten' );

    #like( exception { $obj->set( 10, 2 ) }, qr/Cannot call set with more than 1 argument/, 'set throws an error when 2 arguments are passed' );

    is( $obj->div(2), 5, 'div returns new value' );

    $obj->integer(5);
    is( $obj->integer, 5, 'divide by 2' );

    #like( exception { $obj->div( 10, 2 ) }, qr/Cannot call div with more than 1 argument/, 'div throws an error when 2 arguments are passed' );

    is( $obj->mul(2), 10, 'mul returns new value' );
    $obj->integer(10);

    is( $obj->integer, 10, 'multiplied by 2' );

    #like( exception { $obj->mul( 10, 2 ) }, qr/Cannot call mul with more than 1 argument/, 'mul throws an error when 2 arguments are passed' );

    is( $obj->mod(2), 0, 'mod returns new value' );
    $obj->integer(0);

    is( $obj->integer, 0, 'Mod by 2' );

    #like( exception { $obj->mod( 10, 2 ) }, qr/Cannot call mod with more than 1 argument/, 'mod throws an error when 2 arguments are passed' );

    #$obj->set(7);

    $obj->mod(5);
    $obj->integer(2);

    is( $obj->integer, 2, 'Mod by 5' );

    #$obj->set(-1);
    $obj->integer(-1);

    is( $obj->abs, 1, 'abs returns new value' );

    #like( exception { $obj->abs(10) }, qr/Cannot call abs with any arguments/, 'abs throws an error when an argument is passed' );

    $obj->integer(1);
    is( $obj->integer, 1, 'abs 1' );

    $obj->integer(12);
    #$obj->set(12);

    $obj->inc;

    is( $obj->inc, 13, 'inc 12' );

    $obj->dec;

    is( $obj->dec, 11, 'dec 13' );

    #if ( $attr->{lazy} ) {
        #my $obj = $class->new;

        #$obj->add(2);

        #is( $obj->add, 7, 'add with lazy default' );

        #this probably should work. need some interface to moo internals..
        #$obj->_clear_integer;

        #$obj->mod(2);

        #is( $obj->mod, 1, 'mod with lazy default' );
    #}
}

done_testing;
