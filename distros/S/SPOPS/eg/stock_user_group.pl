#!/usr/bin/perl

# $Id: stock_user_group.pl,v 3.2 2004/01/10 02:49:58 lachoy Exp $

# stock_user_group.pl
#
#   Create sample users, groups and relationships using the SQL
#   definitions and objects found in SPOPS/eg

use strict;
use Data::Dumper qw( Dumper );
use Log::Log4perl;
Log::Log4perl::init( 'log4perl.conf' );

require My::Security;
require My::User;

my @USER_FIELD  = qw( email last_name first_name password login_name );
my @USER_DATA   = (
                   [ 'superuser@myco.com', 'user', 'super', 'password', 'superuser' ],
                   ( map { [ "$_\@myco.com", "$_", 'User', "password$_", "User$_" ] } qw( A B ) ),
                   ( map { [ "$_\@myco.com", "$_", 'Manager', "password$_", "Manager$_" ] } qw( C D ) ),
                   ( map { [ "$_\@myco.com", "$_", 'Admin', "password$_", "Admin$_" ] } qw( E F ) ),
);

my @GROUP_FIELD = qw( group_id name notes );
my @GROUP_DATA  = (
     [ 1, 'admin',    'The all-powerful group' ],
     [ 2, 'public',   'All users should belong' ],
     [ 3, 'managers', 'PHB' ],
);

{
    # Install users

    foreach my $data ( @USER_DATA ) {
        my $user = My::User->new;
        for ( my $i = 0; $i < scalar @USER_FIELD; $i++ ) {
            $user->{ $USER_FIELD[ $i ] } = $data->[ $i ];
        }
        $user->save({ skip_cache => 1 });
        print "Created user with ID: ", $user->id, "\n";
    }

    # Next the groups

    foreach my $data ( @GROUP_DATA ) {
        my $group = My::Group->new;
        for ( my $i = 0;  $i < scalar @GROUP_FIELD; $i++ ) {
            $group->{ $GROUP_FIELD[ $i ] } = $data->[ $i ];
        }
        $group->save({ skip_cache => 1 });
        print "Created group with ID: ", $group->id, "\n";
    }

    # Finally the memberships

    my $public_group = My::Group->fetch_by_name( 'public',
                                                 { return_single => 1 } );
    my $admin_group  = My::Group->fetch_by_name( 'admin',
                                                 { return_single => 1 } );
    my $mgr_group    = My::Group->fetch_by_name( 'managers',
                                                 { return_single => 1 } );
    my $user_list = My::User->fetch_group({ skip_security => 1 });

    foreach my $user ( @{ $user_list } ) {
        eval {
            $user->group_add( $public_group->id );
            if ( $user->{login_name} =~ /^Admin/ ) {
                $user->group_add( $admin_group->id );
            }
            if ( $user->{login_name} =~ /^Manager/ ) {
                $user->group_add( $mgr_group->id );
            }
        };
        if ( $@ ) {
            die "Error creating relationships:\n$@\n";
        }
    }
}
