use strict;
use warnings;
use utf8;
use Test::More tests => 9;
use XML::LibXML;

use PDF::FacturX::XML qw(build_xml guideline_id);

my $invoice = {
    number   => 'FA-2026-0042',
    date     => '2026-04-19',
    due_date => '2026-05-19',
    currency => 'EUR',
    seller   => {
        name      => 'Acme SARL',
        address_1 => '1 rue du Test',
        postcode  => '75001',
        city      => 'Paris',
        country   => 'FR',
        siret     => '12345678901234',
        vat       => 'FR12345678901',
    },
    buyer    => {
        name      => 'Client SAS',
        address_1 => '2 avenue Buyer',
        postcode  => '69002',
        city      => 'Lyon',
        country   => 'FR',
    },
    lines => [
        { name => 'Service A', qty => 1, unit_price => 1000, vat_rate => 20, vat_cat => 'S' },
    ],
};

# guideline_id retourne l'URN attendu par profil
is(guideline_id('minimum'), 'urn:factur-x.eu:1p0:minimum',
    'guideline_id minimum');
is(guideline_id('en16931'), 'urn:cen.eu:en16931:2017',
    'guideline_id en16931');

my $xml = build_xml($invoice, 'minimum');
ok($xml, 'build_xml minimum returns non-empty string');

my $doc = XML::LibXML->load_xml(string => $xml);
my $xpc = XML::LibXML::XPathContext->new($doc);
$xpc->registerNs(rsm => 'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100');
$xpc->registerNs(ram => 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100');

is($doc->documentElement->nodeName, 'rsm:CrossIndustryInvoice',
    'root element is rsm:CrossIndustryInvoice');

is(
    $xpc->findvalue('//ram:GuidelineSpecifiedDocumentContextParameter/ram:ID'),
    'urn:factur-x.eu:1p0:minimum',
    'GuidelineID matches MINIMUM profile',
);

is($xpc->findvalue('//rsm:ExchangedDocument/ram:ID'), 'FA-2026-0042', 'invoice number');
is($xpc->findvalue('//ram:SellerTradeParty/ram:Name'), 'Acme SARL', 'seller name');
is($xpc->findvalue('//ram:BuyerTradeParty/ram:Name'),  'Client SAS', 'buyer name');

# Le profil MINIMUM n'inclut pas IncludedSupplyChainTradeLineItem
my @lines = $xpc->findnodes('//ram:IncludedSupplyChainTradeLineItem');
is(scalar @lines, 0, 'MINIMUM profile omits line items');
