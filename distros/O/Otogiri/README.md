# NAME

Otogiri - A lightweight medicine for using database

# SYNOPSIS

    use Otogiri;
    my $db = Otogiri->new(connect_info => ['dbi:SQLite:...', '', '']);
    
    $db->insert(book => {title => 'mybook1', author => 'me', ...});

    my $book_id = $db->last_insert_id;
    my $row = $db->single(book => {id => $book_id});

    print 'Title: '. $row->{title}. "\n";
    
    my @rows = $db->select(book => sql_ge(price => 500));
    
    # or non-strict mode
    my @rows = $db->select(book => {price => {'>=' => 500}});

    for my $r (@rows) {
        printf "Title: %s \nPrice: %s yen\n", $r->{title}, $r->{price};
    }
    
    # or using iterator
    my $iter = $db->select(book => {price => {'>=' => 500}});
    while (my $row = $iter->next) {
        printf "Title: %s \nPrice: %s yen\n", $row->{title}, $row->{price};
    }

    # If you using perl 5.38 or later, you can use class feature.
    class Book {
        field $id :param;
        field $title :param;
        field $author :param;
        field $price :param;
        field $created_at :param;
        field $updated_at :param;

        method title {
            return $title;
        }
    };
    my $book = $db->row_class('Book')->single(book => {id => 1}); # $book is Book object.
    say $book->title; # => say book title.
    
    my $hash = $db->no_row_class->single(book => {id => 1}); # $hash is HASH reference.
    say $hash->{title}; # => say book title.
    
    $db->update(book => [author => 'oreore'], {author => 'me'});
    
    $db->delete(book => {author => 'me'});
    
    # using transaction
    do {
        my $txn = $db->txn_scope;
        $db->insert(book => ...);
        $db->insert(store => ...);
        $txn->commit;
    };

# DESCRIPTION

Otogiri is a thing that like as ORM. A slogan is "Schema-less, Fat-less".

# ATTRIBUTES

Please see ATTRIBUTES section of [DBIx::Otogiri](https://metacpan.org/pod/DBIx%3A%3AOtogiri) documentation.

# METHODS

## new

    my $db = Otogiri->new( connect_info => [$dsn, $dbuser, $dbpass] );

Instantiate and connect to db. Then, it returns [DBIx::Otogiri](https://metacpan.org/pod/DBIx%3A%3AOtogiri) object.

# EXPORT FUNCTIONS

Otogiri exports each SQL::QueryMaker::sql\_\* functions. (ex. sql\_ge(), sql\_like() and more...)

For more information, please see FUNCTIONS section of [SQL::QueryMaker](https://metacpan.org/pod/SQL%3A%3AQueryMaker)'s documentation.

# INFORMATION ABOUT INCOMPATIBILITY

## version 0.11

An insert() method is removed, and it was become a synonym of fast\_insert() method.

If you want to use previous style insert() method, please try [Otogiri::Plugin::InsertAndFetch](https://metacpan.org/pod/Otogiri%3A%3APlugin%3A%3AInsertAndFetch) .

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>

# SEE ALSO

[DBIx::Otogiri](https://metacpan.org/pod/DBIx%3A%3AOtogiri)

[DBIx::Sunny](https://metacpan.org/pod/DBIx%3A%3ASunny)

[SQL::Maker](https://metacpan.org/pod/SQL%3A%3AMaker)

[SQL::QueryMaker](https://metacpan.org/pod/SQL%3A%3AQueryMaker)
