package RoutesAdvanced::Controller::Ipa::Project;

use strict;
use warnings;
use Data::Dumper;
use v5.10;

my $project = {
    1 => {
        id       => 1,
        name     => 'project 1',
        type     => 'test type 1',
        owner    => 'Bloggs 1',
        users    => [ 'blogs 1', 'major 1' ],
        contacts => [ 'George 1', 'John 1', 'Paul 1', 'Ringo 1' ],
        planning => {
            name  => 'longterm 1',
            build => 1
        }
    },
    2 => {
        id       => 2,
        name     => 'project 2a',
        type     => 'test type 2a',
        owner    => 'Bloggs 2',
        users    => [ 'blogs 2', 'major 2' ],
        contacts => [ 'George 2', 'John 2', 'Paul 2', 'Ringo 2' ],
        planning => {
            name  => 'longterm 2',
            build => 2
        }
    },
    4 => {
        id       => 4,
        name     => 'project 3',
        type     => 'test type 3',
        owner    => 'Bloggs 3',
        users    => [ 'blogs 3', 'major 3' ],
        contacts => [ 'George 3', 'John 3', 'Paul 3', 'Ringo 3' ],
        planning => {
            name  => 'longterm 3',
            build => '3'
        }
    },
   
};

use base 'Mojolicious::Controller';


sub mydeatails {
    my $self = shift;
     if ( $self->req->method eq 'GET' ) {

         $self->render( json => { status => 200 } );
    }
     $self->render( json => { status => 404 } );
}

sub view_users {
    my $self = shift;
     if ( $self->req->method eq 'GET' ) {

         $self->render( json => { status => 200 } );
    }
     $self->render( json => { status => 404 } );
}

sub planning {
    my $self = shift;
     if ( $self->req->method eq 'GET' ) {

         $self->render( json => { status => 200 } );
    }
     $self->render( json => { status => 404 } );
}


1;
