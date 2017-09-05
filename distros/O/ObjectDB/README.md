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
        table                    => 'author',
        auto_increment           => 'id',
        discover_schema          => 1,
        generate_columns_methods => 1,
        generate_related_methods => 1,
        relationships            => {
            books => {
                type  => 'one to many',
                class => 'MyBook',
                map   => { id => 'author_id' }
            }
        }
    );

    package MyBook;
    use base 'MyDB';

    __PACKAGE__->meta(
        table                    => 'book',
        auto_increment           => 'id',
        discover_schema          => 1,
        generate_columns_methods => 1,
        generate_related_methods => 1,
        relationships            => {
            author => {
                type  => 'many to one',
                class => 'MyAuthor',
                map   => { author_id => 'id' }
            }
        }
    );

    my $book_by_id = MyBook->new(id => 1)->load(with => 'author');

    my @books_authored_by_Pushkin = MyBook->table->find(where => [ 'author.name' => 'Pushkin' ]);

    $author->create_related('books', title => 'New Book');

# DESCRIPTION

ObjectDB is a lightweight and flexible object-relational mapper. While being
light it stays usable. ObjectDB borrows many things from [Rose::DB::Object](https://metacpan.org/pod/Rose::DB::Object),
but unlike in the last one columns are not objects, everything is pretty much
straightforward and flat.

Supported servers: SQLite, MySQL, PostgreSQL.

# STABILITY

This module is used in several productions, under heavy load and big volumes.

# PERFORMANCE

When performance is a must but you don't want to switch back to [DBI](https://metacpan.org/pod/DBI) take a look at `find_by_compose`, `find_by_sql`
methods and at `rows_as_hashes` option in [ObjectDB::Table](https://metacpan.org/pod/ObjectDB::Table).

Latest benchmarks

    # Create

              Rate create    DBI
    create 10204/s     --   -73%
    DBI    37975/s   272%     --

    # Select 1

                       Rate          find find_by_compose  find_by_sql           DBI
    find             4478/s            --            -36%         -80%          -91%
    find_by_compose  7042/s           57%              --         -69%          -86%
    find_by_sql     22556/s          404%            220%           --          -56%
    DBI             51724/s         1055%            634%         129%            --

    # Select many

                       Rate          find find_by_compose  find_by_sql           DBI
    find             5618/s            --            -21%         -76%          -89%
    find_by_compose  7109/s           27%              --         -69%          -86%
    find_by_sql     23077/s          311%            225%           --          -53%
    DBI             49180/s          775%            592%         113%            --

    # Select many with iterator

                             Rate find_by_sql find_by_compose  find
    find_by_sql            25.8/s          --            -18%  -19%
    find_by_compose        31.5/s         22%              --   -2%
    find                   32.1/s         24%              2%    --
    find_by_compose (hash)  201/s        677%            537%  526%
    find (hash)             202/s        680%            539%  528%
    find_by_sql (hash)      415/s       1505%           1215% 1193%
    DBI                    1351/s       5128%           4184% 4109%

                             find_by_compose (hash) find (hash) find_by_sql (hash)  DBI
    find_by_sql                                -87%        -87%               -94% -98%
    find_by_compose                            -84%        -84%               -92% -98%
    find                                       -84%        -84%               -92% -98%
    find_by_compose (hash)                       --         -0%               -52% -85%
    find (hash)                                  0%          --               -51% -85%
    find_by_sql (hash)                         107%        106%                 -- -69%
    DBI                                        573%        570%               226%   --

## Meta auto discovery and method generation

When you have [DBIx::Inspector](https://metacpan.org/pod/DBIx::Inspector) installed meta can be automatically discovered without the need to specify columns. And
special methods for columns and relationships are automatically generated.

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
The only exception is `find`, it is available on a row object for convenience.

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

Copyright 2013-2017, Viacheslav Tykhanovskyi.

This module is free software, you may distribute it under the same terms as Perl.
