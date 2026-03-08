package    # not an official package
  OpenGL::Modern::Helpers;

our $VERSION = '0.0401';

use strict;
use Exporter 'import';
use Carp qw(croak);
use Config;

use OpenGL::Modern qw(
  GL_VERSION
  glGenTextures_p
  glGenFramebuffers_p
  glGenVertexArrays_p
  glGenBuffers_p
  glGetString
  glpCheckErrors
  glGetShaderInfoLog_p
  glGetProgramInfoLog_p
  glGetProgramiv_p
  glGetShaderiv_p
  glGetIntegerv_p
  glShaderSource_p
  glBufferData_c
  glUniform2f
  glUniform4f
);

=head1 NAME

OpenGL::Modern::Helpers - example usage of raw pointers from perl

=head1 OpenGL::Modern API Implementation

This module existed to support the use of the OpenGL::Modern
package for OpenGL bindings by documenting details of the
implementation and giving example routines showing the
use from perl.

OpenGL::Modern is an XS module providings bindings to the
C OpenGL library for graphics. As of 0.0403, it now has C<_p>
bindings for all functions with pointers that have metadata in the
OpenGL XML registry (see
L<https://raw.githubusercontent.com/KhronosGroup/OpenGL-Registry/refs/heads/main/xml/gl.xml>).
All of the "helper" versions of routines that implemented C<_p>
versions on top of C<_c> versions now just import and re-export the
native C<_p> versions.

See the automatically-generated documentation in L<OpenGL::Modern>
for interfaces for all OpenGL functions that are bound, which is
pretty much all of them, since the list comes from GLEW. Some only
have C<_c> bindings as noted above, due to incomplete metadata in
the registry. Since that is largely only true for routines that
were removed in 3.2+ "core" profiles, that is unlikely to change.

=cut

our @EXPORT_OK = qw(
  pack_GLuint
  pack_GLfloat
  pack_GLdouble
  pack_GLint
  pack_GLstrings
  pack_ptr
  iv_ptr
  xs_buffer

  glGetShaderInfoLog_p
  glGetProgramInfoLog_p
  croak_on_gl_error

  glGetVersion_p
  glGenTextures_p
  glGetProgramiv_p
  glGetShaderiv_p
  glShaderSource_p
  glGenFramebuffers_p
  glGenVertexArrays_p
  glGenBuffers_p
  glGetIntegerv_p
  glBufferData_p
  glUniform2f_p
  glUniform4f_p
);

our $PACK_TYPE = $Config{ptrsize} == 4 ? 'L' : 'Q';

sub pack_GLuint { pack 'I*', @_ }
sub pack_GLint { pack 'i*', @_ }
sub pack_GLfloat { pack 'f*', @_ }
sub pack_GLdouble { pack 'd*', @_ }
sub pack_GLstrings { pack 'P*', @_ } # No declare params as don't want copies

# No parameter declaration because we don't want copies
# This returns a packed string representation of the
# pointer to the perl string data.  Not useful as is
# because the scope of the inputs is not maintained so
# the PV data may disappear before the pointer is actually
# accessed by OpenGL routines.
#
sub pack_ptr {
    $_[0] = "\0" x $_[1];
    return pack 'P', $_[0];
}

sub iv_ptr {
    $_[0] = "\0" x $_[1] if $_[1];
    return unpack( $PACK_TYPE, pack( 'P', $_[0] ) );
}

# No parameter declaration because we don't want copies
# This makes a packed string buffer of desired length.
# As above, be careful of the variable scopes.
#
sub xs_buffer {
    $_[0] = "\0" x $_[1];
    $_[0];
}

# This should probably be named glpGetVersion since there is actually
# no glGetVersion() in the OpenGL API.
#
sub glGetVersion_p {

    # const GLubyte * GLAPIENTRY glGetString (GLenum name);
    my $glVersion = glGetString( GL_VERSION );
    ( $glVersion ) = ( $glVersion =~ m!^(\d+\.\d+)!g );
    $glVersion;
}

*croak_on_gl_error = \&glpCheckErrors;

sub glBufferData_p {                                        # NOTE: this might be better named glpBufferDataf_p
    my $usage = pop;
    my ( $target, $size, @data ) = @_;
    my $pdata = pack "f*", @data;

    glBufferData_c $target, $size, unpack( $PACK_TYPE, pack( 'p', $pdata ) ), $usage;
}

sub glBufferData_o {                                        # NOTE: this was glBufferData_p in OpenGL
    my ( $target, $oga, $usage ) = @_;
    glBufferData_c $target, $oga->length, $oga->ptr, $usage;
}

sub glUniform2fv_p {                                        # NOTE: this name is more consistent with OpenGL API
    my ( $uniform, $v0, $v1 ) = @_;
    glUniform2f $uniform, $v0, $v1;
}

sub glUniform4fv_p {                                        # NOTE: this name is more consistent with OpenGL API
    my ( $uniform, $v0, $v1, $v2, $v3 ) = @_;
    glUniform4f $uniform, $v0, $v1, $v2, $v3;
}

1;
