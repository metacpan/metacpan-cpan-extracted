#!/usr/bin/perl -w
use strict;
use warnings;
use lib qw(t);

use Test::More;
use Test::Deep;

use SQL::Statement;
use SQL::Parser;

my($stmt,$cache)=(undef,{});
my $p = SQL::Parser->new();

ok(cmp_parse('SELECT 1', 'SELECT 1'), 'sanity check');

foreach my $op (qw( <> <= >= )) {
    ok(cmp_parse(
        "SELECT * FROM x WHERE col1 ${op} col2",
        "SELECT * FROM x WHERE col1${op}col2"
    ), "'${op}' without spaces");
}

done_testing();

sub cmp_parse {
    my ($sql_given,$sql_want) = @_;
    my($stmt_given,$stmt_want);

    eval {
        $stmt_given = SQL::Statement->new($sql_given,$p);
        $stmt_want  = SQL::Statement->new($sql_want,$p);
    };

    return 0 if $@;

    foreach (qw(
        command
        columns
        column_aliases
        tables
    )) {
        return 0 if !eq_deeply($stmt_given->{$_}, $stmt_want->{$_});
    }

    return 1;
}

