#!/usr/bin/perl
#
# test various error returns
#

use blib;
do "t/config" or die $@;
die "configuration failure" unless  defined $dhcpCONFIG{host};
use Net::DHCP::Control '$STATUS';
use Net::DHCP::Control::Lease;
use MIME::Base64;
use Socket 'inet_aton';
use Test::More tests => 5;
ok(1, "Partial credit for showing up");

my $server = Net::DHCP::Control::ServerHandle->new(host => $dhcpCONFIG{host},
				      key => $dhcpCONFIG{key},
				      key_name => $dhcpCONFIG{keyname},
				      key_type => $dhcpCONFIG{keytype},
				      )
    or die "Couldn't connect to server: $STATUS; aborting";


my $addr = $dhcpCONFIG{'lease-addr-range'};
for (1..255) {
    my $lease = Net::DHCP::Control::Lease->new(handle => $server,
				  attrs => { 'ip-address' => inet_aton("$addr.$_") },
				  );
    next unless $lease;

    my @attrs = $lease->attrs;
    ok(scalar(@attrs), "->attrs returned something");
    is(scalar(@attrs), 8, "Number of attributes returned");
    print "# attrs = @attrs\n";

    my %attrhash = $lease->get_all;
    ok(scalar(%attrhash), "->get_all returned something");
    is(scalar(@attrs), keys(%attrhash), "Number of keys in ->get_all hash");
    print "# get_all = (", hash2str(\%attrhash), ")\n";
    $DONE = 1;
    last;
}
unless ($DONE) {
    die "Couldn't find any active leases.\n";
}

sub hash2str {
    my $h = shift;
    my @kv;
    for my $k (sort keys %$h) {
	my $v = $h->{$k} || "<UNDEF>";
	$v =~ s/[^[:print:]]/sprintf "\\x%02X", ord $&/ge;
	push @kv, "$k => $v";
    }
    return join ", ", @kv;
}
