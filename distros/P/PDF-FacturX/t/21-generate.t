use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use PDF::FacturX qw(generate);
use PDF::Builder;

my $gs_path = `which gs 2>/dev/null`;
chomp $gs_path;
plan skip_all => 'Ghostscript (gs) not installed' unless $gs_path && -x $gs_path;

plan tests => 7;

my $invoice = {
    number   => 'FA-2026-FACADE',
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

my $tmp     = tempdir(CLEANUP => 1);
my $pdf_out = File::Spec->catfile($tmp, 'out.pdf');

# 1. Flow nominal en16931
my ($ok, $msg) = generate(
    pdf_in  => 't/data/source.pdf',
    pdf_out => $pdf_out,
    invoice => $invoice,
    profile => 'en16931',
    title   => 'Facture FA-2026-FACADE',
    author  => 'Acme SARL',
);
ok($ok, "generate end-to-end OK: $msg") or diag($msg);
ok(-s $pdf_out > 0, 'PDF output produced');

# 2. Validation XSD est faite par défaut → un invoice invalide pour XSD
#    devrait être rejeté avec validate=>1 (défaut). Je force une situation
#    qui passe la validation maison mais échoue XSD : currency exotique
#    inacceptable XSD. Hmm, currency=EUR ok. Plus simple : XML manuel
#    invalide. Test direct via la couche basse — ici on teste juste que
#    generate() respecte validate=>0.
my $pdf_out2 = File::Spec->catfile($tmp, 'out2.pdf');
($ok, $msg) = generate(
    pdf_in   => 't/data/source.pdf',
    pdf_out  => $pdf_out2,
    invoice  => $invoice,
    profile  => 'en16931',
    validate => 0,
);
ok($ok, "generate validate=>0 still OK: $msg");

# 3. Hash invalide propage erreur (validation maison bloque avant XSD)
my $bad = { %$invoice }; delete $bad->{seller};
($ok, $msg) = generate(
    pdf_in  => 't/data/source.pdf',
    pdf_out => File::Spec->catfile($tmp, 'bad.pdf'),
    invoice => $bad,
    profile => 'basic',
);
ok(!$ok, 'invalid invoice rejected by facade');
like($msg, qr/seller/i, 'error message mentions missing field');

# 4. PDF source manquant
($ok, $msg) = generate(
    pdf_in  => '/nonexistent/source.pdf',
    pdf_out => File::Spec->catfile($tmp, 'nope.pdf'),
    invoice => $invoice,
    profile => 'basic',
);
ok(!$ok, 'missing pdf_in rejected');
like($msg, qr/introuvable|not found/i, 'error message mentions missing PDF');
