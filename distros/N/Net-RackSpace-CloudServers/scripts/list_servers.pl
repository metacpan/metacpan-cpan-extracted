#!perl
use strict;
use warnings;
use Net::RackSpace::CloudServers;
use 5.010_000;

my $user = $ENV{'CLOUDSERVERS_USER'} or die "Need CLOUDSERVERS_USER environment variable set";
my $key  = $ENV{'CLOUDSERVERS_KEY'}  or die "Need CLOUDSERVERS_KEY environment variable set";

$Net::RackSpace::CloudServers::DEBUG = 1;
warn "** Creating Net::RackSpace::CloudServers object..\n";
my $CS = Net::RackSpace::CloudServers->new(
  user => $user,
  key  => $key,
);
warn "** \$CS->get_server()..\n";
$CS->get_server();
warn "** \$CS->get_server_detail..\n";
$CS->get_server_detail();
