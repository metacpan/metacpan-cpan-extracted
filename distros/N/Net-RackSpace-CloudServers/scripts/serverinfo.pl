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
warn "** Getting flavor details..\n";
my @flavors = $CS->get_flavor_detail;
warn "** Getting images details..\n";
my @images = $CS->get_image_detail;
warn "** Getting server details..\n";
my @servers = $CS->get_server_detail;

say '#' x 72;

foreach my $server (@servers) {
  say "Server ID ", $server->id, " Name ", $server->name;
  say "Server status ", $server->status || 'undef', " progress ", $server->progress || 'undef';
  say "Public IPs: ",  join( ' ', @{ $server->public_address  || () } );
  say "Private IPs: ", join( ' ', @{ $server->private_address || () } );
  my $img = ( grep { $_->id == $server->imageid } @images )[0];    # find image by id
  die "Can't find image ID ", $server->imageid, " on list" if ( !defined $img );
  say "Image ID ", $server->imageid, " (", $img->name, ")",
    " status ", $img->status || 'undef', " progress ", $img->progress || 'undef';
  my $flv = ( grep { $_->id == $server->flavorid } @flavors )[0];    # find flavor by id
  die "Can't find flavor ID ", $server->flavorid, " on list" if ( !defined $flv );
  say "Flavor ID ", $server->flavorid, " (", $flv->name, ")",
    " ram ", $flv->ram || 'undef', " disk ", $flv->disk || 'undef';
}
