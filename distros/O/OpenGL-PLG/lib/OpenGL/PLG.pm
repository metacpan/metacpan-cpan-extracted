package OpenGL::PLG;
use Carp;

use warnings;
use strict;

our $VERSION = '0.03';


# creates a new PoLyGon object
sub new {
    my ($class) = @_;
    my $self = bless {},$class;

    $self->{'vertices'} = [];
    $self->{'polygons'} = [];

    return $self;
}


# reads a given PLG file
# and parse it into the object
# TODO: handle multiple PLG formats
sub parse_file {
    my ($self, $filename) = @_;

    open my $fh, '<', $filename
        or croak "error loading '$filename': $!\n";

    my $reading_vertexes = 1;

    while (my $line = <$fh>) {
        my @fields = split /\s+/, $line;

        # if we reach an empty line,
        # then what will follow is
        # the list of positions for each
        # collected vertex
        if ( @fields == 0 ) {
            $reading_vertexes = 0;
            next;
        }

        # if we are reading vertices,
        # load them into our object
        if ($reading_vertexes) {
            $self->set_vertex(@fields);
        }

        # otherwise, we are reading
        # a polygon list (each of it
        # using some of the vertices
        # collected beforehand)
        else {

            # validade the input
            if ($fields[0] !~ m/^\d+$/ ) {
                croak 'error parsing file. Expected single number of '
                    . "vertices in polygon, but got '@fields' instead\n";
            }

            my $n_vertices = $fields[0];

            # retrieve the next line
            $line = <$fh>;
            @fields = split /\s+/, $line;

            $self->set_polygon($n_vertices, @fields);
        }
    }
    close $fh;
}


# include a polygon shape into the object.
# the first parameter indicates the number
# of vertices in the polygon. Next follows
# the list of vertices ids. This function
# does not return anything, but croak's if
# the number of vertices is not the same as
# expected.
sub set_polygon {
    my $self = shift;
    my ($n_vertices, @fields) = @_;

    # validade input (at least some of it)
    if ( @fields != $n_vertices ) {
        croak "error reading polygon input. Expected $n_vertices "
            . 'vertices but got ' . scalar @fields . " instead.\n";
    }
    else {
        push @{ $self->{'polygons'} }, [ @fields ];
    }
}

# deletes a given polygon by its id number.
# The first included polygon has id "1",
# while the last one is total_polygons().
# Circular references work, so you can
# get to the last polygon via a -1 id and
# so on. The id "0" does not exist. If you
# try to use it, you'll get an error.
# Also note that, once you delete a polygon,
# the id's of the polygons following it 
# will be decreased by one.
sub delete_polygon {
    my ($self, $id) = @_;

    if ( not defined $id ) {
        croak "delete_polygon needs a loaded polygon id\n";
    }
    elsif ( $id == 0 ) {
        croak "polygon id cannot be zero\n";
    }

    # corrects behavior of plg files,
    # as they start with 1, not 0
    $id-- if $id > 0;

    if ( not defined $self->{'polygons'}->[$id] ) {
        croak "delete_polygon needs a loaded polygon id\n";
    }
    else {
        splice @{ $self->{'polygons'} }, $id, 1;
        return 1;
    }
   
}


# create a vertex in positions
# x, y, z. You can optionally specify an id
# for it ( >= 1 ), and PLG will put your
# vertex in that slot, replacing any vertex
# there (if available). Otherwise
# we'll place it in the last available
# id slot. 
# TODO: croak if x,y,z values are not floats
# (regexp for -?\d+(?:\.\d+)?+e\d+ special float cases
# or something like that)
sub set_vertex {
    my $self = shift;
    my ($x, $y, $z, $id) = @_;

    # if 'id' is not valid or doesn't exist,
    # we'll use the last position on the array
    if (not defined $id or $id !~ /^\d+$/ ) {
        $id = @{ $self->{'vertices'} } + 1;
    }
    elsif ( $id == 0 ) {
        croak "vertex id cannot be zero\n";
    }

    if (not defined $x
     or not defined $y
     or not defined $z
    ) {
        croak "vertices must have all three coordinates (x, y, z)";
    }

    # corrects behavior of plg files,
    # as they start with 1, not 0
    $id-- if $id > 0;

    # insert the vertex in the correct
    # index (id) position
    $self->{'vertices'}->[$id] = [$x, $y, $z];

    return $id;
}


