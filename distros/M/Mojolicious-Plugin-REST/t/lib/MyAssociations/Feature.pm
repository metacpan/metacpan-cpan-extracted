package MyAssociations::Feature;
use Mojo::Base 'Mojolicious::Controller';

sub list_user_feature {
    my $self = shift;
    $self->render( json => { data => [ { id => 1, name => 'mysql' }, { id => 2, name => 'mails' } ] } );
}

sub create_user_feature {
    my $self = shift;
    $self->render( json => { data => { id => $self->req->json->{id}, name => $self->req->json->{name} } } );
}

sub read_user_feature {
    my $self = shift;
    $self->render(
        json => { data => { id => $self->stash('userId'), features => [ { id => 'mysql' }, { id => 'mails' } ] } } );
}

sub update_user_feature {
    my $self = shift;
    $self->render(
        json => { data => { id => $self->stash('userId'), feature => { id => $self->stash('featureId') } } } );
}

sub delete_user_feature {
    my $self = shift;
    $self->render(
        json => { data => { id => $self->stash('userId'), feature => { id => $self->stash('featureId') } } } );
}
1;
