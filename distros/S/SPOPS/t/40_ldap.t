# -*-perl-*-

# $Id: 40_ldap.t,v 3.2 2004/05/26 01:17:22 lachoy Exp $

use strict;
use constant NUM_TESTS => 37;
use Data::Dumper qw( Dumper );

my $USER_LDAP_CLASS  = 'LDAP_User';
my $GROUP_LDAP_CLASS = 'LDAP_Group';
my $TEST_OU          = 'ou=SPOPSTest';
my $USER_OU          = "ou=Users";
my $GROUP_OU         = "ou=Groups";
my ( $BASE_DN, $USER_BASE_DN, $GROUP_BASE_DN );

my @USER_FIELDS = qw( uid cn sn givenname mail );
my @USER_DATA = (
   [ 'laverne', 'Laverne the Great', 'DaFazio', 'Laverne', 'laverne@beer.com' ],
   [ 'fonzie', 'The Fonz', 'Fonzerelli', 'Arthur', 'fonzie@cool.com' ],
   [ 'lachoy', 'La Choy', 'Choy', 'La', 'lachoy@spoiled.com' ],
   [ 'bofh', 'Joe Shmoe', 'Shmoe', 'Joe', 'dingdong@411.com' ]
);

my ( $ldap, $do_end );
END {
    if ( defined $do_end ) {
        tear_down( $ldap );
        $ldap->unbind;
    }
}

