use strict;
use warnings;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}

plan tests => 1;

use PPR;

ok "qr[ $PPR::GRAMMAR ]"
    =~ m{ ^ (?&PerlOWS) (?&PerlQuotelikeQR) (?&PerlOWS) $  $PPR::GRAMMAR }xms
        => 'Matched own grammar';

done_testing();

