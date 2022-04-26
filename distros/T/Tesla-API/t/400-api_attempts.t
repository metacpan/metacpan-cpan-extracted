use warnings;
use strict;
use feature 'say';

use Tesla::API;
use Test::More;

my $t = Tesla::API->new(unauthenticated => 1);

is $t->_api_attempts, 0, "_api_attemtps() returns 0 on first call";
is $t->_api_attempts, 0, "_api_attemtps() returns 0 on second call call";


is $t->_api_attempts(1), 1, "_api_attemtps() returns 1 on first true call";
is $t->_api_attempts('a'), 2, "_api_attemtps() increments on any true value";
is $t->_api_attempts(1), 3, "_api_attemtps() increments on next true value";

is $t->_api_attempts(0), 0, "_api_attemtps() returns 0 when false value sent in";

is $t->_api_attempts(1), 1, "_api_attemtps() then increments again";
is $t->_api_attempts(1), 2, "_api_attemtps() keeps incrementing";

done_testing();