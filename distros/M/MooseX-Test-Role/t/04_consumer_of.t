use strict;
use warnings;

use FindBin qw( $Bin );
use lib $Bin;
require util;

use Test::More tests => 4;
use Class::Load qw( try_load_class );

use MooseX::Test::Role;

subtest 'Moose'      => sub { test_role_type('Moose::Role') };
subtest 'Moo'        => sub { test_role_type('Moo::Role') };
subtest 'Role::Tiny' => sub { test_role_type('Role::Tiny') };
subtest 'Bad arguments' => \&test_bad_arguments;

sub test_role_type {
    my $type = shift;

  SKIP: {
        if ( !try_load_class($type) ) {
            skip "$type not installed", 7;
        }

        my $role = util::make_role(
            type             => $type,
            required_methods => ['c'],
            methods          => [ 'sub a { "return a" }', ]
        );

        my $consumer = consumer_of($role);
        ok( $consumer, 'consumer_of should return something' );
        ok( $consumer->does($role),
            'consumer_of should return an object that consumes the role' );
        is( $consumer->a, 'return a',
            'role methods can be called on the object' );

        $consumer = consumer_of( $role, b => sub { 'from b' } );
        is( $consumer->b, 'from b',
            'extra object methods can be passed to consumer_of' );

        $consumer = consumer_of($role);
        can_ok( $consumer, 'c' );
        is( $consumer->c, undef, 'default required methods return undef' );

        $consumer = consumer_of( $role, c => sub { 'custom c' } );
        is( $consumer->c, 'custom c', 'explicit methods override the default' );
    }
}

sub test_bad_arguments {
    eval { consumer_of('asdf'); };
    like(
        $@,
        qr/first argument to consumer_of should be a role/,
        'consumer_of should die when passed something that\'s not a role'
    );

    eval { consumer_of( __PACKAGE__ ); };
    like(
        $@,
        qr/first argument to consumer_of should be a role/,
        'consumer_of should die when passed something that\'s not a role'
    );
}

