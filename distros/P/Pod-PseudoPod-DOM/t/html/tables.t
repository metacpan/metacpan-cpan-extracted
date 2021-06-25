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
my ($doc, $result) = parse_with_anchors( $file, filename => 'tables_test.tex' );

like $result, qr!<table>!, 'table should translate to <table>';

like $result, qr!<caption>A Table of!, '... containing caption';
like $result, qr!<caption>A Table of <em>Fun</em> Things</caption>!,
    '... with formatting preserved';

like $result,
    qr!<tr><th><em>Left Column</em></th><th><em>Right Column</em></th></tr>!,
    '... and head row';
like $result, qr!</th></tr>\s*<tr><td>Left Cell One</td>\s*<td><ul>!,
    '... and body cell';
like $result, qr!<td><ul>\s*<li>First item.+</li>\s*<li>Second item.+</ul>!s,
    '... with list in cell';
like $result, qr!</ul>\s*</td>\s*</tr>!s,
    '... and list ending';
like_string $result, qr!</td>\s*</tr>\s*</table>!,
    '... and table ending';

done_testing;
