#!/usr/bin/perl

# This is public domain, do whatever you want you are safe from me.
#
# Very simple program to check the IP address of SMTP connections
# and try to bloxor the spammers. If you use postfix (of course you do)
# then add this line to the bottom of your /etc/postfix/main.cf :
#
#       smtpd_milters = inet:localhost:8978
#
# NOTE: Change $portno below as appropriate and change above config to match,
# but I put a real number in because some people won't even read this far.

my $APIkey = '1234567890123456789012345678901234567890';
my $portno = 8978;              # Port to listen on localhost
my $name   = 'milterabusedb';   # For sendmail config of milters
my $debug  = 1;

use strict;
use warnings;
use Sendmail::PMilter qw(:all);
use Sendmail::AbuseIPDB;
use Socket;                     # For unpack_sockaddr_in() and inet_ntoa()

my $from_addr;                  # Other party FQDN as declared by them.
my $from_ip;                    # Other party IPv4 address as delivered by socket.
my %cbs;                        # Callback lookup table

$cbs{connect} = sub {
    my $ctx = shift; 
    $from_addr = shift;
    my ($port, $ip_address) = unpack_sockaddr_in(shift);
    $from_ip = inet_ntoa($ip_address); # Don't care about the port
    if( $debug ) { print "CONNECT ADDR: $from_addr\nCONNECT IP:   $from_ip\n"; }

    SMFIS_CONTINUE;
};

$cbs{eom} = sub {
    my $ctx = shift;
    my $db = Sendmail::AbuseIPDB->new( Key => $APIkey, Debug => $debug );
    my @all_data = $db->get( $from_ip );
    if( scalar( $db->filter( 'Email Spam', @all_data )) > 2 )
    {
        die( "SMTP user ${from_addr}[${from_ip}] seems like a spammer" );
    }
    if( scalar( @all_data ) > 4 )
    {
        die( "SMTP user ${from_addr}[${from_ip}] seems like a bad guy" );
    }
    if( $debug ) { print "NO PROBLEM:   ${from_addr}[${from_ip}]\n"; }

    SMFIS_CONTINUE;
};     

if( $APIkey eq '1234567890123456789012345678901234567890' ) { die( "https://www.abuseipdb.com/register" ); }

my $milter = new Sendmail::PMilter;
my $at = '@';
$milter->setconn( "inet:${portno}${at}localhost" );
$milter->register( $name, \%cbs, SMFI_CURR_ACTS );

my $dispatcher = Sendmail::PMilter::prefork_dispatcher(
    max_children => 10,
    max_requests_per_child => 1,
);

$milter->set_dispatcher($dispatcher);
$milter->main();
# ================================================================
#            On a clear disk you can seek forever.
# ================================================================
