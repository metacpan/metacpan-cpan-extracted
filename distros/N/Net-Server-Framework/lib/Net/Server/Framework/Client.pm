#!/usr/bin/perl -w -Ilib
#
# a General client library using the Net::Server::Framework framework
#

package Net::Server::Framework::Client;

use strict;
use warnings;
use Carp;
use IO::Socket;
use Net::Server::Framework::DB;
use Net::Server::Framework::Spooler;
use Time::HiRes;
use Data::Serializer;

our ($VERSION) = '1.0';
our $DB = 'registry';

sub c_connect {
    my $service = shift;

    my @hosts = _find($service);
    foreach my $host (@hosts) {
        if ( $host->{host} eq 'unix' ) {
            return IO::Socket::UNIX->new( Peer => $host->{port}, )
              or next;
        }
        else {
            return IO::Socket::INET->new(
                Proto    => "tcp",
                PeerAddr => $host->{host},
                PeerPort => $host->{port},
            ) or next;
        }
    }
    carp("Could not find a valid connection method!");
}

sub encode {
    my $data = shift;
    my $s = Data::Serializer->new( compress => '1' );
    return $s->serialize($data);
}

sub decode {
    my $data = shift;
    my $s = Data::Serializer->new( compress => '1' );
    return $s->deserialize($data);
}

sub talk {
    my ( $mech, $data ) = @_;

    my $start = time();
    my $timeout = 15;
    my $remote = c_connect($mech)
      or carp( "cannot connect to $mech Daemon, check the config section in your program");

    # send the hash to the daemon
    print $remote encode($data);
    shutdown $remote, 1;
    my $resp = <$remote>;
    # we work in asyc mode and have to poll the queue
    if ($resp eq 'accepted')
    {
        while (1) {
            my $res = Net::Server::Framework::Spooler::virgin($data);
            return $res if defined $res;
            if ( time > $start + $timeout ) {
                return 1001;
            }
            Time::HiRes::usleep 100_000;
        }
    } else {
        return decode($resp);
    }
}

#TODO make logging in couchDB
sub logging {
    my $h = shift;
    return $h;
}

sub log {
    my $h = shift;
    $h->{command} = 'put';
    my $id = talk('logD', $h);
    return $h;
}

sub _find {
    my $service = shift;
    my $dbh     = Net::Server::Framework::DB::dbconnect($DB);
    my @ret;
    my $res =
      Net::Server::Framework::DB::get( { dbh => $dbh, key => 'host', term => $service } );
    foreach my $l ( keys %{$res} ) {
        my $ret;
        if ( $l eq '*' ) {
            if ( $res->{$l}->{port} =~ m{\d+} ) {
                $ret->{host} = 'localhost';
                $ret->{port} = $res->{$l}->{port};
            }
            else {
                $ret->{host} = 'unix';
                $ret->{port} = $res->{$l}->{port};
            }
        }
        else {
            $ret->{host} = $l;
            $ret->{port} = $res->{$l}->{port};
        }
        push( @ret, $ret );
    }
    return @ret;
}

1;

=head1 NAME

Net::Server::Framework::Client - a client library with auto discovery for
daemons


=head1 VERSION

This documentation refers to Net::Server::Framework::Client version 1.0.


=head1 SYNOPSIS

A typical invocation looks like this:

    my $data = Net::Server::Framework::Client::talk('DAEMON_TO_TALK_TO',$c);

=head1 DESCRIPTION

This is a lib that is used to interface with daemons. The interface uses
by default a C<Data::Serializer> compressed string to exchange information
and finds the appropriate daemon based on the name. The name is looked
up in the central registry configured with the $DB variable. The
database based registry holds connection data like UNIX sockets or TCP
sockets. If there is more than one daemon with the same name the lib
does a basic round robin.


=head1 BASIC METHODS

=head2 c_connect

The connection logic.

=head2 encode

The analog to the C<Net::Server::Framework::encode> function only client
sides.

=head2 decode

The analog to the C<Net::Server::Framework::decode> function only client
sides.

=head2 talk

This method abstracts the connection logic and the syn/async connection
handling. Use this function to talk to a daemon within the
C<Net::Server::Framework>.

=head2 log

Deprecated. Has to be consolidated to one general function that is
backend neutral

=head2 logging

See log

=head1 CONFIGURATION AND ENVIRONMENT

The library needs a working etc/db.conf file and a configured $DB
variable. If asynchronous connections are used then a spooler process is
needed.

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
