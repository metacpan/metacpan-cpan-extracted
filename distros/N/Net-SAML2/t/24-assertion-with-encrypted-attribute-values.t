use strict;
use warnings;
use Test::Lib;
use Test::Net::SAML2;
use MIME::Base64 qw/decode_base64/;

use Net::SAML2::Protocol::Assertion;

my $xml = path('t/data/eherkenning-decrypted.xml')->slurp;

my $assertion = Net::SAML2::Protocol::Assertion->new_from_xml(
    xml      => $xml,
);

isa_ok($assertion, 'Net::SAML2::Protocol::Assertion');

# Santize for easy comparison
foreach my $v (values %{$assertion->attributes}) {
    foreach (@$v) {
       $_ =~ s/^\s+//;
       $_ =~ s/\s+$//;
    }
}

cmp_deeply(
    $assertion->attributes,
    {
        'urn:etoegang:1.9:ServiceRestriction:Vestigingsnr' => ['0000123456789'],
        'urn:etoegang:core:ActingSubjectID'                => ['5039c43b8e350bf6fb24382c9670debd878623680421a7b6f39ec749dfc0b4c7@0ae3c84bce4f060b25e89c0290f040d6'
        ],
        'urn:etoegang:core:AuthorizationRegistryID' => ['urn:etoegang:MR:00000001234567890000:entities:9113'],
        'urn:etoegang:core:LegalSubjectID' => ['9876543210' ],
        'urn:etoegang:core:Representation' => ['true'],
        'urn:etoegang:core:ServiceID'      => ['urn:etoegang:DV:0000000398765432100000:services:9009'],
        'urn:etoegang:core:ServiceUUID'    => ['b2ba62a6-419c-4331-8fbb-40c7b589978d']
    },
    "Got all the decrypted attributes"
);

done_testing;
