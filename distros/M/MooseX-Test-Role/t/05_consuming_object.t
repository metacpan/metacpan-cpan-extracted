use strict;
use warnings;

use FindBin qw( $Bin );
use lib $Bin;
require util;

use Test::More tests => 4;
use Class::Load qw( try_load_class );
use Scalar::Util qw( blessed );

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

        my $modifier_support = 1;
        if ($type eq 'Role::Tiny' && !try_load_class('Class::Method::Modifiers')) {
            $modifier_support = 0;
        }

        my %make_role_args = (
            type             => $type,
            required_methods => ['c', 'appender'],
            methods          => [ 'sub a { "return a" }', ],
        );
        if ($modifier_support) {
            $make_role_args{extra} = q[
                around 'appender' => sub {
                    my ($orig, $self) = @_;
                    return ( $self->$orig(), 'appended' );
                };
            ];
        }
        my $role = util::make_role(%make_role_args);

        my $consumer = consuming_object($role);

        if ($type ne 'Role::Tiny') {
            ok(blessed($consumer), 'should return a blessed reference');
        }

        ok( $consumer, 'consuming_object should return something' );
        ok( $consumer->does($role),
            'consuming_object should return an object that consumes the role' );
        is( $consumer->a, 'return a',
            'role methods can be called on the object' );

        if ($modifier_support) {
            is_deeply( [$consumer->appender()], [undef, 'appended'], 'around\'s should work' );
        }

        $consumer = consuming_object(
            $role,
            methods => {
                b => sub { 'from b' }
            }
        );
        is( $consumer->b, 'from b',
            'extra object methods can be passed to consuming_object' );

        $consumer = consuming_object($role);
        can_ok( $consumer, 'c' );
        is( $consumer->c, undef, 'default required methods return undef' );

        $consumer = consuming_object(
            $role,
            methods => {
                c => sub { 'custom c' }
            }
        );
        is( $consumer->c, 'custom c', 'explicit methods override the default' );

        $consumer = consuming_object(
            $role,
            methods => {
                d => 'from d'
            }
        );
        is( $consumer->d, 'from d',
            'scalar values can be passed to consuming_object to create object methods' );

        if ($modifier_support) {
            $consumer = consuming_object(
                $role,
                methods => {
                    appender => sub { 'x' }
                }
            );
            is_deeply( [$consumer->appender()], ['x', 'appended'], 'around\'s should wrap passed in methods' );
        }
    }
}

sub test_bad_arguments {
    eval { consuming_object('asdf'); };
    like(
        $@,
        qr/first argument should be a role/,
        'consuming_object should die when passed something that\'s not a role'
    );

    eval { consuming_object(__PACKAGE__); };
    like(
        $@,
        qr/first argument should be a role/,
        'consuming_object should die when passed something that\'s not a role'
    );
}

