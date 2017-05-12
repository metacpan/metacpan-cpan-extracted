#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <stdio.h>
#include <Cg/cg.h>
#include <Cg/cgGL.h>

#define ERROR_STORE "SDL::OpenGL::Cg::_error_message"

MODULE = SDL::OpenGL::Cg        PACKAGE = SDL::OpenGL::Cg

void
cgBindProgram (...)
  PREINIT:
    CGprogram program;
    CGerror err;
  PPCODE:
    if (items != 1) {
      warn ("Usage: cgBindProgram($program)");
      return;
    }
    program = INT2PTR(CGprogram, SvIV(ST(0)));
    cgGLBindProgram(program);
    EXTEND (SP,1);
    if (err = cgGetError()) {
      sv_setiv(get_sv(ERROR_STORE,1),PTR2IV(err));
      PUSHs (&PL_sv_undef);
    } else {
      PUSHs (sv_2mortal(newSViv(PTR2IV(program))));
    }

void
cgCopyProgram (...)
  PREINIT:
    CGprogram program;
    CGprogram new_program;
    CGerror err;
  PPCODE:
    EXTEND (SP,1);
    if (items != 1) {
      warn ("Usage: $new_program = cgCopyProgram($program)");
      PUSHs (&PL_sv_undef);
      return;
    }
    program = INT2PTR(CGprogram, SvIV(ST(0)));
    new_program = cgCopyProgram(program);
    if (err = cgGetError()) {
      sv_setiv(get_sv(ERROR_STORE,1),PTR2IV(err));
      PUSHs (&PL_sv_undef);
    } else {
      PUSHs (sv_2mortal(newSViv(PTR2IV(new_program))));
    }

void
cgCreateContext (...)
  PREINIT:
    CGcontext context;
    CGerror err;
  PPCODE:
    EXTEND (SP,1);
    if (items != 0) {
      warn ("Usage: cgCreateContext()");
      PUSHs (&PL_sv_undef);
      return; 
    }
    context = cgCreateContext();
    if (err = cgGetError()) {
      sv_setiv(get_sv(ERROR_STORE,1),PTR2IV(err));
      PUSHs (&PL_sv_undef);
    } else {
      PUSHs (sv_2mortal(newSViv(PTR2IV(context))));
    }    

void
cgCreateProgram (...)
  PREINIT:
    CGcontext context;
    CGenum program_type;
    char *program_code;
    CGprofile profile;
    char *entry;
    char **args;
    CGprogram program;
    CGerror err;
  PPCODE:
    EXTEND (SP,1);
    if (items != 6) {
      warn ("Usage: $program = cgCreateProgramFromFile ($context,$type,$filename,$program_name, $profile, $entry)");
      PUSHs (&PL_sv_undef);
      return;
    }

    context = INT2PTR(CGcontext, SvIV(ST(0)));
    program_type = SvUV(ST(1));
    program_code = SvPV_nolen(ST(2));
    profile = SvIV(ST(3));
    entry = SvPV_nolen(ST(4));
    // TODO: Handle Args!

    program = cgCreateProgram(
      context,program_type,program_code,
      profile,entry,0
    );

    if (err = cgGetError()) {
      sv_setiv(get_sv(ERROR_STORE,1),PTR2IV(err));
      PUSHs (&PL_sv_undef);
    } else {
      PUSHs (sv_2mortal(newSViv(PTR2IV(program))));
    }
    
void
cgCreateProgramFromFile (...)
  PREINIT:
    CGcontext context;
    CGenum program_type;
    char *program_name;
    CGprofile profile;
    char *entry;
    char **args;
    CGprogram program;
    CGerror err;
  PPCODE:
    EXTEND (SP,1);
    if (items != 6) {
      warn ("Usage: $program = cgCreateProgramFromFile ($context,$type,$filename,$program_name, $profile, $entry)");
      PUSHs (&PL_sv_undef);
      return;
    }

    context = INT2PTR(CGcontext, SvIV(ST(0)));
    program_type = SvUV(ST(1));
    program_name = SvPV_nolen(ST(2));
    profile = SvIV(ST(3));
    entry = SvPV_nolen(ST(4));
    // TODO: Handle Args!

    program = cgCreateProgramFromFile(
      context,program_type,program_name,
      profile,entry,0
    );

    if (err = cgGetError()) {
      sv_setiv(get_sv(ERROR_STORE,1),PTR2IV(err));
      PUSHs (&PL_sv_undef);
    } else {
      PUSHs (sv_2mortal(newSViv(PTR2IV(program))));
    }
    
