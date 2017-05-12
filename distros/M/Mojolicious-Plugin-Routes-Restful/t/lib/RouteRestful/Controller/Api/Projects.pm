package RouteRestful::Controller::Api::Projects;

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

sub create {
    my $self = shift;
    
    if ( $self->param('id') ) {
        return $self->render( json => { status => 404 } );
    }
    else {

        foreach my $in_key (qw(type name owner)) {
            $project->{3}->{$in_key} = $self->param($in_key);
        }
        $project->{3}->{id} = 3;

        $self->render(
            json => {
                status => 200,
                new_id => 3
            }
        );

    }

}

sub update {
    my $self = shift;

# warn("Api::Projects update id=".$self->param('id'));

    if ( $self->param('id') ) {
        my $out = $project->{ $self->param('id') };
        foreach my $in_key (qw(type name owner)) {

            $out->{$in_key} = $self->param($in_key);
        }

        $self->render( json => { status => 200 } );
    }
    else {
        return $self->rendered(404);

    }

}

sub replace {
    my $self = shift;

# warn("Api::Projects replace id=".$self->param('id'));

    if ( $self->param('id') ) {
        
        my $replace ={
        id       => 4,
        name     => 'project 3a',
        type     => 'test type 3a',
        owner    => 'Bloggs 3a',
        users    => [ 'blogs 3a', 'major 3a' ],
        contacts => [ 'George 3a', 'John 3a', 'Paul 3a', 'Ringo 3a' ],
        planning => {
            name  => 'longterm 3a',
            build => '3a'
        }
    };
        my $old_id = $self->param('id');
      
         delete($project->{ $old_id });
         $project->{ $old_id } =   $replace;


         # warn("Api::Projects 2 id=".Dumper($project));    
         
        $self->render( json => { status => 200 } );
    }
    else {
        return $self->rendered(404);

    }

}

sub get {
    my $self = shift;
# warn("Api::Projects get id=".$self->param('id'));
    my $out;
    if ( $self->param('id') ) {
        $out = $project->{ $self->param('id') };
    }
    else {
        $out = [ map { $project->{$_} } sort keys %{$project} ];
    }
    
    # warn("Api::Projects get id=".Dumper($out));

    if ($out) {
        $self->render( json => $out );
    }
    else {

        return $self->rendered(404);
    }
}

sub delete {
    my $self = shift;
    if ( $self->param('id') ) {
        delete( $project->{ $self->param('id') } );

        $self->render( json => { status => 200 } );
    }
    else {
        return $self->rendered(404);

    }
}

sub details {
    my $self = shift;
    if ( $self->param('id') ) {
        my $out = $project->{ $self->param('id') };
        foreach my $in_key (qw(owner)) {
            $out->{$in_key} = $self->param($in_key);
        }
        $self->render( json => { status => 200 } );
    }
    else {
        return $self->rendered(404);

    }
}

sub longdetails {
    my $self = shift;
    if ( $self->param('id') ) {
        my $out = $project->{ $self->param('id') };
        foreach my $in_key (qw(type name)) {
            $out->{$in_key} = $self->param($in_key);
        }

        $self->render( json => { status => 200 } );
    }
    else {
        return $self->rendered(404);

    }

}

sub planning {
    my $self = shift;
    if ( $self->param('id') ) {
        my $out      = $project->{ $self->param('id') };
        my $planning = $self->param('planning');

        foreach my $in_key (qw(build name)) {

            $out->{planning}->{$in_key} =
              $planning->{headers}->{headers}->{$in_key}->[0];

        }
        $self->render( json => { status => 200 } );
    }
    else {
        return $self->rendered(404);

    }
}

sub users {
    my $self = shift;

    if ( $self->param('id') ) {

        my $out = $project->{ $self->param('id') }->{users};
        $self->render( json => $out );
    }
    else {
        return $self->rendered(404);

    }
}

sub contacts {
    my $self = shift;

    if ( $self->param('id') ) {

        my $out = $project->{ $self->param('id') }->{contacts};
        $self->render( json => $out );
    }
    else {
        return $self->rendered(404);

    }
}

1;
