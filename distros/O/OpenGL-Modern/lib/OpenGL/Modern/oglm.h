extern int _done_glewInit;
extern int _auto_check_errors;

#define OGLM_CROAK_IF_ERR(name, cleanup) \
  { \
    int err = glGetError(); /* spec: once one happens, no more recorded */ \
    if (err != GL_NO_ERROR) { \
      cleanup; \
      croak(#name ": OpenGL error: 0x%04x %s", err, gl_error_string(err)); \
    } \
  }
#define OGLM_CHECK_ERR(name, cleanup) \
  if (_auto_check_errors) { \
    OGLM_CROAK_IF_ERR(name, cleanup) \
  }
#define OGLM_GLEWINIT \
  if (!_done_glewInit) { \
    GLenum err; \
    glewExperimental = GL_TRUE; \
    err = glewInit(); \
    if (GLEW_OK != err) \
      croak("Error: %s", glewGetErrorString(err)); \
    _done_glewInit++; \
  }
#define OGLM_AVAIL_CHECK(impl, name) \
  if ( !impl ) { \
    croak(#name " not available on this machine"); \
  }
#define OGLM_OUT_FINISH(buffername, n, newfunc) \
  EXTEND(sp, n); \
  { int i; for (i=0;i<n;i++) mPUSHs(newfunc(buffername[i])); }
#define OGLM_GET_VARARGS(varname, startfrom, type, perltype, howmany) \
  NULL; if (items-(startfrom) != (howmany)) \
    croak("error: expected %d args but given %d", howmany, items-(startfrom)); \
  varname = OGLM_ALLOC(howmany, type, varname); \
  { IV i; for(i = 0; i < (howmany); i++) { \
    varname[i] = (type)Sv##perltype(ST(i + (startfrom))); \
  } }
#define OGLM_VALIDATE_AV(varSV) \
  if (!SvOK(varSV)) croak("given undef instead of array-ref"); \
  if (!SvROK(varSV)) croak("given non-reference instead of array-ref"); \
  if (SvTYPE(SvRV(varSV)) != SVt_PVAV) croak("given reference to non-array");
#define OGLM_GET_ARRAY(varname, type, perltype, howmany) \
  NULL; OGLM_VALIDATE_AV(varname##SV) \
  if (av_count((AV*)SvRV(varname##SV)) != (howmany)) \
    croak("error: expected %d args but given %zd", howmany, av_count((AV*)SvRV(varname##SV))); \
  varname = OGLM_ALLOC(howmany, type, varname); \
  { AV *av = (AV*)SvRV(varname##SV); IV i; for(i = 0; i < (howmany); i++) { \
    SV **got = av_fetch(av, i, 0); \
    if (!got) croak("av_fetch failed"); \
    if (!*got) croak("av_fetch failed(2)"); \
    if (!SvOK(*got)) croak("got undef from " #varname); \
    varname[i] = (type)Sv##perltype(*got); \
  } }
#define OGLM_LEN_ARRAY(len, varname) \
  0; OGLM_VALIDATE_AV(varname##SV) \
  len = av_count((AV*)SvRV(varname##SV));
#define OGLM_SIZE_ENUM(group, pname, mult) \
  int pname ## _count = oglm_count_##group(pname) * (mult); \
  if (pname ## _count < 0) croak("Unknown " #group " %d", pname);
#define OGLM_ALLOC(size, buffertype, buffername) \
  NULL; if (size <= 0) croak("called with invalid n=%d", size); \
  buffername = malloc(sizeof(buffertype) * size); \
  if (!buffername) croak("malloc failed");
#define OGLM_PUSH_ARRAY(name, newfunc, buffername, howmany) \
  { \
    AV *newval = newAV(); \
    if (!newval) croak(#name ": newAV failed"); \
    av_extend(newval, howmany); \
    IV i; \
    for (i = 0; i < howmany; i++) { \
      av_push(newval, newfunc(buffername[i])); \
    } \
    mPUSHs(newRV_noinc((SV*)newval)); \
  }
