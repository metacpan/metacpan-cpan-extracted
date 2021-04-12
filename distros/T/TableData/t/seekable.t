#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use TableData::Test::Spec::Seekable;

my $table = TableData::Test::Spec::Seekable->new;

subtest set_row_iterator_index => sub {
    $table->set_row_iterator_index(1);
    is_deeply($table->get_row_arrayref, [3,4]);
    $table->set_row_iterator_index(-3);
    is_deeply($table->get_row_arrayref, [1,2]);
    is_deeply($table->get_row_arrayref, [3,4]);

    dies_ok { $table->set_row_iterator_index(3) };
    dies_ok { $table->set_row_iterator_index(-4) };
    lives_ok { $table->set_row_iterator_index(-3) };
};

done_testing;
