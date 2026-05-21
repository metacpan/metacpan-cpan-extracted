use strict;
use warnings;
use utf8;
use Test::More tests => 6;
use XML::LibXML;

use PDF::FacturX::XML qw(build_xml);

my $invoice = {
    number   => 'FA-2026-0200',
    date     => '2026-04-19',
    due_date => '2026-05-19',
    currency => 'EUR',
    seller   => { name => 'Acme SARL', address_1 => '1 rue T', postcode => '75001', city => 'Paris', country => 'FR' },
    buyer    => { name => 'Client SAS', address_1 => '2 av B',  postcode => '69002', city => 'Lyon',  country => 'FR' },
    payment  => {
        terms => 'Paiement à 30 jours',
        iban  => 'FR7612345678901234567890123',
        bic   => 'BNPAFRPP',
    },
    lines => [
        { name => 'Conseil', qty => 1, unit_price => 1000, vat_rate => 20, vat_cat => 'S' },
    ],
};

# Profile en16931 : IBAN + BIC tous les deux émis
my $xml = build_xml($invoice, 'en16931');
my $doc = XML::LibXML->load_xml(string => $xml);
my $xpc = XML::LibXML::XPathContext->new($doc);
$xpc->registerNs(ram => 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100');

is($xpc->findvalue('//ram:PayeePartyCreditorFinancialAccount/ram:IBANID'),
   'FR7612345678901234567890123', 'IBAN present in en16931');
is($xpc->findvalue('//ram:PayeeSpecifiedCreditorFinancialInstitution/ram:BICID'),
   'BNPAFRPP', 'BIC present in en16931');
is($xpc->findvalue('//ram:SpecifiedTradePaymentTerms/ram:Description'),
   'Paiement à 30 jours', 'payment terms description (UTF-8 preserved)');

# Profile basic : BIC interdit (BT-86), IBAN seul
my $xml_basic = build_xml($invoice, 'basic');
my $doc_basic = XML::LibXML->load_xml(string => $xml_basic);
my $xpc_basic = XML::LibXML::XPathContext->new($doc_basic);
$xpc_basic->registerNs(ram => 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100');

is($xpc_basic->findvalue('//ram:PayeePartyCreditorFinancialAccount/ram:IBANID'),
   'FR7612345678901234567890123', 'IBAN present in basic');
my @bic_basic = $xpc_basic->findnodes('//ram:PayeeSpecifiedCreditorFinancialInstitution');
is(scalar @bic_basic, 0, 'BIC absent in basic profile (BT-86 forbidden)');

# DueDate
is($xpc->findvalue('//ram:SpecifiedTradePaymentTerms/ram:DueDateDateTime/*[local-name()="DateTimeString"]'),
   '20260519', 'due date formatted YYYYMMDD');
