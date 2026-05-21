use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use PDF::FacturX::XML   qw(build_xml);
use PDF::FacturX::Embed qw(embed_xml_pdfa3);
use PDF::Builder;

# Skip si Ghostscript pas installé
my $gs_path = `which gs 2>/dev/null`;
chomp $gs_path;
plan skip_all => 'Ghostscript (gs) not installed' unless $gs_path && -x $gs_path;

plan tests => 9;

my $invoice = {
    number   => 'FA-2026-EMBED',
    date     => '2026-04-19',
    due_date => '2026-05-19',
    currency => 'EUR',
    seller   => { name => 'Acme SARL', siret => '12345678901234',
                  address_1 => '1 rue T', postcode => '75001', city => 'Paris', country => 'FR' },
    buyer    => { name => 'Client SAS', address_1 => '2 av B',
                  postcode => '69002', city => 'Lyon', country => 'FR' },
    lines    => [
        { name => 'Service', qty => 1, unit_price => 1000, vat_rate => 20, vat_cat => 'S' },
    ],
};

my $xml = build_xml($invoice, 'basic');

my $tmp     = tempdir(CLEANUP => 1);
my $pdf_in  = 't/data/source.pdf';
my $pdf_out = File::Spec->catfile($tmp, 'out.pdf');

ok(-r $pdf_in, "fixture PDF readable: $pdf_in") or BAIL_OUT("missing fixture");

my @warnings;
my ($ok, $msg) = embed_xml_pdfa3(
    pdf_in     => $pdf_in,
    xml        => $xml,
    pdf_out    => $pdf_out,
    profile    => 'basic',
    title      => 'Facture FA-2026-EMBED',
    author     => 'Acme SARL',
    on_warning => sub { push @warnings, $_[0] },
);
ok($ok, "embed_xml_pdfa3 OK: $msg") or diag("error: $msg");
ok(-s $pdf_out > 0, "PDF output non-empty");

# Inspection structurelle via PDF::Builder
my $pdf = PDF::Builder->open($pdf_out);
my $cat = $pdf->{catalog};

ok(ref $cat->{AF},             '/AF array present in Catalog');
ok(ref $cat->{OutputIntents},  '/OutputIntents present in Catalog');
ok(ref $cat->{Names},          '/Names present (EmbeddedFiles holder)');
ok(ref $cat->{Metadata},       '/Metadata stream present (XMP)');

# XMP Metadata stream content : doit contenir pdfaid + Factur-X
my $meta_obj = $cat->{Metadata}->realise;
my $xmp_bytes = $meta_obj->{' stream'};
like($xmp_bytes, qr{pdfaid:part>3</pdfaid:part}, 'XMP declares pdfaid:part 3');
like($xmp_bytes, qr{fx:ConformanceLevel>BASIC},   'XMP declares Factur-X profile BASIC');