void
cgDestroyContext (...)
  PREINIT:
    CGerror err;
  PPCODE:
    EXTEND (SP,1);
    if (items != 1) {
      warn ("Usage: cgDestroyContext($context");
      PUSHs (&PL_sv_undef);
      return;
    }
    cgDestroyContext(INT2PTR(CGcontext, SvIV(ST(0))));
    if (err = cgGetError()) { 
      sv_setiv(get_sv(ERROR_STORE,1),PTR2IV(err));
      PUSHs (&PL_sv_undef);
    } else {
      PUSHs (&PL_sv_yes);
    }

void 
cgDisableProfile (...)
  PREINIT: 
    CGerror err;
  PPCODE:
    EXTEND (SP,1);
    if (items != 1) {
      warn ("Usage: cgDisableProfile($profile)");
      PUSHs (&PL_sv_undef);
      return;
    }
    cgGLDisableProfile (SvNV(ST(0)));
    if (err = cgGetError()) { 
      sv_setiv(get_sv(ERROR_STORE,1),PTR2IV(err));
      PUSHs (&PL_sv_undef);
    } else {
      PUSHs (&PL_sv_yes);
    }

bool
cgEnableProfile (...)
  PREINIT:
    CGerror err;
  PPCODE:
    EXTEND (SP,1);
    if (items != 1) {
      warn ("Usage: cgEnableProfile($profile)");
      PUSHs (&PL_sv_undef);
      return;
    }
    cgGLEnableProfile (SvNV(ST(0)));
    if (err = cgGetError()) { 
      sv_setiv(get_sv(ERROR_STORE,1),PTR2IV(err));
      PUSHs (&PL_sv_undef);
    } else {
      PUSHs (&PL_sv_yes);
    }

void
cgGetError(...)
  PREINIT:  
    SV* err;
  PPCODE:
    EXTEND (SP,1);
    err = get_sv(ERROR_STORE,1);
    if (SvTYPE(err) == SVt_NULL) {
      PUSHs (sv_2mortal(newSViv(0)));
    } else {
      PUSHs (sv_mortalcopy(err));
      sv_setiv(err, 0);
    }

void
cgGetErrorString(...)
  PREINIT:  
    SV* err;
  PPCODE:
    EXTEND (SP,1);
    err = get_sv(ERROR_STORE,1);
    if (err == 0) {
      PUSHs (sv_2mortal(newSVpv("",1)));
    } else {
      PUSHs (sv_2mortal(newSVpv(cgGetErrorString(SvIV(err)),0)));
      sv_setiv(err, 0);
    }

void 
cgGetLastListing(...)
  PREINIT:
    CGcontext context;
    char* listing;
  PPCODE:
    EXTEND (SP,1);
    if (items != 1) {
      warn ("Usage: cgGetLatestProfile($context)");
      PUSHs (&PL_sv_undef);
      return;
    }
    context = INT2PTR(CGcontext, SvIV(ST(0)));
    listing = (char *) cgGetLastListing(context);
    if (listing) {
      PUSHs (sv_2mortal(newSVpv(listing,0)));
    } else {
      PUSHs (&PL_sv_undef);
    }

void
cgGetLatestProfile(...)
  PREINIT:
    CGerror err;
    CGprofile profile;
  PPCODE:
    EXTEND (SP,1);
    if (items != 1) {
      warn ("Usage: cgGetLatestProfile($profile_type)");
      PUSHs (&PL_sv_undef);
      return;
    }
    profile = cgGLGetLatestProfile(SvIV(ST(0)));
    PUSHs (sv_2mortal(newSViv(PTR2IV(profile))));

void
cgGetNamedParameter (...)
  PREINIT:
    char *param_name;
    CGprogram program;
    CGparameter param;
    CGerror err;
  PPCODE:
    EXTEND (SP,1);
    if (items != 2) {
      warn ("Usage: $param= cgGetNamedParameter($program,$param_name)");
      PUSHs (&PL_sv_undef);
      return;
    }
    program = INT2PTR(CGprogram, SvIV(ST(0)));
    param_name = SvPV_nolen(ST(1));
    param = cgGetNamedParameter(program,param_name);
    if (err = cgGetError()) {
      sv_setiv(get_sv(ERROR_STORE,1),PTR2IV(err));
      PUSHs (&PL_sv_undef);
    } else {
      PUSHs (sv_2mortal(newSViv(PTR2IV(param))));
    }
    
