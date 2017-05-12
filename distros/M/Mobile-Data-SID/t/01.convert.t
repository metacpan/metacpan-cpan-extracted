use strict;
use Test::Base;
use utf8;
plan tests => 1 * blocks;

use Mobile::Data::SID;

run {
    my $block = shift;
    my ($sid)     = split(/\n/,$block->input);
    my ($country) = split(/\n/,$block->expected);

    my $tcountry = eval { sid2country( $sid ) };

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
0
--- expected
Reserved (not to be assigned)

===
--- input
1
--- expected
United States of America

===
--- input
10000
--- expected
Mozambique

===
--- input
20000
--- expected
Unassigned

===
--- input
30000
--- expected
CIBERNET BIDs

===
--- input
40000
--- expected
Unassigned

===
--- input
80000
--- expected
UNDEF

===
--- input
15000
--- expected
Afghanistan

