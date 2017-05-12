# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-CUPS.t'

#########################

use Test::More tests => 11;
BEGIN { use_ok('Net::CUPS'); use_ok('Net::CUPS::Destination'); };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $cups = Net::CUPS->new();

ok( $cups );

$cups->setServer( "localhost" );

ok( $cups->getServer() eq "localhost" );

my @makes = $cups->getPPDMakes();

ok (@makes);

my @ppds = $cups->getAllPPDs();

ok (@ppds);

my $ppd_file = $cups->getPPDFileName($ppds[1]);

ok ($ppd_file);

my $name = "yatp";
my $location = "nowhere";
my $printer_info = "blahblah";
my $device_uri = 'socket://192.168.1.3:9100';

$cups->addDestination($name, $location, $printer_info, $ppd_file, $device_uri);

my $dest = $cups->getDestination( $name );

ok ($dest);

my $description = $dest->getDescription();

ok( $description eq $printer_info );

my $uri = $dest->getUri();

ok( $uri eq $device_uri );

$cups->deleteDestination($name);

ok (! $cups->getDestination($name));
