#!perl
use strict;
use warnings;
use Net::RackSpace::CloudServers;
use Net::RackSpace::CloudServers::Image;

my $user = $ENV{'CLOUDSERVERS_USER'} or die "Need CLOUDSERVERS_USER environment variable set";
my $key  = $ENV{'CLOUDSERVERS_KEY'}  or die "Need CLOUDSERVERS_KEY environment variable set";

my $imgid = shift or die "$0: need ID of image to be deleted\n";
print "Will delete image ID $imgid\n";

my $CS = Net::RackSpace::CloudServers->new(
  user => $user,
  key  => $key,
);
$Net::RackSpace::CloudServers::DEBUG = 0;
my $img = $CS->get_image_detail($imgid);
die "you do not have an image ID $imgid, quitting\n" if ( !defined $img );

$Net::RackSpace::CloudServers::DEBUG = 1;
$CS->delete_image($imgid);

print "Image deletion requested...\n";
