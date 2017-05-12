package MyRest::Dog;
use Mojo::Base 'Mojolicious::Controller::REST';

sub list_dog {
    my $self = shift;
    $self->render( json => { data => [ { id => 1, name => 'bo' }, { id => 2, name => 'boo' } ] } );
}

sub create_dog {
    my $self = shift;
    $self->data( id => $self->req->json->{id} )->data( name => $self->req->json->{name} );
}

sub read_dog {
    my $self = shift;
    $self->render( json => { data => { id => $self->stash('dogId'), name => 'bo' } } );
}

sub update_dog {
    my $self = shift;
    $self->render( json => { data => { id => $self->stash('dogId'), name => $self->req->json->{name} } } );
}

sub delete_dog {
    my $self = shift;
    $self->render( json => { data => { id => $self->stash('dogId'), name => 'bo' } } );
}

1;
