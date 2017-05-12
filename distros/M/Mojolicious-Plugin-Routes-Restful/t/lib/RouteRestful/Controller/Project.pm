package RouteRestful::Controller::Project;

use strict;
use warnings;
use v5.10;
use Mojo::Base 'Mojolicious::Controller';


sub show {

    my $self = shift;

    if ( $self->param('id') ) {
        $self->render(
            text => "show for " . $self->param('id'),

        );
    }
    else {
        $self->render(
            text => "show all",

        );
    }

}

sub detail {
    my $self = shift;

    $self->render(
        text => "detail for " . $self->param('id'),

    );
}

sub longdetail {
    my $self = shift;

    $self->render(
        text => "longdetail for " . $self->param('id'),

    );
}

sub planning {
    my $self = shift;

    my $text = 'my plans';

    if ( $self->param('child_id') ) {
        $text = 'plan='
          . $self->param('child_id')
          . ', for project='
          . $self->param('id');
    }
    elsif ( $self->param('id') ) {
        $text = 'all plans for project=' . $self->param('id');

    }

    $self->render( text => $text, );
}

sub user {
    my $self = shift;

    my $text = 'my users';

    if ( $self->param('child_id') ) {
        $text = 'user='
          . $self->param('child_id')
          . ', for project='
          . $self->param('id');
    }
    elsif ( $self->param('id') ) {
        $text = 'all users for project=' . $self->param('id');
    }

    $self->render( text => $text, );

}

sub contact {
    my $self = shift;

    my $text = 'my contacts';

    if ( $self->param('child_id') ) {
        $text =
            'contact='
          . $self->param('child_id')
          . ', for project='
          . $self->param('id');
    }
    elsif ( $self->param('id') ) {
        $text = 'all contacts for project=' . $self->param('id');

    }


    $self->render( text => $text, );
}
1;
