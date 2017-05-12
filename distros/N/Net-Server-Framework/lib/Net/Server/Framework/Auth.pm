#!/usr/bin/perl -Ilib -w

package Net::Server::Framework::Auth;

use strict;
use warnings;
use Carp;
use Switch;
use Net::Server::Framework::DB;
use Net::Server::Framework::Crypt;

our ($VERSION) = '1.0';
our $DB = 'framework';

sub authenticate {
    my ( $user, $token, $mode ) = @_;
    switch ($mode) {
        case /client/i { return ( _token( $user, $token ) ); }
        case /server/i { return ( _check( $user, $token ) ); }
        case /userpass/i { return ( _userpass( $user, $token ) ); }
        else { carp "2003"; }
    }
}

sub make_pass {
    my $pass = shift;
    return Net::Server::Framework::Crypt::hash($pass);
}

sub _check {
    my ( $user, $token ) = @_;
    my $dbh = Net::Server::Framework::DB::dbconnect($DB);
    my $res = Net::Server::Framework::DB::get( { dbh => $dbh, key => 'auth', term => $user } );
    if ( my $pass = $res->{$user}->{password} ) {
        my $string = Net::Server::Framework::Crypt::decrypt( $token, $pass, 'blowfish', 'a' );
        my ( $u, $time ) = split( /-/, $string, 2 );
        if ( $u eq $user ) {

            # more than one day time difference is too much
            if (    ( ( $time + 86400 ) gt time )
                and ( time gt( $time - 86400 ) ) )
            {
                return;
            }
        }
    }
    return 2200;
}

sub _token {
    my ( $user, $pass ) = @_;

    my $string = $user . "-" . time;
    my $token = Net::Server::Framework::Crypt::encrypt( $string, $pass, 'blowfish', 'a' );
    chomp($token);
    return $token;
}

sub _userpass {
    my ( $user, $token ) = @_;
    my $dbh = Net::Server::Framework::DB::dbconnect($DB);
    my $res = Net::Server::Framework::DB::get( { dbh => $dbh, key => 'auth', term => $user } );
    if ( my $pass = $res->{$user}->{password} ) {
        if ( $token eq $pass ) {
            return;
        }
    }
    return 2200;
}

1;

=head1 NAME

Net::Server::Framework::Auth - authentication for Net::Server::Framework
based daemons


=head1 VERSION

This documentation refers to C<Net::Server::Framework::Auth> version 1.0.


=head1 SYNOPSIS

The Authentication part of the C<Net::Server::Framework>

A typical invocation looks like this:

    if ( !defined ($error = Net::Server::Framework::Auth::authenticate(
                    $c->{user}, $c->{pass}, 'userpass' )))
    {
        # this is authenticated
    } else {
        # throw an error
    }


=head1 DESCRIPTION

This is a lib that is used to authenticate clients connecting to the
daemon.


=head1 BASIC METHODS

=head2 authenticate

This function authenticates a user against a stored password hash.

=head2 make_pass

This function creates a password hash secure enough to store it in a
database.

=head1 COMMANDS

The commands accepted by the lib are: 

=head2 client

=head2 server

=head2 userpass


=head1 CONFIGURATION AND ENVIRONMENT

The library needs a working etc/db.conf file and a configured $DB
variable.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to 
Lenz Gschwendtner ( <lenz@springtimesoft.com> )
Patches are welcome.

=head1 AUTHOR

Lenz Gschwendtner ( <lenz@springtimesoft.com> )

=head1 LICENCE AND COPYRIGHT

Copyright (c) 
2007 Lenz Gschwerndtner ( <lenz@springtimesoft.comn> )
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