# same as set_vertex, but lets you create
# several vertices at once.
sub set_vertices {
    my ($self, $v_ref) = @_;

    if (not defined $v_ref
     or ref($v_ref) ne 'HASH') {
        croak "set_vertices must receive a hash reference.\n";
    }

    foreach (sort keys %{$v_ref} ) {
        $self->set_vertex(@{$v_ref->{$_}}, $_);
    }
}


# returns the total number of vertices
# in the object
sub total_vertices {
    my $self = shift;
    return scalar ( @{ $self->{'vertices'} } );
}

# returns the total number of polygons
# in the object
sub total_polygons {
    my $self = shift;
    return scalar ( @{ $self->{'polygons'} } );
}


# retrieves a vertex by its id
sub get_vertex {
    my ($self, $id) = @_;

    if ( not defined $id ) {
        croak "get_vertex needs a loaded vertex id\n";
    }
    elsif ( $id == 0 ) {
        croak "vertex id cannot be zero\n";
    }

    # corrects behavior of plg files,
    # as they start with 1, not 0
    $id-- if $id > 0;

    if ( not defined $self->{'vertices'}->[$id] ) {
        croak "get_vertex needs a loaded vertex id\n";
    }
    else {
        return @{ $self->{'vertices'}->[$id] };
    }
}


# returns an array reference containing
# the coordinates of each vertex inside a 
# given polygon
sub get_vertices_from_polygon {
    my ($self, $polygon) = @_;
    my $vertices_ref = [];

    my $i = 0;
    foreach ( $self->get_polygon($polygon) ) {
        push @{$vertices_ref->[$i++]}, $self->get_vertex($_);
    }
    return $vertices_ref;
}


# deletes a given vertex by its id number.
# The first included vertex has id "1",
# while the last one is total_vertices().
# Circular references work, so you can
# get to the last vertex via a -1 id and
# so on. The id "0" does not exist. If you
# try to use it, you'll get an error.
# Also note that, once you delete a vertex,
# the id's of the vertices following it will 
# be decreased by one.
sub delete_vertex {
    my ($self, $id) = @_;

    if ( not defined $id ) {
        croak "delete_vertex needs a loaded vertex id\n";
    }
    elsif ( $id == 0 ) {
        croak "vertex id cannot be zero\n";
    }

    # corrects behavior of plg files,
    # as they start with 1, not 0
    $id-- if $id > 0;

    if ( not defined $self->{'vertices'}->[$id] ) {
        croak "delete_vertex needs a loaded vertex id\n";
    }
    else {
        splice @{ $self->{'vertices'} }, $id, 1;
        return 1;
    }
}


# retrieves a polygon by its id
sub get_polygon {
    my ($self, $id) = @_;

    if ( not defined $id ) {
        croak "get_polygon needs a loaded polygon id\n";
    }
    elsif ( $id == 0 ) {
        croak "polygon id cannot be zero\n";
    }

    # corrects behavior of plg files,
    # as they start with 1, not 0
    $id-- if $id > 0;

    if ( not defined $self->{'polygons'}->[$id] ) {
        croak "get_polygon needs a loaded polygon id\n";
    }
    else {
        return @{ $self->{'polygons'}->[$id] };
    }
}


# renders OpenGL code to display the
# object (i.e. the collection of polygons
# forming whatever-it-is-they-form).
# Note that using this outside of an
# OpenGL program will most likely *not*
# produce the expected results (see example
# in the USAGE section for a way to actually
# display the image on the screen). This
# method needs the Perl OpenGL library to work.
sub render {
    my $self = shift;

    eval 'use OpenGL; 1';
    if ($@) {
        croak "Can't load Perl OpenGL: $@\n";
    }

    foreach my $plg_ref ( @{$self->{'polygons'} } ) {

        # each polygon is represented
        # independently
        &OpenGL::glBegin(&OpenGL::GL_POLYGON);

        foreach my $vertex_id ( @{$plg_ref} ) {
            my @v = $self->get_vertex($vertex_id);
            &OpenGL::glVertex3f(@v);
        }

        &OpenGL::glEnd;
    }
}

