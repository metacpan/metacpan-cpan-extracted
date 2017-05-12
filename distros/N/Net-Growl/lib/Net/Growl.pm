package Net::Growl;

use vars qw($VERSION); $VERSION = '0.99';
use warnings;
use strict;
use IO::Socket;
use Exporter;
use Carp;

# Derived from Rui Carmo's (http://the.taoofmac.com)
# netgrowl.php (http://the.taoofmac.com/space/Projects/netgrowl.php)
# by Nathan McFarland - (http://nmcfarl.org)

our @ISA    = qw(Exporter);
our @EXPORT = ( 'register', 'notify' );

use constant GROWL_UDP_PORT          => 9887;
use constant GROWL_PROTOCOL_VERSION  => 1;
use constant GROWL_TYPE_REGISTRATION => 0;
use constant GROWL_TYPE_NOTIFICATION => 1;

sub register {
    my %args = @_;
    my %addr = (
                 PeerAddr => $args{host} || "localhost",
                 PeerPort => Net::Growl::GROWL_UDP_PORT,
                 Proto    => 'udp' );
    die "A password is required" if ( !$args{password} );
    my $s = IO::Socket::INET->new(%addr) || die "Could not create socket: $!\n";
    my $p = Net::Growl::RegistrationPacket->new(%args);
    $p->addNotification();
    print( $s $p->payload() );
    close($s);
}

sub notify {
    my %args = @_;
    my %addr = (
                 PeerAddr => $args{host} || "localhost",
                 PeerPort => Net::Growl::GROWL_UDP_PORT,
                 Proto    => 'udp' );
    die "A password is required" if ( !$args{password} );
    my $s = IO::Socket::INET->new(%addr) || die "Could not create socket: $!\n";
    my $p = Net::Growl::NotificationPacket->new(%args);
    print( $s $p->payload() );

    close($s);
}

1;

package Net::Growl::RegistrationPacket;
use Digest::MD5 qw( md5_hex );
use base 'Net::Growl';

sub new {
    my $class = shift;
    my %args  = @_;
    $args{application} ||= "growl_notify";
    my $self = bless \%args, $class;
    $self->{notifications} = {};
    utf8::encode( $self->{application} );
    return $self;
}

sub addNotification {
    my ( $self, %args ) = @_;
    $args{notification} ||= "Command-Line Growl Notification";
    $args{enabled} = "True" if !defined $args{enabled};
    $self->{notifications}->{ $args{notification} } = $args{enabled};
}

sub payload {
    my $self = shift;
    my ( $name,       $defaults );
    my ( $name_count, $defaults_count );
    for ( keys %{ $self->{notifications} } ) {
        utf8::encode($_);
        $name .= pack( "n", length($_) ) . $_;
        $name_count++;
        if ( $self->{notifications}->{$_} ) {
            $defaults .= pack( "c", $name_count - 1 );
            $defaults_count++;
        }
    }
    $self->{data} = pack( "c2nc2",
                          $self->GROWL_PROTOCOL_VERSION,
                          $self->GROWL_TYPE_REGISTRATION,
                          length( $self->{application} ),
                          $name_count,
                          $defaults_count );
    $self->{data} .= $self->{application} . $name . $defaults;

    my $checksum;
    if ( $self->{password} ) {
        $checksum = pack( "H32", md5_hex( $self->{data} . $self->{password} ) );
    }
    else {
        $checksum = pack( "H32", md5_hex( $self->{data} ) );
    }

    $self->{data} .= $checksum;
    return $self->{data};
}

1;

package Net::Growl::NotificationPacket;
use Digest::MD5 qw( md5_hex );
use base 'Net::Growl';

