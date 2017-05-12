
use strict;
use warnings;

use Test::More tests => 3;

use Net::Link;

fail('module is linux-only') if($^O ne 'linux');
fail('module needs sysfs') unless -d '/sys/';

my @interfaces = map { $_->name } Net::Link->interfaces;

exit pass('no interfaces found, no further tests possible') unless @interfaces;

my $choice;

until($choice) {
	print "Choose a network interface to test (or skip) (@interfaces skip): ";
	$choice = <STDIN> || '';
	chomp $choice;
	exit pass('skipping everything') if($choice eq 'skip');
	($choice) = grep { $_ eq $choice } @interfaces;
}

my $if = new Net::Link($choice);
ok($if, 'create interface');

print <<EOT;
If the chosen network interface as an ethernet device, plug in the cable now
and make sure it's also connected to another device, like a switch or router or
whatever. If it's a wireless network interface, please connect to an access
point or ad-hoc node or something. Then hit return.
EOT

<STDIN>;

ok($if->up, 'interface up');

print <<EOT;
Now unplug the cable or disconnect from the access point and hit return again.
EOT

<STDIN>;

ok($if->down, 'interface down');
