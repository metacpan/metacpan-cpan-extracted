use strict;
use warnings;
use utf8;
use Template::Test;

# UTF-8 in TAP output
binmode STDOUT, ':encoding(UTF-8)';

test_expect(\*DATA);

__END__
[% USE StringDump -%]

--test--
[% 'Ĝis! ☺' | dump_hex %]
--expect--
11C 69 73 21 20 263A

--test--
[% 'Ĝis! ☺' | dump_dec %]
--expect--
284 105 115 33 32 9786

--test--
[% 'Ĝis! ☺' | dump_oct %]
--expect--
434 151 163 41 40 23072

--test--
[% 'Ĝis! ☺' | dump_bin %]
--expect--
100011100 1101001 1110011 100001 100000 10011000111010

--test--
[% 'Ĝis! ☺' | dump_names %]
--expect--
LATIN CAPITAL LETTER G WITH CIRCUMFLEX, LATIN SMALL LETTER I, LATIN SMALL LETTER S, EXCLAMATION MARK, SPACE, WHITE SMILING FACE

--test--
[% 'Ĝis! ☺' | dump_codes %]
--expect--
U+011C U+0069 U+0073 U+0021 U+0020 U+263A
