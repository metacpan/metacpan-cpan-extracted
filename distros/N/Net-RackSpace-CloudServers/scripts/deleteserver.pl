#!perl
use strict;
use warnings;
use Net::RackSpace::CloudServers;
use Net::RackSpace::CloudServers::Server;

my $user = $ENV{'CLOUDSERVERS_USER'} or die "Need CLOUDSERVERS_USER environment variable set";
my $key  = $ENV{'CLOUDSERVERS_KEY'}  or die "Need CLOUDSERVERS_KEY environment variable set";

my $serverid = shift or die "$0: need ID of server to be deleted\n";
print "Will delete server ID $serverid\n";

my $CS = Net::RackSpace::CloudServers->new(
  user => $user,
  key  => $key,
);
$Net::RackSpace::CloudServers::DEBUG = 0;
my @servers = $CS->get_server_detail;
my $srv = ( grep { $_->id == $serverid } @servers )[0];
die "you do not have a server ID $serverid, quitting\n" if ( !defined $srv );

$Net::RackSpace::CloudServers::DEBUG = 1;
$srv->delete_server();

print "Server deletion requested...\n";
