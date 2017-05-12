package RouteRestful::Controller::Api::Users;

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

    if ( $self->param('parent') eq 'projects' ) {

        $out =
          $project->{ $self->param("id") }->{users}
          ->[ $self->param("child_id") - 1 ];
    }

    if ($out) {
        $self->render( json => $out );
    }
    else {

        return $self->rendered(404);
    }

}

sub create {
    my $self = shift;
    my $out;

    if ( $self->param('parent') eq 'projects' ) {

        push(
            @{ $project->{ $self->param("id") }->{users} },
            $self->param('user')
        );

        $self->render(
            json => {
                status => 200,
                new_id => 3
            }
        );
    }

    else {

        return $self->rendered(404);
    }
}

sub delete {
    my $self = shift;
    my $out;

    if ( $self->param('parent') eq 'projects' ) {

        $project->{ $self->param("id") }->{users} = undef;

        $self->render( json => { status => 200, } );
    }

    else {

        return $self->rendered(404);
    }
}
1;