# dumps a string containing the OpenGL code 
# to display the object (i.e. the collection 
# of polygons forming whatever-it-is-they-form).
# Use this to see the code that will be produced
# by render() should you use it inside an OpenGL
# display. You do *NOT* need OpenGL to use this,
# as it will just output the code, not eval it.
sub dump_code {
    my $self = shift;
    my $dump = '';

    foreach my $plg_ref ( @{$self->{'polygons'} } ) {
        $dump .= "glBegin(GL_POLYGON);\n";
        foreach my $vertex_id ( @{$plg_ref} ) {
            my $v = join ( ', ', $self->get_vertex($vertex_id) );
            $dump .= "  glVertex3f($v);\n";
        }
        $dump .= "glEnd();\n";
    }

    return $dump;
}


# this is the same as dump_code(), but will write
# the string to a given file instead of giving
# it back to the user. This is useful if you want
# to use the OpenGL code in another language
# (like C or C++).
sub dump_code_to_file {
    my ($self, $filename) = @_;

    open my $fh, '>', $filename
        or croak "Error opening '$filename': $!\n";

    print $fh $self->dump()
        or croak "Error writing to file '$filename': $!\n";

    close $fh;
}

# this will write the object's vertices and
# polygons to a file, in raw PLG format. This
# is the exact reverse of parse_file().
# TODO: option to include vertices index next to them
# TODO: option to save in multiple PLG formats
sub write_to_file {
    my ($self, $filename) = @_;

    open my $fh, '>', $filename
        or croak "Error opening '$filename': $!\n";

    # write vertex data
    my $i = 0;
    while ($i < $self->total_vertices) {
        my @vertex = $self->get_vertex($i);
        next unless defined $vertex[0];
        print $fh join (' ', @vertex ) . "\n";
    }
    continue {
        $i++;
    }

    # insert a blank line
    print $fh "\n";

    # write polygon data
    $i = 0;
    while ($i < $self->total_polygons) {
        my @polygon = $self->get_polygon($i);
        next unless defined $polygon[0];

        print $fh scalar (@polygon) . "\n"
            . join (' ', @polygon ) . "\n"
            ;
    }
    continue {
        $i++;
    }
    close $fh;
}

42; # End of OpenGL::PLG

__END__


=head1 NAME

OpenGL::PLG - Create, manipulate and render PoLyGon objects and files


=head1 VERSION

Version 0.03


=head1 SYNOPSIS

    use OpenGL::PLG;

    # create a new PoLyGon object
    my $plg = OpenGL::PLG->new();

    # define a few vertices with an
    # ID as a last argument
    $plg->set_vertex( 0.0,  1.0, 0.0, 1 );
    $plg->set_vertex( 1.0, -1.0, 0.0, 2 );
    $plg->set_vertex(-1.0, -1.0, 0.0, 3 );

    # if you ommit the ID, it will add in the
    # first free ID slot, and return that ID number.
    my $id = $plg->set_vertex(0.5, 0.5, 0.5);
    print "vertex inserted with id $id\n";  # '4', in our case here
    
    # you can also set a lot of them simultaneously.
    # The code below does exactly the same as above
    # (overriding previously set values)
    $plg->set_vertices( {
            1 => [ 0.0,  1.0, 0.0],
            2 => [ 1.0, -1.0, 0.0],
            3 => [-1.0, -1.0, 0.0],
          });
    
    # create a polygon using above vertices chosen 
    # by vertex "ID". The first value must indicate
    # the size of the polygon, i.e., the size of 
    # the array.
    $plg->set_polygon(3, 1,2,3);

    # after vertices and polygons are created, you
    # can fetch them like this:
    my @v_ids       = $plg->get_polygon( 1 );
    my @coordinates = $plg->get_vertex( $v_ids[0] );

    # you can even get all vertices from a given polygon
    # in an array ref:
    my $vertices = $plg->get_vertices_from_polygon( 2 );
   
    # you can see the OpenGL code necessary to render
    # the model inside:
    print $plg->dump_code();

    # The above command outputs (in this case):
    # -----------------------------------------
    #
    # glBegin(GL_POLYGON);
    #   glVertex3f(0.0, 1.0, 0.0);
    #   glVertex3f(1.0, -1.0, 0.0);
    #   glVertex3f(-1.0, -1.0, 0.0);
    # glEnd();
    
    # you can optionally dump the generated code
    # directly to a file:
    $plg->dump_code_to_file('triangle.render');
    
    # or write a file in raw PLG format
    $plg->write_to_file('mytriangle.plg');
    
    # finally, you can delete vertices 
    # and polygons at will by ID
    $plg->delete_polygon(1);
    $plg->delete_vertex(4);


