#!perl
use strict;
use warnings;
use 5.010_000;
use Net::RackSpace::CloudServers;
use Net::RackSpace::CloudServers::Server;
use Net::RackSpace::CloudServers::Image;

my $user = $ENV{'CLOUDSERVERS_USER'} or die "Need CLOUDSERVERS_USER environment variable set";
my $key  = $ENV{'CLOUDSERVERS_KEY'}  or die "Need CLOUDSERVERS_KEY environment variable set";

my $serverid = shift or die "$0: need server id\n";
my $imgname = "@ARGV";
die "Need a name for the new image\n" unless $imgname;

my $CS = Net::RackSpace::CloudServers->new(
  user => $user,
  key  => $key,
);
$Net::RackSpace::CloudServers::DEBUG         = 0;
$Net::RackSpace::CloudServers::Server::DEBUG = 0;
my $server;
{
  my @servers = $CS->get_server_detail($serverid);
  die "Server id $serverid not found; exiting\n" unless @servers;
  $server = $servers[0];
}
my $img      = $server->create_image($imgname);
my $newimgid = $img->id;

say "Image ID ", $img->id, " created from server id ", $img->serverid;
say "Named '", $img->name, "', status ", $img->status;
say "The image will need to be ACTIVE before being able to be used.";
say "Rackspace's caching may prevent you from getting an up-to-date status.";
