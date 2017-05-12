use strict;
use Test::Base::SubTest;

filters {
    input => ['trim', sub { uc(shift) }],
    expected => ['trim'],
};

run_is input => 'expected';

done_testing;

__DATA__

=== Normal Case
--- input
x
y
z
--- expected
X
Y
Z

=== Contains numeric chars
--- input
Hello,
5963
--- expected
HELLO,
5963
