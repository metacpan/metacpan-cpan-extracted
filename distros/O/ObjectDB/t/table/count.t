use strict;
use warnings;
use lib 't/lib';

use Test::More;
use Test::Fatal;
use TestDBH;
use TestEnv;

use ObjectDB::Table;
use Author;
use Book;
use Person;

subtest 'return_zero_on_empty_table' => sub {
    _setup();

    my $table = _build_table();

    is($table->count, 0);
};

subtest 'count_rows' => sub {
    _setup();

    Person->new(name => $_)->create for 1 .. 10;

    my $table = _build_table();

    is($table->count, 10);
};

subtest 'count_rows_with_query' => sub {
    _setup();

    Person->new(name => $_)->create for 1 .. 10;

    my $table = _build_table();

    is($table->count(where => [ name => { '>=' => 5 } ]), 5);
};

subtest 'count_rows_with_query_and_join' => sub {
    _setup();

    my $author = Author->new(name => 'author')->create;
    Book->new(title => $_, author_id => $author->column('id'))->create for 1 .. 2;

    my $author2 = Author->new(name => 'author2')->create;
    Book->new(title => $_, author_id => $author2->column('id'))->create for 1 .. 3;

    my $table = _build_table(class => 'Book');

    is($table->count(where => [ 'parent_author.name' => 'author' ], group_by => 'parent_author.id'), 2);
};

done_testing;

sub _setup {
    TestEnv->prepare_table('person');
    TestEnv->prepare_table('book');
    TestEnv->prepare_table('author');
}

sub _build_table {
    ObjectDB::Table->new(class => 'Person', dbh => TestDBH->dbh, @_);
}
