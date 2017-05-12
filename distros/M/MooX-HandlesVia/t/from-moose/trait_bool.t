#!/usr/bin/perl

use strict;
use warnings;

#use lib 't/lib';

#use Moose ();
#use Moose::Util::TypeConstraints;
#use NoInlineAttribute;
use Test::More;
use Test::Fatal;
#use Test::Moose;

{
    my %handles = (
        illuminate  => 'set',
        darken      => 'unset',
        flip_switch => 'toggle',
        is_dark     => 'not',
    );

    my $name = 'Foo1';

    sub build_class {
        my %attr = @_;

        eval qq|
            package $name;

            use Moo;
            use MooX::HandlesVia;
            use MooX::Types::MooseLike::Base qw/Bool/;

            has is_lit => (
                handles_via => 'Bool',
                handles => \\%handles,
                isa => Bool,
                is      => 'rw',
                default => sub { 0 },
                clearer => '_clear_is_list',
                \%attr,
            );

            1;
        |;

        return ( $name++, \%handles );
    }
}

{
    run_tests(build_class);
    run_tests( build_class( lazy => 1 ) );
    run_tests( build_class( trigger => sub { } ) );
    run_tests( build_class( no_inline => 1 ) );

    # Will force the inlining code to check the entire hashref when it is modified.
    #subtype 'MyBool', as 'Bool', where { 1 };

    #run_tests( build_class( isa => 'MyBool' ) );

    #coerce 'MyBool', from 'Bool', via { $_ };

    #run_tests( build_class( isa => 'MyBool', coerce => 1 ) );
}

sub run_tests {
    my ( $class, $handles ) = @_;

    can_ok( $class, $_ ) for sort keys %{$handles};

    my $obj = $class->new(is_lit => 1);

    #ok( $obj->illuminate, 'set returns true' );
    ok( $obj->is_lit,   'set is_lit to 1 using ->illuminate' );
    ok( !$obj->is_dark, 'check if is_dark does the right thing' );

    #like( exception { $obj->illuminate(1) }, qr/Cannot call set with any arguments/, 'set throws an error when an argument is passed' );

    $obj = $class->new(is_lit => 0);
    #ok( !$obj->darken, 'unset returns false' );
    ok( !$obj->is_lit, 'set is_lit to 0 using ->darken' );
    ok( $obj->is_dark, 'check if is_dark does the right thing' );

    #like( exception { $obj->darken(1) }, qr/Cannot call unset with any arguments/, 'unset throws an error when an argument is passed' );

    $obj = $class->new(is_lit => 1);
    #ok( $obj->flip_switch, 'toggle returns new value' );
    ok( $obj->is_lit,   'toggle is_lit back to 1 using ->flip_switch' );
    ok( !$obj->is_dark, 'check if is_dark does the right thing' );

    #like( exception { $obj->flip_switch(1) }, qr/Cannot call toggle with any arguments/, 'toggle throws an error when an argument is passed' );

    #$obj->flip_switch;
    $obj = $class->new(is_lit => 0);
    ok( !$obj->is_lit,
        'toggle is_lit back to 0 again using ->flip_switch' );
    ok( $obj->is_dark, 'check if is_dark does the right thing' );
}

done_testing;
