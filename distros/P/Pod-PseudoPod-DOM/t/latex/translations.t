use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::LongString;
use TestDOM 'Pod::PseudoPod::DOM::Role::LaTeX';

use File::Slurp;
use File::Spec::Functions;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my $file   = read_file( catfile( qw( t test_file.pod ) ) );
my $result = parse( $file );

like_string $result, qr/something special too.\n\n``The interesting/,
    'blank lines should remain between paragraphs';

like_string $result, qr/\\'a la/,
    'acute diacritic should translate to single quote escape';

like_string $result, qr/na\\"ive/,
    'umlaut diacritic should translate to double quote escape';

like_string $result, qr/attach\\`e/,
    'grave diacritic should translate to single backquote escape';

like_string $result, qr/Fran\\c\{c\}aise/, 'cedilla should translate to \c';

like_string $result, qr/fun ones\\texttrademark./,
    '... and trademark symbol needs an escape';

like_string $result, qr/\\copyright caper/,
    'copyright symbol should get escaped';

like_string $result, qr/ligatures---and/,
    'double hyphen dash should become unspacey long dash';

like_string $result, qr/\\pm some constant/, 'plusmn should get an escape too';

like_string $result, qr/\\textbf\{very} important/,
    'bold text needs a formatting directive';

like_string $result, qr/\\texttt\{code-like text}/,
    'code-marked text needs a formatting directive';

like_string $result,
    qr/\\texttt\{\\textquotesingle\{}single quotes\\textquotesingle\{}}/,
    '... and needs special treatment for single quotes';

like_string $result, qr/such as \\texttt\{0\}/,
    '... even if text is Perl-like false';

like_string $result, qr/\$some\\_variable-\\mbox\{\}-/,
    '... and if it contains special characters';

like_string $result, qr/special \\emph\{emphasis}/,
    'file paths need an emphasis directive';

like_string $result, qr/or \\emph\{0\} should/,
    '... even if text is Perl-like false';

like_string $result, qr/\\emph\{semantic-only emphasis}/,
    '... and so does italicized text';

like_string $result, qr/\\footnote\{but beware of footnotes!}/,
    'footnotes need special escaping too';

like_string $result, qr/\\index\{Special formatting}/,
    'indexed items need even more special escaping';

like_string $result, qr/mc\$\^\{2\}\$/, 'superscript works';

like_string $result, qr/H\$\_\{2\}\$O/, 'subscript works';

like_string $result, qr[\\url\{http://www.google.com/}], 'urls work';

done_testing;
