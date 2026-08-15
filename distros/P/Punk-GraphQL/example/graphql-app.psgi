#!/usr/bin/env perl
use strict;
use warnings;

# A complete Punk + GraphQL application, controller style. Run it on
# Hyperman:
#
#   hyperman example/graphql-app.psgi
#
# then open http://localhost:5000/graphql in a browser for GraphiQL, or:
#
#   curl -s -X POST -H 'Content-Type: application/json' \
#     -d '{"query":"{ books { title author { name } } }"}' \
#     http://localhost:5000/graphql

package Library::Model;

our %AUTHORS = (
    1 => { id => 1, name => 'Octavia Butler' },
    2 => { id => 2, name => 'Ursula K. Le Guin' },
);
our @BOOKS = (
    { id => 1, title => 'Kindred',              author_id => 1 },
    { id => 2, title => 'Parable of the Sower', author_id => 1 },
    { id => 3, title => 'The Dispossessed',     author_id => 2 },
);

# Resolvers are controller methods, wired the way routes are: the Query
# type names the class, so books() and book() attach to the same-named
# SDL fields; Book.author is a route-style 'Controller#method' target.
package Library::Controller::Books;

sub books { [ @Library::Model::BOOKS ] }

sub book {
    my (undef, $args) = @_;
    my ($b) = grep { $_->{id} == $args->{id} } @Library::Model::BOOKS;
    return $b;
}

sub author {
    my ($book) = @_;
    return $Library::Model::AUTHORS{ $book->{author_id} };
}

package Library;
use Punk;
use Punk::Plugin::GraphQL;

graphql '/graphql' => <<'SDL', {
type Author {
  id: ID!
  name: String!
}
type Book {
  id: ID!
  title: String!
  author: Author!
}
type Query {
  books: [Book!]!
  book(id: ID!): Book
}
SDL
    resolvers => {
        Query => 'Books',
        Book  => { author => 'Books#author' },
    },
    graphiql => 1,
};

plugin 'GraphQL';

package main;
Library->to_app;
