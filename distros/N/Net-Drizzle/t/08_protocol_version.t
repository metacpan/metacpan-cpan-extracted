use strict;
use warnings;
use Test::More tests => 1;
use Net::Drizzle;

my $con = Net::Drizzle::Connection->new();
$con->set_protocol_version(3);
is $con->protocol_version, 3;

