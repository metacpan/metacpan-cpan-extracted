use strict;
use Test::More;
use Test::Exception;
use PICA::Data ':all';

my $pica = pica_data(<<'PICA');
045B/02 $aLit
021A $aEin Buch$hzum Lesen
003@ $012345X
PICA

is pica_sort($pica)->string, <<'PICA';
003@ $012345X
021A $aEin Buch$hzum Lesen
045B/02 $aLit

PICA

done_testing;
