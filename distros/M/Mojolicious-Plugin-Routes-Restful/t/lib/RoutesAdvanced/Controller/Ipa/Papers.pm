package RoutesAdvanced::Controller::Ipa::Papers;

use strict;
use warnings;
use v5.10;
use Data::Dumper;
use base 'Mojolicious::Controller';
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
        name     => 'project 2',
        type     => 'test type 2',
        owner    => 'Bloggs 2',
        users    => [ 'blogs 2', 'major 2' ],
        contacts => [ 'George 2', 'John 2', 'Paul 2', 'Ringo 2' ],
        planning => {
            name  => 'longterm 2',
            build => 2
        }
    }
};

sub get {
    my $self = shift;

    my $out;

    if ( $self->param('id') ) {

        $out = [paper_id=>1,paper_id=>2]
          ;
    }
    else {
        $out= {id=>1};
    }

    if ($out) {
        $self->render( json => $out );
    }
    else {

        return $self->rendered(404);
    }

}


1;
