use strict;
use warnings;

use Test::More;
use Test::LongString;

use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::HTML';

use File::Slurp;
use File::Spec::Functions;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my $file   = read_file( catfile( qw( t test_file.pod ) ) );
my $result = parse_with_anchors( $file );

like_string $result, qr!<div class="sidebar">!,
    'sidebar should produce a sidebar div';

like_string $result, qr!<p class="title">Sidebar Has Title</p>!,
    '... including the title';

like_string $result, qr!<p>Hello, this is a =begin sidebar\.</p>\s*</div>!,
    '... and ending the div';

done_testing;
