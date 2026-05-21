use strict;
use warnings;
use utf8;
use Test::More tests => 11;
use XML::LibXML;

use PDF::FacturX::XML qw(build_xml);

my $invoice = {
    number   => 'FA-2026-0100',
    date     => '2026-04-19',
    due_date => '2026-05-19',
    currency => 'EUR',
    seller   => { name => 'Acme SARL', siret => '12345678901234', vat => 'FR12345678901',
                  address_1 => '1 rue Test', postcode => '75001', city => 'Paris', country => 'FR' },
    buyer    => { name => 'Client SAS', address_1 => '2 av Buyer', postcode => '69002',
                  city => 'Lyon', country => 'FR' },
    lines => [
        # 100 EUR @ 20% TVA  (TVA = 20.00)
        { name => 'Service A', qty => 1, unit_price => 100, vat_rate => 20, vat_cat => 'S' },
        # 200 EUR @ 5.5% TVA (TVA = 11.00)
        { name => 'Service B', qty => 2, unit_price => 100, vat_rate => 5.5, vat_cat => 'S' },
    ],
};

my $xml = build_xml($invoice, 'basic');
my $doc = XML::LibXML->load_xml(string => $xml);
my $xpc = XML::LibXML::XPathContext->new($doc);
$xpc->registerNs(rsm => 'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100');
$xpc->registerNs(ram => 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100');

my @lines = $xpc->findnodes('//ram:IncludedSupplyChainTradeLineItem');
is(scalar @lines, 2, 'BASIC profile includes 2 line items');

is($xpc->findvalue('(//ram:IncludedSupplyChainTradeLineItem)[1]/ram:SpecifiedTradeProduct/ram:Name'),
   'Service A', 'line 1 name');
is($xpc->findvalue('(//ram:IncludedSupplyChainTradeLineItem)[2]/ram:SpecifiedTradeProduct/ram:Name'),
   'Service B', 'line 2 name');

# Agrégation TVA : 2 groupes (S:20 et S:5.5)
my @taxes = $xpc->findnodes('//ram:ApplicableHeaderTradeSettlement/ram:ApplicableTradeTax');
is(scalar @taxes, 2, 'two ApplicableTradeTax groups (one per rate)');

# Totaux : line=300, taxBasis=300, tax=31, grand=331
is($xpc->findvalue('//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:LineTotalAmount'),
   '300.00', 'LineTotalAmount = 300.00');
is($xpc->findvalue('//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxBasisTotalAmount'),
   '300.00', 'TaxBasisTotalAmount = 300.00');
is($xpc->findvalue('//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:TaxTotalAmount'),
   '31.00', 'TaxTotalAmount = 31.00 (20 + 11)');
is($xpc->findvalue('//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:GrandTotalAmount'),
   '331.00', 'GrandTotalAmount = 331.00');
is($xpc->findvalue('//ram:SpecifiedTradeSettlementHeaderMonetarySummation/ram:DuePayableAmount'),
   '331.00', 'DuePayableAmount = 331.00');

# SIRET côté seller, pas côté buyer
is($xpc->findvalue('//ram:SellerTradeParty/ram:SpecifiedLegalOrganization/ram:ID'),
   '12345678901234', 'seller SIRET present');
my @buyer_org = $xpc->findnodes('//ram:BuyerTradeParty/ram:SpecifiedLegalOrganization');
is(scalar @buyer_org, 0, 'buyer has no SpecifiedLegalOrganization');
