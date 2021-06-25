use strict;
use warnings;

use Test::More;
use Test::LongString;

use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::LaTeX';
use File::Spec::Functions;
use File::Slurp;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my $file   = read_file( catfile( qw( t test_file.pod ) ) );
my ( $doc, $result) = parse( $file );

like_string $result, qr/\\begin\{figure}\[H\]\n\\centering/,
    'figure should start a figure environment';
like_string $result, qr!\\includegraphics\[width=\\linewidth\]\{some/path!,
    '... with path to graphics file';
like_string $result, qr!\{some/path/to/image_file.png}!,
    '... without quoting image file paths';
like_string $result, qr!\\caption\{A Figure with Caption}!,
    '... and caption';
like_string $result, qr!\n\\label\{figure_link}\n!,
    '... and label';
like_string $result, qr!\\end\{figure}!,
    '... and ending figure environment';

done_testing;
