#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
	use_ok('POE::Filter::LZW::Progressive');
}

use POE::Filter::LZW::Progressive;

my $filter = POE::Filter::LZW::Progressive->new();

isa_ok($filter, 'POE::Filter::LZW::Progressive');

my $str1 = "<stream:stream xmlns='jabber:client' xmlns:stream='http://etherx.jabber.org/streams' to='foo.com' version='1.0'>";
my $str2 = "<stream:features><starttls xmlns='urn:ietf:params:xml:ns:xmpp-tls'><required/></starttls><mechanisms xmlns='urn:ietf:params:xml:ns:xmpp-sasl'><mechanism>DIGEST-MD5</mechanism></mechanisms></stream:features>";

# Do simple test
my $lzw_r = $filter->put([ $str1 ]);
my $plain_r = $filter->get($lzw_r);

ok($plain_r->[0] eq $str1, "Simple compress/decompress");
