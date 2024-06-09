package Otogiri;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.23";

use parent 'Exporter';
use SQL::QueryMaker;
use DBIx::Otogiri;

our @EXPORT = map {"sql_$_"} qw/
    eq like lt gt le ge
    is_null is_not_null
    between not_between
    in not_in
    and or not
    op raw
/;

sub new {
    my ($class, %opts) = @_;
    DBIx::Otogiri->new(%opts);
}

1;
__END__

=encoding utf-8

=head1 NAME

Otogiri - A lightweight medicine for using database

=head1 SYNOPSIS

    use Otogiri;
    my $db = Otogiri->new(connect_info => ['dbi:SQLite:...', '', '']);

    # or use with DBURL
    my $db = Otogiri->new(dburl => 'sqlite://...');
    
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

=head1 DESCRIPTION

Otogiri is a thing that like as ORM. A slogan is "Schema-less, Fat-less".

=head1 ATTRIBUTES

Please see ATTRIBUTES section of L<DBIx::Otogiri> documentation.

=head1 METHODS

=head2 new

    my $db = Otogiri->new( connect_info => [$dsn, $dbuser, $dbpass] );

Instantiate and connect to db. Then, it returns L<DBIx::Otogiri> object.

=head1 EXPORT FUNCTIONS

Otogiri exports each SQL::QueryMaker::sql_* functions. (ex. sql_ge(), sql_like() and more...)

For more information, please see FUNCTIONS section of L<SQL::QueryMaker>'s documentation.

=head1 INFORMATION ABOUT INCOMPATIBILITY

=head2 version 0.11

An insert() method is removed, and it was become a synonym of fast_insert() method.

If you want to use previous style insert() method, please try L<Otogiri::Plugin::InsertAndFetch> .

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=head1 SEE ALSO

L<DBIx::Otogiri>

L<DBIx::Sunny>

L<SQL::Maker>

L<SQL::QueryMaker>

=cut

