#! perl

use strict;
use warnings;

use IO::String;
use File::Spec::Functions;

use Test::More tests => 18;

use_ok( 'Pod::PseudoPod::LaTeX' ) or exit;

my $fh     = IO::String->new();
my $parser = Pod::PseudoPod::LaTeX->new();
$parser->output_fh( $fh );
$parser->parse_file( catfile( qw( t test_file.pod ) ) );

$fh->setpos(0);
my $text = join( '', <$fh> );

like( $text, qr/something special too.\n\n``The interesting/,
	'blank lines should remain between paragraphs' );

like( $text, qr/\\'a la/,
	'acute diacritic should translate to single quote escape' );

like( $text, qr/na\\"ive/,
	'umlaut diacritic should translate to double quote escape' );

like( $text, qr/attach\\`e/,
	'grave diacritic should translate to single backquote escape' );

like( $text, qr/Fran\\c\{c}aise/, 'cedilla should translate to \c{c}' );

like( $text, qr/\\copyright caper/, 'copyright symbol should get escaped' );

like( $text, qr/ligatures---and/,
	'double hyphen dash should become unspacey long dash' );

like( $text, qr/\\ensuremath\{\\pm} some constant/, 'plusmn should get an escape too' );

like( $text, qr/\\textbf\{very} important/,
	'bold text needs a formatting directive' );

like( $text, qr/\\texttt\{code-like text}/,
	'code-marked text needs a formatting directive' );

like( $text, qr/special \\emph\{emphasis}/,
	'file paths need an emphasis directive' );

like( $text, qr/\\emph\{semantic-only emphasis}/,
	'... and so does italicized text' );

like( $text, qr/\\footnote\{but beware of footnotes!}/,
	'footnotes need special escaping too' );

like( $text, qr/\\index\{Special formatting|textit}/,
	'indexed items need even more special escaping' );

like( $text, qr/mc\$\^\{2\}\$/, 'superscript works' );

like( $text, qr/H\$\_\{2\}\$O/, 'subscript works' );

like( $text, qr[\\url\{http://www.google.com/}], 'urls work');
