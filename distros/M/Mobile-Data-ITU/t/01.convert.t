use strict;
use Test::Base;
use utf8;
plan tests => 1 * blocks;

use Mobile::Data::ITU;

run {
    my $block = shift;
    my ($itu)     = split(/\n/,$block->input);
    my ($country) = split(/\n/,$block->expected);

    my $tcountry = eval { itu2country( $itu ) };

    if ( $@ ) {
        is $country, 'ERROR';
    }
    elsif ( $tcountry ) {
        is $country, $tcountry;
    } else {
        is $country, 'UNDEF';
    }

};

__END__
===
--- input
bad
--- expected
ERROR

===
--- input
000
--- expected
Reserved

===
--- input
202
--- expected
Greece

===
--- input
302
--- expected
Canada

===
--- input
400
--- expected
Azerbaijani Republic

===
--- input
502
--- expected
Malaysia

===
--- input
602
--- expected
Egypt (Arab Republic of)

===
--- input
90101
--- expected
ICO Global Communications

===
--- input
999
--- expected
UNDEF

