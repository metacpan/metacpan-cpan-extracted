use strict;
use warnings;

use FindBin qw( $Bin );
use lib $Bin;

use Test::More tests => 3;
use Class::Load qw( try_load_class );
use Scalar::Util qw( blessed );

use MooseX::Test::Role;

subtest 'Moose'      => sub { test_role_type( 'Moose::Role', 'moose_role' ) };
subtest 'Moo'        => sub { test_role_type( 'Moo::Role',   'moo_role' ) };
subtest 'Role::Tiny' => sub { test_role_type( 'Role::Tiny',  'role_tiny' ) };

sub test_role_type {
    my $type = shift;
    my $role = shift;

  SKIP: {
        if ( !try_load_class($type) ) {
            skip "$type not installed", 3;
        }

        my $consumer = consuming_class($role);
        ok( !blessed($consumer), 'should not return a a blessed reference' );
        ok( $consumer,           'consuming_class should return something' );
        ok( $consumer->does($role),
            'consuming_class should return an object that consumes the role' );
    }
}
