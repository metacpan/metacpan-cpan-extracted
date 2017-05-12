#!/usr/bin/env perl
use strict;
use warnings;
use SQL::Executor;
use DBI;
use Test::More;
use t::Util;

my $dbh = prepare_dbh();

subtest 'insert_multi', sub {
    my $ex = SQL::Executor->new($dbh);
    my @insert_rows = (
        { id => 1, value => 'xxx' },
        #{ id => 2, value => 'yyy' }, #disable this data because SQLite is not support statement for bulk insert.
    );
    $ex->insert_multi('TEST', \@insert_rows);
    my @rows = $ex->select('TEST', {});
    is_deeply(\@rows, \@insert_rows);
};

done_testing;


