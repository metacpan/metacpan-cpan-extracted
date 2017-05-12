package    # not an official package
  OpenGL::Modern::Helpers;

use strict;
use Exporter 'import';
use Carp qw(croak);
use Config;

use OpenGL::Modern qw(
  GL_NO_ERROR
  GL_INVALID_ENUM
  GL_INVALID_VALUE
  GL_INVALID_OPERATION
  GL_STACK_OVERFLOW
  GL_STACK_UNDERFLOW
  GL_OUT_OF_MEMORY
  GL_TABLE_TOO_LARGE
  GL_VERSION
  glGetString
  glGetError
  glGetShaderInfoLog_c
  glGetProgramInfoLog_c
  glGenTextures_c
  glGetProgramiv_c
  glGetShaderiv_c
  glShaderSource_c
  glGenFramebuffers_c
  glGenVertexArrays_c
  glGenBuffers_c
  glGetIntegerv_c
  glBufferData_c
  glUniform2f
  glUniform4f
);

=head1 NAME

OpenGL::Modern::Helpers - example usage of raw pointers from perl

=head1 WARNING

This API is an experiment and will change!

=head1 OpenGL::Modern API Implementation

This module exists to support the use of the OpenGL::Modern
package for OpenGL bindings by documenting details of the
implementation and giving example routines showing the
use from perl.

=head2 Implementation

OpenGL::Modern is an XS module providings bindings to the
C OpenGL library for graphics.  As such, it needs to handle
conversion of input arguements from perl into the required
datatypes for the C OpenGL API, it then calls the OpenGL\
routine, and then converts the return value (if any) from
the C API datatype into an appropriate Perl type.

=head3 Scalar Values

Routines that take scalar values and return scalar
values at the C level, are nicely mapped by the built in
typemap conversions.  For example:

  GLenum
  glCheckNamedFramebufferStatus(GLuint framebuffer, GLenum target);

where the functions takes two values, one an integer and
one an enumeration which is basically an integer value
as well.  The return value is another enumeration/integer
value.  Since perl scalars can hold integers, the default
XS implementation from perl would be prototyped in perl
as

  $status = glCheckNamedFramebufferStatus($framebuffer, $target);

or, taking advantage of the binding of all the OpenGL
enumerations to perl constant functions we could write

  $status = glCheckNamedFramebufferStatus($framebuffer, GL_DRAW_FRAMEBUFFER);

The key here is explicit scalar values and types which makes
the XS perl implementation essentially the same at the C one
just with perl scalars in place of C typed values.
Of the 2743 OpenGL API routines, 1092 have scalar input
and return values and can be considered implemented as
is.

=head3 Pointer Values

The remaining OpenGL routines all have one (or more)
pointer argument or return value which are not so
simply mapped into perl because the use of pointers
from C does not fully determine the use of those
values:

=over 4

=item *
Pointers can be used to return values from routines

=item *
Pointers can be used to pass single input values

=item *
Pointers can be used to pass multiple input values

=item *
Pointers can be used to return multiple input values

=back

The current XS implementation now represents non-char
type pointers as the typemap T_PTR and the string and
character pointers are T_PV.  The routines will be
renamed with an added _c so as to indicate that the
mapping is the direct C one.

These _c routines closely match the OpenGL C API but
it requires that the perl user hand manage the allocation,
initialization, packing and unpacking, etc for each
function call.

Please see this source file for the implementations of

  glGetShaderInfoLog_p
  glGetProgramInfoLog_p
  glGetVersion_p

  croak_on_gl_error

showing the use of some utility routines to interface
to the OpenGL API routines.  OpenGL::Modern::Helpers
will be kept up to date with each release to document
the API implementations and usage as the bindings
evolve and improve.  Once standardized and stable,
a final version of Helpers.pm will be released.

=cut

use vars qw(@EXPORT_OK $VERSION %glErrorStrings);
$VERSION = '0.01_02';

