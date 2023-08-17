package Mojo::CouchDB;

use Mojo::Base -base;
use Mojo::CouchDB::DB;
use Carp         qw(croak);
use MIME::Base64 qw(encode_base64);

our $VERSION = '1.0';

has 'url';
has 'auth';
has dbs => sub { state $dbs = {} };

sub db {
    my $self    = shift;
    my $db_name = shift;

    return $self->dbs->{$db_name} if exists $self->dbs->{$db_name};

    my $db = Mojo::CouchDB::DB->new($self->url->path($db_name), $self->auth);
    $self->dbs->{$db_name} = $db;

    return $db;
}

sub new {
    my $self     = shift->SUPER::new;
    my $str      = shift;
    my $username = shift;
    my $password = shift;

    return $self unless $str;

    chop $str if substr($str, -1) eq '/';

    my $url = Mojo::URL->new($str);
    croak "Invalid CouchDB URI string $str" unless $url->protocol =~ /^http(?:s)?$/;

    chomp($self->{auth} = 'Basic ' . encode_base64("$username:$password"))
        if $username and $password;

    $self->{url} = $url;

    return $self;
}

1;

=encoding utf8

=head1 NAME

Mojo::CouchDB

=head1 SYNOPSIS

    use Mojo::CouchDB;

    # Create a CouchDB instance
    my $couch = Mojo::CouchDB->new('http://localhost:6984', 'username', 'password');
    my $db = $couch->db('books');

    $db->create_db; # Create the database on the server

    # Make a document
    my $book = {
        title => 'Nineteen Eighty Four',
        author => 'George Orwell'
    };

    # Save your document to the database
    $book = $db->save($book);

    # If _id is assigned to a hashref, save will update rather than create
    say $book->{_id}; # Assigned when saving or getting
    $book->{title} = 'Dune';
    $book->{author} = 'Frank Herbert'

    # Re-save to update the document
    $book = $db->save($book);

    # Get the document as a hashref
    my $dune = $db->get($book->{_id});

    # You can also save many documents at a time
    my $books = $db->save_many([{title => 'book', author => 'John'}, { title => 'foo', author => 'bar' }])->{docs};

=head2 db

    my $db = $couch->db('books');

Create an instance of L<"Mojo::CouchDB::DB"> that corresponds to the database name specified in the first parameter.

=head2 new

    my $url   = 'https://127.0.0.1:5984';
    my $couch = Mojo::CouchDB->new($url, $username, $password);

Creates an instance of L<"Mojo::CouchDB">. The URL specified must include the protocol either C<http> or C<https> as well as the port your CouchDB instance is using.

=head1 API

=over 2

=item * L<Mojo::CouchDB>
=item * L<Mojo::CouchDB::DB>

=back

=head1 AUTHOR

Rawley Fowler, C<rawleyfowler@proton.me>.

=head1 CREDITS

=over 2

=back

=head1 LICENSE

Copyright (C) 2023, Rawley Fowler and contributors.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<https://mojolicious.org>.

=cut
