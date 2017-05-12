#!/usr/bin/perl

use strict;
use warnings;
use Net::SSH::Tunnel;
use Data::Dumper;
use Test::More qw/no_plan/;

BEGIN { use_ok( 'Net::SSH::Tunnel' ); }

print "Hostname: ";
chomp( my $hostname = <STDIN> );
print "Host: ";
chomp( my $host = <STDIN> );
print "Tunnel type: ";
chomp( my $type = <STDIN>) ;

# emulating how command-line args are passed in
my $args = {
    '--hostname'    => $hostname,
    '--host'        => $host,
    '--type'        => $type,
};

# stuffing them into @ARGV for the module to handle
unshift @ARGV, %{ $args };

my $obj = Net::SSH::Tunnel->run();
my $pid = $obj->check_tunnel();

like( $pid, qr/^\d+$/, "check_tunnel() test to see if a tunnel has been established" );

$obj->destroy_tunnel();
$pid = $obj->check_tunnel();

is( $pid, undef, "check_tunnel() test to see if a tunnel has been destroyed" );