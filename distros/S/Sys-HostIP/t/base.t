#!perl

use strict;
use warnings;
use Test::More tests => 6;
use Sys::HostIP qw/ip ips ifconfig interfaces/;
use Data::Dumper;

my $hostip = Sys::HostIP->new;

# -- ip() --
my $sub_ip   = ip();
my $class_ip = $hostip->ip;

diag("Class IP: $class_ip");
ok( $class_ip =~ /^ \d+ (?: \. \d+ ){3} $/x, 'IP by class looks ok' );
is( $class_ip, $sub_ip, 'IP by class matches IP by sub' );

# -- ips() --
my $class_ips = $hostip->ips;
isa_ok( $class_ips, 'ARRAY', 'scalar context ips() gets arrayref' );
ok( 1 == grep( /^$class_ip$/, @{$class_ips} ), 'Found IP in IPs by class' );

# -- interfaces() --
my $interfaces = $hostip->interfaces;
isa_ok( $interfaces, 'HASH', 'scalar context interfaces gets hashref' );
cmp_ok(
    scalar keys ( %{$interfaces} ),
    '==',
    scalar @{$class_ips},
    'Matching number of interfaces and ips',
);

