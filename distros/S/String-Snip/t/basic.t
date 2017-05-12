#! perl -wT

use Test::More;

use String::Snip;

is( String::Snip::snip('Some short string') , 'Some short string');
is( String::Snip::snip('OneVeryLongString' x 200 ) , "OneVeryLongStringOneVeryLongStringOn ..[SNIP (was 3400chars)].. ngOneVeryLongStringOneVeryLongString");
is( String::Snip::snip('A Short one and '.( 'OneVeryLongString' x 200 ).' followed by normal length one' ),
    "A Short one and OneVeryLongStringOneVeryLongStringOn ..[SNIP (was 3400chars)].. ngOneVeryLongStringOneVeryLongString followed by normal length one");
is( String::Snip::snip('A Short one and '.( 'OneVeryLongString' x 200 ).' followed by normal length one and '.( 'anotherverylong' x 200 ) ),
    "A Short one and OneVeryLongStringOneVeryLongStringOn ..[SNIP (was 3400chars)].. ngOneVeryLongStringOneVeryLongString followed by normal length one and anotherverylonganotherverylonganothe ..[SNIP (was 3000chars)].. rylonganotherverylonganotherverylong");

done_testing();
