#!/usr/bin/perl

#
# Example of how to use AbuseIPDB for firewall control.
# See "ipset" documentation in Linux, there are a number of advantages:
# -- Efficient handling of large numbers of IP addresses without complex trees.
# -- Automatically handles timeout, once address has been in sin-bin long enough.
# -- Tolerates additions beyond maximum size, by removing random old address (forceadd).
#
# Output of this program will be suitable as input to "ipset-restore"
# Can safely be run multiple times.
#
# Typical iptables would be something like this:
#     iptables -A INPUT -m set --match-set abuseipdb src -j DROP
#     iptables -A OUTPUT -m set --match-set abuseipdb dst -j DROP
#

use warnings;
use strict;
use Sendmail::AbuseIPDB;

my $v2APIkey = '1234567890123456789012345678901234567890';
my $name = 'abuseipdb';  # Name of ipset
my $timeout = 259200;    # Number of seconds in 3 days
my $maxelem = 32768;     # Maximum number of IP's, must be power of 2.

if( $v2APIkey eq '1234567890123456789012345678901234567890' ) { die( "https://www.abuseipdb.com/register" ); }
my $db = Sendmail::AbuseIPDB->new( v2Key => $v2APIkey );
my $blacklist = $db->blacklist( 100 );
my @list;

#
# First line creates the list, or gets ignored if list already exists.
#
push @list, "create $name hash:ip forceadd family inet hashsize $maxelem maxelem $maxelem timeout $timeout -exist";

#
# Visit each IP address and add to the list.
# Order of items from API is based on most recent report of the IP, oldest to newest.
#
if( defined( $blacklist->{ 'data' }))
{
    foreach my $item ( @{ $blacklist->{ 'data' }})
    {
        my $ip = $item->{ 'ipAddress' };
        if( $ip =~ m{^([0-9.]+)$})                   # IPv4 address
        {
            push @list, "add $name $ip -exist";
        }
        elsif( $ip =~ m{^([0-9a-fA-F:]+)$})          # IPv6 address are not used at this stage.
        {
            warn( "Ignore IPv6: $ip" );
        }
        else                                         # Some other junk?!?
        {
            warn( "Dodgy characters found: $ip" );
        }
    }
}

#
# Dump entire list as ASCII text.
#
print( join( "\n", @list ), "\n" );

