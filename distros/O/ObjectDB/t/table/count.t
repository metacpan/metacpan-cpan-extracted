use Test::Spec;
use Test::Fatal;

use lib 't/lib';

use TestDBH;
use TestEnv;
use ObjectDB::Table;
use Author;
use Book;
use Person;

describe 'table count' => sub {

    before each => sub {
        TestEnv->prepare_table('person');
        TestEnv->prepare_table('book');
        TestEnv->prepare_table('author');
    };

    it 'return_zero_on_empty_table' => sub {
        my $table = _build_table();

        is($table->count, 0);
    };

    it 'count_rows' => sub {
        Person->new(name => $_)->create for 1 .. 10;

        my $table = _build_table();

        is($table->count, 10);
    };

    it 'count_rows_with_query' => sub {

        Person->new(name => $_)->create for 1 .. 10;

        my $table = _build_table();

        is($table->count(where => [name => {'>=' => 5}]), 5);
    };

    it 'count_rows_with_query_and_join' => sub {
        my $author = Author->new(name => 'author')->create;
        Book->new(title => $_, author_id => $author->column('id'))->create
          for 1 .. 2;

        my $author2 = Author->new(name => 'author2')->create;
        Book->new(title => $_, author_id => $author2->column('id'))->create
          for 1 .. 3;

        my $table = _build_table(class => 'Book');

        is(
            $table->count(
                where    => ['parent_author.name' => 'author'],
                group_by => 'parent_author.id'
            ),
            2
        );
    };

};

sub _build_table {
    ObjectDB::Table->new(class => 'Person', dbh => TestDBH->dbh, @_);
}

runtests unless caller;
