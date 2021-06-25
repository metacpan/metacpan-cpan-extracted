use strict;
use warnings;

use Test::More;
use Test::LongString;

use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::HTML';
use File::Spec::Functions;
use File::Slurp;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my $file   = read_file( catfile( qw( t test_file.pod ) ) );
my $result = parse_with_anchors( $file );

like_string $result, qr!normal numbered lists:</p>\s*<ol>!,
    'numbered lists should translate to <ol> lists';

like_string $result,
    qr!<li number="1">Something\.</li>!,
    '... using <li> tags with numbers';

like_string $result,
    qr!<li number="2">Or\.</li>!,
    '... the *right* numbers';

like_string $result,
    qr!<li number="3">Other\.</li>\s*</ol>!,
    '... and ending appropriately';

like_string $result,
    qr!Basic bulleted list:</p>\s*<ul>\s*<li>First item</li>!,
    'Basic bulleted lists should be itemized';

done_testing;
