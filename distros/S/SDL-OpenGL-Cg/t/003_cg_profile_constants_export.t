use Test::More tests => 49;
use strict;
use warnings;

BEGIN { use_ok ('SDL::OpenGL::Cg', qw/:CONSTANTS cgGetProfileString/) };

# Test the values against those in the Cg/cgGL_profiles.h file.
# These should not change since doing so would break the interface
is (CG_PROFILE_FP20(), 6147);
is (CG_PROFILE_FP30(), 6149);
is (CG_PROFILE_ARBFP1(), 7000);
is (CG_PROFILE_VP20(), 6146);
is (CG_PROFILE_VP30(), 6148);
is (CG_PROFILE_ARBVP1(), 6150);

# Check we get the right names back for these profiles too.
is (cgGetProfileString(CG_PROFILE_FP20()), 'fp20');
is (cgGetProfileString(CG_PROFILE_FP30()), 'fp30');
is (cgGetProfileString(CG_PROFILE_ARBFP1()), 'arbfp1');
is (cgGetProfileString(CG_PROFILE_VP20()), 'vp20');
is (cgGetProfileString(CG_PROFILE_VP30()), 'vp30');
is (cgGetProfileString(CG_PROFILE_ARBVP1()), 'arbvp1');

# Now check error constants.
is (CG_ARRAY_PARAM_ERROR(), 22);
is (CG_COMPILER_ERROR(), 1);
is (CG_COMPILE_ERROR(), 1);
is (CG_FILE_READ_ERROR(), 12);
is (CG_FILE_WRITE_ERROR(), 13);
is (CG_INVALID_CONTEXT_HANDLE_ERROR(), 16);
is (CG_INVALID_DIMENSION_ERROR(), 21);
is (CG_INVALID_ENUMERANT_ERROR(), 10);
is (CG_INVALID_PARAMETER_ERROR(), 2);
is (CG_INVALID_PARAM_HANDLE_ERROR(), 18);
is (CG_INVALID_PROFILE_ERROR(), 3);
is (CG_INVALID_PROGRAM_HANDLE_ERROR(), 17);
is (CG_INVALID_VALUE_TYPE_ERROR(), 8);
is (CG_MEMORY_ALLOC_ERROR(), 15);
is (CG_NO_ERROR(), 0);
is (CG_NVPARSE_ERROR(), 14);
is (CG_OUT_OF_ARRAY_BOUNDS_ERROR(), 23);
is (CG_PROGRAM_BIND_ERROR(), 5);
is (CG_PROGRAM_LOAD_ERROR(), 4);
is (CG_PROGRAM_NOT_LOADED_ERROR(), 6);
is (CG_UNKNOWN_PROFILE_ERROR(), 19);
is (CG_UNSUPPORTED_GL_EXTENSION_ERROR(), 7);
is (CG_VAR_ARG_ERROR(), 20);

# Now check matrix constants.
is (CG_MATRIX_IDENTITY(), 0);
is (CG_MATRIX_TRANSPOSE(), 1);
is (CG_MATRIX_INVERSE(), 2);
is (CG_MATRIX_INVERSE_TRANSPOSE(), 3);
ok (CG_MODELVIEW_MATRIX);
ok (CG_PROJECTION_MATRIX);
ok (CG_TEXTURE_MATRIX);
ok (CG_MODELVIEW_PROJECTION_MATRIX);
ok (CG_VERTEX);
ok (CG_FRAGMENT);


ok (CG_SOURCE());
ok (CG_OBJECT());
ok (CG_SOURCE()!=CG_OBJECT());
