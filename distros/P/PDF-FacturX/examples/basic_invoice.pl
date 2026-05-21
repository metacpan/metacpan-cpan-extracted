#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use PDF::FacturX qw(generate);

# This example takes a source PDF and writes a Factur-X PDF/A-3 next to it.
# Run from the project root:
#
#   perl examples/basic_invoice.pl
#
# Requires Ghostscript installed (`gs` in PATH).

my $pdf_in  = "$Bin/../t/data/source.pdf";    # any visual PDF
my $pdf_out = "$Bin/output.pdf";

my %invoice = (
    number   => 'FA-2026-EXAMPLE',
    date     => '2026-04-19',
    due_date => '2026-05-19',
    currency => 'EUR',
    seller   => {
        name      => 'Acme SARL',
        siret     => '12345678901234',
        vat       => 'FR12345678901',
        address_1 => '1 rue de la Paix',
        postcode  => '75001',
        city      => 'Paris',
        country   => 'FR',
    },
    buyer => {
        name      => 'Kunde GmbH',
        address_1 => 'Hauptstrasse 1',
        postcode  => '10115',
        city      => 'Berlin',
        country   => 'DE',
    },
    lines => [
        { name => 'Conseil',          qty => 8, unit_price => 125,
          vat_rate => 20, vat_cat => 'S' },
        { name => 'Restauration',     qty => 1, unit_price => 50,
          vat_rate => 5.5, vat_cat => 'S' },
    ],
    payment => {
        terms => 'Paiement à 30 jours',
        iban  => 'FR7612345678901234567890123',
        bic   => 'BNPAFRPP',
    },
);

my ($ok, $msg) = generate(
    pdf_in  => $pdf_in,
    pdf_out => $pdf_out,
    invoice => \%invoice,
    profile => 'en16931',
    title   => 'Facture FA-2026-EXAMPLE',
    author  => 'Acme SARL',
);

if ($ok) {
    print "Factur-X PDF/A-3 written to: $pdf_out\n";
    print "  $msg\n";
}
else {
    die "Factur-X generation failed: $msg\n";
}
