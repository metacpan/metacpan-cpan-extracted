package RoutesAdvanced::Controller::My::Office;

use strict;
use warnings;
use v5.10;
use Mojo::Base 'Mojolicious::Controller';


sub show {
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
}


1;
