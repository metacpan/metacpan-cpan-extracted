use strict;
use warnings;
use Test::Tester;
use Test::More;
use Test::Clear;

subtest 'todo scope' => sub {
    subtest 'inner scope' => sub {
        my $guard = todo_scope 'not yet implementated';
        fail;
    };
    check_test(
        sub { fail }, {
        ok => 0,
    });
};


done_testing;
