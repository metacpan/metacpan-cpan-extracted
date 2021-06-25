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

contains_string $result, qq!\\label\{startofdocument}!,
    'Z<> tags should become labels';

like_string $result, qr!\\label\{next_heading}!, '... without normal escaping';

like_string $result, qr!\\label\{slightly-complex-heading}!,
    '... and escaping non-alphanumerics';

like_string $result, qr!\\url\{http://www.google.com/}!,
    'U<> tag should become urls';

like_string $result, qr!\\ppodxref\{startofdocument}!,
    'L<> tag should become cross references';

like_string $result, qr!; \\ppodxref\{startofdocument}!,
    'A<> tag should become cross references';

like_string $result, qr!\\ppodxref\{slightly-complex-heading}!,
    '... with appropriate quoting';

like_string $result, qr!\\ppodxref\{next_heading}!,
    '... and non-quoting when appropriate';

like_string $result, qr!\\index\{Special formatting}\s*Special!,
    'index tags in separate paragraphs should suppress newlines';

done_testing;
