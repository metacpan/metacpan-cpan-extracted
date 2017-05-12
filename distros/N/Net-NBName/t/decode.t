use strict;
use diagnostics;

use Test;

BEGIN { plan tests => 22 }

# Test Net::NBName::NodeStatus

my @data = qw(04 D4 84 00 00 00 00 01 00 00 00 00 20 43 4B 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 00 00 21 00 01 00 00 00 00 00 E3 0A 53 50 41 52 4B 20 20 20 20 20 20 20 20 20 20 20 44 00 53 50 41 52 4B 20 20 20 20 20 20 20 20 20 20 00 44 00 50 4C 41 59 47 52 4F 55 4E 44 20 20 20 20 20 00 C4 00 50 4C 41 59 47 52 4F 55 4E 44 20 20 20 20 20 1C C4 00 50 4C 41 59 47 52 4F 55 4E 44 20 20 20 20 20 1B 44 00 50 4C 41 59 47 52 4F 55 4E 44 20 20 20 20 20 1E C4 00 53 50 41 52 4B 20 20 20 20 20 20 20 20 20 20 03 44 00 50 4C 41 59 47 52 4F 55 4E 44 20 20 20 20 20 1D 44 00 01 02 5F 5F 4D 53 42 52 4F 57 53 45 5F 5F 02 01 C4 00 41 44 4D 49 4E 49 53 54 52 41 54 4F 52 20 20 03 44 00 00 1C 2B 3A 49 58 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 01 00 00 00 00 FF 03 1F 00 20 90 68 80 E0 52 F0 77 00);

my $resp = pack "C*", map { hex } @data;

my @names = (['SPARK', 0x20],
             ['SPARK', 0x00],
             ['PLAYGROUND', 0x00],
             ['PLAYGROUND', 0x1C],
             ['PLAYGROUND', 0x1B],
             ['PLAYGROUND', 0x1E],
             ['SPARK', 0x03],
             ['PLAYGROUND', 0x1D],
             ['..__MSBROWSE__.', 0x01],
             ['ADMINISTRATOR', 0x03],
            );

use Net::NBName::NodeStatus;
ok(1); # loaded ok

my $ns = Net::NBName::NodeStatus->new($resp);
ok($ns); # $ns should be defined; undef indicates a problem decoding

# check netbios names have been decoded correctly
my $i = 0;
for my $rr ($ns->names) {
    ok($rr->name, $names[$i][0]);
    $i++;
}

# check mac address decoded correctly
ok($ns->mac_address, "00-1C-2B-3A-49-58");

# Test Net::NBName::NodeStatus 2
# Truncated response, as returned by HP LaserJet printers

@data = qw(2b 5c 00 00 00 01 00 00 00 00 00 00 20 43 4b 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 00 00 21 00 01);

$resp = pack "C*", map { hex } @data;

$ns = Net::NBName::NodeStatus->new($resp);
ok($ns); # $ns should be defined; undef indicates a problem decoding

ok(scalar $ns->names, 0); # check names is an empty list

ok($ns->mac_address, ""); # check the mac_address is an empty string

# Test Net::NBName::NameQuery

@data = qw(04 4C 85 80 00 00 00 01 00 00 00 00 20 45 4C 45 4A 45 4F 45 48 45 45 45 50 45 4E 43 41 43 41 43 41 43 41 43 41 43 41 43 41 43 41 42 4D 00 00 20 00 01 00 00 00 00 00 12 80 00 C0 A8 00 0A 80 00 C0 A8 00 0B 80 00 C0 A8 00 0C);

my @addresses = qw(192.168.0.10 192.168.0.11 192.168.0.12);

$resp = pack "C*", map { hex } @data;

use Net::NBName::NameQuery;
ok(1); # loaded ok

my $nq = Net::NBName::NameQuery->new($resp);
ok($nq); # $nq should be defined; undef indicates a problem decoding

# check ip addresses have been decoded correctly
$i = 0;
for my $rr ($nq->addresses) {
    ok($rr->address, $addresses[$i]);
    $i++;
}

ok($nq->RA, 1); # check RA flag was detected
