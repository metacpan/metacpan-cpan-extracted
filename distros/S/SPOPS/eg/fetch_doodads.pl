#!/usr/bin/perl

# $Id: fetch_doodads.pl,v 3.1 2004/01/10 02:49:58 lachoy Exp $

use strict;
use Log::Log4perl;
Log::Log4perl::init( 'log4perl.conf' );

require My::Security;
require My::User;
require My::Doodad;

{
    # Display info as a normal user, then as a manager
    runas( 'UserA' );
    runas( 'ManagerC' );
}

sub runas {
    my ( $username ) = @_;
    my $user = My::User->fetch_by_login_name( $username, { return_single => 1 } );
    My::Doodad->set_user( $user );
    My::Doodad->set_group( $user->group );
    my $iter = My::Doodad->fetch_iterator;
    print "\nDoodads in database, fetched as user ($username):\n";
    while ( my $doodad = $iter->get_next ) {
        printf "%-20s (\$%5.2f) Security: %s\n", $doodad->{name}, $doodad->{unit_cost},
                                                $doodad->{tmp_security_level};
    }
}
