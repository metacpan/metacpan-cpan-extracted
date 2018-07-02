#!/usr/bin/env perl

use strict;
use warnings;

use lib './lib';
use Net::Abuse::Utils qw( :all );

my %dnsbl = (
		'Spamhaus'      => 'sbl-xbl.spamhause.org',
		'SpamCop'       => 'bl.spamcop.net',
#		'Relays ORDB'   => 'relays.ordb.org',
		'Relays VISI'   => 'relays.vsi.com',
#		'Composite BL'  => 'cbl.abuseat.org',
		'Dynablock BL'  => 'dnsbl.njabl.org',
#		'DSBL Proxy'    => 'list.dsbl.org',
#		'DSBL Multihop' => 'multihop.dsbl.org',
#		'SORBS OR'      => 'dnsbl.sorbs.net',
		'SPEWS L1'      => 'l1.spews.dnsbl.sorbs.net',
		'SPEWS L2'      => 'l2.spews.dnsbl.sorbs.net',
#		'Blitzed OPM'   => 'opm.blitzed.org',
		);

my $ip = shift;

if (!is_ip($ip)) {
    warn "$ip doesn't look like an IP.\n";
    exit;
}


my $rdns = get_rdns($ip) || '';
print "IP Info:\n";
print "\tIP:         $ip\n";
print "\tRDNS:       $rdns\n";
print "\tIP Country: ", get_ip_country($ip), "\n";

print "\nAS Info:\n";
if (my @asn = get_asn_info($ip) ) {
    my $asn_org = get_as_description($asn[0]) || '';
    my $asn_co  = get_as_company($asn[0]) || '';
    print "\tASN:               $asn[0] - $asn[1]\n";
    print "\tAS  Org:           $asn_org\n";
    print "\tClean Org:         $asn_co\n";
    print "\tRIR:               $asn[3]\n";
    print "\tAS Country:        ", get_asn_country($asn[0]), "\n";
    print "\n";
    my @peers = get_peer_info($ip);
    if($#peers > -1){
        print "\nPeer Info";

        foreach my $peer (@peers){
            my $peer_org = get_as_description($peer->{'asn'}) || '';
            my $peer_co = get_as_company($peer->{'asn'}) || '';

            print "\n";
            print "\tPeer:              $peer->{'asn'}\n";
            print "\tPeer Prefix:       $peer->{'prefix'}\n";
            print "\tPeer Org:          $peer_org\n";
            print "\tPeer Clean Org:    $peer_co\n";
            print "\tPeer Country:      ".$peer->{'cc'}."\n";
        }
    }
}
else {
    print "\tUnknown ASN\n";
}

my $soa_contact = get_soa_contact($ip) || 'not found';
print "\nContact Addresses:\n";
print "\tPTR SOA Contact: $soa_contact\n";
print "\tIP Whois Contacts: ", join (' ', get_ipwi_contacts($ip) ), "\n";

if ($soa_contact =~ /\@(\S+)$/) {
    print "\tAbuse.net ($1): ", get_abusenet_contact($1), "\n";
}

print "\nDNSBL Listings:\n";
foreach my $bl (keys %dnsbl) {
    my $txt = get_dnsbl_listing($ip, $dnsbl{$bl}) || 'not listed';
    print "\t$bl:\t$txt\n";
}
