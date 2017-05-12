#!/usr/bin/perl

use lib qw( lib );

use Sprocket qw(
    Server
    Client
);

#-------------------------------------------
# Config

my $forward_from = '0.0.0.0:8080';
my $forward_to = '127.0.0.1:80';
my $dump_packets = 1;

#-------------------------------------------

my $client = Sprocket::Client->spawn(
    LogLevel => 4,
    TimeOut => 0,
    Name => 'Forward Client',
    Plugins => [
        {
            Plugin => Sprocket::Plugin::PortForward->new(
                dump_packets => $dump_packets,
            ),
            Priority => 0,
        },
    ],
);

Sprocket::Server->spawn(
    LogLevel => 4,
    TimeOut => 0,
    Name => 'Forward Server',
    ListenPort => ( split( ':', $forward_from ) )[ 1 ],
    ListenAddress => ( split( ':', $forward_from ) )[ 0 ],
    Plugins => [
        {
            Plugin => Sprocket::Plugin::PortForward->new(
                forward_to => $forward_to,
                forward_with => $client,
                dump_packets => $dump_packets,
            ),
            Priority => 0,
        },
    ],
);
     

$poe_kernel->run();

1;

package Sprocket::Plugin::PortForward;

use Sprocket qw( Plugin );
use base 'Sprocket::Plugin';

use strict;
use warnings;


sub new {
    my $class = shift;
    $class->mk_accessors( qw( forward_to forward_with dump_packets ) );
    $class->SUPER::new(
        name => 'Forward plugin',
        dump_offset => 0,
        @_
    );
}

# ---------------------------------------------------------
# server

sub local_connected {
    my ( $self, $server, $con, $socket ) = @_;
    
    $self->take_connection( $con );

    # pause input until we're connected
    $con->wheel->pause_input();

    # connect out to dest
    my $client = $self->forward_with->connect( $self->forward_to );
   
    # fused connections tear down each other on disconnect
    $con->fuse( $client );
    
    return;
}

sub local_receive {
    my ( $self, $server, $con, $d ) = @_;
   
    $self->dump( $d, $server->{name}.':' ) if ( $self->dump_packets );
    $con->fused->send( $d );
    
    return;
}


sub remote_connected {
    my ( $self, $client, $con, $socket ) = @_;
    
    $self->take_connection( $con );
    
    # connected!, resume input on our fused socket
    $con->fused->wheel->resume_input();
    
    return;
}

sub remote_receive {
    my ( $self, $client, $con, $d ) = @_;
    
    $self->dump( $d, $client->{name}.':' ) if ( $self->dump_packets );
    $con->fused->send( $d );

    return;
}

sub dump {
    my ( $self, $d, $pre ) = @_;

    $pre ||= '';
    my $stream = "$d";

    while ( length $stream ) {
      my $line = substr( $stream, 0, 16, '' );
      my $hexdump  = unpack( 'H*', $line );
      $hexdump =~ s/(..)/$1 /g;
      $line =~ tr[ -~][.]c;
      
      # or $self->_log( v => 4, msg => blah blah );
      print STDERR $pre.sprintf( "%04x %-47.47s - %s\n", $self->{dump_offset}, $hexdump, $line );
      $self->{dump_offset} += 16;
    }
    
}

1;