@EXPORT_OK = qw(
  pack_GLuint
  pack_GLfloat
  pack_GLdouble
  pack_GLint
  pack_GLstrings
  pack_ptr
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

%glErrorStrings = (
    GL_NO_ERROR()          => 'No error has been recorded.',
    GL_INVALID_ENUM()      => 'An unacceptable value is specified for an enumerated argument.',
    GL_INVALID_VALUE()     => 'A numeric argument is out of range.',
    GL_INVALID_OPERATION() => 'The specified operation is not allowed in the current state.',
    GL_STACK_OVERFLOW()    => 'This command would cause a stack overflow.',
    GL_STACK_UNDERFLOW()   => 'This command would cause a stack underflow.',
    GL_OUT_OF_MEMORY()     => 'There is not enough memory left to execute the command.',
    GL_TABLE_TOO_LARGE()   => 'The specified table exceeds the implementation\'s maximum supported table size.',
);

our $PACK_TYPE = $Config{ptrsize} == 4 ? 'L' : 'Q';

sub pack_GLuint {
    my @gluints = @_;
    pack 'I*', @gluints;
}

sub pack_GLint {
    my @gluints = @_;
    pack 'I*', @gluints;
}

sub pack_GLfloat {
    my @glfloats = @_;
    pack 'f*', @glfloats;
}

sub pack_GLdouble {
    my @gldoubles = @_;
    pack 'd*', @gldoubles;
}

# No parameter declaration because we don't want copies
sub pack_GLstrings {
    pack 'P*', @_;
}

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

# No parameter declaration because we don't want copies
# This makes a packed string buffer of desired length.
# As above, be careful of the variable scopes.
#
sub xs_buffer {
    $_[0] = "\0" x $_[1];
    $_[0];
}

sub get_info_log_p {
    my ( $call, $id ) = @_;
    my $bufsize = 1024 * 64;
    my $buffer  = "\0" x $bufsize;
    my $len     = "\0" x 4;

    # void glGetShaderInfoLog(GLuint shader, GLsizei bufSize, GLsizei* length, GLchar* infoLog);
    # void glGetProgramInfoLog(GLuint program, GLsizei bufSize, GLsizei* length, GLchar* infoLog);
    $call->( $id, $bufsize, unpack( $PACK_TYPE, pack( 'p', $len ) ), $buffer );
    $len = unpack 'I', $len;
    return substr $buffer, 0, $len;
}

sub glGetShaderInfoLog_p  { get_info_log_p \&glGetShaderInfoLog,  @_ }
sub glGetProgramInfoLog_p { get_info_log_p \&glGetProgramInfoLog, @_ }

sub glGetVersion_p {

    # const GLubyte * GLAPIENTRY glGetString (GLenum name);
    my $glVersion = glGetString( GL_VERSION );
    ( $glVersion ) = ( $glVersion =~ m!^(\d+\.\d+)!g );
    $glVersion;
}

sub croak_on_gl_error {

    # GLenum glGetError (void);
    my $error = glGetError();
    if ( $error != GL_NO_ERROR ) {
        croak $glErrorStrings{$error} || "Unknown OpenGL error: $error";
    }
}

sub gen_thing_p {
    my ( $call, $n ) = @_;
    xs_buffer my $new_ids, 4 * $n;
    $call->( $n, unpack( $PACK_TYPE, pack( 'p', $new_ids ) ) );
    my @ids = unpack 'I*', $new_ids;
    return wantarray ? @ids : $ids[0];
}

sub glGenTextures_p { gen_thing_p \&glGenTextures_c, @_ }

sub glGenFramebuffers_p { gen_thing_p \&glGenFramebuffers_c, @_ }

sub glGenVertexArrays_p { gen_thing_p \&glGenVertexArrays_c, @_ }

sub glGenBuffers_p { gen_thing_p \&glGenBuffers_c, @_ }

sub get_iv_p {
    my ( $call, $id, $pname, $count ) = @_;
    $count ||= 1;
    xs_buffer my $params, 4 * $count;
    $call->( $id, $pname, unpack( "$PACK_TYPE*", pack( 'p*', $params ) ) );
    my @params = unpack 'I*', $params;
    return wantarray ? @params : $params[0];
}

sub glGetProgramiv_p { get_iv_p \&glGetProgramiv_c, @_ }

sub glGetShaderiv_p { get_iv_p \&glGetShaderiv_c, @_ }

sub glShaderSource_p {
    my ( $shader, @sources ) = @_;
    my $count = @sources;
    my @lengths = map length, @sources;
    glShaderSource_c( $shader, $count, pack( 'P*', @sources ), pack( 'I*', @lengths ) );
    return;
}

sub glGetIntegerv_p {
    my ( $pname, $count ) = @_;
    $count ||= 1;
    xs_buffer my $data, 4 * $count;
    glGetIntegerv_c $pname, unpack( $PACK_TYPE, pack( 'p', $data ) );
    my @data = unpack 'I*', $data;
    return wantarray ? @data : $data[0];
}

sub glBufferData_p {
    my ( $target, $oga, $usage ) = @_;
    glBufferData_c $target, $oga->length, $oga->ptr, $usage;
}

sub glUniform2f_p {
    my ( $uniform, $v0, $v1 ) = @_;
    glUniform2f $uniform, $v0, $v1;
}

sub glUniform4f_p {
    my ( $uniform, $v0, $v1, $v2, $v3 ) = @_;
    glUniform4f $uniform, $v0, $v1, $v2, $v3;
}

1;
