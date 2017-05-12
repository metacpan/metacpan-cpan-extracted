# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-Google-SafeBrowsing2.t'

#########################


use List::Util qw(first);
use Test::More qw(no_plan);
BEGIN { use_ok('Net::Google::SafeBrowsing2') };

require_ok( 'Net::Google::SafeBrowsing2' );


#########################

my $gsb = Net::Google::SafeBrowsing2->new();

is( $gsb->hex_to_ascii( 'A' ), 41, 'hex_to_ascii OK');
is( $gsb->hex_to_ascii( $gsb->ascii_to_hex('11223344') ), '11223344', 'hex_to_ascii OK');


# From Google API doc, prefix
is( length $gsb->prefix('abc'), 4, 'Prefix length is 4');
is( $gsb->prefix('abc'), $gsb->ascii_to_hex('ba7816bf'), 'prefix "abc" is OK');

is( $gsb->prefix('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'), $gsb->ascii_to_hex('248d6a61'), 'prefix  is OK');
is( $gsb->prefix('a' x 1000000), $gsb->ascii_to_hex('cdc76e5c'), 'prefix "a"  is OK');

# From Google API doc, URL canonicalization
is( $gsb->canonical_uri('http://host/%25%32%35')->as_string, 'http://host/%25', 'canonicalization "http://host/%25%32%35" is OK');
is( $gsb->canonical_uri('http://host/%25%32%35%25%32%35')->as_string, 'http://host/%25%25', 'canonicalization "http://host/%25%32%35" is OK');
is( $gsb->canonical_uri('http://host/asdf%25%32%35asd')->as_string, 'http://host/asdf%25asd', 'canonicalization "http://host/asdf%25asd" is OK');
is( $gsb->canonical_uri('http://host/%%%25%32%35asd%%')->as_string, 'http://host/%25%25%25asd%25%25', 'canonicalization "http://host/%25%25%25asd%25%25 is OK');
is( $gsb->canonical_uri('http://www.google.com/')->as_string, 'http://www.google.com/', 'canonicalization "http://www.google.com/" is OK');
is( $gsb->canonical_uri('http://%31%36%38%2e%31%38%38%2e%39%39%2e%32%36/%2E%73%65%63%75%72%65/%77%77%77%2E%65%62%61%79%2E%63%6F%6D/')->as_string, 'http://168.188.99.26/.secure/www.ebay.com/', 'canonicalization "http://168.188.99.26/.secure/www.ebay.com/" is OK');
is( $gsb->canonical_uri('http://195.127.0.11/uploads/%20%20%20%20/.verify/.eBaysecure=updateuserdataxplimnbqmn-xplmvalidateinfoswqpcmlx=hgplmcx/')->as_string, 'http://195.127.0.11/uploads/%20%20%20%20/.verify/.eBaysecure=updateuserdataxplimnbqmn-xplmvalidateinfoswqpcmlx=hgplmcx/', 'canonicalization "http://195.127.0.11/uploads/%20%20%20%20/.verify/.eBaysecure=updateuserdataxplimnbqmn-xplmvalidateinfoswqpcmlx=hgplmcx/" is OK');
# is( $gsb->canonical_uri('http://host%23.com/%257Ea%2521b%2540c%2523d%2524e%25f%255E00%252611%252A22%252833%252944_55%252B')->as_string, 'http://host%23.com/~a!b@c%23d$e%25f^00&11*22(33)44_55+', 'canonicalization "http://host%23.com/%257Ea%2521b%2540c%2523d%2524e%25f%255E00%252611%252A22%252833%252944_55%252B" is OK'); # Fails because URI->new does some parsing automatically and parse ^ into %5E
is( $gsb->canonical_uri('http://3279880203/blah')->as_string, 'http://195.127.0.11/blah', 'canonicalization "http://195.127.0.11/blah" is OK');
is( $gsb->canonical_uri('http://www.google.com/blah/..')->as_string, 'http://www.google.com/', 'canonicalization "http://www.google.com/blah/..." is OK');
is( $gsb->canonical_uri('www.google.com/')->as_string, 'http://www.google.com/', 'canonicalization "www.google.com/" is OK');
is( $gsb->canonical_uri('www.google.com')->as_string, 'http://www.google.com/', 'canonicalization "www.google.com" is OK');
is( $gsb->canonical_uri('http://www.evil.com/blah#frag')->as_string, 'http://www.evil.com/blah', 'canonicalization "http://www.evil.com/blah" is OK');
is( $gsb->canonical_uri('http://www.GOOgle.com/')->as_string, 'http://www.google.com/', 'canonicalization "http://www.google.com/" is OK');
# is( $gsb->canonical_uri('http://www.google.com.../')->as_string, 'http://www.google.com/', 'canonicalization "http://www.google.com/" is OK'); # Dies!
is( $gsb->canonical_uri("http://www.google.com/foo\tbar\rbaz\n2")->as_string, 'http://www.google.com/foobarbaz2', 'canonicalization "http://www.google.com/foobarbaz2" is OK');
is( $gsb->canonical_uri('http://www.google.com/q?')->as_string, 'http://www.google.com/q?', 'canonicalization "http://www.google.com/q?" is OK');
is( $gsb->canonical_uri('http://www.google.com/q?r?')->as_string, 'http://www.google.com/q?r?', 'canonicalization "http://www.google.com/q?r?" is OK');
is( $gsb->canonical_uri('http://www.google.com/q?r?s')->as_string, 'http://www.google.com/q?r?s', 'canonicalization "http://www.google.com/q?r?s" is OK');
is( $gsb->canonical_uri('http://evil.com/foo#bar#baz')->as_string, 'http://evil.com/foo', 'canonicalization "http://evil.com/foo" is OK');
is( $gsb->canonical_uri('http://evil.com/foo;')->as_string, 'http://evil.com/foo;', 'canonicalization "http://evil.com/foo;" is OK');
is( $gsb->canonical_uri('http://evil.com/foo?bar;')->as_string, 'http://evil.com/foo?bar;', 'canonicalization "http://evil.com/foo?bar;" is OK');
# is( $gsb->canonical_uri("http://\x01\x80.com/")->as_string, 'http://%01%80.com/', 'canonicalization "http://%01%80.com/" is OK'); # fails
is( $gsb->canonical_uri('http://notrailingslash.com')->as_string, 'http://notrailingslash.com/', 'canonicalization "http://notrailingslash.com/" is OK');
is( $gsb->canonical_uri('http://www.gotaport.com:1234/')->as_string, 'http://www.gotaport.com:1234/', 'canonicalization "http://www.gotaport.com:1234/" is OK');
is( $gsb->canonical_uri('  http://www.google.com/  ')->as_string, 'http://www.google.com/', 'canonicalization "http://www.google.com/" is OK');
is( $gsb->canonical_uri('http:// leadingspace.com/')->as_string, 'http://%20leadingspace.com/', 'canonicalization "http://%20leadingspace.com/" is OK');
is( $gsb->canonical_uri('http://%20leadingspace.com/')->as_string, 'http://%20leadingspace.com/', 'canonicalization "http://%20leadingspace.com/" (1) is OK');
is( $gsb->canonical_uri('%20leadingspace.com/')->as_string, 'http://%20leadingspace.com/', 'canonicalization "%20leadingspace.com/" is OK');
is( $gsb->canonical_uri('https://www.securesite.com/')->as_string, 'https://www.securesite.com/', 'canonicalization "https://www.securesite.com/" is OK');
is( $gsb->canonical_uri('http://host.com/ab%23cd')->as_string, 'http://host.com/ab%23cd', 'canonicalization "http://host.com/ab%23cd" is OK'); # fails
is( $gsb->canonical_uri('http://host.com//twoslashes?more//slashes')->as_string, 'http://host.com/twoslashes?more//slashes', 'canonicalization "http://host.com/twoslashes?more//slashes" is OK');