void
cgGetProfileString (...)
  PREINIT:
    int profile;
  PPCODE:
    EXTEND (SP,1);
    if (items != 1) {
      warn ("Usage: $profile_string= cgGetProfileString($profile)");
      PUSHs (&PL_sv_undef);
      return;
    }
    profile = SvIV(ST(0));
    PUSHs (sv_2mortal(newSVpv(cgGetProfileString(profile),0)));

void
cgIsProfileSupported (...)
  PPCODE:
    EXTEND (SP,1);
    if (items != 1) {
      warn ("Usage: $support = cgIsProfileSupported($profile)");
      PUSHs (&PL_sv_undef);
      return;
    }
    if (cgGLIsProfileSupported(SvNV(ST(0)))) {
      PUSHs (&PL_sv_yes);
    } else {
      PUSHs (&PL_sv_undef);
    };

void 
cgLoadProgram (...)
  PREINIT:
    CGprogram program;
    CGerror err;
  PPCODE:
    EXTEND (SP,1);
    if (items != 1) {
      warn ("Usage: cgLoadProgram($program)");
      PUSHs (&PL_sv_undef);
      return;
    }
    program = INT2PTR(CGprogram, SvIV(ST(0)));
    cgGLLoadProgram(program);
    if (err = cgGetError()) { 
      sv_setiv(get_sv(ERROR_STORE,1),PTR2IV(err));
      PUSHs (&PL_sv_undef);
    } else {
      PUSHs (&PL_sv_yes);
    }

void
cgSetMatrixParameterc (...)
  PREINIT:
    double values[16];
    CGparameter param;
    CGerror err;
    int i;
  PPCODE:
    EXTEND (SP,1);
    if (items != 17) {
      warn ("For now cgSetMatrixParameter only supports 4x4 matrix");
      PUSHs (&PL_sv_undef);
      return;
    }
    for (i=1; i<items; i++) {
      values[i-1] = SvNV(ST(i));
    }
    param = INT2PTR(CGparameter, SvIV(ST(0)));
    cgGLSetMatrixParameterdc (param, values);
    if (err = cgGetError()) {
      sv_setiv(get_sv(ERROR_STORE,1),PTR2IV(err));
      PUSHs (&PL_sv_undef);
    } else {
      PUSHs (sv_2mortal(newSViv(PTR2IV(param))));
    }

void
cgSetMatrixParameterr (...)
  PREINIT:
    double values[16];
    CGparameter param;
    CGerror err;
    int i;
  PPCODE:
    EXTEND (SP,1);
    if (items != 17) {
      warn ("For now cgSetMatrixParameter only supports 4x4 matrix");
      PUSHs (&PL_sv_undef);
      return;
    }
    for (i=1; i<items; i++) {
      values[i-1] = SvNV(ST(i));
      printf ("Param %d = %f\n", i, values[i-1]); 
    }
    param = INT2PTR(CGparameter, SvIV(ST(0)));
    cgGLSetMatrixParameterdr (param, values);
    if (err = cgGetError()) {
      sv_setiv(get_sv(ERROR_STORE,1),PTR2IV(err));
      PUSHs (&PL_sv_undef);
    } else {
      PUSHs (sv_2mortal(newSViv(PTR2IV(param))));
    }

void
cgSetParameter (...)
  PREINIT:
    CGparameter param;
    CGerror err;
  PPCODE:
    // TODO: Modify so it's not only the 4 param version. 
    EXTEND (SP,1);
    if (items<2 || items>5) {
       warn("Usage: cgSetParameter($param, $val1) OR");
       warn("Usage: cgSetParameter($param, $val1, $val2) OR");
       warn("Usage: cgSetParameter($param, $val1, $val2, $val3) OR");
       warn("Usage: cgSetParameter($param, $val1, $val2, $val3, $val4)");
       PUSHs (&PL_sv_undef);
       return;
    }
    param = INT2PTR(CGparameter, SvIV(ST(0)));
    switch (items) {
      case 2:
	cgGLSetParameter1d(param, SvNV(ST(1)));
        break;
      case 3:
        cgGLSetParameter2d(param, SvNV(ST(1)),SvNV(ST(2)));
        break;
      case 4:
        cgGLSetParameter3d(param, SvNV(ST(1)),SvNV(ST(2)),SvNV(ST(3)));
        break;
      case 5:
        cgGLSetParameter4d(param, SvNV(ST(1)),SvNV(ST(2)),SvNV(ST(3)),SvNV(ST(4)));
        break;
    };
    if (err = cgGetError()) { 
      sv_setiv(get_sv(ERROR_STORE,1),PTR2IV(err));
      PUSHs (&PL_sv_undef);
    } else {
      PUSHs (&PL_sv_yes);
    }
   
