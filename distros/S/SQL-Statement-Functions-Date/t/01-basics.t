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

subtest YEAR => sub {
    my $func = get_func("YEAR");
    is_deeply($func->(undef, undef, "2015-02-03"), 2015);
    is_deeply($func->(undef, undef, "2015-02-03 04:05:06"), 2015);
    is_deeply($func->(undef, undef, "foo"), undef);
};

subtest MONTH => sub {
    my $func = get_func("MONTH");
    is_deeply($func->(undef, undef, "2015-02-03"), 2);
    is_deeply($func->(undef, undef, "2015-02-03 04:05:06"), 2);
    is_deeply($func->(undef, undef, "foo"), undef);
};

for my $name (qw/DAY DAYOFMONTH/) {
    subtest $name => sub {
        my $func = get_func($name);
        is_deeply($func->(undef, undef, "2015-02-03"), 3);
        is_deeply($func->(undef, undef, "2015-02-03 04:05:06"), 3);
        is_deeply($func->(undef, undef, "foo"), undef);
    };
}

subtest DAYOFYEAR => sub {
    my $func = get_func("DAYOFYEAR");
    is_deeply($func->(undef, undef, "2015-02-03"), 34);
    is_deeply($func->(undef, undef, "2015-02-03 04:05:06"), 34);
    is_deeply($func->(undef, undef, "foo"), undef);
};

subtest WEEKDAY => sub {
    my $func = get_func("WEEKDAY");
    is_deeply($func->(undef, undef, "2015-02-03"), 1);
    is_deeply($func->(undef, undef, "2015-02-03 04:05:06"), 1);
    is_deeply($func->(undef, undef, "foo"), undef);
};

subtest WEEKOFYEAR => sub {
    my $func = get_func("WEEKOFYEAR");
    is_deeply($func->(undef, undef, "2015-02-03"), 6);
    is_deeply($func->(undef, undef, "2015-02-03 04:05:06"), 6);
    is_deeply($func->(undef, undef, "foo"), undef);
};

done_testing;
