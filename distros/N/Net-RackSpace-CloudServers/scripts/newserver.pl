#!perl
use strict;
use warnings;
use Net::RackSpace::CloudServers;
use Net::RackSpace::CloudServers::Server;

my $user = $ENV{'CLOUDSERVERS_USER'} or die "Need CLOUDSERVERS_USER environment variable set";
my $key  = $ENV{'CLOUDSERVERS_KEY'}  or die "Need CLOUDSERVERS_KEY environment variable set";

my $CS = Net::RackSpace::CloudServers->new(
  user => $user,
  key  => $key,
);
$Net::RackSpace::CloudServers::DEBUG = 0;
my @servers = $CS->get_server_detail;
if ( grep { $_->name eq 'perlmfapitest' } @servers ) {
  die "you already have a server named perlmfapitest, quitting\n";
}

my @flavors = $CS->get_flavor_detail;
my @images  = $CS->get_image_detail;

## Provision a new server
$Net::RackSpace::CloudServers::DEBUG = 1;
my $srv;
{
  my $tmp = Net::RackSpace::CloudServers::Server->new(
    cloudservers => $CS,
    name         => 'perlmfapitest',
    flavorid     => ( grep { $_->ram == 256 } @flavors )[0]->id,
    imageid      => ( grep { $_->name =~ /karmic/ } @images )[0]->id,
    personality  => [ { path => '/root/test.txt', contents => 'dGVzdCAxMjMK' } ], # "test 123\n"
  );
  $srv = $tmp->create_server();
}

$Net::RackSpace::CloudServers::DEBUG = 0;
my $adminpass = $srv->adminpass;    # will not be returned afterwards!
print "Created server ID ", $srv->id, ", root password is: ", $adminpass, "\n";
print "Available at public IP: @{$srv->public_address}\n";
{
  my @tmpservers = $CS->get_server_detail();
  $srv = ( grep { $_->name eq 'perlmfapitest' } @tmpservers )[0];

}

## unusable until ->status will be ACTIVE, from BUILD
do {
  print "Status: ", $srv->status // '?', " progress: ", $srv->progress // '?', "\n";
  my @tmpservers = $CS->get_server_detail();
  $srv = ( grep { $_->name eq 'perlmfapitest' } @tmpservers )[0];
  sleep 2 if ( ( $srv->status // '' ) ne 'ACTIVE' );
} while ( ( $srv->status // '' ) ne 'ACTIVE' );

print "Server is now built and available:\n";
print "Server ID ", $srv->id, ", root password is: ", $adminpass, "\n";
print "Available at public IP: @{$srv->public_address}\n";