{
    # Read in the config file and make sure we're supposed to run

    do "t/config.pl";
    my $config = _read_config_file() || {};

    require Test::More;
    unless ( $config->{LDAP_base_dn} and $config->{LDAP_host} ) {
        Test::More->import( skip_all => 'Insufficient information to use LDAP for tests' );
    }

    Test::More->import( tests => NUM_TESTS );

    # Tests: 1 - 3

    require_ok( 'Net::LDAP' );
    require_ok( 'SPOPS::LDAP' );
    require_ok( 'SPOPS::Initialize' );

    # Initialize our classes

    $BASE_DN       = "$TEST_OU,$config->{LDAP_base_dn}";
    $USER_BASE_DN  = "$USER_OU,$BASE_DN";
    $GROUP_BASE_DN = "$GROUP_OU,$BASE_DN";
    my $spops_config = {
         user => {
             ldap_base_dn => $USER_BASE_DN,
             class        => $USER_LDAP_CLASS,
             isa          => [ 'SPOPS::LDAP' ],
             field        => [ qw/ uid cn sn givenname mail objectclass / ],
             id_field     => 'uid',
             id_value_field => 'uid',
             field_map    => { user_id => 'uid', first_name => 'givenname' },
             multivalue   => [ 'objectclass' ],
             ldap_object_class => [ qw/ top person inetOrgPerson organizationalPerson / ],
             ldap_fetch_object_class => 'person',
             links_to     => { $GROUP_LDAP_CLASS => 'uniquemember' },
         },
         group => {
             ldap_base_dn => $GROUP_BASE_DN,
             class        => $GROUP_LDAP_CLASS,
             isa          => [ 'SPOPS::LDAP' ],
             field        => [ qw/ cn uniquemember description objectclass / ],
             id_field     => 'cn',
             field_map    => { name => 'cn', notes => 'description' },
             multivalue   => [ 'uniquemember', 'objectclass' ],
             ldap_object_class => [ qw/ top groupOfUniqueNames / ],
             ldap_fetch_object_class => 'groupOfUniqueNames',
             has_a        => { $USER_LDAP_CLASS => 'uniquemember' },
         }

    };

    # Tests: 4 - 6

    my $class_init_list = eval { SPOPS::Initialize->process({ config => $spops_config }) };
    ok( ! $@, 'Initialize process run' );
    my %class_init_map = map { $_ => 1 } @{ $class_init_list };
    is( $class_init_map{ $USER_LDAP_CLASS }, 1, 'Class initialize (user)' );
    is( $class_init_map{ $GROUP_LDAP_CLASS }, 1, 'Class initialize (group)' );

    # Now create the connection

    # Tests: 7 - 8

    $ldap = Net::LDAP->new( $config->{LDAP_host},
                            port    => $config->{LDAP_port} );
    ok( $ldap, 'Connect to directory' );
    my @bind_args = ( $config->{LDAP_bind_dn} )
                      ? ( $config->{LDAP_bind_dn}, password => $config->{LDAP_bind_password} )
                      : ();
    my $ldap_msg = $ldap->bind( @bind_args );
    ok( ! $ldap_msg->code, 'Bind to directory' ); # && die "Cannot bind! Error: ", $msg->error, "\n";

    $do_end++;

    # Cleanup any leftover items

    my $old_items = tear_down( $ldap );
    if ( $old_items ) {
        warn "Cleaned up ($old_items) old entries in LDAP directory\n",
             "(probably leftover from previous halted test run, don't worry)\n";
    }

    setup( $ldap );

    my ( $test_object, $fetch_id );

    # Create a user object

    # Tests: 9 - 12

    my @o = ();
    my $create_error = 0;
    my $data_idx = int( rand scalar @USER_DATA );
    my $data = $USER_DATA[ $data_idx ];
    $test_object = $USER_LDAP_CLASS->new;
    ok( ! $test_object->is_saved, 'Save status of new object' );
    for ( my $j = 0; $j < scalar @USER_FIELDS; $j++ ) {
        $test_object->{ $USER_FIELDS[ $j ] } = $data->[ $j ];
    }
    ok( $test_object->is_changed, 'Change status of modified object' );
    eval { $test_object->save({ ldap => $ldap }) };
    ok( ! $@, 'Create object' );
    ok( $test_object->is_saved, 'Save status of saved object' );
    $fetch_id = $test_object->id;
    undef $test_object;

    # Fetch the object

    # Tests: 13 - 16

    $test_object = eval { $USER_LDAP_CLASS->fetch( $fetch_id, { ldap => $ldap }) };
    ok( ! $@ and $test_object, 'Fetch object (action)' );
    is( $test_object->{mail}, $data->[4], 'Fetch object (content)' );
    ok( $test_object->is_saved, 'Fetch object save status' );
    ok( ! $test_object->is_changed, 'Fetch object change status' );
    my $fetch_filter = "mail=$test_object->{mail}";
    undef $test_object;

    # Fetch the object with a filter

    # Tests: 17 - 18

    $test_object = eval { $USER_LDAP_CLASS->fetch( undef,
                                              { ldap  => $ldap,
                                                filter => $fetch_filter } ) };
    ok( ! $@ and $test_object, 'Fetch object by filter (action)' );
    is( $test_object->{mail}, $data->[4], 'Fetch object by filter (content)' );
    my $fetch_dn = $test_object->dn;
    undef $test_object;

    # Fetch the object with a DN

    # Tests: 19 - 20

    $test_object = eval { $USER_LDAP_CLASS->fetch_by_dn( $fetch_dn, { ldap => $ldap }) };
    ok( ! $@ and $test_object, 'Fetch object by DN (action)' );
    is( $test_object->{mail}, $data->[4], 'Fetch object by DN (content)' );

    # Now update that object

    # Tests: 21 - 24

    $test_object->{cn}   = 'Heavy D';
    $test_object->{mail} = 'slapdash@yahoo.com';
    ok( $test_object->is_changed, 'Change status of modified object' );
    eval { $test_object->save({ ldap => $ldap }) };
    ok( ! $@, 'Update object' );
    ok( ! $test_object->is_changed, 'Change status of updated object' );
    $fetch_id = $test_object->id;
    undef $test_object;
    $test_object = eval { $USER_LDAP_CLASS->fetch( $fetch_id, { ldap => $ldap }) };
    is( $test_object->{cn}, 'Heavy D', 'Update object (content after)' );

    # And update the object so that the 'ldap_update_only_changed' flag is on

    # Tests: 25 - 27

    $test_object->{givenname} = 'monster';
    $test_object->CONFIG->{ldap_update_only_changed} = 1;
    eval { $test_object->save({ ldap => $ldap }) };
    ok( ! $@, 'Update object (only changed fields)' );
    $fetch_id = $test_object->id;
    undef $test_object;
    $test_object = eval { $USER_LDAP_CLASS->fetch( $fetch_id, { ldap => $ldap }) };
    is( $test_object->{givenname}, 'monster','Update object (content after, changed)' );
    is( $test_object->{cn}, 'Heavy D','Update object (content after, unchanged)' );
    undef $test_object;

    # Now add some more

    my $added = 0;
    for ( my $i = 0; $i < scalar @USER_DATA; $i++ ) {
        next if ( $i == $data_idx );
        my $new_object = $USER_LDAP_CLASS->new;
        my $new_data   = $USER_DATA[ $i ];
        for ( my $j = 0; $j < scalar @USER_FIELDS; $j++ ) {
            $new_object->{ $USER_FIELDS[ $j ] } = $new_data->[ $j ];
        }
        eval { $new_object->save({ ldap => $ldap }) };
        $added++;
    }

    # Then fetch them all

    # Tests: 28

    my $object_list = $USER_LDAP_CLASS->fetch_group({ ldap  => $ldap });
    is( scalar @USER_DATA, scalar @{ $object_list }, 'Fetch group of objects' );

    # And fetch them all with an iterator

    # Tests: 29 - 30

    my $ldap_iter = $USER_LDAP_CLASS->fetch_iterator({ ldap => $ldap });
    ok( $ldap_iter->isa( 'SPOPS::Iterator' ), 'Iterator return' );
    my $iter_count = 0;
    while ( my $iterated = $ldap_iter->get_next ) {
        $iter_count++;
    }
    is( scalar @USER_DATA, $iter_count, 'Iterate through objects' );

    # Now add two groups - it looks like Convert::ASN1 whines a little
    # under -w because we're setting uniquemember to an empty list,
    # but we have to do that so the group will meet its schema
    # requirements...

    my $public_group = eval { $GROUP_LDAP_CLASS->new({ cn          => 'public',
                                                       description => 'Public Group',
                                                       uniquemember => [] })
                                               ->save({ ldap => $ldap }) };
    my $admin_group  = eval { $GROUP_LDAP_CLASS->new({ cn           => 'admin',
                                                       description  => 'Admin Group',
                                                       uniquemember => []  })
                                               ->save({ ldap => $ldap }) };

    # Add every user to the public group and every other user to the
    # admin group

    # Tests: 31 - 32

    my $user_iter = $USER_LDAP_CLASS->fetch_iterator({ ldap => $ldap });
    my ( $public_count, $admin_count, $public_ok, $admin_ok ) = ( 0, 0, 0, 0 );
    while ( my $user = $user_iter->get_next ) {
        eval { $public_group->user_add( [ $user ], { ldap => $ldap } ) };
        $public_ok++ unless ( $@ );
        $public_count++;
        if ( $public_count % 2 == 0 ) {
            $admin_group->user_add( [ $user ], { ldap => $ldap } );
            $admin_ok++ unless ( $@ );
            $admin_count++;
        }
    }
    is( $public_ok, $public_count, "Add has_a 1" );
    is( $admin_ok,  $admin_count,  "Add has_a 2" );

    # Now try to fetch them again

    # Tests: 33 - 34

    my $public_user_list = $public_group->user({ ldap => $ldap });
    my $admin_user_list  = $admin_group->user({ ldap => $ldap });

    is( scalar @{ $public_user_list }, $public_ok, "Fetch has_a 1" );
    is( scalar @{ $admin_user_list },  $admin_ok,  "Fetch has_a 1" );

    # And remove all users in the 'admin' group from the 'public' group

    # Test: 35

    my $removed = $public_group->user_remove( $admin_user_list, { ldap => $ldap } );
    is( $public_ok - $admin_ok, $removed, "Remove has_a" );

    # Now every user should link to one group -- see if it's so

    # Test: 36

    my ( $user_count, $group_count ) = ( 0, 0 );
    $user_iter = $USER_LDAP_CLASS->fetch_iterator({ ldap => $ldap });
    while ( my $user = $user_iter->get_next ) {
        my $member_of = eval { $user->group({ ldap => $ldap }) };
        warn $@ if ( $@ );
        $user_count++;
        $group_count += scalar @{ $member_of };
    }
    is( $user_count, $group_count, 'Links to' );

    # Now remove all the users

    # Tests: 37

    my $user_remove = 0;
    foreach my $ldap_object ( @{ $object_list } ) {
        eval { $ldap_object->remove({ ldap => $ldap }) };
        $user_remove++  unless ( $@ );
    }

    is ( $user_remove, scalar @USER_DATA, 'Remove object' );
}

