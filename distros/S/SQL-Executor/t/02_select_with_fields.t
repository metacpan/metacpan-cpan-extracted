#!/usr/bin/env perl
use strict;
use warnings;
use SQL::Executor;
use DBI;
use Test::More;
use t::Util;
use t::Row;

my $dbh = prepare_dbh();
prepare_testdata($dbh);

my $table_name = 'TEST';
my $fields = ['id'];
my $condition = { value => 'aaa' };
my $option = { order_by => 'id' };

subtest 'select_row_with_fields', sub {
    my $ex = SQL::Executor->new($dbh);
    my $row = $ex->select_row_with_fields($table_name, $fields, $condition, $option);
    single_row_ok($row);
};


subtest 'select_all_with_fields', sub {
    my $ex = SQL::Executor->new($dbh);
    my @rows = $ex->select_all_with_fields($table_name, $fields, $condition, $option);
    rows_ok(@rows);
};

subtest 'select_with_fields', sub {
    my $ex = SQL::Executor->new($dbh);

    my $row = $ex->select_with_fields($table_name, $fields, $condition, $option);
    single_row_ok($row);

    my @rows = $ex->select_with_fields($table_name, $fields, $condition, $option);
    rows_ok(@rows);
};

subtest 'select_itr_with_fields', sub {
    my $ex = SQL::Executor->new($dbh);
    my $itr = $ex->select_itr_with_fields($table_name, $fields, $condition, $option);
    is( ref $itr, 'SQL::Executor::Iterator' );
};


subtest 'with_callback', sub {
    my $ex = SQL::Executor->new($dbh, {
        callback => sub {
            my ($self, $row, $table_name) = @_;
            return t::Row->new($row);
        },
    });

    my $row = $ex->select_with_fields($table_name, $fields, $condition, $option);
    is( $row->name, 'callback');

    my @rows = $ex->select_with_fields($table_name, $fields, $condition, $option);
    is( $rows[0]->name, 'callback');
    is( $rows[1]->name, 'callback');

    my $itr = $ex->select_itr_with_fields($table_name, $fields, $condition, $option);
    my $next_row = $itr->next;
    is( $next_row->name, 'callback');
};


subtest 'select_row allow_empty_condition', sub {
    my $ex = SQL::Executor->new($dbh, { allow_empty_condition => 0 });
    eval {
        my $row = $ex->select_row_with_fields($table_name, $fields);
        fail("exception expected");
    };
    like( $@, qr/^condition is empty/);
};

subtest 'select_all allow_empty_condition', sub {
    my $ex = SQL::Executor->new($dbh, { allow_empty_condition => 0 });
    eval {
        my @rows = $ex->select_all_with_fields($table_name, $fields);
        fail("exception expected");
    };
    like( $@, qr/^condition is empty/);
};



done_testing;

sub single_row_ok {
    my ($row) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok( defined $row );
    is( ref $row,      'HASH' );
    is( $row->{id},    1);
    ok( !exists $row->{value} );
}

sub rows_ok {
    my (@rows) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $expected = [
        { id => 1 },
        { id => 2 },
    ];
    is_deeply( \@rows, $expected );
}