You can also parse standard PLG files and even render your code in an OpenGL program. The following snippet is a tiny working program that does that (keys 'x', 'y' and 'z', when pressed, will rotate the 3d model on each axis):

    use Time::HiRes qw(usleep);
    use OpenGL qw(:all);
    
    use OpenGL::PLG;
    
    my $dino = OpenGL::PLG->new();
    $dino->parse_file('trex.plg');
   
    my ($rx, $ry, $rz) = (0.0, 0.0, 0.0);
    glutInit;  
    glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE);  
    glutCreateWindow("Sample PLG Renderer");  
    glutDisplayFunc(\&DrawGLScene);  
    glutIdleFunc(\&DrawGLScene);
    glutKeyboardFunc(\&keyPressed);
    glClearColor(0.0, 0.0, 0.0, 0.0);
    InitGL(640, 480);
    glutMainLoop;  
    
    sub InitGL {
        my ($width, $height) = @_;
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity;
        gluPerspective(65.0, $width/$height, 0.1, 100.0);
        glMatrixMode(GL_MODELVIEW);
    }

    sub DrawGLScene {
        glClear(GL_COLOR_BUFFER_BIT);  
        glLoadIdentity;
        glTranslatef(0.0, 0.0, -5.0); 
        glRotatef($rz, 0, 0, 1);
        glRotatef($rx, 1, 0, 0);
        glRotatef($ry, 0, 1, 0);
        glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
    
        $dino->render();
    
        glutSwapBuffers;
        usleep (50000);
    }

    sub keyPressed {
        my ($key, $x, $y) = @_;
        if ($key == ord('z') ) {
            $rz = ($rz + 2.0) % 360.0;
        }
        elsif ( $key == ord('x') ) {
            $rx = ($rx + 2.0) % 360.0;
        }
        elsif ( $key == ord('y') ) {
            $ry = ($ry + 2.0) % 360.0;
        }
    }


=head1 DESCRIPTION

OpenGL::PLG is a class for OpenGL polygon objects. It lets you easily create and manipulate 3d polygon models. It also reads and writes files in raw PLG format, dumps OpenGL code and renders the 3d model (if you have Perl OpenGL installed).


=head1 METHODS

B<Note:> This is a rather new module so the API and standard behavior might slightly change in the future. Please submit any feature requests for new methods and/or any (minor) behavior adjustment. Thanks!

An OpenGL::PLG container has the following methods:

=head2 General

=head3 new()

Creates a new PoLyGon object.


=head2 File Manipulation

=head3 parse_file( I<FILENAME> )

Reads a given file in PLG format and parse it into the object. A PLG file is a text file that starts by listing vertices (x, y, z), one per line. Each vertex line may optionally end with a fourth value, consisting of the vertex id (if the id is not supplied, the vertex id is incremental, starting with 1). A blank line separates the vertex list from the polygon list, the latter consisting of two lines: one with the number of vertices in the polygon, and another with each vertice's id.

Some sample PLG files can be found here:
L<http://orion.lcg.ufrj.br/compgraf1/past/downloads/modelos/>

=head3 render()

Renders OpenGL code to display the object (i.e. the collection of polygons forming I<whatever-it-is-they-form>). Note that using this outside of an OpenGL program will most likely B<*NOT*> produce the expected results (see example in the USAGE section for a way to actually render the image on the screen with this). This method needs the Perl OpenGL library to work.

