use strict;
use warnings;

use FindBin qw( $Bin );
use lib $Bin;
require util;

use Test::More tests => 4;

use Class::Load qw( try_load_class );

use MooseX::Test::Role;

my $ok;
my $msg;
local $MooseX::Test::Role::ok = sub {
    ( $ok, $msg ) = @_;
};

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
            required_methods => [qw/ a b c/],
        );

        requires_ok( $role, 'a' );
        ok( $ok, 'should match single items' );
        is( $msg, $role . ' requires a', 'single match test name' );

        requires_ok( $role, 'a', 'b' );
        ok( $ok, 'should match 2 items' );
        is( $msg, $role . ' requires a, b', '2 methods test name' );

        requires_ok( $role, 'a', 'b', 'c' );
        ok( $ok, 'should match 3 items' );
        is( $msg, $role . ' requires a, b, c', '3 methods test name' );

        requires_ok( $role, 'd' );
        ok( !$ok, 'can fail on single items' );
        is( $msg, $role . ' requires d', 'single match failure test name' );

        requires_ok( $role, 'b', 'd' );
        ok( !$ok, 'can fail with one passing and one missing method' );
        is(
            $msg,
            $role . ' requires b, d',
            '2 methods match failure test name'
        );
    }
}

sub test_bad_arguments {
    requires_ok( 'asdf', 'a' );
    ok( !$ok, 'fails on non-classes' );
    is( $msg, 'asdf requires a', 'test name for non-class failure' );

    requires_ok( 'main', 'a' );
    ok( !$ok, 'fails on non-roles' );
    is( $msg, 'main requires a', 'test name for non-role failure' );
}

