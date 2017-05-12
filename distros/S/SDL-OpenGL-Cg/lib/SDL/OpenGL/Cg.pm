
package SDL::OpenGL::Cg;
use strict;
use strict;
use warnings;
use Carp;

BEGIN {
  use Exporter ();
  use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
  $VERSION     = 0.01;
  my @constants;
  {
    no strict 'refs';

    # Force loading of all of our constants.
    @constants = qw/
      CG_PROFILE_FP20
      CG_PROFILE_FP30
      CG_PROFILE_ARBFP1
      CG_PROFILE_VP20
      CG_PROFILE_VP30
      CG_PROFILE_ARBVP1
      
      CG_SOURCE
      CG_OBJECT

      CG_ARRAY_PARAM_ERROR
      CG_COMPILER_ERROR
      CG_COMPILE_ERROR
      CG_FILE_READ_ERROR
      CG_FILE_WRITE_ERROR
      CG_INVALID_CONTEXT_HANDLE_ERROR
      CG_INVALID_DIMENSION_ERROR
      CG_INVALID_ENUMERANT_ERROR
      CG_INVALID_PARAMETER_ERROR
      CG_INVALID_PARAM_HANDLE_ERROR
      CG_INVALID_PROFILE_ERROR
      CG_INVALID_PROGRAM_HANDLE_ERROR
      CG_INVALID_VALUE_TYPE_ERROR
      CG_MEMORY_ALLOC_ERROR
      CG_NOT_MATRIX_PARAM_ERROR
      CG_NO_ERROR
      CG_NVPARSE_ERROR
      CG_OUT_OF_ARRAY_BOUNDS_ERROR
      CG_PROGRAM_BIND_ERROR
      CG_PROGRAM_LOAD_ERROR
      CG_PROGRAM_NOT_LOADED_ERROR
      CG_UNKNOWN_PROFILE_ERROR
      CG_UNSUPPORTED_GL_EXTENSION_ERROR
      CG_VAR_ARG_ERROR

      CG_MATRIX_IDENTITY
      CG_MATRIX_TRANSPOSE
      CG_MATRIX_INVERSE
      CG_MATRIX_INVERSE_TRANSPOSE

      CG_MODELVIEW_MATRIX
      CG_PROJECTION_MATRIX
      CG_TEXTURE_MATRIX
      CG_MODELVIEW_PROJECTION_MATRIX

      CG_VERTEX
      CG_FRAGMENT
    /;
    for my $constant (@constants) {
      *{"SDL::OpenGL::Cg::$constant"} = sub {_load_constant($constant)}; 
    }
  }

  @ISA         = qw (Exporter);
  #Give a hoot don't pollute, do not export more than needed by default
  @EXPORT      = qw ();
  @EXPORT_OK   = qw (
    cgBindProgram
    cgCreateContext
    cgCreateProgram
    cgCreateProgramFromFile
    cgDestroyContext
    cgDisableProfile
    cgEnableProfile
    cgGetError
    cgGetErrorString
    cgGetLastListing
    cgGetNamedParameter
    cgGetLatestProfile
    cgGetProfileString
    cgIsProfileSupported
    cgLastError
    cgLoadProgram
    cgSetMatrixParameterc
    cgSetMatrixParameterr
    cgSetStateMatrixParameter
    cgSetParameter
  );
  push @EXPORT_OK, @constants;
  %EXPORT_TAGS = (
    all => [@EXPORT_OK],
    CONSTANTS => [@constants],
    PROFILES => [qw (
      cgEnableProfile cgDisableProfile
      cgGetProfileString cgIsProfileSupported
      CG_PROFILE_FP20 CG_PROFILE_FP30 CG_PROFILE_ARBFP1
      CG_PROFILE_VP20 CG_PROFILE_VP30 CG_PROFILE_ARBVP1
    )],
    PROGRAMS => [qw (
      CG_SOURCE CG_OBJECT
    )],
  ); 
}

# A simple 'new' function to allow people to call us in an OO manner.
sub new {
  my ($class) = @_;
  return  bless {}, ref($class)||$class;
}

# A way to autoinit constants.
sub _load_constant {
  my ($constant) = @_;
#  warn ("Loading $constant\n");
  no strict 'refs';
  my $c_constant = $constant;
  $c_constant =~ s/^CG//;
  *{"SDL::OpenGL::$constant"} = \&{$c_constant};
  goto &{"SDL::OpenGL::$constant"};
}

# A destroy thing.  May well have autotidying facilities in some point.
sub DESTROY {}

require XSLoader;
XSLoader::load('SDL::OpenGL::Cg', $VERSION);

