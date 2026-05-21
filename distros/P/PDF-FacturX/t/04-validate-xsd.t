use strict;
use warnings;
use utf8;
use Test::More tests => 8;

use PDF::FacturX::XML qw(build_xml validate_xml xsd_root_for);

# En mode dev (avant install), xsd_root_for résout via le checkout local.
my $xsd_basic = xsd_root_for('basic');
ok(-d $xsd_basic, "XSD dir exists for basic: $xsd_basic");

my $invoice = {
    number   => 'FA-2026-XSD',
    date     => '2026-04-19',
    due_date => '2026-05-19',
    currency => 'EUR',
    seller   => { name => 'Acme SARL', siret => '12345678901234', vat => 'FR12345678901',
                  address_1 => '1 rue Test', postcode => '75001', city => 'Paris', country => 'FR' },
    buyer    => { name => 'Client SAS', address_1 => '2 av Buyer', postcode => '69002',
                  city => 'Lyon', country => 'FR' },
    lines => [
        { name => 'Service A', qty => 1, unit_price => 100,   vat_rate => 20,  vat_cat => 'S' },
        { name => 'Service B', qty => 2, unit_price => 100,   vat_rate => 5.5, vat_cat => 'S' },
    ],
    payment => { terms => 'Net 30', iban => 'FR7612345678901234567890123' },
};

for my $profile (qw(minimum basicwl basic en16931)) {
    my $xml = build_xml($invoice, $profile);
    my ($ok, $msg) = validate_xml($xml, $profile);
    ok($ok, "XML profile=$profile validates against bundled XSD")
        or diag("validation error: $msg");
}

# Invalide explicite : XML pas de tout Factur-X
{
    my ($ok, $msg) = validate_xml('<bogus/>', 'basic');
    ok(!$ok, 'arbitrary XML rejected by XSD');
    like($msg, qr/./, 'error message non-empty');
}

# Profil inconnu doit lever
eval { build_xml($invoice, 'extended'); };
like($@, qr/Profil Factur-X inconnu/i, 'unknown profile dies');