=head3 dump_code()

Dumps a string containing the OpenGL code to display the object (i.e. the collection of polygons forming I<whatever-it-is-they-form>). Use this to see the code that will be produced by render() should you use it inside an OpenGL display. You do B<*NOT*> need OpenGL to use this, as it will just output the code, not eval it.

=head3 dump_code_to_file( I<FILENAME> )

This is the same as dump_code(), but will write the string to a given file instead of giving it back to the user. This is useful if you want to use the OpenGL code in another language (like C or C++).

=head3 write_to_file( I<FILENAME> )

This will write the object's vertices and polygons to a file, in raw PLG format. This is the exact reverse of parse_file().



=head2 Vertex Manipulation

=head3 get_vertex( I<ID> )

Returns an array containing the wanted vertex coordinates (by its id).

=head3 get_vertices_from_polygon( I<ID> )

Returns an array reference containing all vertex coordinates inside a given polygon, already resolved (instead of just the vertices' id number from get_polygon).

=head3 set_vertex( I<X>, I<Y>, I<Z> [, I<ID>] )

Create a vertex in position x, y, z. You can optionally specify an id for it ( >= 1 ), and PLG will put your vertex in that slot, replacing any pre-existant vertex there. Otherwise we'll place it in the last available id slot. It returns the ID where the vertex is stored.

=head3 set_vertices( { I<ID1> => [I<X>, I<Y>, I<Z>], I<ID2> => ... } )

Same as set_vertex(), but lets you create several vertices at once by passing a hash reference with the vertex ID as key, and the X-Y-Z position as value (an array reference).

=head3 delete_vertex( I<ID> )

Deletes a given vertex by its id number. The first included vertex has id "1", while the last one is total_vertices(). Circular references work, so you can get to the last vertex via a -1 id and so on. The id "0" does not exist. If you try to use it, you'll get an error. Also note that, once you delete a vertex, the id's of the vertices following it will be decreased by one.

=head3 total_vertices()

Returns the total number of vertices in the object.



=head2 Polygon Manipulation

=head3 get_polygon( I<ID> )

Returns an array containing the wanted polygon (by its id).

=head3 set_polygon( I<N_VERTICES>, I<@VERTICES> )

Add a polygon shape into the object. The first parameter indicates the number of vertices in the polygon. Next follows the list of vertices ids. This function does not return anything, but croak's if the number of vertices is not the same as expected. It returns the ID number where the polygon is stored.

=head3 delete_polygon( I<ID> )

Deletes a given polygon by its id number. The first included polygon has id "1", while the last one is total_polygons(). Circular references work, so you can get to the last polygon via a -1 id and so on. The id "0" does not exist. If you try to use it, you'll get an error. Also note that, once you delete a polygon, the id's of the polygons following it will be decreased by one.

=head3 total_polygons()

Returns the total number of polygons in the object.



=head1 CONFIGURATION AND ENVIRONMENT

OpenGL::PLG requires no configuration files or environment variables.



=head1 DEPENDENCIES

None. But the render() method will only work if you have the Perl OpenGL module installed.



=head1 INCOMPATIBILITIES

None reported.



=head1 BUGS AND LIMITATIONS

There are a few other raw PLG formats available out-there. I'll try to adjust OpenGL::PLG to be able to parse and output to those in the near future.

Please report any bugs or feature requests to C<bug-opengl-plg at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OpenGL-PLG>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OpenGL::PLG


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=OpenGL-PLG>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/OpenGL-PLG>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OpenGL-PLG>

=item * Search CPAN

L<http://search.cpan.org/dist/OpenGL-PLG>

=back



=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>



=head1 ACKNOWLEDGEMENTS

A big thank you for grafman's OpenGL Perl module (and original author Stan Melax), which is a lot of fun to play with. Kudos also to everyone who helped the Perl OpenGL project along the way (and the OpenGL community itself).



=head1 COPYRIGHT & LICENSE

Copyright 2008 Breno G. de Oliveira, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.



