use strict;
use warnings;

use Test::More;

ok 1, 'subtest-todo-msg-1';

subtest 'subtest-A-name', sub {
    ok 1, 'subtest-todo-msg-2';
    local $TODO = 'not expected to pass';
    ok 1, 'subtest-todo-msg-3';
    ok 0, 'subtest-todo-msg-4';
};

done_testing;
