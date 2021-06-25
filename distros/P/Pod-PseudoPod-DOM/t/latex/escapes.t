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

like_string $result,
    qr/"This text should not be escaped -\\mbox\{}- it is normal \\\$text\."/,
    'verbatim sections should be unescaped';

like_string $result,
    qr|\\#!/bin/perl does need escaping, but not \\textbackslash\{\} \(back|,
    '... except for a few metacharacters';

like_string $result, qr/\\mbox\{}- it is also "normal".+\$text./s,
    '... indented too';

like_string $result, qr/octothorpe, \\#/,            '# should get quoted';
like_string $result, qr/\\\$/,                       '$ should get quoted';
like_string $result, qr/\\&/,                        '& should get quoted';
like_string $result, qr/\\%/,                        '% should get quoted';
like_string $result, qr/ \\_\./,                     '_ should get quoted';
like_string $result, qr/ \\textasciitilde\{}/,        '~ should get quoted';
like_string $result, qr/caret \\char94\{\}/,         '^  should get quoted';

like_string $result, qr/escaping: \$\\textbackslash\$/, '\ should get quoted';
like_string $result, qr/\\\{\\},/, '{ and } should get quoted';

like_string $result, qr/``The interesting/,
    'starting double quotes should turn into double opening single quotes';

like_string $result, qr/, ``they turn/, '... even inside a paragraph';

like_string $result, qr/quotes,'' he said,/,
    'ending double quotes should turn into double closing single quotes';

like_string $result, qr/ direction\.''/, '... also at the end of a paragraph';

like_string $result, qr/ellipsis\\ldots and/, 'ellipsis needs a translation';

like_string $result, qr/f\\mbox\{}lame/, 'fl ligature needs marking';

like_string $result, qr/f\\mbox\{}ilk/, 'fi ligature also needs marking';

like_string $result, qr/inef\\mbox\{}fable/,
    'ff ligature also needs marking too';

like_string $result, qr/ligatures---and/,
    'spacey double dash should become a real emdash';

like_string $result, qr/\\index\{negation "! operator}/,
    '! must be quoted with " in an index entry';

like_string $result, qr/\\index\{array "@ sigil}/,
    '@ must be quoted with " in an index entry';

like_string $result, qr/\\index\{the pipe "|}/,
    '| must be quoted with " in an index entry';

like_string $result, qr/\\index\{strange quote a""a}/,
    'non-escaped " must be quoted with another " in an index entry';

like_string $result, qr/\$\\char94\{}W}!carats}/,
    '... and carat needs special treatment';

like_string $result, qr/\\index\{hierarchical terms!omitting trailing spaces}/,
    'trailing spaces in hierarchical terms should be ignored';

like_string $result, qr/\\index\{code\@\\texttt\{code} and \\emph\{italics} text}/,
    '... but interior space should remain';

like_string $result, qr/\\index\{arrays!splice\@\\texttt\{splice}} is even more/,
    '... and formatting in indexes should still work';

like_string $result, qr/\\index\{\\textless\{}=\\textgreater\{}\@\\texttt/,
    '... even with escaped symbols';

like_string $result, qr/\\\$BANG BANG\\\$/,
    'escapes works inside items first line';

like_string $result, qr/And they \\_ are \\\$ properly \\\% escaped/,
    'escapes works inside items paragraphs';

like_string $result, qr/has\\_method/,
    'escapes works inside description lists';

like_string $result, qr/add\\_method/,
    'escapes works inside description lists paragraphs';

done_testing;
