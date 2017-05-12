#!/usr/bin/env perl
use strict;
use warnings;
use SQL::Executor;
use DBI;
use Test::More;
use t::Util;

my $dbh = prepare_dbh();

subtest 'execute_query_named', sub {
    my $ex = SQL::Executor->new($dbh);
    $ex->execute_query_named('INSERT INTO TEST (id, value) VALUES (:id, :value)', { id => 4, value => 'xxx' });
    my $row = $ex->select('TEST', { id => 4 });
    ok( defined $row );
    is( $row->{id},    4);
    is( $row->{value}, 'xxx');
};

done_testing;


