# -*-perl-*-

# $Id: 80_security.t,v 1.3 2004/02/26 02:02:29 lachoy Exp $

use strict;
use lib qw( t/ );
use Test::More tests => 39;

do "t/config.pl";

BEGIN { use_ok( 'SPOPS::Secure', qw( :level :scope ) ) }

{
    my %config = (
      test => {
         class      => 'DummyTest',
         isa        => [ 'SecurityCommon', 'SPOPS::Secure', 'SPOPS::Loopback' ],
         field      => [ qw( myid name ) ],
         id_field   => 'myid',
         creation_security => {
            u => 'WRITE',
            g   => { 2 => 'WRITE' },
            w   => 'READ',
         },
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
    is( $creation_security->{u}, 'WRITE', 'User creation security specified' );
    is( $creation_security->{g}{2}, 'WRITE', 'Group creation security specified' );
    is( $creation_security->{w}, 'READ', 'Group creation security specified' );

    DummyTest->set_security_class( 'SecurityTest' );

    # First create a few groups
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

    # Now create a few dummy objects as various users
    eval {
        DummyTest->set_user( $user_admin );
        DummyTest->set_group( $grp_admin );
        DummyTest->new({ myid => 1, name => 'Primo' })->save();
        DummyTest->set_user( $user_snoopy );
        DummyTest->set_group( $grp_manager );
        DummyTest->new({ myid => 2, name => 'Secondo' })->save();
        DummyTest->set_user( $user_chuck );
        DummyTest->set_group( $grp_public );
        DummyTest->new({ myid => 3, name => 'Trio' })->save();
    };
    diag( "Dummy create failed: $@" ) if ( $@ );
    ok( ! $@, "Dummy objects created ok" );

    # Retrieve the dummy objects and ensure the security level is set
    # properly when we set the user for each

    DummyTest->set_group( undef );

    DummyTest->set_user( $user_admin );
    my $du_one   = eval { DummyTest->fetch(1) };
    ok( ! $@, "No security violation user 1" );
    is( $du_one->{tmp_security_level}, SEC_LEVEL_WRITE, "Fetched security user level 1" );

    DummyTest->set_user( $user_chuck );
    my $du_two   = eval { DummyTest->fetch(2) };
    ok( ! $@, "No security violation user 2" );
    is( $du_two->{tmp_security_level}, SEC_LEVEL_READ, "Fetched security user level 2" );

    DummyTest->set_user( $user_snoopy );
    my $du_three = eval { DummyTest->fetch(3) };
    ok( ! $@, "No security violation user 3" );
    is( $du_three->{tmp_security_level}, SEC_LEVEL_READ, "Fetched security user level 3" );

    # Retrieve the dummy objects and ensure the security level is set
    # properly when we set the group to admin

    DummyTest->set_group( $grp_manager );
    DummyTest->set_user( undef );

    my $dg_one   = eval { DummyTest->fetch(1) };
    ok( ! $@, "No security violation group 1" );
    is( $dg_one->{tmp_security_level}, SEC_LEVEL_WRITE, "Fetched security group level 1" );

    my $dg_two   = eval { DummyTest->fetch(2) };
    ok( ! $@, "No security violation group 2" );
    is( $dg_two->{tmp_security_level}, SEC_LEVEL_WRITE, "Fetched security group level 2" );

    my $dg_three = eval { DummyTest->fetch(3) };
    ok( ! $@, "No security violation group 3" );
    is( $dg_three->{tmp_security_level}, SEC_LEVEL_WRITE, "Fetched security group level 3" );


    # Now fetch some security objects and check them out

    my $security_one   = SecurityTest->fetch_group({ where => 'object_id = 1' });
    my $security_two   = SecurityTest->fetch_group({ where => 'object_id = 2' });
    my $security_three = SecurityTest->fetch_group({ where => 'object_id = 3' });

    is( scalar @{ $security_one }, 3, 'Number of security objects 1' );
    is( check_user( $security_one, 1 ), SEC_LEVEL_WRITE, 'User settings 1' );
    is( check_group( $security_one, 2 ), SEC_LEVEL_WRITE, 'Group settings 1' );
    is( check_world( $security_one ), SEC_LEVEL_READ, 'World settings 1' );

    is( scalar @{ $security_two }, 3, 'Number of security objects 2' );
    is( check_user( $security_two, 2 ), SEC_LEVEL_WRITE, 'User settings 2' );
    is( check_group( $security_two, 2 ), SEC_LEVEL_WRITE, 'Group settings 2' );
    is( check_world( $security_two ), SEC_LEVEL_READ, 'World settings 2' );

    is( scalar @{ $security_three }, 3, 'Number of security objects 3' );
    is( check_user( $security_three, 3 ), SEC_LEVEL_WRITE, 'User settings 3' );
    is( check_group( $security_three, 2 ), SEC_LEVEL_WRITE, 'Group settings 3' );
    is( check_world( $security_three ), SEC_LEVEL_READ, 'World settings 3' );

    my $s_world_one = SecurityTest->fetch_match( $du_one, { scope => SEC_SCOPE_WORLD } );
    is( $s_world_one->{security_level}, SEC_LEVEL_READ, 'Fetch match world 1' );
    my $s_one_user = SecurityTest->fetch_match( $du_one, { scope => SEC_SCOPE_USER,
                                                           scope_id => 1 } );
    is( $s_one_user->{security_level}, SEC_LEVEL_WRITE, 'Fetch match user 1' );

}

sub check_user {
    my ( $security, $user_id ) = @_;
    for ( @{ $security } ) {
        if ( $_->{scope} eq SEC_SCOPE_USER and $_->{scope_id} eq $user_id ) {
            return $_->{security_level};
        }
    }
    return undef;
}

sub check_group {
    my ( $security, $group_id ) = @_;
    for ( @{ $security } ) {
        if ( $_->{scope} eq SEC_SCOPE_GROUP and $_->{scope_id} eq $group_id ) {
            return $_->{security_level};
        }
    }
    return undef;
}

sub check_world {
    my ( $security ) = @_;
    for ( @{ $security } ) {
        if ( $_->{scope} eq SEC_SCOPE_WORLD ) {
            return $_->{security_level};
        }
    }
    return undef;
}
