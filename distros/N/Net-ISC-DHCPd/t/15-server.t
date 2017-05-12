#!perl

use strict;
use warnings;
use lib 'lib';
use File::Temp;
use Net::ISC::DHCPd;
use Path::Class::File;
use Test::More;

my $binary = Path::Class::File->new(qw/ t data dhcpd3 /);

plan skip_all => "cannot execute $binary" unless(-x $binary);
plan tests => 5;

my $pid_file = File::Temp->new;
my $dhcpd = Net::ISC::DHCPd->new(
                binary => $binary,
                pidfile => "$pid_file",
                config => { file => 't/data/dhcpd.conf' },
                leases => { file => 't/data/dhcpd.leases' },
           );

is($dhcpd->binary, $binary, 'binary is set');
ok($dhcpd->test('config'), 'mock config is valid') or diag $dhcpd->errstr;
ok($dhcpd->test('leases'), 'mock leases is valid') or diag $dhcpd->errstr;

$dhcpd->leases->file('/fooooooooooooooooooooooooooooooo');
ok(!$dhcpd->test('leases'), 'mock leases is now invalid') or diag $dhcpd->errstr;
like($dhcpd->errstr, qr{Invalid leases file}, 'script output "Invalid leases file"');
