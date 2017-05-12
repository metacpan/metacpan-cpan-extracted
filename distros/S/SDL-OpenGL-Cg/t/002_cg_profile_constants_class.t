use Test::More tests => 49;
use strict;
use warnings;

BEGIN { use_ok ('SDL::OpenGL::Cg') };

# Test the values against those in the Cg/cgGL_profiles.h file.
# These should not change since doing so would break the interface
is (SDL::OpenGL::Cg::CG_PROFILE_FP20(), 6147);
is (SDL::OpenGL::Cg::CG_PROFILE_FP30(), 6149);
is (SDL::OpenGL::Cg::CG_PROFILE_ARBFP1(), 7000);
is (SDL::OpenGL::Cg::CG_PROFILE_VP20(), 6146);
is (SDL::OpenGL::Cg::CG_PROFILE_VP30(), 6148);
is (SDL::OpenGL::Cg::CG_PROFILE_ARBVP1(), 6150);

# Check we get the right names back for these profiles too.
is (SDL::OpenGL::Cg::cgGetProfileString(SDL::OpenGL::Cg::CG_PROFILE_FP20()),
  'fp20');
is (SDL::OpenGL::Cg::cgGetProfileString(SDL::OpenGL::Cg::CG_PROFILE_FP30()),
  'fp30');
is (SDL::OpenGL::Cg::cgGetProfileString(SDL::OpenGL::Cg::CG_PROFILE_ARBFP1()),
  'arbfp1');
is (SDL::OpenGL::Cg::cgGetProfileString(SDL::OpenGL::Cg::CG_PROFILE_VP20()),
  'vp20');
is (SDL::OpenGL::Cg::cgGetProfileString(SDL::OpenGL::Cg::CG_PROFILE_VP30()),
  'vp30');
is (SDL::OpenGL::Cg::cgGetProfileString(SDL::OpenGL::Cg::CG_PROFILE_ARBVP1()),
  'arbvp1');

# Now check error constants.
is (SDL::OpenGL::Cg::CG_ARRAY_PARAM_ERROR(), 22);
is (SDL::OpenGL::Cg::CG_COMPILER_ERROR(), 1);
is (SDL::OpenGL::Cg::CG_COMPILE_ERROR(), 1);
is (SDL::OpenGL::Cg::CG_FILE_READ_ERROR(), 12);
is (SDL::OpenGL::Cg::CG_FILE_WRITE_ERROR(), 13);
is (SDL::OpenGL::Cg::CG_INVALID_CONTEXT_HANDLE_ERROR(), 16);
is (SDL::OpenGL::Cg::CG_INVALID_DIMENSION_ERROR(), 21);
is (SDL::OpenGL::Cg::CG_INVALID_ENUMERANT_ERROR(), 10);
is (SDL::OpenGL::Cg::CG_INVALID_PARAMETER_ERROR(), 2);
is (SDL::OpenGL::Cg::CG_INVALID_PARAM_HANDLE_ERROR(), 18);
is (SDL::OpenGL::Cg::CG_INVALID_PROFILE_ERROR(), 3);
is (SDL::OpenGL::Cg::CG_INVALID_PROGRAM_HANDLE_ERROR(), 17);
is (SDL::OpenGL::Cg::CG_INVALID_VALUE_TYPE_ERROR(), 8);
is (SDL::OpenGL::Cg::CG_MEMORY_ALLOC_ERROR(), 15);
is (SDL::OpenGL::Cg::CG_NO_ERROR(), 0);
is (SDL::OpenGL::Cg::CG_NVPARSE_ERROR(), 14);
is (SDL::OpenGL::Cg::CG_OUT_OF_ARRAY_BOUNDS_ERROR(), 23);
is (SDL::OpenGL::Cg::CG_PROGRAM_BIND_ERROR(), 5);
is (SDL::OpenGL::Cg::CG_PROGRAM_LOAD_ERROR(), 4);
is (SDL::OpenGL::Cg::CG_PROGRAM_NOT_LOADED_ERROR(), 6);
is (SDL::OpenGL::Cg::CG_UNKNOWN_PROFILE_ERROR(), 19);
is (SDL::OpenGL::Cg::CG_UNSUPPORTED_GL_EXTENSION_ERROR(), 7);
is (SDL::OpenGL::Cg::CG_VAR_ARG_ERROR(), 20);

# Now check matrix constants.
is (SDL::OpenGL::Cg::CG_MATRIX_IDENTITY(), 0);
is (SDL::OpenGL::Cg::CG_MATRIX_TRANSPOSE(), 1);
is (SDL::OpenGL::Cg::CG_MATRIX_INVERSE(), 2);
is (SDL::OpenGL::Cg::CG_MATRIX_INVERSE_TRANSPOSE(), 3);
ok (SDL::OpenGL::Cg::CG_MODELVIEW_MATRIX);
ok (SDL::OpenGL::Cg::CG_PROJECTION_MATRIX);
ok (SDL::OpenGL::Cg::CG_TEXTURE_MATRIX);
ok (SDL::OpenGL::Cg::CG_MODELVIEW_PROJECTION_MATRIX);
ok (SDL::OpenGL::Cg::CG_VERTEX);
ok (SDL::OpenGL::Cg::CG_FRAGMENT);

# Check we have values for the other constants too.
ok (SDL::OpenGL::Cg::CG_SOURCE());
ok (SDL::OpenGL::Cg::CG_OBJECT());
ok (SDL::OpenGL::Cg::CG_SOURCE() != SDL::OpenGL::Cg::CG_OBJECT());

