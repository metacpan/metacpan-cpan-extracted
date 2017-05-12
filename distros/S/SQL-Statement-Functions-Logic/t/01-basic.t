#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

sub get_func {
    no strict 'refs';

    my $name = shift;
    require "SQL/Statement/Function/ByName/$name.pm";
    \&{"SQL::Statement::Function::ByName::$name\::SQL_FUNCTION_$name"};
}

subtest IF => sub {
    my $func = get_func("IF");
    is_deeply($func->(undef, undef, 1, 2, 3), 2);
    is_deeply($func->(undef, undef, 0, 2, 3), 3);
};

done_testing;
