# -*-perl-*-

# $Id: 81_security_hierarchical.t,v 1.2 2004/02/26 02:02:29 lachoy Exp $

use strict;
use lib qw( t/ );
use Test::More tests => 26;
use Data::Dumper qw( Dumper );

do "t/config.pl";

BEGIN {
    use_ok( 'SPOPS::Secure', qw( :level :scope ) );
    use_ok( 'SPOPS::Secure::Hierarchy', qw( $ROOT_OBJECT_NAME ) );
}

{
    my %config = (
      test => {
         class               => 'DummyTest',
         isa                 => [ 'SecurityCommon',
                                  'SPOPS::Secure::Hierarchy',
                                  'SPOPS::Loopback' ],
         field               => [ qw( myid name ) ],
         id_field            => 'myid',
         hierarchy_separator => '/',
         hierarchy_field     => 'myid',
         creation_security   => {},
      },
      security => {
         class      => 'SecurityTest',
         isa        => [ 'SPOPS::Key::Random', 'SPOPS::Secure::Loopback', 'SPOPS::Loopback' ],
         field      => [ qw/ sid object_id class scope scope_id security_level / ],
         id_field   => 'sid',
      },
      user => {
         class      => 'UserTest',
         isa        => [ 'SPOPS::Loopback' ],
         field      => [ qw/ user_id login_name group_id / ],
         id_field   => 'user_id',
      },
      group => {
         class      => 'GroupTest',
         isa        => [ 'SPOPS::Loopback' ],
         field      => [ qw/ group_id name / ],
         id_field   => 'group_id',
      },
    );

    # Create our test class using the loopback

    require_ok( 'SPOPS::Initialize' );

    my $class_init_list = eval { SPOPS::Initialize->process({ config => \%config }) };
    diag( "Error initializing: $@" ) if ( $@ );
    ok( ! $@, "Initialize process run" );
    my %class_init_map = map { $_ => 1 } @{ $class_init_list };
    ok( $class_init_map{DummyTest}, 'Object class initialized' );
    ok( $class_init_map{SecurityTest}, 'Security object class initialized' );
    ok( $class_init_map{UserTest}, 'User object class initialized' );
    ok( $class_init_map{GroupTest}, 'Group object class initialized' );

    my $creation_security = DummyTest->creation_security;
    is( DummyTest->CONFIG->{hierarchy_separator}, '/', 'Hierarchy separator specified' );
    is( DummyTest->CONFIG->{hierarchy_field}, 'myid', 'Hierarchy separator specified' );

    DummyTest->set_security_class( 'SecurityTest' );

    # Create a few users and groups

    eval {
        GroupTest->new({ group_id => 1, name => 'admin' })->save();   # supergroup
        GroupTest->new({ group_id => 2, name => 'manager' })->save();
        GroupTest->new({ group_id => 3, name => 'public' })->save();
    };
    ok( ! $@, "Groups created ok" );

    # Now a few users
    eval {
        UserTest->new({ user_id => 1, login_name => 'admin',          # superuser
                        group_id => 1 })->save();
        UserTest->new({ user_id => 2, login_name => 'snoopy',
                        group_id => 2 })->save();
        UserTest->new({ user_id => 3, login_name => 'charlie',
                        group_id => 3 })->save();
    };
    ok( ! $@, "Users created ok" );

    my $user_admin  = UserTest->fetch(1);
    my $grp_admin   = GroupTest->fetch(1);
    my $user_snoopy = UserTest->fetch(2);
    my $grp_manager = GroupTest->fetch(2);
    my $user_chuck  = UserTest->fetch(3);
    my $grp_public  = GroupTest->fetch(3);

    # Now create a few dummy objects
    eval {
        DummyTest->new({ myid => '/root/first',
                         name => 'Primo' })->save();
        DummyTest->new({ myid => '/root/first/second',
                         name => 'Secondo' })->save();
        DummyTest->new({ myid => '/root/first/second/third',
                         name => 'Trio' })->save();
    };
    ok( ! $@, "Dummy objects created ok" );

    # Create security for the root object

    eval { DummyTest->create_root_object_security({
               scope => [ SEC_SCOPE_WORLD, SEC_SCOPE_GROUP ],
               level => { SEC_SCOPE_WORLD() => SEC_LEVEL_READ,
                          SEC_SCOPE_GROUP() => { 2 => SEC_LEVEL_WRITE } },
    }) };
    ok( ! $@, "Security for root of hierarchy created" );
    my $objects = SecurityTest->fetch_group();
    for ( @{ $objects } ) {
        if ( $_->{scope} eq SEC_SCOPE_WORLD ) {
            is( $_->{security_level}, SEC_LEVEL_READ, "Security for root at WORLD" );
            is( $_->{object_id}, $ROOT_OBJECT_NAME, "Security ID for root at WORLD" );
        }
        elsif ( $_->{scope} eq SEC_SCOPE_GROUP ) {
            is( $_->{security_level}, SEC_LEVEL_WRITE, "Security for group at WORLD" );
            is( $_->{object_id}, $ROOT_OBJECT_NAME, "Security ID for group at WORLD" );
            is( $_->{scope_id}, 2, "Security scope ID for group at WORLD" );
        }
    }

    DummyTest->set_user( $user_snoopy );
    DummyTest->set_group( undef );
    my $du_one = DummyTest->fetch( '/root/first' );
    is( $du_one->{tmp_security_level}, SEC_LEVEL_READ, 'Security for object 1 for WORLD' );
    my $du_two = DummyTest->fetch( '/root/first/second' );
    is( $du_two->{tmp_security_level}, SEC_LEVEL_READ, 'Security for object 2 for WORLD' );

    DummyTest->set_group( $grp_manager );
    my $dg_one = DummyTest->fetch( '/root/first' );
    is( $dg_one->{tmp_security_level}, SEC_LEVEL_WRITE, 'Security for object 1 for manager' );
    my $dg_two = DummyTest->fetch( '/root/first/second' );
    is( $dg_two->{tmp_security_level}, SEC_LEVEL_WRITE, 'Security for object 2 for manager' );

    # Set security for object 2...

    eval { $dg_two->set_security({ scope => SEC_SCOPE_WORLD,
                                   level => SEC_LEVEL_WRITE }) };
    ok( ! $@, "Set security for object 2" );

    DummyTest->set_group( undef );
    my $dut_one = DummyTest->fetch( '/root/first/second' );
    is( $dut_one->{tmp_security_level}, SEC_LEVEL_WRITE, 'Security for object 2 for WORLD (after set)' );
    my $dut_two = DummyTest->fetch( '/root/first/second/third' );
    is( $dut_two->{tmp_security_level}, SEC_LEVEL_WRITE, 'Security for object 3 for WORLD (after set)' );
}
