package 
    BenchCat::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';
use JSON::MaybeXS ();

# The three benched responses, matching punk-hello / punk-dyn / punk-json.

__PACKAGE__->config(namespace => '');

my $JSON = JSON::MaybeXS->new(utf8 => 1);

sub hello :Path('/') :Args(0) {
    my ($self, $c) = @_;
    $c->res->content_type('text/plain');
    $c->res->body('hello');
}

sub book :Path('/books') :Args(1) {
    my ($self, $c, $id) = @_;
    $c->res->content_type('text/plain');
    $c->res->body('hello');
}

sub as_json :Path('/json') :Args(0) {
    my ($self, $c) = @_;
    $c->res->content_type('application/json');
    $c->res->body($JSON->encode({ hello => 'world' }));
}

1;
