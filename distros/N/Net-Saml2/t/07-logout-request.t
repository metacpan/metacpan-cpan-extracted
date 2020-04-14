use Test::More;
use strict;
use warnings;
use Net::SAML2;

my $lor = Net::SAML2::Protocol::LogoutRequest->new(
        issuer => 'http://some/sp',
        destination => 'http://some/idp',
        nameid => 'name-to-log-out',
        session => 'session-to-log-out',
        nameid_format => 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
);
ok($lor);
my $xml = $lor->as_xml;
ok($xml);
#diag($xml);

like($xml, qr/ID=".+"/);
like($xml, qr/IssueInstant=".+"/);
like($xml, qr/persistent/);

done_testing;
