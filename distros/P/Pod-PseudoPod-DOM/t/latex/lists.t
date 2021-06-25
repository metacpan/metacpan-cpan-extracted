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
my $result = parse( $file );

like_string $result, qr!normal numbered lists:\n\n\\begin\{enumerate}!,
    'numbered lists should translate to \\begin\{enumerate}';

like_string $result,
    qr!\\item Something\.\n\n\\item Or\.\n\n\\item Other\.\n\n\\end\{enumerate}!,
    '... and should use bare \\item';

like_string $result,
    qr!Basic bulleted list:\s+\\begin\{itemize}\s+\\item First item!,
    'Basic bulleted lists should be itemized';

done_testing;
