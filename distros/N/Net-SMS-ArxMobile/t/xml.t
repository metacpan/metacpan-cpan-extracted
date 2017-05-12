#!/usr/bin/env perl

=pod

=head1 NAME

t/xml.t - Net::SMS::ArxMobile unit tests

=head1 DESCRIPTION

Tests that the generated XML messages for the ArxMobile API
are correct and they can be parsed back into data structures.

=cut

use strict;
use warnings;
#se Data::Dumper ();
use XML::Simple ();

use Test::More tests => 14;

use Net::SMS::ArxMobile;

my $code = "some_code";
my $text = "Ualla. <> Some Text";
my $phone = "18885551212";

my $sms = Net::SMS::ArxMobile->new(
    _auth_code => $code,
);
ok($sms, "Created a Net::SMS::ArxMobile object");

my $xml = $sms->_send_sms_xml(
    _auth_code => $code,
    text => $text,
    to => $phone,
);

ok($xml, "Generated some XML");
#diag($xml);

like($xml, qr{<auth_code>$code</auth_code>}ms);
like($xml, qr{<body>Ualla. &lt;&gt; Some Text</body>}ms, "Body was XML encoded");
like($xml, qr{<phone>$phone</phone>}, "XML has the correct phone tag");
like($xml, qr{<message> .* </message>}msx, "XML has an enclosing message tag");
like($xml, qr{^<\?xml version="1.0" \?>}, "XML has the <?xml> declaration");

my $data = XML::Simple::XMLin($xml);
#diag("Parsed XML: " . Data::Dumper::Dumper($data));

is(
    $data->{auth_code}, $code,
    "Generated XML is parsed back correctly (has 'auth_code')"
);

is(
    $data->{body}, $text,
    "Generated XML is parsed back correctly (has 'body')",
);

is(
    $data->{user}->{phone}, $phone,
    "Generated XML is parsed back correctly (has 'phone')",
);


# Query SMS ID
my $smsid = 'abcdef123456';
$xml = $sms->_query_smsid_xml(
    _auth_code => $code,
    smsid => $smsid,
);

ok($xml, "Generated XML for query_sms API");
#diag("XML: $xml");

$data = XML::Simple::XMLin($xml, SuppressEmpty => '');
#diag("Parsed XML: " . Data::Dumper::Dumper($data));
ok(ref $data eq "HASH" && keys %{ $data }, "Parsed back XML for query_sms");

is($data->{auth_code}, $code, "'auth_code' is ok");
is($data->{smsid}, $smsid, "'smsid' is ok");

# End of test

