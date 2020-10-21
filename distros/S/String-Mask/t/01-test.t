use Test::More;

use String::Mask;

is(String::Mask::mask('thisusedtobeanemail@gmail.com'), 'thisusedtobean*****@*****.***');
is(String::Mask::mask('thisusedtobeanemail@gmail.com', 'start', 5), 'thisu**************@*****.***');
is(String::Mask::mask('thisusedtobeanemail@gmail.com', 'end'), '***************mail@gmail.com');
is(String::Mask::mask('thisusedtobeanemail@gmail.com', 'end', 5), '*******************@****l.com');
is(String::Mask::mask('thisusedtobeanemail@gmail.com', 'middle'), '*******dtobeanemail@g****.***');
is(String::Mask::mask('thisusedtobeanemail@gmail.com', 'middle', 5), '************anema**@*****.***');

is(String::Mask::mask('9991234567'), '99912*****');
is(String::Mask::mask('9991234567', 'start', 3), '999*******');
is(String::Mask::mask('9991234567', 'end'), '*****34567');
is(String::Mask::mask('9991234567', 'end', 3), '*******567');
is(String::Mask::mask('9991234567', 'middle'), '**91234***');
is(String::Mask::mask('9991234567', 'middle', 4), '***1234***');

is(String::Mask::mask('9991234567', 'middle', 4, '_'), '___1234___');

done_testing();
