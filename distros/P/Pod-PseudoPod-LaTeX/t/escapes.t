#! perl

use strict;
use warnings;

use IO::String;
use File::Spec::Functions;

use Test::More tests => 30;

use_ok( 'Pod::PseudoPod::LaTeX' ) or exit;

my $fh     = IO::String->new();
my $parser = Pod::PseudoPod::LaTeX->new();
$parser->output_fh( $fh );
$parser->parse_file( catfile( qw( t test_file.pod ) ) );

$fh->setpos(0);
my $text  = join( '', <$fh> );

like( $text, qr/"This text should not be escaped -- it is normal \$text."/,
	'verbatim sections should be unescaped.' );

like( $text, qr/-- it is also "normal".+\$text./s, '... indented too' );

like( $text, qr/octothorpe, \\#/,            '# should get quoted' );
like( $text, qr/escaping: \$\\backslash\$/,  '\ should get quoted' );
like( $text, qr/\\\$/,                       '$ should get quoted' );
like( $text, qr/\\&/,                        '& should get quoted' );
like( $text, qr/\\%/,                        '% should get quoted' );
like( $text, qr/ \\_\./,                     '_ should get quoted' );
like( $text, qr/\\\{\\},/,                   '{ and } should get quoted' );
like( $text, qr/ \$\\sim\$/,                 '~ should get quoted' );
like( $text, qr/caret \\char94\{\}/,         '^  should get quoted' );

like( $text, qr/``The interesting/,
	'starting double quotes should turn into double opening single quotes' );

like( $text, qr/, ``they turn/, '... even inside a paragraph' );

like( $text, qr/quotes,'' he said,/,
	'ending double quotes should turn into double closing single quotes' );

like( $text, qr/ direction\.''/, '... also at the end of a paragraph' );

like( $text, qr/ellipsis\\ldots and/, 'ellipsis needs a translation' );

like( $text, qr/f\\mbox\{}lame/, 'fl ligature needs marking' );

like( $text, qr/f\\mbox\{}ilk/, 'fi ligature also needs marking' );

like( $text, qr/inef\\mbox\{}fable/, 'ff ligature also needs marking too' );

like( $text, qr/ligatures---and/,
	'spacey double dash should become a real emdash' );

like( $text, qr/\\index\{negation "! operator}/,
	'! must me quoted with " in an index entry' );

like( $text, qr/\\index\{array "@ sigil}/,
	'@ must me quoted with " in an index entry' );

like( $text, qr/\\index\{the pipe "|}/,
	'| must me quoted with " in an index entry' );

like( $text, qr/\\index\{strange quote a""a}/,
	'non-escaped " must me quoted with another " in an index entry' );

like( $text, qr/\\index\{hierarchical terms!omiting trailing spaces}/,
	'trailing spaces in hierarchical terms should be ignored' );

like( $text, qr/\\\$BANG BANG\\\$/,
        'escapes works inside items first line');

like( $text, qr/And they \\_ are \\\$ properly \\\% escaped/,
        'escapes works inside items paragraphs');

like( $text, qr/has\\_method/,
        'escapes works inside description lists');

like( $text, qr/add\\_method/,
        'escapes works inside description lists paragraphs');