# Own tests, URL canonicalization
is( $gsb->canonical_uri('http://www.google.com/a/../b/../c')->as_string, 'http://www.google.com/c', 'canonicalization "http://www.google.com/a/../b/../c" is OK');
is( $gsb->canonical_uri('http://www.google.com/a/../b/..')->as_string, 'http://www.google.com/', 'canonicalization "http://www.google.com/a/../b/.." is OK');
is( $gsb->canonical_uri('http://www.google.com/a/../b/..?foo')->as_string, 'http://www.google.com/?foo', 'canonicalization "http://www.google.com/a/../b/..?foo" is OK');
is( $gsb->canonical_uri('http://www.google.com/#a#b')->as_string, 'http://www.google.com/', 'canonicalization "http://www.google.com/#a#b" is OK');
is( $gsb->canonical_uri('http://www.google.com/#a#b#c')->as_string, 'http://www.google.com/', 'canonicalization "http://www.google.com/#a#b#c" is OK');
is( $gsb->canonical_uri('http://16843009/index.html')->as_string, 'http://1.1.1.1/index.html', 'canonicalization "http://16843009/index.html" is OK');
is( $gsb->canonical_uri('http://1/index.html')->as_string, 'http://0.0.0.1/index.html', 'canonicalization "http://16843009/index.html" is OK');

