#!/usr/bin/perl
## >>---------------------------------------------------------------------------------

use strict;

use Sys::Hostname;
use Socket;
use Net::DHCP::Packet;
use Net::DHCP::Constants;
use POSIX qw(setsid strftime);

use IO::Socket::INET;

# sample logger
sub logger {
    my $str = shift;
    print STDOUT strftime "[%d/%b/%Y:%H:%M:%S] ", localtime;
    print STDOUT "$str\n";
}

logger("Starting dhcpd");

my $DAEMON = 0;    # run as daemon ?

# accept only from selected VENDOR classes (avoids messing existing networks)
my $VENDOR_ACCEPTED = "foo|bar";

# broadcast address
my $bcastaddr = sockaddr_in( "68", INADDR_BROADCAST );

# get a flag to force daemon to stop
my $time_to_die = 0;

# generic signal handler to cause daemon to stop
sub signal_handler {
    $time_to_die = 1;
}
$SIG{INT} = $SIG{TERM} = $SIG{HUP} = \&signal_handler;

# trap or ignore $SIG{PIPE}

# Daemon behaviour
# ignore any PIPE signal: standard behaviour is to quit process
$SIG{PIPE} = 'IGNORE';

# open listening socket
my $sock_in = IO::Socket::INET->new(
    LocalPort => 67,
    LocalAddr => "127.0.0.1",
    Proto     => 'udp'
) || die "Socket creation error: $@\n";

if ($DAEMON) {    # doesn't seem to work very well on cygwin
    logger("Entering Daemon mode");
    chdir '/' or die "Can't chdir to /: $!";
    umask 0;

    open STDIN,  '<', '/dev/null'  or die "Can't read /dev/null: $!";
    open STDOUT, '>', '/dev/null' or die "Can't write to /dev/null: $!";
    open STDERR, '>', '/dev/null' or die "Can't write to /dev/null: $!";

    my $pid = fork;
    exit if $pid;
    die "Couldn't fork: $!" unless defined($pid);

    POSIX::setsid() or die "Can't start a new session: $!";
    logger("Now in Daemon mode");
}

logger("Initialization complete");

# main loop
#
# process incoming packets
my $transaction = 0;    # report transaction number

until ($time_to_die) {
    my $buf = undef;
    my $fromaddr;       # address & port from which packet was received
    my $dhcpreq;

    eval {              # catch fatal errors
        logger("Waiting for incoming packet");

        # receive packet
        $fromaddr = $sock_in->recv( $buf, 4096 ) || logger("recv:$!");
        next if ($!);    # continue loop if an error occured
        $transaction++;  # transaction counter

        {
            use bytes;
            my ( $port, $addr ) = unpack_sockaddr_in($fromaddr);
            my $ipaddr = inet_ntoa($addr);
            logger( "Got a packet tr=$transaction src=$ipaddr:$port length="
                  . length($buf) );
        }

        my $dhcpreq = Net::DHCP::Packet->new($buf);
        $dhcpreq->comment($transaction);

        my $messagetype = $dhcpreq->getOptionValue( DHO_DHCP_MESSAGE_TYPE() );

        if ( $messagetype eq DHCPDISCOVER() ) {
            do_discover($dhcpreq);
        }
        elsif ( $messagetype eq DHCPREQUEST() ) {
            do_request($dhcpreq);
        }
        elsif ( $messagetype eq DHCPINFORM() ) {

        }
        else {
            logger("Packet dropped");

            # bad messagetype, we drop it
        }
    };    # end of 'eval' blocks
    if ($@) {
        logger("Caught error in main loop:$@");
    }

}
logger("Exiting dhcpd");

