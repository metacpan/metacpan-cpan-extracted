use strict;
use warnings;

use Test::More;
use Test::LongString;

use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::LaTeX';

use File::Slurp;
use File::Spec::Functions;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my $file   = read_file( catfile( qw( t test_file.pod ) ) );
my $result = parse( $file );

like_string $result, qr|\\begin\{figure}\[H\]\n\\begin\{center}\n\\begin\{Sbox}|,
    'sidebar should begin an Sbox centered in a figure';
like_string $result, qr|\\begin\{Sbox}\n\\begin\{minipage}\{\\linewidth}\n|,
    '... with a minipage of the linewidth';
like_string $result, qr|\{\\linewidth}\n\nHello, this is a sidebar\n\n|,
    '... and the sidebar contents';
like_string $result, qr|sidebar\n\n\\end\{minipage}\n\\end\{Sbox}\n|,
    '... closing the minipage and Sbox';
like_string $result, qr|Sbox}\n\\framebox\{\\TheSbox}\n|,
    '... wrapping the Sbox in a framebox';
like_string $result, qr|TheSbox}\n\\end\{center}\n\\end\{figure}\n|,
    '... and ending the centered figure';

done_testing();
