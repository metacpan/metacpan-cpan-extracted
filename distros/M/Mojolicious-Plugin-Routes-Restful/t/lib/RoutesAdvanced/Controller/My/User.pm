package RoutesAdvanced::Controller::My::User;

use strict;
use warnings;
use v5.10;
use Mojo::Base 'Mojolicious::Controller';

sub my_projects {

    my $self = shift;

    if ( $self->req->method eq 'PUT' ) {

        if ( $self->param('child_id') ) {
            $self->render(
                    text => "Put for project="
                  . $self->param('id')
                  . " user="
                  . $self->param('child_id')

            );
        }
        else {
            $self->render(
                text => "Put all users under project" . $self->param('id'),

            );
        }
    }
    elsif ( $self->req->method eq 'PATCH' ) {

        if ( $self->param('child_id') ) {
            $self->render(
                    text => "Patch for project="
                  . $self->param('id')
                  . " user="
                  . $self->param('child_id')

            );
        }
        else {
            $self->render(
                text => "Patch all users under project" . $self->param('id'),

            );
        }
    }
    elsif ( $self->req->method eq 'DELETE' ) {

        if ( $self->param('child_id') ) {
            $self->render(
                    text => "delete for project="
                  . $self->param('id')
                  . " user="
                  . $self->param('child_id')

            );
        }
        else {
            $self->render(
                text => "delete all users under project" . $self->param('id'),

            );
        }
    }

}

1;
