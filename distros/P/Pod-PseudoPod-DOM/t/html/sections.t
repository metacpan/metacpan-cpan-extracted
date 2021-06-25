#! perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::HTML';
use Pod::PseudoPod::DOM::App;
use File::Spec::Functions;
use File::Slurp;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my %anchors;
my $file   = read_file( catfile( qw( t test_file.pod ) ) );
my $result = parse_with_anchors( $file );

my $link   = encode_link( 'SomeDocument' );
my $l2     = encode_link( 'startofdocument' );
like_string $result,
    qr!<h1 id="$l2"><a name="$link"></a>Some Document</h1>!,
    '0 heads should become chapter titles';

$link = encode_link( 'AHeading' );
$l2   = encode_link( 'next_heading' );
like_string $result, qr!<h2 id="$l2"><a name="$link"></a>A Heading</h2>!,
    'A heads should become section titles';

$link = encode_link( 'Bheading' );
$l2   = encode_link( 'slightlycomplex?heading' );
contains_string $result, qq!<h3 id="$l2"><a name="$link"></a>B heading</h3>!,
    'B heads should become subsection titles' . " $l2 $link ";

lacks_string $result, qq|<p id="$l2">|,
    '... and rolled up anchors should not appear in paragraphs too';

$link = encode_link( 'cheading' );
like_string $result, qr!<h4 id="$link">c heading</h4>!,
    'C heads should become subsubsection titles';

$link = encode_link( 'AnotherSuppressedHeading' );
contains_string $result,
    qq!<h1 id="$link">Another Suppressed Heading</h1>!,
    '... chapter title TOC suppression should create heading';

$link = encode_link( 'AnotherSuppressedHeading' );
lacks_string $result, qq!<a name="$link"></a>!,
    '... without anchor';

$link = encode_link( 'ASuppressedHeading' );
contains_string $result, qq!<h2 id="$link">A Suppressed Heading</h2>!,
    '... section title suppression should create heading';

lacks_string $result, qq!<a name="$link"></a>!,
    '... without anchor';

$link = encode_link( 'YetAnotherSuppressedHeading' );
contains_string $result,
    qq!<h3 id="$link">Yet Another Suppressed Heading</h3>!,
    '... subsection title suppression should create heading';

lacks_string $result, qq!<a name="$link"></a>!,
    '... without anchor';

like_string $result,
    qr/<pre><code>\s*&quot;This text.+--.+ \$text.&quot;\n/s,
    'programlistings should become unescaped, verbatim result';

like_string $result,
    qr!<pre><code>\s*This should also be \$unm0d\+ified</code>!s,
    'screens should become unescaped, verbatim result';

like_string $result,
    qr/class="blockquote">\s*<p>Blockquoted text.+&quot;escaped&quot;\./,
    'blockquoted text gets escaped';

like_string $result, qr!<ul>\s*<li>Verbatim</li>!s,
    'text-item lists need description formatting to start';

like_string $result, qr!<li>items</li>\s*</ul>!,
    '... and to end';

like_string $result, qr!rule too:</p>\s*<ul>!s,
    'bulleted lists need to start as unordered lists';

like_string $result, qr!<ul>\s*<li>BANG</li>!s,
    'bulleted lists need itemized formatting to start';

like_string $result, qr|<li>BANGERANG!</li>\s*</ul>|,
    '... and to end';

like_string $result,
    qr!<ul>\s*<li><p>wakawaka</p>\s*<p>What Pac-Man says.</p>\s*</li>!s,
    'definition lists need description formatting to start';

like_string $result,
    qr!<li><p>ook ook</p>\s*<p>What.+says\.</p>\s*</li>\s*</ul>!,
    '... and to end';

like_string $result,
    qr!<div class="literal"><p>Here are several paragraphs.</p>!s,
    'literal sections should work';

like_string $result,
    qr!<p>They should have <em>newlines</em> in between them\.</p>!s,
    '... even with subelements of paragraphs';

like_string $result, qr!them\.</p>\s*<p></p>!,
    '... even with extra embedded newlines';

like_string $result,
    qr!part of some document \(.+?>Some Document</a>; .+?>Some Document</a>\)!,
    'Z<> and A<> tags should use contents of previous heading for text';

TODO:
{
    local $TODO = "Seems like an upstream bug here\n";

    like_string $result, qr/\\begin\{enumerate}.+\\item \[2\] First/,
        'enumerated lists need their numbers intact';

    like_string $result, qr/\\item \[77\].+Fooled you!.+\\end\{itemize}/s,
        '... and their itemized endings okay';
}

done_testing;
