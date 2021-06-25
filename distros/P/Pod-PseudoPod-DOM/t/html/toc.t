use strict;
use warnings;

use Test::More;

use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::HTML';
use File::Spec::Functions;
use File::Slurp;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my $file           = read_file( catfile( qw( t test_file.pod ) ) );
my ($doc, $result) = parse_with_anchors( $file, filename => 'html_toc.html' );
my $toc            = $doc->emit_toc;

my $link           = encode_link( 'SomeDocument' );

like   $toc, qr/Some Document/, 'TOC should contain chapter heading';
like   $toc, qr!<a href="html_toc.html#$link">Some Document</a>!,
    '... with link to chapter heading anchor';

$link  = encode_link( 'AHeading' );
like   $toc, qr/A Heading/, 'TOC should contain section heading';
like   $toc, qr!<a href="html_toc.html#$link">A Heading</a>!,
    '... with link to section heading anchor';

$link  = encode_link( 'Bheading' );
like   $toc, qr/B heading/, 'TOC should contain sub-section heading';
like   $toc, qr!<a href="html_toc.html#$link">B heading</a>!,
    '... with link to sub-section heading anchor';

$link  = encode_link( 'cheading' );
like   $toc, qr/c heading/, 'TOC should contain sub-sub-section heading';
like   $toc, qr!<a href="html_toc.html#$link">c heading</a>!,
    '... with link to sub-sub-section heading anchor';

unlike $toc, qr/Another Suppressed Heading/,
    'TOC should lack suppressed chapter heading';
unlike $toc, qr/A Suppressed Heading/,
    'TOC should lack suppressed section heading';
unlike $toc, qr/Yet Another Suppressed Heading/,
    'TOC should lack suppressed sub-section heading';

done_testing;
