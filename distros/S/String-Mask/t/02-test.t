use Test::More;

use String::Mask qw/mask/;

is(mask('thisusedtobeanemail@gmail.com'), 'thisusedtobean*****@*****.***');
is(mask('thisusedtobeanemail@gmail.com', 'start', 5), 'thisu**************@*****.***');
is(mask('thisusedtobeanemail@gmail.com', 'end'), '***************mail@gmail.com');
is(mask('thisusedtobeanemail@gmail.com', 'end', 5), '*******************@****l.com');
is(mask('thisusedtobeanemail@gmail.com', 'middle'), '*******dtobeanemail@g****.***');
is(mask('thisusedtobeanemail@gmail.com', 'middle', 5), '************anema**@*****.***');

is(mask('9991234567'), '99912*****');
is(mask('9991234567', 'start', 3), '999*******');
is(mask('9991234567', 'end'), '*****34567');
is(mask('9991234567', 'end', 3), '*******567');
is(mask('9991234567', 'middle'), '**91234***');
is(mask('9991234567', 'middle', 4), '***1234***');

is(mask('9991234567', 'middle', 4, '_'), '___1234___');

done_testing();
