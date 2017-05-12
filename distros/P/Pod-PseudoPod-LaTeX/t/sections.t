#! perl

use strict;
use warnings;

use IO::String;
use File::Spec::Functions;

use Test::More tests => 16;

use_ok( 'Pod::PseudoPod::LaTeX' ) or exit;

my $fh     = IO::String->new();
my $parser = Pod::PseudoPod::LaTeX->new();
$parser->output_fh( $fh );
$parser->parse_file( catfile( qw( t test_file.pod ) ) );

$fh->setpos(0);
my $text  = join( '', <$fh> );

like( $text, qr/\\chapter\{Some Document}/,
    '0 heads should become chapter titles' );

like( $text, qr/\\section\*\{A Heading}/,
    'A heads should become section titles' );

like( $text, qr/\\subsection\*\{B heading}/,
    'B heads should become subsection titles' );

like( $text, qr/\\subsubsection\*\{c heading}/,
    'C heads should become subsubsection titles' );

like( $text, qr/\\begin\{Verbatim}.+"This text.+--.+\$text."\n\\end\{Verbatim}/s,
    'programlistings should become unescaped, verbatim text' );

like( $text, qr/\\begin\{Verbatim}.*label=.+This should also be \$unm0d\+ified\n\\end\{Verbatim}/s,
    'screens should become unescaped, verbatim text' );

like( $text, qr/Blockquoted text.+``escaped''\./,
    'blockquoted text gets escaped' );

like( $text, qr/\\begin\{description}.+\\item\[\] Verbatim\n\n/s,
    'text-item lists need description formatting to start' );

like( $text, qr/\\item\[\] items\n\n\\end\{description}/,
    '... and to end' );

like( $text, qr/rule too:\n\n.+?\\begin\{itemize}.+?\\item BANG\n\n/s,
    'bulleted lists need itemized formatting to start' );

like( $text, qr/\\item BANGERANG!\n\n\\end\{itemize}/,
    '... and to end' );

like( $text,
    qr/\\begin\{description}.+?\\item\[\] wakawaka.+?What/s,
    'definition lists need description formatting to start' );

like( $text, qr/\\item\[\] ook ook\n\nWhat.+says\.\n\n\\end\{description}/,
    '... and to end' );

TODO:
{
    local $TODO = "Seems like an upstream bug here\n";

    like( $text, qr/\\begin\{enumerate}.+\\item \[22\] First/,
        'enumerated lists need their numbers intact' );

    like( $text, qr/\\item \[77\].+Fooled you!.+\\end\{itemize}/,
        '... and their itemized endings okay' );
}