sub new {
    my ( $class, %args ) = @_;
    $args{application}  ||= "growlnotify";
    $args{notification} ||= "Command-Line Growl Notification";
    $args{title}        ||= "Title";
    $args{description}  ||= "Description";
    $args{priority}     ||= 0;
    my $self = bless \%args, $class;

    utf8::encode( $self->{application} );
    utf8::encode( $self->{notification} );
    utf8::encode( $self->{title} );
    utf8::encode( $self->{description} );
    my $flags = ( $args{priority} & 0x07 ) * 2;
    if ( $args{priority} < 0 ) {
        $flags |= 0x08;
    }
    if ( $args{sticky} ) {
        $flags = $flags | 0x0001;
    }
    $self->{data} = pack( "c2n5",
                          $self->GROWL_PROTOCOL_VERSION,
                          $self->GROWL_TYPE_NOTIFICATION,
                          $flags,
                          length( $self->{notification} ),
                          length( $self->{title} ),
                          length( $self->{description} ),
                          length( $self->{application} ) );
    $self->{data} .= $self->{notification};
    $self->{data} .= $self->{title};
    $self->{data} .= $self->{description};
    $self->{data} .= $self->{application};

    if ( $args{password} ) {
        $self->{checksum} =
          pack( "H32", md5_hex( $self->{data} . $args{password} ) );
    }
    else {
        $self->{checksum} = pack( "H32", md5_hex( $self->{data} ) );
    }
    $self->{data} .= $self->{checksum};
    return $self;
}

sub payload {
    my $self = shift;
    return $self->{data};
}

1;

__END__

=head1 NAME

Net::Growl - Growl Notifications over the network. 


=head1 SYNOPSIS

 use Net::Growl;
 register(host => 'thegrowlhost',   
          application=>"My App",  
          password=>'Really Secure', )  if ! $ALREADY_REGISTERED;
 notify(
        application=>"My App",
        title=>'warning',
        description=>'some text',
        priority=>2,
        sticky=>'True',
        password=>'Really Secure',
 );


  
=head1 DESCRIPTION

A simple interface to send Mac OS X Growl notifications across the network.  Growl only needs to be installed on the receiving Mac not on the machine using this module.  

To use register your app using 'register', send using 'notify' - it that easy.

=head1 INTERFACE 

=head2  register

 Usage: register(host=>'thegrowlhost', application=>"My App", password=>'Really Secure') ;
 Description:  Registers the application and all the possible kinds of notifications it sends.

=head2  notify

 Usage: notify(application=>"My App", title=>'warning', description=>'some text',
               priority=>2,  sticky=>'True', password=>'Really Secure',);
 Description: Actual configures and sends a notification.


=head1 DIAGNOSTICS

=head2 General Debugging:

Go to System Preferences -> Growl -> General  and 'enable logging'  and open Console.app.  Messages are logged - and debugging is much easier.

=head2 Internal OO API only: 

If no notifications are received, and Growl crashes, and you are not using a password -- you've hit a known bug.  Use a password! This is a network app and open to abuse. Also this is the only known workaround. The module will not work without passwords enabled.


=head1 CONFIGURATION AND ENVIRONMENT

You must enable network notifications, and set a password in the Growl preference panel of System Preferences, on the mac recieving the notifications.

=head1 DEPENDENCIES

Growl (http://growl.info) on the computer receiving the notifications (not necessarily on computer sending the notifications).


=head1 INCOMPATIBILITIES

Does not work with Growl version previous to 0.6 as network support was not available.

=head1 BUGS AND LIMITATIONS

This module currently REQUIRES that you use a password, for network notification. This is not true of the Growl Framework. This should be fixed in a future release.

Please report any bugs or feature requests to
C<bug-net-growl@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 EXPORT

register -  register an app, and notifications

notify  - send a notifcation

=head1 SEE ALSO

http://growl.info  - The Growl Project site.

L<Mac::Growl> - Local Growl Notification Framework.

http://the.taoofmac.com/space/Projects/netgrowl.php - The inspiration/base for this module

=head1 AUTHOR

Nathan McFarland  C<< <nmcfarl@cpan.org> >>

Inspired by Rui Carmo's netgrowl.php

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Nathan McFarland C<< <nmcfarl@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


