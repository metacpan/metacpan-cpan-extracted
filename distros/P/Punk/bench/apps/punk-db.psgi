#!/usr/bin/env perl
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../../lib";
# BENCH-PATH: /book

# A single model get on an in-memory SQLite database, the whole Punk model
# path: $c->model('Book') (cached per worker), Punk::Model::DBI's cached
# prepared statement, the DBI round-trip, auto-JSON. The DB dominates - this
# is the phase-4 baseline, not a threshold, to compare later backends and
# caching against.

package Bench::DB::Model::Book;
use Punk::Model;
table 'books';
field id    => { type => 'integer', primary => 1 };
field title => { type => 'string' };

package Bench::DB;
use Punk;

database dsn => 'dbi:SQLite:dbname=:memory:';
model 'Book';

get '/book' => sub {
    my ($c) = @_;
    return $c->model('Book')->get(id => 1) || $c->not_found;
};

package main;

# seed the shared in-memory database once, through the model's own handle
my $app = Bench::DB->to_app;
{
    my $book = Bench::DB->punk_app->model_instance('Book');
    my $dbh  = $book->backend->dbh;
    $dbh->do('CREATE TABLE books (id INTEGER PRIMARY KEY, title TEXT)');
    $dbh->do("INSERT INTO books (id, title) VALUES (1, 'Neuromancer')");
}
$app;
