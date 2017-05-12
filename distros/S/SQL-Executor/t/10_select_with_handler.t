#!/usr/bin/env perl
use strict;
use warnings;
use SQL::Executor;
use DBI;
use Test::More;
use t::Util;


subtest 'select_row', sub {
    my ($dsn, $user, $pass, $opt) =  args_for_connect();
    my $ex = SQL::Executor->connect($dsn, $user, $pass, $opt);

    prepare_table($ex->handler->dbh);
    prepare_testdata($ex->handler->dbh);

    my $row = $ex->select_row('TEST', { value => 'aaa' }, { order_by => 'id' });
    ok( defined $row );
    is( ref $row,      'HASH' );
    is( $row->{id},    1);
    is( $row->{value}, 'aaa');

};




done_testing;

