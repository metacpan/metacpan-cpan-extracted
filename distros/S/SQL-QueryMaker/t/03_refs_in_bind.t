use strict;
use warnings;
use SQL::QueryMaker;
use Test::More;

sub checkerr {
    my $code = shift;
    return sub {
        local $@;
        my $query = eval {
            $code->();
        };
        ok ! defined $query, "does not return anything";
        ok $@, "error is thrown";
    };
}

subtest "sql_eq" => checkerr(sub {
    sql_eq('foo' => [1,2,3]);
});

subtest "sql_in" => checkerr(sub {
    sql_in('foo' => [[1,2,3], 4]);
});

subtest "sql_and" => checkerr(sub {
    sql_and(a => [ [1,2], 3]);
});

done_testing;
