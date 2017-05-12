# $Id: Teamspeak.pm 37 2008-03-09 01:10:00Z maletin $
# $URL: http://svn.berlios.de/svnroot/repos/cpan-teamspeak/cpan/trunk/lib/Teamspeak.pm $

package Teamspeak;
use Teamspeak::Channel;
use Teamspeak::Player;

use 5.004;
use strict;
use Net::Telnet;
use Carp;
use vars qw( $VERSION );

$VERSION = '0.6';

sub new {
    my ( $class, %arg ) = @_;
    if ( $arg{type} eq 'telnet' ) {
        require Teamspeak::Telnet;
        return Teamspeak::Telnet->new(%arg);
    }
    elsif ( $arg{type} eq 'sql' ) {
        require Teamspeak::SQL;
        return Teamspeak::SQL->new(%arg);
    }
    elsif ( $arg{type} eq 'web' ) {
        require Teamspeak::Web;
        return Teamspeak::Web->new(%arg);
    }
    else {
        croak("unknown type $arg{type}");
    }
}    # new

sub error {
    my ($self) = @_;
    $self->{err}    = 1;
    $self->{errstr} = $_[1];
    return 0;
}    # error

sub _croak {
    my ($self, $msg) = @_;
    Carp::croak($msg || $self);
}

1;

__END__

=head1 NAME

Teamspeak - Interface to administrate Teamspeak-Server.

=head1 VERSION

This document refers to version 0.6 of Teamspeak.

=head1 SYNOPSIS

 use Teamspeak;
 my $tsh = Teamspeak->new( 
     timeout => <sec>,
     port => <port_number>,
     host => <ip_or_hostname>
   );
 
=head1 DESCRIPTION

You can connect to a Teamspeak-Server in four different Connection-Types:
  1. Telnet
  2. MySQL or MySQL::Lite
  3. Web-Frontend
  4. Teamspeak-Client is using UDP

Every Connection-Type can only use a part of all available Methods.

=head1 SUBROUTINES/METHODS

=head2 new( type => conn_type, [...] )

conn_type is the connection type and can be telnet, sql or web.

=head2 error( [$parms, ] $msg )

Used internally to set the error status and message.

=head1 CONFIGURATION AND ENVIRONMENT

There are no Environment-Variables used, at the moment.

=head1 DEPENDENCIES

=head1 DIAGNOSTICS

The Project is still Pre-Alpha.

=over 4

=item Can't locate Teamspeak.pm in @INC

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are undoubtedly serious bugs lurking somewhere in this code, if
only because parts of it give the impression of understanding a great deal
more about Perl than they really do. 

Bug reports and other feedback are most welcome at
http://rt.cpan.org/NoAuth/Dists.html?Queue=Teamspeak

=head1 FILES

=head1 SEE ALSO

The different Teamspeak-Handle-Interfaces:
Teamspeak::Telnet, 
Teamspeak::SQL,
Teamspeak::Web.
The different Objects:
Teamspeak::Server,
Teamspeak::Ban,
Teamspeak::Player,
Teamspeak::Channel,
Teamspeak::Ban.
The Homepage of the Sourecode:
http://cpan-teamspeak.berlios.de/

=head1 AUTHOR

Martin von Oertzen (maletin@cpan.org)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2005-2008, Martin von Oertzen. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.
