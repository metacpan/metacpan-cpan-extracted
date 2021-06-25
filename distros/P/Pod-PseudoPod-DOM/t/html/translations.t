use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::LongString;
use TestDOM 'Pod::PseudoPod::DOM::Role::HTML';

use File::Slurp;
use File::Spec::Functions;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my $file   = read_file( catfile( qw( t test_file.pod ) ) );
my $result = parse_with_anchors( $file );

like_string $result, qr!something special too.</p>\s*<p>&quot;The interesting!,
    'blank lines should become real paragraphs';

like_string $result, qr/&aacute; la/,
    'acute diacritic should become correct entity';

like_string $result, qr/na&iuml;ve/,
    'umlaut diacritic should translate to correct entity';

like_string $result, qr/attach&egrave;/,
    'grave diacritic should translate to correct entity';

like_string $result, qr/Fran&ccedil;aise/,
    'cedilla should translate to correct entity';

like_string $result, qr/fun ones&#8482;/,
    '... and trademark symbol needs an escape';

like_string $result, qr/&copy; caper/,
    'copyright symbol should get escaped';

like_string $result, qr/ligatures&mdash;and/,
    'double hyphen dash should become unspacey long dash';

like_string $result, qr/&plusmn; some constant/,
    'plusmn should get an escape too';

like_string $result, qr!<strong>very</strong> important!,
    'bold text needs a formatting directive';

like_string $result, qr!<code>code-like text</code>!,
    'code-marked text needs a formatting directive';

like_string $result, qr!such as <code>0</code>!,
    '... even if text is Perl-like false';

like_string $result, qr!<code>\$some_variable--</code>!,
    '... and if it contains special characters';

like_string $result, qr!special <em>emphasis</em>!,
    'file paths need an emphasis directive';

like_string $result, qr!or <em>0</em> should!,
    '... even if text is Perl-like false';

like_string $result, qr!<em>semantic-only emphasis</em>!,
    '... and so does italicized text';

like_string $result, qr|<span class="footnote">but beware of footnotes!</span>|,
    'footnotes need special escaping too';

my $link = encode_link( 'Specialformatting' );
like_string $result, qr!<p id="${link}1">!m,
    'indexed items need even more special escaping';

like_string $result, qr!<p id="${link}2">!m,
    '... and de-duplication';

like_string $result, qr!mc<sup>2</sup>!, 'superscript works';

like_string $result, qr!H<sub>2</sub>O!, 'subscript works';

like_string $result,
    qr!<a class="url" href="http://www.google.com/">http://www.google.com/</a>!,
    'urls work';

done_testing;
