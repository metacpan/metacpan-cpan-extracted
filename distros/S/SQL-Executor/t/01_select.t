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
my $condition = { value => 'aaa' };
my $option = { order_by => 'id' };

subtest 'select_row', sub {
    my $ex = SQL::Executor->new($dbh);
    my $row = $ex->select_row($table_name, $condition, $option);
    single_row_ok($row);
};


subtest 'select_all', sub {
    my $ex = SQL::Executor->new($dbh);
    my @rows = $ex->select_all($table_name, $condition, $option);
    rows_ok(@rows);
};

subtest 'select', sub {
    my $ex = SQL::Executor->new($dbh);

    my $row = $ex->select($table_name, $condition, $option);
    single_row_ok($row);

    my @rows = $ex->select($table_name, $condition, $option);
    rows_ok(@rows);
};

subtest 'select_itr', sub {
    my $ex = SQL::Executor->new($dbh);

    my $itr = $ex->select_itr($table_name, $condition, $option);
    is( ref $itr, 'SQL::Executor::Iterator' );
    my $itr_count = 0;
    my @rows;
    while ( my $row = $itr->next ) {
        push (@rows, $row);
        $itr_count++;
    }
    rows_ok(@rows);
    is( $itr_count, 2, 'iterator count' );
};


subtest 'select_with_callback', sub {
    my $ex = SQL::Executor->new($dbh, {
        callback => sub {
            my ($self, $row, $table_name) = @_;
            return t::Row->new($row);
        },
    });

    my $row = $ex->select($table_name, $condition, $option);
    is( $row->name, 'callback');
    single_row_obj_ok($row);

    my @rows = $ex->select($table_name, $condition, $option);
    row_objs_ok(@rows);

    my $itr = $ex->select_itr($table_name, $condition, $option);
    my $next_row = $itr->next;
    is( $next_row->name, 'callback');
    single_row_obj_ok($next_row);
};

subtest 'enable and disable callback', sub {
    my $ex = SQL::Executor->new($dbh, {
        callback => sub {
            my ($self, $row, $table_name) = @_;
            return t::Row->new($row);
        },
    });

    ok( defined $ex->callback );

    $ex->disable_callback();
    ok( !defined $ex->callback );

    $ex->restore_callback();
    ok( defined $ex->callback );
    my $row = $ex->select($table_name, $condition, $option);
    is( $row->name, 'callback', 'callback restored');
};

subtest 'select_row allow_empty_condition', sub {
    my $ex = SQL::Executor->new($dbh, { allow_empty_condition => 0 });
    eval {
        my $row = $ex->select_row($table_name);
        fail("exception expected");
    };
    like( $@, qr/^condition is empty/);
};

subtest 'select_all allow_empty_condition', sub {
    my $ex = SQL::Executor->new($dbh, { allow_empty_condition => 0 });
    eval {
        my @rows = $ex->select_all($table_name);
        fail("exception expected");
    };
    like( $@, qr/^condition is empty/);
};

subtest 'select allow_empty_condition', sub {
    my $ex = SQL::Executor->new($dbh, { allow_empty_condition => 0 });
    eval {
        my @rows = $ex->select($table_name);
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
    is( $row->{value}, 'aaa');
}

sub single_row_obj_ok {
    my ($row) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok( defined $row );
    is( $row->id,    1);
    is( $row->value, 'aaa');
}


sub rows_ok {
    my (@rows) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $expected = [
        { id => 1, value => 'aaa' },
        { id => 2, value => 'aaa' },
    ];
    is_deeply( \@rows, $expected );
}

sub row_objs_ok {
    my (@rows) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $expected = [
        { id => 1, value => 'aaa' },
        { id => 2, value => 'aaa' },
    ];
    is( scalar(@rows), 2, 'size');
    is( $rows[0]->id,    1, 'id for [0]');
    is( $rows[0]->value, 'aaa', 'value for [0]');
    is( $rows[1]->id,    2, 'id for [1]');
    is( $rows[1]->value, 'aaa', 'value for [1]');

}
