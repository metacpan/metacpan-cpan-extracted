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

subtest ARGMINSTR => sub {
    my $func = get_func("ARGMINSTR");
    is_deeply($func->(undef, undef, 1, 10, 2, 3), 1);
};

subtest ARGMAXSTR => sub {
    my $func = get_func("ARGMAXSTR");
    is_deeply($func->(undef, undef, 1, 10, 2, 3), 3);
};

subtest ARGMINNUM => sub {
    my $func = get_func("ARGMINSTR");
    is_deeply($func->(undef, undef, 1, 10, 2, 3), 1);
};

subtest ARGMAXNUM => sub {
    my $func = get_func("ARGMAXNUM");
    is_deeply($func->(undef, undef, 1, 10, 2, 3), 10);
};


done_testing;