# Form Google API doc, possible strings for lookup
my @values = $gsb->canonical('http://a.b.c/1/2.html?param=1');
is( scalar @values, 8, 'Number of possible strings for "http://a.b.c/1/2.html?param=1" is OK');

my @strings = qw(a.b.c/1/2.html?param=1 a.b.c/1/2.html a.b.c/ a.b.c/1/ b.c/1/2.html?param=1 b.c/1/2.html b.c/ b.c/1/);
foreach my $string (@strings) {
	my $found = defined first { $_ eq $string } @values;
	is( $found, 1, "$string is present");
}

@values = $gsb->canonical('http://a.b.c.d.e.f.g/1.html');
is( scalar @values, 10, 'Number of possible strings for "http://a.b.c.d.e.f.g/1.html" is OK');

@strings = qw(a.b.c.d.e.f.g/1.html a.b.c.d.e.f.g/ c.d.e.f.g/1.html c.d.e.f.g/ d.e.f.g/1.html d.e.f.g/ e.f.g/1.html e.f.g/ f.g/1.html f.g/);
foreach my $string (@strings) {
	my $found = defined first { $_ eq $string } @values;
	is( $found, 1, "$string is present");
}


@values = $gsb->canonical('http://www1.rapidsoftclearon.net/');
is( scalar @values, 2, 'Number of possible strings for "http://www1.rapidsoftclearon.net/" is OK');

@strings = qw(www1.rapidsoftclearon.net/ rapidsoftclearon.net/);
foreach my $string (@strings) {
	my $found = defined first { $_ eq $string } @values;
	is( $found, 1, "$string is present");
}

# Own test for canonical_domain_suffix

@values = $gsb->canonical_domain_suffixes('www.google.com');
is( scalar @values, 2, 'Number of possible domains for "www.google.com" is OK');

@strings = qw(www.google.com google.com);
foreach my $string (@strings) {
	my $found = defined first { $_ eq $string } @values;
	is( $found, 1, "domain $string is present");
}

@values = $gsb->canonical_domain_suffixes('google.com');
is( scalar @values, 1, 'Number of possible domains for "google.com" is OK');

@strings = qw(google.com);
foreach my $string (@strings) {
	my $found = defined first { $_ eq $string } @values;
	is( $found, 1, "domain $string is present");
}

@values = $gsb->canonical_domain_suffixes('malware.testing.google.test');
is( scalar @values, 2, 'Number of possible domains for "malware.testing.google.test" is OK');

@strings = qw(testing.google.test google.test);
foreach my $string (@strings) {
	my $found = defined first { $_ eq $string } @values;
	is( $found, 1, "domain $string is present");
}



# ok(2); # Module tested OK