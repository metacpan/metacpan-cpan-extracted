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

like_string $result,
    qr/&quot;This text should not be escaped -- it is normal \$text\.&quot;/,
    'verbatim sections should be unescaped';

like_string $result,
    qr|#!/bin/perl does need escaping, but not \\ \(back|,
    '... including a few metacharacters';

like_string $result, qr/-- it is also &quot;normal&quot;.+\$text./s,
    '... indented too';

like_string $result, qr/octothorpe, #/,              '# needs no quoting';
like_string $result, qr/ \$/,                        '$ needs no quoting';

like_string $result, qr/&amp;/,                      '& should get quoted';
like_string $result, qr/ %/,                         '% needs no quoting';
like_string $result, qr/ _\./,                       '_ needs no quoting';
like_string $result, qr/ ~/,                         '~ needs no quoting';
like_string $result, qr/caret \^/,                   '^ needs no quoting';

like_string $result, qr/escaping: \\\./,             '\ needs no quoting';
like_string $result, qr/\{\},/,                      '{ and } need no quoting';

like_string $result, qr/&quot;The interesting/,
    'starting double quotes should get escaped into entity';

like_string $result, qr/, &quot;they turn/, '... even inside a paragraph';

like_string $result, qr/quotes,&quot; he said,/,
    'ending double quotes should get escaped into entity';

like_string $result, qr/ direction\.&quot;/,
    '... also at the end of a paragraph';

like_string $result, qr/ellipsis\.\.\. and/, 'ellipsis needs no translation';

like_string $result, qr/flame/, 'fl ligature gets no marking';

like_string $result, qr/filk/, 'fi ligature also gets no marking';

like_string $result, qr/ineffable/, 'ff ligature also gets no marking';

like_string $result, qr/ligatures&mdash;and/,
    'spacey double dash should become a real emdash';

my $link = encode_link( 'negation!operator' );
like_string $result, qr/<a name="${link}1">/,
    '! needs URI encoding in index anchor';

$link = encode_link( 'array@sigil' );
like_string $result, qr/<a name="${link}1">/,
    '@ needs URI encoding in index anchor';

$link = encode_link( 'thepipe|' );
like_string $result, qr/<a name="${link}1">/,
    'spaces removed from index anchors';

$link = encode_link( 'strangequoteaa' );
like_string $result, qr/<a name="${link}1">/,
    'quotes removed from index anchors';

$link = encode_link( '$^W;carats' );
like_string $result, qr/<a name="${link}1">/,
    '... carat needs URI encoding in anchor';

$link = encode_link( 'hierarchicalterms;omittingtrailingspaces' );
like_string $result, qr/<a name="${link}1">/,
    'trailing spaces in hierarchical terms should be ignored';

$link = encode_link( 'codeanditalicstext' );
like_string $result, qr/<a name="${link}1">/,
    '... and code/italics formatting';

$link = encode_link( '<=>;numericcomparisonoperator' );
like_string $result, qr/<a name="${link}1">/,
    '... and should escape <> symbols';

$link = encode_link( 'sigils;&' );
like_string $result, qr/<a name="${link}1">/,
    '... in index anchors as well';

$link = encode_link( '.tfiles' );
like_string $result, qr/<a name="${link}1">/,
    '... and should suppress HTML tags in index anchors';

$link = encode_link( 'operators;<' );
like_string $result, qr/<a name="${link}1">/,
    '... encoding entities as necessary';

like_string $result, qr/<code>&lt;=&gt;<\/code>/,
    '... even when specified as characters';

like_string $result, qr/<li>\$BANG BANG\$<p>/,
    'escapes work inside items first line';

like_string $result, qr/And they _ are \$ properly \% escaped/,
    'escapes work inside items paragraphs';

like_string $result, qr/has_method/, 'no need to escape _';

like_string $result, qr/add_method/, '... anywhere';

done_testing;
