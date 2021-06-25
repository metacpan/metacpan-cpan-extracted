use strict;
use warnings;

use Test::More;
use Test::LongString;

use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::HTML';
use File::Spec::Functions;
use File::Slurp;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my $file           = read_file( catfile( qw( t test_file.pod ) ) );
my ($doc, $result) = parse_with_anchors( $file );

my $link = encode_link( 'figure_link' );
like_string $result, qr/<p id="$link">/,
    'figure should start a figure environment';
like_string $result, qr!<img src="some/path/to/image_file.png"!,
    '... without quoting image file paths';
like_string $result, qr!<br />\s*<em>A Figure with Caption</em>!,
    '... and caption';
like_string $result, qr!Caption</em>\s*</p>!,
    '... and ending figure';

done_testing;