#=======================================================================
sub do_discover($) {
    my ($dhcpreq) = @_;
    my $sock_out;
    my ( $calc_ip, $calc_router, $calc_mask );

    # calculate address
    $calc_ip = "12.34.56.78";

    my $vendor = $dhcpreq->getOptionValue( DHO_VENDOR_CLASS_IDENTIFIER() );
    if ( $vendor !~ $VENDOR_ACCEPTED ) {
        logger("DISCOVER rejected, unsupported VENDOR class");
        return;    # dropping packet
    }

    my $dhcpresp = Net::DHCP::Packet->new(
        Comment                 => $dhcpreq->comment(),
        Op                      => BOOTREPLY(),
        Hops                    => $dhcpreq->hops(),
        Xid                     => $dhcpreq->xid(),
        Flags                   => $dhcpreq->flags(),
        Ciaddr                  => $dhcpreq->ciaddr(),
        Yiaddr                  => $calc_ip,
        Siaddr                  => $dhcpreq->siaddr(),
        Giaddr                  => $dhcpreq->giaddr(),
        Chaddr                  => $dhcpreq->chaddr(),
        DHO_DHCP_MESSAGE_TYPE() => DHCPOFFER(),
    );

    logger("Sending response");

    # Socket object keeps track of whom sent last packet
    # so we don't need to specify target address
    logger( "Sending OFFER tr=" . $dhcpresp->comment() );
    $sock_in->send( $dhcpresp->serialize() ) || die "Error sending OFFER:$!\n";

# TODO: you have to choose between sending back to sender or broadcasting to network

}

#=======================================================================
sub do_request {
    my $dhcpreq = shift;
    my $sock_out;
    my $calc_ip;
    my $dhcpresp;

    $calc_ip = "12.34.56.78";

    my $vendor = $dhcpreq->getOptionValue( DHO_VENDOR_CLASS_IDENTIFIER() );
    if ( $vendor !~ $VENDOR_ACCEPTED ) {
        logger("REQUEST rejected, unsupported VENDOR class");
        return;    # dropping packet
    }

    # compare calculated address with requested address
    if ( $calc_ip eq $dhcpreq->getOptionValue( DHO_DHCP_REQUESTED_ADDRESS() ) )
    {
        # address is correct, we send an ACK

        $dhcpresp = Net::DHCP::Packet->new(
            Comment                 => $dhcpreq->comment(),
            Op                      => BOOTREPLY(),
            Hops                    => $dhcpreq->hops(),
            Xid                     => $dhcpreq->xid(),
            Flags                   => $dhcpreq->flags(),
            Ciaddr                  => $dhcpreq->ciaddr(),
            Yiaddr                  => $calc_ip,
            Siaddr                  => $dhcpreq->siaddr(),
            Giaddr                  => $dhcpreq->giaddr(),
            Chaddr                  => $dhcpreq->chaddr(),
            DHO_DHCP_MESSAGE_TYPE() => DHCPACK(),
        );
    }
    else {
        # bad request, we send a NAK
        $dhcpresp = Net::DHCP::Packet->new(
            Comment                 => $dhcpreq->comment(),
            Op                      => BOOTREPLY(),
            Hops                    => $dhcpreq->hops(),
            Xid                     => $dhcpreq->xid(),
            Flags                   => $dhcpreq->flags(),
            Ciaddr                  => $dhcpreq->ciaddr(),
            Yiaddr                  => "0.0.0.0",
            Siaddr                  => $dhcpreq->siaddr(),
            Giaddr                  => $dhcpreq->giaddr(),
            Chaddr                  => $dhcpreq->chaddr(),
            DHO_DHCP_MESSAGE_TYPE() => DHCPNAK(),
            DHO_DHCP_MESSAGE()      => "Bad request...",
        );
    }

    # Socket object keeps track of whom sent last packet
    # so we don't need to specify target address
    logger( "Sending ACK/NAK tr=" . $dhcpresp->comment() );
    $sock_in->send( $dhcpresp->serialize() )
      || die "Error sending ACK/NAK:$!\n";

# TODO: you have to choose between sending back to sender or broadcasting to network

}
