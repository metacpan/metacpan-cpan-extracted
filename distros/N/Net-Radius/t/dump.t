#!/usr/bin/perl

# Test packet dumping

# $Id: dump.t 38 2006-11-14 01:46:05Z lem $


no utf8;
use IO::File;
use Test::More tests => 257;
use Net::Radius::Packet;
use Net::Radius::Dictionary;

# Init the dictionary for our test run...
BEGIN {
    my $fh = new IO::File "dict.$$", ">";
    print $fh <<EOF;
ATTRIBUTE	User-Name		1	string
ATTRIBUTE	User-Password		2	string
ATTRIBUTE	NAS-IP-Address		4	ipaddr
EOF

    close $fh;
};

END { unlink 'dict.' . $$; }

# Build a request and test it is ok
my $p = new Net::Radius::Packet;
isa_ok($p, 'Net::Radius::Packet');
$p->set_dict("dict.$$");
$p->set_code("Access-Request");
$p->set_attr("User-Name" => 'FOO@MY.DOMAIN');
$p->set_attr("NAS-IP-Address" => "127.0.0.1");
my $str;

# Really special chars
for my $c (0 .. 31, 127..255)
{
    $p->set_authenticator(substr("Char-" . chr($c) . "\x0" x 16, 0, 16));
    $str = $p->str_dump;
    my $re = sprintf('(?m)^Authentic:\s+Char-\\\\x\{%x\}(?:\\\\x\{0\})+$', $c);
    like($str, qr/$re/, "Correct dump of chr($c)");
}

# Really normal chars
for my $c (32..35, 44..45, 47 .. 62, 64 .. 90, 95, 97..122, 124)
{
    $p->set_authenticator(substr("Char-" . chr($c) . "\x0" x 16, 0, 16));
    $str = $p->str_dump;
    my $re = sprintf('(?m)^Authentic:\s+Char-%s(?:\\\\x\{0\})+$', chr($c));
    like($str, qr/$re/, "Correct dump of chr($c)");
}

# Things that mean something special to Perl
for my $c (42, 43, 46, 63)
{
    $p->set_authenticator(substr("Char-" . chr($c) . "\x0" x 16, 0, 16));
    $str = $p->str_dump;
    my $re = sprintf('(?m)^Authentic:\s+Char-\\%s(?:\\\\x\{0\})+$', chr($c));
    like($str, qr/$re/, "Correct dump of chr($c)");
}

# Quote-like things
for my $c (36..41, 91..94, 96, 123..125)
{
    $p->set_authenticator(substr("Char-" . chr($c) . "\x0" x 16, 0, 16));
    $str = $p->str_dump;
    my $re = sprintf('(?m)^Authentic:\s+Char-\\\\\\%s(?:\\\\x\{0\})+$', 
		     chr($c));
    like($str, qr/$re/, "Correct dump of chr($c)");
}
