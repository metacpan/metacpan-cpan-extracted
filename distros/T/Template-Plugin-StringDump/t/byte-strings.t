use strict;
use warnings;
use Template::Test;

test_expect(\*DATA);

__END__
[% USE StringDump -%]

--test--
[% 'Ĝis! ☺' | dump_hex %]
--expect--
C4 9C 69 73 21 20 E2 98 BA

--test--
[% 'Ĝis! ☺' | dump_dec %]
--expect--
196 156 105 115 33 32 226 152 186

--test--
[% 'Ĝis! ☺' | dump_oct %]
--expect--
304 234 151 163 41 40 342 230 272

--test--
[% 'Ĝis! ☺' | dump_bin %]
--expect--
11000100 10011100 1101001 1110011 100001 100000 11100010 10011000 10111010
