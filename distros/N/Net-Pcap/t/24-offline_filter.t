#!perl -T
use strict;
use File::Spec;
use Test::More;
use Net::Pcap;
use lib 't';
use Utils;

my $has_test_exception = eval "use Test::Exception; 1";

plan tests => 7;

my ($r, $err, $icmpfilter, $tcpfilter);

my $path = File::Spec->catfile(qw(t samples ping-ietf-20pk-be.dmp));
my $pcap = pcap_open_offline($path, \$err);
ok $pcap, 'open testfile';

$r = eval { pcap_compile($pcap, \$icmpfilter, 'icmp', 1, 0xffffffff) };
is $r, 0, 'compile icmp filter';

$r = eval { pcap_compile($pcap, \$tcpfilter, 'tcp', 1, 0xffffffff) };
is $r, 0, 'compile tcp filter';

SKIP: {
    skip "Test::Exception not available", 1 unless $has_test_exception;

    # check offline_filter() errors
    throws_ok(sub {
        pcap_offline_filter($tcpfilter, undef, undef)
    }, '/^arg2 not a hash ref/',
       "calling offline_filter() with no argument");
}

my (%header, $packet);
my ($n, $icmp, $tcp) = (0, 0, 0);

while (pcap_next_ex($pcap, \%header, \$packet) == 1) {
    $n++;
    $icmp++ if pcap_offline_filter($icmpfilter, \%header, $packet);
    $tcp++  if pcap_offline_filter($tcpfilter,  \%header, $packet);
}

pcap_close($pcap);

is $n,    20, 'read all packets';
is $icmp, 20, 'found all icmp packets';
is $tcp,   0, 'test for tcp packets in an icmp-only testfile';
