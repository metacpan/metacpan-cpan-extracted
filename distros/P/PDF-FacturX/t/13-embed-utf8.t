use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use PDF::FacturX::XML   qw(build_xml);
use PDF::FacturX::Embed qw(embed_xml_pdfa3);
use PDF::Builder;

my $gs_path = `which gs 2>/dev/null`;
chomp $gs_path;
plan skip_all => 'Ghostscript (gs) not installed' unless $gs_path && -x $gs_path;

plan tests => 4;

# Scénario : noms avec caractères accentués (« Poséidon ») + monnaie €
my $invoice = {
    number   => 'FA-2026-UTF8',
    date     => '2026-04-19',
    currency => 'EUR',
    seller   => { name => 'Société Poséidon', country => 'FR',
                  address_1 => 'Quai des Açores' },
    buyer    => { name => 'Müller GmbH',     country => 'DE' },
    lines    => [
        { name => 'Étude technique « façade »',
          qty => 1, unit_price => 100, vat_rate => 20, vat_cat => 'S' },
    ],
};

my $xml = build_xml($invoice, 'basic');

# Le XML sortant doit déjà être en UTF-8 lisible côté Perl (caractères, pas octets)
like($xml, qr/Société Poséidon/,        'XML preserves seller name with accents');
like($xml, qr/Étude technique « façade »/, 'XML preserves line name with accents + guillemets');

# Embed end-to-end — contenu attaché doit toujours contenir les accents intacts
my $tmp     = tempdir(CLEANUP => 1);
my $pdf_out = File::Spec->catfile($tmp, 'utf8.pdf');

my ($ok, $msg) = embed_xml_pdfa3(
    pdf_in  => 't/data/source.pdf',
    xml     => $xml,
    pdf_out => $pdf_out,
    profile => 'basic',
    title   => 'Facture Société Poséidon',
);
ok($ok, "embed OK: $msg") or BAIL_OUT($msg);

# Le XML embarqué dans le PDF doit contenir le seller name intact (pas double-encodé).
# PDF::Builder ré-écrit le stream avec FlateDecode → on dézippe avant de matcher.
use Compress::Zlib qw(uncompress);
use Encode qw(decode_utf8);

my $pdf   = PDF::Builder->open($pdf_out);
my $names = $pdf->{catalog}{Names}{EmbeddedFiles}{Names}->realise;
my $fs    = $names->{' val'}->[1]->realise;
my $f     = $fs->{EF}->realise->{F}->realise;
my $raw   = $f->{' stream'};
my $xml_bytes = (ref $f->{Filter}) ? uncompress($raw) : $raw;
my $xml_chars = decode_utf8($xml_bytes);
like($xml_chars, qr/Société Poséidon/,
    'embedded XML preserves UTF-8 (no double-encoding)');
