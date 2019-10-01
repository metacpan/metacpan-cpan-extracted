use strict;
use Test::More;

use PICA::Data ':all';

my %tests = (
    '028A $ax' => 'Plain',
    '<record xlmns="info:srw/schema/5/picaXML-v1.0">' => 'XML',
    "028A \x{1F}a\x{1E}\x{0A}" => 'Plus',
    "028A \x{1F}a\x{1E}\x{1D}" => 'Binary',
);

while (my ($pica, $format) = each %tests) {
    is pica_guess($pica), "PICA::Parser::$format", $format;
}

is pica_guess('WTF?!'), undef, '???';

done_testing;
