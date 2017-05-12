use strict;
use warnings;
use Test::More;

use Sub::Frequency;

foreach my $thing (
       # no spaces between number and %
       '17%'  ,
       '  17%',
       '17%  ',
       ' 17% ',

       # with space between number and %
       '17  %',
       '  17  %',
       '17  %  ',
       '  17  %  ',
) {
    is Sub::Frequency::_coerce($thing), 0.17, "testing coercion of $thing";
}

done_testing;
