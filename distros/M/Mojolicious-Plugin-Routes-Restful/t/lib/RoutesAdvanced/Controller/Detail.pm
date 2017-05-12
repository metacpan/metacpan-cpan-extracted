package RoutesAdvanced::Controller::Detail;

use strict;
use warnings;
use v5.10;
use Mojo::Base 'Mojolicious::Controller';


sub project {

    my $self = shift;

    if ($self->req->method eq 'GET'){
        
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
    else {
    if ( $self->param('id') ) {
        $self->render(
            text => "update for " . $self->param('id'),

        );
    }
    else {
        $self->render(
            text => "New for 2",

        );
     }        
        
    }
}


1;