void
cgSetStateMatrixParameter(...)
  PREINIT:
    CGparameter param;
    CGGLenum matrix;
    CGGLenum transform;
    CGerror err;
  PPCODE:
    EXTEND (SP,1);
    if (items < 2 || items > 3) {
      warn ("Usage: cgSetStateMatrixParameter($param,$matrix,$transform)");
      PUSHs (&PL_sv_undef);
      return;
    }
    param = INT2PTR(CGparameter, SvIV(ST(0)));
    matrix = SvIV(ST(1));
    if (items == 3) {
      transform = SvIV(ST(2));
    } else {
      transform = CG_GL_MATRIX_IDENTITY;
    }
    cgGLSetStateMatrixParameter(param,matrix,transform);
    if (err = cgGetError()) { 
      sv_setiv(get_sv(ERROR_STORE,1),PTR2IV(err));
      PUSHs (&PL_sv_undef);
    } else {
      PUSHs (&PL_sv_yes);
    }

int
_PROFILE_FP20(...)
  CODE:
    RETVAL = CG_PROFILE_FP20;
  OUTPUT:
    RETVAL

int
_PROFILE_FP30(...)
  CODE:
    RETVAL = CG_PROFILE_FP30;
  OUTPUT:
    RETVAL

int
_PROFILE_ARBFP1(...)
  CODE:
    RETVAL = CG_PROFILE_ARBFP1;
  OUTPUT:
    RETVAL

int
_PROFILE_VP20(...)
  CODE:
    RETVAL = CG_PROFILE_VP20;
  OUTPUT:
    RETVAL

int
_PROFILE_VP30(...)
  CODE:
    RETVAL = CG_PROFILE_VP30;
  OUTPUT:
    RETVAL

int
_PROFILE_ARBVP1(...)
  CODE:
    RETVAL = CG_PROFILE_ARBVP1;
  OUTPUT:
    RETVAL

int 
_SOURCE(...)
  CODE:
    RETVAL = CG_SOURCE;
  OUTPUT:
    RETVAL

int 
_OBJECT(...)
  CODE:
    RETVAL = CG_OBJECT;
  OUTPUT:
    RETVAL

int 
_ARRAY_PARAM_ERROR(...)
  CODE:
    RETVAL = CG_ARRAY_PARAM_ERROR;
  OUTPUT:
    RETVAL

int 
_COMPILER_ERROR(...)
  CODE:
    RETVAL = CG_COMPILER_ERROR;
  OUTPUT:
    RETVAL

int 
_COMPILE_ERROR(...)
  CODE:
    // It looks like a few of the documents accidentally refer
    // to CG_COMPILER_ERROR as CG_COMPILE_ERROR so this alias
    // is here to fix this.
    RETVAL = CG_COMPILER_ERROR;
  OUTPUT:
    RETVAL

int 
_FILE_READ_ERROR(...)
  CODE:
    RETVAL = CG_FILE_READ_ERROR;
  OUTPUT:
    RETVAL

int 
_FILE_WRITE_ERROR(...)
  CODE:
    RETVAL = CG_FILE_WRITE_ERROR;
  OUTPUT:
    RETVAL

int 
_INVALID_CONTEXT_HANDLE_ERROR(...)
  CODE:
    RETVAL = CG_INVALID_CONTEXT_HANDLE_ERROR;
  OUTPUT:
    RETVAL

int 
_INVALID_DIMENSION_ERROR(...)
  CODE:
    RETVAL = CG_INVALID_DIMENSION_ERROR;
  OUTPUT:
    RETVAL

int 
_INVALID_ENUMERANT_ERROR(...)
  CODE:
    RETVAL = CG_INVALID_ENUMERANT_ERROR;
  OUTPUT:
    RETVAL

int 
_INVALID_PARAMETER_ERROR(...)
  CODE:
    RETVAL = CG_INVALID_PARAMETER_ERROR;
  OUTPUT:
    RETVAL

int 
_INVALID_PARAM_HANDLE_ERROR(...)
  CODE:
    RETVAL = CG_INVALID_PARAM_HANDLE_ERROR;
  OUTPUT:
    RETVAL

