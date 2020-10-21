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
$p->{RaiseError}=1; 

my $sql1 = 'SELECT * FROM x JOIN y ON x.a = y.b AND x.c = y.d';
ok(cmp_parse($sql1,$sql1), 'JOIN with AND');

my $sql2 = 'SELECT * FROM x JOIN y ON x.a = y.b OR x.c = y.d';
ok(cmp_parse($sql2,$sql2), 'JOIN with OR');

my $sql3 = 'SELECT * FROM x JOIN y ON (x.a = y.b) OR (x.c = y.d)';
ok(cmp_parse($sql3,$sql3), 'JOIN with OR and ()s');

my $sql4 = 'SELECT * FROM x JOIN y ON (x.a = y.b AND x.x = y.z) OR (x.c = y.d OR x.e = y.f)';
ok(cmp_parse($sql4,$sql4), 'JOIN with complex AND/OR in ()s');

my $sql5 = 'SELECT * FROM x JOIN y ON (x.a = y.b AND x.a > 12 AND x.a < 20) OR (x.c = y.d OR x.e = y.f)';
ok(cmp_parse($sql5,$sql5), 'JOIN with lt"<" and gt">"');

my $sql6 = "INSERT INTO asdf (col1, col2) VALUES ('asdf', CONCAT('x', 'y', 'z'))";
ok(cmp_parse($sql6,$sql6), 'FUNCTION in VALUES');

my $sql7 = "UPDATE asdf SET (col1 = 'asdf', col2 = CONCAT('x', 'y', 'z'))";
ok(cmp_parse($sql7,$sql7), 'FUNCTION in SET CLAUSE');

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

