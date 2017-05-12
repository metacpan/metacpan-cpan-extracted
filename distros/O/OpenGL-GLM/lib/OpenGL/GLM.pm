package OpenGL::GLM;

use 5.008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use OpenGL::GLM ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	GLM_2_SIDED
	GLM_COLOR
	GLM_FLAT
	GLM_MATERIAL
	GLM_MAX_SHININESS
	GLM_MAX_TEXTURE_SIZE
	GLM_NONE
	GLM_SMOOTH
	GLM_TEXTURE
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	GLM_2_SIDED
	GLM_COLOR
	GLM_FLAT
	GLM_MATERIAL
	GLM_MAX_SHININESS
	GLM_MAX_TEXTURE_SIZE
	GLM_NONE
	GLM_SMOOTH
	GLM_TEXTURE
);

our $VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&OpenGL::GLM::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('OpenGL::GLM', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

OpenGL::GLM - Interface to the GLM library for loading Alias Wavefront OBJ files

=head1 SYNOPSIS

  use OpenGL::GLM;
  $model = new OpenGL::GLM($filename);
  $model->Unitize;
  $model->Draw(GLM_SMOOTH);

=head1 DESCRIPTION

This module is a perl interface to the GLM library, by Nate Robbins and
Jeff Rogers, for loading Alias Wavefront 3d object files and displaying
them through OpenGL. 

Note that no OpenGL::GLM objects should be created until an OpenGL context has
first been established, by, eg, opening a GLUT or SDL OpenGL window.

=head1 METHODS

=over 1

=item B<new>

 my $object = new OpenGL::GLM('camel.obj');

Reads a model description from a Wavefront .OBJ file, and returns an
OpenGL::GLM object. Takes one argument, the name of the file.

=item B<Unitize>

  my $scale = $object->Unitize;

"Unitizes" a model by translating it to the origin and scaling it to fit
in a unit cube around the origin.  Returns the scalefactor used.

=item B<Scale>

  $model->Scale($scalefactor);

Scales a model by a given amount.

=item B<ReverseWinding>

  $model->ReverseWinding;

Reverse the polygon winding for all polygons in this model.  Default
winding is counter-clockwise.  Also changes the direction of the
normals.

=item B<FacetNormals>

 $model->FacetNormals;

Generates facet normals for a model (by taking the cross product of the
two vectors derived from the sides of each triangle).  Assumes a
counter-clockwise winding.

=item B<VertexNormals>

 $model->VertexNormals($angle,$keep_existing);

Generates smooth vertex normals for a model.
First builds a list of all the triangles each vertex is in.  Then
loops through each vertex in the the list averaging all the facet
normals of the triangles each vertex is in.  Finally, sets the
normal index in the triangle for the vertex to the generated smooth
normal.  If the dot product of a facet normal and the facet normal
associated with the first triangle in the list of triangles the
current vertex is in is greater than the cosine of the angle
parameter to the function, that facet normal is not added into the
average normal calculation and the corresponding vertex is given
the facet normal.  This tends to preserve hard edges.  The angle to
use depends on the model, but 90 degrees is usually a good start.
 
=over 2

=item B<$angle> - maximum angle (in degrees) to smooth across

=item B<$keep_existing> - if GL_TRUE, do not overwrite existing normals

=back

=item B<LinearTexture>

 $model->LinearTexture;

Generates texture coordinates according to a linear projection of the
texture map.  It generates these by linearly mapping the vertices onto a
square.

=item B<SpheremapTexture>

 $model->SpheremapTexture;

Generates texture coordinates according to a
spherical projection of the texture map.  Sometimes referred to as
spheremap, or reflection map texture coordinates.  It generates
these by using the normal to calculate where that vertex would map
onto a sphere.  Since it is impossible to map something flat
perfectly onto something spherical, there is distortion at the
poles.  This particular implementation causes the poles along the X
axis to be distorted.

=item B<WriteOBJ>

 $model->WriteOBJ($filename,$mode);

Writes a model description in Wavefront .OBJ format to a file. B<$mode>
is a bitwise OR of values describing what is written to the file:

=over 2

=item B<GLM_NONE>    -  write only vertices

=item B<GLM_FLAT>    -  write facet normals

=item B<GLM_SMOOTH>  -  write vertex normals

=item B<GLM_TEXTURE> -  write texture coords

=back

B<GLM_FLAT> and B<GLM_SMOOTH> should not both be specified.

=item B<Draw>

 $model->Draw($mode);

Renders the model to the current OpenGL context using the mode
specified. B<$mode> is a bitwise OR of values describing what is to be
rendered:

=over 2

=item B<GLM_NONE>    -  render with only vertices

=item B<GLM_FLAT>    -  render with facet normals

=item B<GLM_SMOOTH>  -  render with vertex normals

=item B<GLM_TEXTURE> -  render with texture coords

=back

B<GLM_FLAT> and B<GLM_SMOOTH> should not both be specified.

=item B<List>

 $model->List($mode);

Generates and returns a display list for the model using the mode
specified. B<$mode> is a bitwise OR of values describing what is to be
rendered:

=over 2

=item B<GLM_NONE>    -  render with only vertices

=item B<GLM_FLAT>    -  render with facet normals

=item B<GLM_SMOOTH>  -  render with vertex normals

=item B<GLM_TEXTURE> -  render with texture coords

=back

B<GLM_FLAT> and B<GLM_SMOOTH> should not both be specified.


=item B<Weld>

 $model->Weld($epsilon);

Eliminate (weld) vectors that are within an epsilon of each other.
B<$epsilon> is the maximum difference between vertices ; 0.00001 is a
good start for a unitized model.

=back

=head2 Exportable constants

  GLM_2_SIDED
  GLM_COLOR
  GLM_FLAT
  GLM_MATERIAL
  GLM_MAX_SHININESS
  GLM_MAX_TEXTURE_SIZE
  GLM_NONE
  GLM_SMOOTH
  GLM_TEXTURE

=head1 SEE ALSO

=over 1

=item L<http://devernay.free.fr/hacks/glm/>

=item L<http://www.dcs.ed.ac.uk/home/mxr/gfx/3d/OBJ.spec>

=item L<OpenGL::Simple>

=item L<OpenGL::Simple::GLUT>

=item L<OpenGL::Simple::Viewer>

=back

=head1 AUTHOR

Jonathan Chin, E<lt>jon-opengl-glm@earth.liE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Jonathan Chin. Released and distributed under the
GPL.



=cut
