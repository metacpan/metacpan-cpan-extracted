package MyApp::Controller::API::Book;

use strict;
use warnings;
use parent 'Punk::Controller';

sub allBooks {
    my ($c) = @_;
    my $page = $c->model('Book')->search({}, {
        limit => $c->param('limit') || 20,
        (length($c->param('next') // '') ? (after => $c->param('next')) : ()),
    });
    return {
        books         => $page->{rows},
        has_more_data => $page->{has_more_data},
        next          => $page->{next},
    };
}

sub getBook {
    my ($c) = @_;
    return $c->model('Book')->get( id => $c->param('id') )
        // $c->not_found;
}

sub addBook {
    my ($c) = @_;
    $c->status(201);
    return $c->model('Book')->create( $c->openapi->{body} );
}

1;
