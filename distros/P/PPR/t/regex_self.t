use strict;
use warnings;

use Test::More;
plan tests => 1;

use PPR;

ok "qr[ $PPR::GRAMMAR ]"
    =~ m{ ^ (?&PerlOWS) (?&PerlQuotelikeQR) (?&PerlOWS) $  $PPR::GRAMMAR }xms
        => 'Matched own grammar';

done_testing();

