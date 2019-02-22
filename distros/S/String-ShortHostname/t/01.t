use strict;
use warnings;
use 5.10.0;

use Test::More tests => 4;
#use lib 'lib';
use String::ShortHostname;

my $fqdn = 'testhost.example.com';
my $hostname = short_hostname( $fqdn );
ok( $hostname eq 'testhost', 'function with proper FQDN' );

$fqdn = '10.3.5.98';
$hostname = short_hostname( $fqdn );
ok( $hostname eq '10.3.5.98', 'function with IPv4 address' );

$fqdn = 'testhost.example.com';
my $short = String::ShortHostname->new( $fqdn );
$hostname = $short->hostname;
#say $hostname;
ok( $hostname eq 'testhost', 'new object with FQN' );

$fqdn = 'testhost.example.com';
$short = String::ShortHostname->new;
$short->hostname( $fqdn );
$hostname = $short->hostname;
ok( $hostname eq 'testhost', 'FQDN added to existing object' );

