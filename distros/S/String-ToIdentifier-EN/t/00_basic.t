use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestString qw/is_both to_ascii to_unicode/;

plan tests => 8 * 2 + 9;

is_both ['foo.bar'], 'fooDotBar',
    '"foo.bar" => FooDotBar';

is_both ['foo.bar', '_'], 'foo_dot_bar',
    '"foo.bar","_" => foo_dot_bar';

is_both ['foo..bar'], 'foo2DotsBar',
    'plurals';

is_both ['foo..bar', '_'], 'foo_2_dots_bar',
    'plurals with sep char';

is_both ["foo\x80bar\xFFbaz"], 'foo_0x80_Bar_0xFF_Baz',
    'binary';

is_both ["foo\x80bar\xFFbaz", '_'], 'foo_0x80_bar_0xFF_baz',
    'binary with sep char';

is_both ["foo\x80\x80bar\xFF\xFFbaz"], 'foo_2_0x80s_Bar_2_0xFFs_Baz',
    'binary plurals';

is_both ["foo\x80\x80bar\xFF\xFFbaz", '_'], 'foo_2_0x80s_bar_2_0xFFs_baz',
    'binary plurals with sep char';

{
    use utf8;

    is to_ascii("foo\x{5317}bar\x{4EB0}baz"), 'fooBeiBarJingBaz',
        'unicode to ascii';

    is to_ascii("foo\x{5317}bar\x{4EB0}baz", '_'), 'foo_bei_bar_jing_baz',
        'unicode to ascii with sep char';

    is to_ascii("foo\x{5317}\x{5317}bar\x{4EB0}\x{4EB0}baz"),
        'foo2BeisBar2JingsBaz',
        'unicode to ascii plurals';

    is to_ascii("foo\x{5317}\x{5317}bar\x{4EB0}\x{4EB0}baz", '_'),
        'foo_2_beis_bar_2_jings_baz',
        'unicode to ascii plurals with sep char';

    is to_ascii("ÇáéĺúḿÇ", '_'), 'CaelumC',
        'single char unidecodes are not separated, and case is preserved, '
        .'including for first char';

    is_both ["\x{2211}"], 'nDashArySummation',
        'unicode non-\w char';

    is to_unicode("foo\x{5317}bar\x{4EB0}baz"), "foo\x{5317}bar\x{4EB0}baz",
        'unicode to unicode';

    is to_unicode("foo\x{5317}bar\x{4EB0}baz", '_'),
        "foo\x{5317}bar\x{4EB0}baz",
        'unicode to unicode with sep char';
}