int 
_INVALID_PROFILE_ERROR(...)
  CODE:
    RETVAL = CG_INVALID_PROFILE_ERROR;
  OUTPUT:
    RETVAL

int 
_INVALID_PROGRAM_HANDLE_ERROR(...)
  CODE:
    RETVAL = CG_INVALID_PROGRAM_HANDLE_ERROR;
  OUTPUT:
    RETVAL

int 
_INVALID_VALUE_TYPE_ERROR(...)
  CODE:
    RETVAL = CG_INVALID_VALUE_TYPE_ERROR;
  OUTPUT:
    RETVAL

int 
_MEMORY_ALLOC_ERROR(...)
  CODE:
    RETVAL = CG_MEMORY_ALLOC_ERROR;
  OUTPUT:
    RETVAL

int 
_NOT_MATRIX_PARAM_ERROR(...)
  CODE:
    RETVAL = CG_NOT_MATRIX_PARAM_ERROR;
  OUTPUT:
    RETVAL

int 
_NO_ERROR(...)
  CODE:
    RETVAL = CG_NO_ERROR;
  OUTPUT:
    RETVAL

int 
_NVPARSE_ERROR(...)
  CODE:
    RETVAL = CG_NVPARSE_ERROR;
  OUTPUT:
    RETVAL

int 
_OUT_OF_ARRAY_BOUNDS_ERROR(...)
  CODE:
    RETVAL = CG_OUT_OF_ARRAY_BOUNDS_ERROR;
  OUTPUT:
    RETVAL

int 
_PROGRAM_BIND_ERROR(...)
  CODE:
    RETVAL = CG_PROGRAM_BIND_ERROR;
  OUTPUT:
    RETVAL

int 
_PROGRAM_LOAD_ERROR(...)
  CODE:
    RETVAL = CG_PROGRAM_LOAD_ERROR;
  OUTPUT:
    RETVAL

int 
_PROGRAM_NOT_LOADED_ERROR(...)
  CODE:
    RETVAL = CG_PROGRAM_NOT_LOADED_ERROR;
  OUTPUT:
    RETVAL

int 
_UNKNOWN_PROFILE_ERROR(...)
  CODE:
    RETVAL = CG_UNKNOWN_PROFILE_ERROR;
  OUTPUT:
    RETVAL

int 
_UNSUPPORTED_GL_EXTENSION_ERROR(...)
  CODE:
    RETVAL = CG_UNSUPPORTED_GL_EXTENSION_ERROR;
  OUTPUT:
    RETVAL

int 
_VAR_ARG_ERROR(...)
  CODE:
    RETVAL = CG_VAR_ARG_ERROR;
  OUTPUT:
    RETVAL

int
_MATRIX_IDENTITY(...)
  CODE:
    RETVAL = CG_GL_MATRIX_IDENTITY;
  OUTPUT:
    RETVAL

int
_MATRIX_TRANSPOSE(...)
  CODE:
    RETVAL = CG_GL_MATRIX_TRANSPOSE;
  OUTPUT:
    RETVAL

int
_MATRIX_INVERSE(...)
  CODE:
    RETVAL = CG_GL_MATRIX_INVERSE;
  OUTPUT:
    RETVAL

int
_MATRIX_INVERSE_TRANSPOSE(...)
  CODE:
    RETVAL = CG_GL_MATRIX_INVERSE_TRANSPOSE;
  OUTPUT:
    RETVAL

int
_MODELVIEW_MATRIX(...)
  CODE:
    RETVAL = CG_GL_MODELVIEW_MATRIX;
  OUTPUT:
    RETVAL

int
_PROJECTION_MATRIX(...)
  CODE:
    RETVAL = CG_GL_PROJECTION_MATRIX;
  OUTPUT:
    RETVAL

int
_TEXTURE_MATRIX(...)
  CODE:
    RETVAL = CG_GL_TEXTURE_MATRIX;
  OUTPUT:
    RETVAL

int
_MODELVIEW_PROJECTION_MATRIX(...)
  CODE:
    RETVAL = CG_GL_MODELVIEW_PROJECTION_MATRIX;
  OUTPUT:
    RETVAL

int
_VERTEX(...)
  CODE:
    RETVAL = CG_GL_VERTEX;
  OUTPUT:
    RETVAL

int
_FRAGMENT(...)
  CODE:
    RETVAL = CG_GL_FRAGMENT;
  OUTPUT:
    RETVAL

