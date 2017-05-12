package RoutesAdvanced::Controller::My::Lab;

use strict;
use warnings;
use v5.10;
use Mojo::Base 'Mojolicious::Controller';


sub show {

    my $self = shift;

        $self->render(
            text => "show all",

        );

}


1;
