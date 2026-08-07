package MyApp::Controller::Web::Book;

use strict;
use warnings;
use parent 'Punk::Controller';

sub home {
    my ($c) = @_;
    return $c->html('<h1>MyApp</h1>');
}

sub list {
    my ($c) = @_;
    my $page = $c->model('Book')->all;
    return $c->render('book/list', {
        title         => 'Books',
        books         => $page->{rows},
        has_more_data => $page->{has_more_data},
        next          => $page->{next} // '',
    });
}

sub view {
    my ($c) = @_;
    my $book = $c->model('Book')->get( id => $c->param('id') )
        or return $c->not_found;
    return $c->render('book/view', { title => $book->{title},
                                     book  => $book });
}

sub create {
    my ($c) = @_;
    my $book = $c->model('Book')->create( $c->req->json );
    $c->status(201);
    return $book;
}

sub admin_list {
    my ($c) = @_;
    my $page = $c->model('Book')->all;
    return { books => $page->{rows}, admin => \1 };
}

1;