# Create our ou object

sub setup {
    my ( $ldap ) = @_;
    add_ou( $ldap, $BASE_DN,       $TEST_OU, 'SPOPS Testing' );
    add_ou( $ldap, $USER_BASE_DN,  $USER_OU, 'SPOPS Testing Users' );
    add_ou( $ldap, $GROUP_BASE_DN, $GROUP_OU, 'SPOPS Testing Groups' );
}


sub add_ou {
    my ( $ldap, $ou_dn, $ou ,$cn ) = @_;
    my $entry = Net::LDAP::Entry->new( );
    $ou=~s/^ou\=//;
    $entry->add (
       ou => $ou,
       cn => $cn,
       objectClass => [ 'organizationalRole' ]
    );
#    print Dumper($entry);
    $entry->dn( $ou_dn );
#    my $ldap_msg = $ldap->add( $ou_dn,
#             attr => [ objectclass => [ 'organizationalUnit' ],
#             ou          => [ $cn ] ]);
    my $ldap_msg=$entry->update($ldap);
    if ( my $code = $ldap_msg->code ) {
        die "Cannot create OU entry for ($ou_dn) in LDAP\n",
            "Error: ", $ldap_msg->error, " ($code)\n";
    }
}

# Find all the entries and remove them, along with our OU

sub tear_down {
    my ( $ldap ) = @_;
    my $entry_count = 0;
    $entry_count += clear_all( $ldap, $USER_BASE_DN,  'person' );
    $entry_count += clear_all( $ldap, $GROUP_BASE_DN, 'groupOfUniqueNames' );
    my $ldap_msg = $ldap->delete( $BASE_DN );
    return $entry_count if ( $ldap_msg->code );
    return $entry_count + 1;
}


sub clear_all {
    my ( $ldap, $ou_dn, $object_class ) = @_;
    my $ldap_msg = $ldap->search( scope  => 'sub',
                                  base   => $ou_dn,
                                  filter => "objectclass=$object_class" );
    return 0 if ( $ldap_msg->code );
    my $entry_count = 0;
    my @entries = $ldap_msg->entries;
    foreach my $entry ( @entries ) {
        $entry->changetype( 'delete' );
        $entry->update( $ldap );
        $entry_count++;
    }
    $ldap_msg = $ldap->delete( $ou_dn );
    return $entry_count if ( $ldap_msg->code );
    return $entry_count + 1;
}

