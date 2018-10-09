# Test a list of weird IPs against various round trips through
# to_bigint, to_array, and to_intarray.

use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Net::IPv6Addr ':all';
use Math::BigInt;
my ($good, $todogood);
while (<DATA>) {
    chomp;
    s/\s*#.*//;
    next if m/^$/;
    if (/^GOOD/) {
	$good = 1;
	next;
    }
    if (/^TODOGOOD/) {
	$todogood = 1;
	next;
    }
    if (/^BAD/) {
	$good = 0;
	next;
    }

    if ($good) {
	if ($todogood) {
	    TODO: {
		local $TODO = 'fails';
		big_round ($_);
	    };
	}
	else {
	    big_round ($_);
	}
    }
    else {
	die "I'm bad, I'm bad, you know it, I'm really really bad";
    }
}


done_testing ();

# Round trip big int test

sub big_round
{
    my ($ipv6) = @_;
    my $o = Net::IPv6Addr->new ($ipv6);
    my $can = $o->to_string_compressed ();
    my $big = $o->to_bigint ();
    my @ia = $o->to_intarray ();
    my @ha = $o->to_array ();
    my $ipr = from_bigint ($big);
    my $iar = join (':', map {sprintf ("%04X", $_)} @ia);
    my $har = join (':', @ha);
    my $iarr = to_string_compressed ($iar);
    my $harr = to_string_compressed ($har);
    my $canr = $ipr->to_string_compressed ();
    is ($canr, $can, "Round trip of $ipv6 thru to/from_bigint");
    is ($iarr, $can, "Round trip of $ipv6 thru to_intarray");
    is ($harr, $can, "Round trip of $ipv6 thru to_array");
}

__DATA__

GOOD
::127.0.0.1
::1
2001:0db8:85a3:0000:0000:8a2e:0370:7334
2001:db8:85a3:0:0:8a2e:370:7334
2001:db8:85a3::8a2e:370:7334
2001:0db8:0000:0000:0000:0000:1428:57ab
2001:0db8:0000:0000:0000::1428:57ab
2001:0db8:0:0:0:0:1428:57ab
2001:0db8:0:0::1428:57ab
2001:0db8::1428:57ab
2001:db8::1428:57ab
::ffff:12.34.56.78
::ffff:0c22:384e
2001:0db8:1234:ffff:ffff:ffff:ffff:ffff
2001:0db8:1234:0000:0000:0000:0000:0000
2001:db8:a::123
fc00::
::ffff:0:0
2001::
2001:10::
2001:db8::
2001:0000:1234:0000:0000:C1C0:ABCD:0876
3ffe:0b00:0000:0000:0001:0000:0000:000a
FF02:0000:0000:0000:0000:0000:0000:0001
0000:0000:0000:0000:0000:0000:0000:0001
0000:0000:0000:0000:0000:0000:0000:0000
::ffff:192.168.1.26
2::10
ff02::1
fe80::
2002::
2001:db8::
2001:0db8:1234::
::ffff:0:0
::1
::ffff:192.168.1.1
1:2:3:4:5:6:7:8
1:2:3:4:5:6::8
1:2:3:4:5::8
1:2:3:4::8
1:2:3::8
1:2::8
1::8
1::2:3:4:5:6:7
1::2:3:4:5:6
1::2:3:4:5
1::2:3:4
1::2:3
1::8
::2:3:4:5:6:7:8
::2:3:4:5:6:7
::2:3:4:5:6
::2:3:4:5
::2:3:4
::2:3
::8
1:2:3:4:5:6::
1:2:3:4:5::
1:2:3:4::
1:2:3::
1:2::
1::
1:2:3:4:5::7:8
2001:0000:1234:0000:0000:C1C0:ABCD:0876
1:2:3:4::7:8
1:2:3::7:8
1:2::7:8
1::7:8
fe80::217:f2ff:fe07:ed62
2001:DB8:0:0:8:800:200C:417A # unicast, full
FF01:0:0:0:0:0:0:101 # multicast, full
0:0:0:0:0:0:0:1 # loopback, full
0:0:0:0:0:0:0:0 # unspecified, full
2001:DB8::8:800:200C:417A # unicast, compressed
FF01::101 # multicast, compressed
::1 # loopback, compressed, non-routable
0:0:0:0:0:0:13.1.68.3 # IPv4-compatible IPv6 address, full, deprecated
0:0:0:0:0:FFFF:129.144.52.38 # IPv4-mapped IPv6 address, full
::13.1.68.3 # IPv4-compatible IPv6 address, compressed, deprecated
::FFFF:129.144.52.38 # IPv4-mapped IPv6 address, compressed
fe80:0000:0000:0000:0204:61ff:fe9d:f156
fe80:0:0:0:204:61ff:fe9d:f156
fe80::204:61ff:fe9d:f156
fe80::
fe80::1
0000:0000:0000:0000:0000:0000:0000:0001
::1
::ffff:192.0.2.128
::ffff:c000:280
# Double colon is a valid address, so this was moved from BAD: to here.
# See also
# https://metacpan.org/pod/release/SALVA/Regexp-IPv6-0.03/lib/Regexp/IPv6.pm#DESCRIPTION
# https://rt.cpan.org/Public/Bug/Display.html?id=62125
::
1:2:3:4:5:6:1.2.3.4
1:2:3:4:5::1.2.3.4
1:2:3:4::1.2.3.4
1:2:3::1.2.3.4
1:2::1.2.3.4
1::1.2.3.4
1:2:3:4::5:1.2.3.4
1:2:3::5:1.2.3.4
1:2::5:1.2.3.4
1::5:1.2.3.4
1::5:11.22.33.44
fe80::217:f2ff:254.7.237.98
fe80:0:0:0:204:61ff:254.157.241.86
fe80::204:61ff:254.157.241.86

