#! perl -wT

use Test::More;

use String::Snip;

is( String::Snip::snip('0123456789' x 20 , { max_length => 200 } ) , "0123456789012345678901234567890123456 ..[SNIP (was 200chars)].. 456789012345678901234567890123456789");
# Max length remain 100. No snippage
is( String::Snip::snip('0123456789' x 10 , { max_length => 50  } ) , "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789");
is( String::Snip::snip('0123456789' x 20 , { max_length => 200 , short_length => 50 } ) , "012345678901 ..[SNIP (was 200chars)].. 90123456789");

# Multilines stuff, with special regex
my $str = 'Hello,  here is some data: '.( "abcdefghi\n"  x 20 ).' and other small things';

is( String::Snip::snip($str) , $str , "String is not changed without any special regex.");

is( String::Snip::snip($str, { substr_regex => '[\\S\\n]+' , max_length => 100  }) , q|Hello,  here is some data: abcdefghi
abcdefghi
abcdefghi
abcdefg ..[SNIP (was 200chars)].. efghi
abcdefghi
abcdefghi
abcdefghi
 and other small things| );


done_testing();
