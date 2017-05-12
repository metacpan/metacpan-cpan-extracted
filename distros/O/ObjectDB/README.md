# NAME

ObjectDB - usable ORM

# SYNOPSIS

    package MyDB;
    use base 'ObjectDB';

    sub init_db {
        ...
        return $dbh;
    }

    package MyAuthor;
    use base 'MyDB';

    __PACKAGE__->meta(
        table          => 'author',
        columns        => [qw/id name/],
        primary_key    => 'id',
        auto_increment => 'id',
        relationships  => {
            books => {
                type = 'one to many',
                class => 'MyBook',
                map   => {id => 'author_id'}
            }
        }
    );

    package MyBook;
    use base 'MyDB';

    __PACKAGE__->meta(
        table          => 'book',
        columns        => [qw/id author_id title/],
        primary_key    => 'id',
        auto_increment => 'id',
        relationships  => {
            author => {
                type = 'many to one',
                class => 'MyAuthor',
                map   => {author_id => 'id'}
            }
        }
    );

    my $book_by_id = MyBook->new(id => 1)->load(with => 'author');

    my @books_authored_by_Pushkin =
      MyBook->table->find(where => ['author.name' => 'Pushkin']);

    $author->create_related('books', title => 'New Book');

# DESCRIPTION

ObjectDB is a lightweight and flexible object-relational mapper. While being
light it stays usable. ObjectDB borrows many things from [Rose::DB::Object](https://metacpan.org/pod/Rose::DB::Object),
but unlike in the last one columns are not objects, everything is pretty much
straightforward and flat.

Supported servers: SQLite, MySQL, PostgreSQL

## Actions on columns

### Methods

- `set_columns`

    Set columns.

        $book->set_columns(title => 'New Book', pages => 140);

- `set_column`

    Set column.

        $book->set_column(title => 'New Book');

- `get_column`

        my $title = $book->get_column('title');

- `column`

    A shortcut for `set_column`/`get_column`.

        $book->column(title => 'New Book');
        my $title = $book->column('title');

## Actions on rows

Main ObjectDB instance represents a row object. All actions performed on this
instance are performed on one row. For performing actions on several rows see
[ObjectDB::Table](https://metacpan.org/pod/ObjectDB::Table).

### Methods

- `create`

    Creates a new row. If `meta` has an `auto_increment` column then it is
    properly set.

        my $author = MyAuthor->new(name => 'Me')->create;

    It is possible to create related objects automatically:

        my $author = MyAuthor->new(
            name  => 'Me',
            books => [{title => 'Book1'}, {title => 'Book2'}]
        )->create;

    Which is a convenient way of calling C &lt;create\_related> manually .

- `load`

    Loads an object by primary or unique key.

        my $author = MyAuthor->new(id => 1)->load;

    It is possible to load an object with related objects.

        my $book = MyBook->new(title => 'New Book')->load(with => 'author');

- `update`

    Updates an object.

        $book->set_column(title => 'Old Title');
        $book->update;

- `delete`

    Deletes an object. Related objects are NOT deleted.

        $book->delete;

## Actions on tables

In order to perform an action on table a [ObjectDB::Table](https://metacpan.org/pod/ObjectDB::Table) object must be
obtained via `table` method (see [ObjectDB::Table](https://metacpan.org/pod/ObjectDB::Table) for all available actions).
The only exception is `find`, it is available in a row object for convenience.

    MyBook->table->delete; # deletes ALL records from MyBook

## Actions on related objects

### Methods

- `related`

    Returns preloaded related objects or loads them on demand.

        # same as find_related but with caching
        my $description = $book->related('book_description');

        # returns from cache
        my $description = $book->related('book_description');

- `create_related`

    Creates related object, setting appropriate foreign keys. Accepts a list, a hash
    reference, an object.

        $author->create_related('books', title => 'New Book');
        $author->create_related('books', MyBook->new(title => 'New Book'));

- `find_related`

    Finds related object.

        my $books = $author->find_related('books', where => [title => 'New Book']);

- `update_related`

    Updates related object.

        $author->update_related(
            'books',
            set   => {title => 'Old Book'},
            where => [title => 'New Book']
        );

- `delete_related`

    Deletes related object.

        $author->delete_related('books', where => [title => 'New Book']);

## Transactions

All the exceptions will be catched, a rollback will be run and exceptions will
be rethrown. It is safe to use `rollback` or `commit` inside of a transaction
when you want to do custom exception handling.

    MyDB->txn(
        sub {
            ... do smth that can throw ...
        }
    );

`txn`'s return value is preserved, so it is safe to do something like:

    my $result = MyDB->txn(
        sub {
            return 'my result';
        }
    );

### Methods

- `txn`

    Accepts a subroutine reference, wraps code into eval and runs it rethrowing all
    exceptions.

- `commit`

    Commit transaction.

- `rollback`

    Rollback transaction.

## Utility methods

### Methods

- `meta`

    Returns meta object. See `ObjectDB::Meta`.

- `init_db`

    Returns current `DBI` instance.

- `is_modified`

    Returns 1 if object is modified.

- `is_in_db`

    Returns 1 if object is in database.

- `is_related_loaded`

    Checks if related objects are loaded.

- `clone`

    Clones object preserving all columns except primary or unique keys.

- `to_hash`

    Converts object into a hash reference, including all preloaded objects.

# AUTHOR

Viacheslav Tykhanovskyi

# COPYRIGHT AND LICENSE

Copyright 2013, Viacheslav Tykhanovskyi.

This module is free software, you may distribute it under the same terms as Perl.
