#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant_8 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GLU_FILL GLU_FLAT GLU_LINE GLU_NONE GLU_TRUE */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'I':
    if (memEQ(name, "GLU_FILL", 8)) {
    /*                    ^        */
#ifdef GLU_FILL
      *iv_return = GLU_FILL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_LINE", 8)) {
    /*                    ^        */
#ifdef GLU_LINE
      *iv_return = GLU_LINE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "GLU_FLAT", 8)) {
    /*                    ^        */
#ifdef GLU_FLAT
      *iv_return = GLU_FLAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "GLU_NONE", 8)) {
    /*                    ^        */
#ifdef GLU_NONE
      *iv_return = GLU_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "GLU_TRUE", 8)) {
    /*                    ^        */
#ifdef GLU_TRUE
      *iv_return = GLU_TRUE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GLU_BEGIN GLU_ERROR GLU_FALSE GLU_POINT */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'I':
    if (memEQ(name, "GLU_BEGIN", 9)) {
    /*                      ^       */
#ifdef GLU_BEGIN
      *iv_return = GLU_BEGIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "GLU_POINT", 9)) {
    /*                      ^       */
#ifdef GLU_POINT
      *iv_return = GLU_POINT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "GLU_ERROR", 9)) {
    /*                      ^       */
#ifdef GLU_ERROR
      *iv_return = GLU_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "GLU_FALSE", 9)) {
    /*                      ^       */
#ifdef GLU_FALSE
      *iv_return = GLU_FALSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_10 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GLU_INSIDE GLU_SMOOTH GLU_U_STEP GLU_VERTEX GLU_V_STEP */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'I':
    if (memEQ(name, "GLU_INSIDE", 10)) {
    /*                   ^            */
#ifdef GLU_INSIDE
      *iv_return = GLU_INSIDE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "GLU_SMOOTH", 10)) {
    /*                   ^            */
#ifdef GLU_SMOOTH
      *iv_return = GLU_SMOOTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "GLU_U_STEP", 10)) {
    /*                   ^            */
#ifdef GLU_U_STEP
      *iv_return = GLU_U_STEP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "GLU_VERTEX", 10)) {
    /*                   ^            */
#ifdef GLU_VERTEX
      *iv_return = GLU_VERTEX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_V_STEP", 10)) {
    /*                   ^            */
#ifdef GLU_V_STEP
      *iv_return = GLU_V_STEP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_11 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GLU_CULLING GLU_OUTSIDE GLU_UNKNOWN GLU_VERSION */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'K':
    if (memEQ(name, "GLU_UNKNOWN", 11)) {
    /*                     ^           */
#ifdef GLU_UNKNOWN
      *iv_return = GLU_UNKNOWN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "GLU_CULLING", 11)) {
    /*                     ^           */
#ifdef GLU_CULLING
      *iv_return = GLU_CULLING;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "GLU_VERSION", 11)) {
    /*                     ^           */
#ifdef GLU_VERSION
      *iv_return = GLU_VERSION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "GLU_OUTSIDE", 11)) {
    /*                     ^           */
#ifdef GLU_OUTSIDE
      *iv_return = GLU_OUTSIDE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_12 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GLU_EXTERIOR GLU_INTERIOR GLU_TESS_END */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'E':
    if (memEQ(name, "GLU_EXTERIOR", 12)) {
    /*                   ^              */
#ifdef GLU_EXTERIOR
      *iv_return = GLU_EXTERIOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "GLU_INTERIOR", 12)) {
    /*                   ^              */
#ifdef GLU_INTERIOR
      *iv_return = GLU_INTERIOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "GLU_TESS_END", 12)) {
    /*                   ^              */
#ifdef GLU_TESS_END
      *iv_return = GLU_TESS_END;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GLU_EXTENSIONS GLU_NURBS_MODE GLU_SILHOUETTE GLU_TESS_BEGIN GLU_TESS_ERROR
     */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'D':
    if (memEQ(name, "GLU_NURBS_MODE", 14)) {
    /*                           ^        */
#ifdef GLU_NURBS_MODE
      *iv_return = GLU_NURBS_MODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "GLU_TESS_BEGIN", 14)) {
    /*                           ^        */
#ifdef GLU_TESS_BEGIN
      *iv_return = GLU_TESS_BEGIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "GLU_EXTENSIONS", 14)) {
    /*                           ^        */
#ifdef GLU_EXTENSIONS
      *iv_return = GLU_EXTENSIONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "GLU_TESS_ERROR", 14)) {
    /*                           ^        */
#ifdef GLU_TESS_ERROR
      *iv_return = GLU_TESS_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "GLU_SILHOUETTE", 14)) {
    /*                           ^        */
#ifdef GLU_SILHOUETTE
      *iv_return = GLU_SILHOUETTE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GLU_MAP1_TRIM_2 GLU_MAP1_TRIM_3 GLU_NURBS_BEGIN GLU_NURBS_COLOR
     GLU_NURBS_ERROR GLU_PATH_LENGTH GLU_TESS_ERROR1 GLU_TESS_ERROR2
     GLU_TESS_ERROR3 GLU_TESS_ERROR4 GLU_TESS_ERROR5 GLU_TESS_ERROR6
     GLU_TESS_ERROR7 GLU_TESS_ERROR8 GLU_TESS_VERTEX GLU_VERSION_1_1
     GLU_VERSION_1_2 GLU_VERSION_1_3 */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case '1':
    if (memEQ(name, "GLU_TESS_ERROR", 14)) {
    /*                             1      */
#ifdef GLU_TESS_ERROR1
      *iv_return = GLU_TESS_ERROR1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_VERSION_1_", 14)) {
    /*                             1      */
#ifdef GLU_VERSION_1_1
      *iv_return = GLU_VERSION_1_1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "GLU_MAP1_TRIM_", 14)) {
    /*                             2      */
#ifdef GLU_MAP1_TRIM_2
      *iv_return = GLU_MAP1_TRIM_2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_TESS_ERROR", 14)) {
    /*                             2      */
#ifdef GLU_TESS_ERROR2
      *iv_return = GLU_TESS_ERROR2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_VERSION_1_", 14)) {
    /*                             2      */
#ifdef GLU_VERSION_1_2
      *iv_return = GLU_VERSION_1_2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '3':
    if (memEQ(name, "GLU_MAP1_TRIM_", 14)) {
    /*                             3      */
#ifdef GLU_MAP1_TRIM_3
      *iv_return = GLU_MAP1_TRIM_3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_TESS_ERROR", 14)) {
    /*                             3      */
#ifdef GLU_TESS_ERROR3
      *iv_return = GLU_TESS_ERROR3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_VERSION_1_", 14)) {
    /*                             3      */
#ifdef GLU_VERSION_1_3
      *iv_return = GLU_VERSION_1_3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "GLU_TESS_ERROR", 14)) {
    /*                             4      */
#ifdef GLU_TESS_ERROR4
      *iv_return = GLU_TESS_ERROR4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '5':
    if (memEQ(name, "GLU_TESS_ERROR", 14)) {
    /*                             5      */
#ifdef GLU_TESS_ERROR5
      *iv_return = GLU_TESS_ERROR5;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '6':
    if (memEQ(name, "GLU_TESS_ERROR", 14)) {
    /*                             6      */
#ifdef GLU_TESS_ERROR6
      *iv_return = GLU_TESS_ERROR6;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '7':
    if (memEQ(name, "GLU_TESS_ERROR", 14)) {
    /*                             7      */
#ifdef GLU_TESS_ERROR7
      *iv_return = GLU_TESS_ERROR7;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '8':
    if (memEQ(name, "GLU_TESS_ERROR", 14)) {
    /*                             8      */
#ifdef GLU_TESS_ERROR8
      *iv_return = GLU_TESS_ERROR8;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "GLU_PATH_LENGT", 14)) {
    /*                             H      */
#ifdef GLU_PATH_LENGTH
      *iv_return = GLU_PATH_LENGTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "GLU_NURBS_BEGI", 14)) {
    /*                             N      */
#ifdef GLU_NURBS_BEGIN
      *iv_return = GLU_NURBS_BEGIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "GLU_NURBS_COLO", 14)) {
    /*                             R      */
#ifdef GLU_NURBS_COLOR
      *iv_return = GLU_NURBS_COLOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_ERRO", 14)) {
    /*                             R      */
#ifdef GLU_NURBS_ERROR
      *iv_return = GLU_NURBS_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "GLU_TESS_VERTE", 14)) {
    /*                             X      */
#ifdef GLU_TESS_VERTEX
      *iv_return = GLU_TESS_VERTEX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GLU_DISPLAY_MODE GLU_INVALID_ENUM GLU_NURBS_ERROR1 GLU_NURBS_ERROR2
     GLU_NURBS_ERROR3 GLU_NURBS_ERROR4 GLU_NURBS_ERROR5 GLU_NURBS_ERROR6
     GLU_NURBS_ERROR7 GLU_NURBS_ERROR8 GLU_NURBS_ERROR9 GLU_NURBS_NORMAL
     GLU_NURBS_VERTEX GLU_TESS_COMBINE */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case '1':
    if (memEQ(name, "GLU_NURBS_ERROR", 15)) {
    /*                              1      */
#ifdef GLU_NURBS_ERROR1
      *iv_return = GLU_NURBS_ERROR1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "GLU_NURBS_ERROR", 15)) {
    /*                              2      */
#ifdef GLU_NURBS_ERROR2
      *iv_return = GLU_NURBS_ERROR2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '3':
    if (memEQ(name, "GLU_NURBS_ERROR", 15)) {
    /*                              3      */
#ifdef GLU_NURBS_ERROR3
      *iv_return = GLU_NURBS_ERROR3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "GLU_NURBS_ERROR", 15)) {
    /*                              4      */
#ifdef GLU_NURBS_ERROR4
      *iv_return = GLU_NURBS_ERROR4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '5':
    if (memEQ(name, "GLU_NURBS_ERROR", 15)) {
    /*                              5      */
#ifdef GLU_NURBS_ERROR5
      *iv_return = GLU_NURBS_ERROR5;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '6':
    if (memEQ(name, "GLU_NURBS_ERROR", 15)) {
    /*                              6      */
#ifdef GLU_NURBS_ERROR6
      *iv_return = GLU_NURBS_ERROR6;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '7':
    if (memEQ(name, "GLU_NURBS_ERROR", 15)) {
    /*                              7      */
#ifdef GLU_NURBS_ERROR7
      *iv_return = GLU_NURBS_ERROR7;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '8':
    if (memEQ(name, "GLU_NURBS_ERROR", 15)) {
    /*                              8      */
#ifdef GLU_NURBS_ERROR8
      *iv_return = GLU_NURBS_ERROR8;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '9':
    if (memEQ(name, "GLU_NURBS_ERROR", 15)) {
    /*                              9      */
#ifdef GLU_NURBS_ERROR9
      *iv_return = GLU_NURBS_ERROR9;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "GLU_DISPLAY_MOD", 15)) {
    /*                              E      */
#ifdef GLU_DISPLAY_MODE
      *iv_return = GLU_DISPLAY_MODE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_TESS_COMBIN", 15)) {
    /*                              E      */
#ifdef GLU_TESS_COMBINE
      *iv_return = GLU_TESS_COMBINE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "GLU_NURBS_NORMA", 15)) {
    /*                              L      */
#ifdef GLU_NURBS_NORMAL
      *iv_return = GLU_NURBS_NORMAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "GLU_INVALID_ENU", 15)) {
    /*                              M      */
#ifdef GLU_INVALID_ENUM
      *iv_return = GLU_INVALID_ENUM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "GLU_NURBS_VERTE", 15)) {
    /*                              X      */
#ifdef GLU_NURBS_VERTEX
      *iv_return = GLU_NURBS_VERTEX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GLU_INVALID_VALUE GLU_NURBS_END_EXT GLU_NURBS_ERROR10 GLU_NURBS_ERROR11
     GLU_NURBS_ERROR12 GLU_NURBS_ERROR13 GLU_NURBS_ERROR14 GLU_NURBS_ERROR15
     GLU_NURBS_ERROR16 GLU_NURBS_ERROR17 GLU_NURBS_ERROR18 GLU_NURBS_ERROR19
     GLU_NURBS_ERROR20 GLU_NURBS_ERROR21 GLU_NURBS_ERROR22 GLU_NURBS_ERROR23
     GLU_NURBS_ERROR24 GLU_NURBS_ERROR25 GLU_NURBS_ERROR26 GLU_NURBS_ERROR27
     GLU_NURBS_ERROR28 GLU_NURBS_ERROR29 GLU_NURBS_ERROR30 GLU_NURBS_ERROR31
     GLU_NURBS_ERROR32 GLU_NURBS_ERROR33 GLU_NURBS_ERROR34 GLU_NURBS_ERROR35
     GLU_NURBS_ERROR36 GLU_NURBS_ERROR37 GLU_OUTLINE_PATCH GLU_OUT_OF_MEMORY
     GLU_TESS_END_DATA */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case '0':
    if (memEQ(name, "GLU_NURBS_ERROR1", 16)) {
    /*                               0      */
#ifdef GLU_NURBS_ERROR10
      *iv_return = GLU_NURBS_ERROR10;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_ERROR2", 16)) {
    /*                               0      */
#ifdef GLU_NURBS_ERROR20
      *iv_return = GLU_NURBS_ERROR20;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_ERROR3", 16)) {
    /*                               0      */
#ifdef GLU_NURBS_ERROR30
      *iv_return = GLU_NURBS_ERROR30;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '1':
    if (memEQ(name, "GLU_NURBS_ERROR1", 16)) {
    /*                               1      */
#ifdef GLU_NURBS_ERROR11
      *iv_return = GLU_NURBS_ERROR11;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_ERROR2", 16)) {
    /*                               1      */
#ifdef GLU_NURBS_ERROR21
      *iv_return = GLU_NURBS_ERROR21;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_ERROR3", 16)) {
    /*                               1      */
#ifdef GLU_NURBS_ERROR31
      *iv_return = GLU_NURBS_ERROR31;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "GLU_NURBS_ERROR1", 16)) {
    /*                               2      */
#ifdef GLU_NURBS_ERROR12
      *iv_return = GLU_NURBS_ERROR12;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_ERROR2", 16)) {
    /*                               2      */
#ifdef GLU_NURBS_ERROR22
      *iv_return = GLU_NURBS_ERROR22;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_ERROR3", 16)) {
    /*                               2      */
#ifdef GLU_NURBS_ERROR32
      *iv_return = GLU_NURBS_ERROR32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '3':
    if (memEQ(name, "GLU_NURBS_ERROR1", 16)) {
    /*                               3      */
#ifdef GLU_NURBS_ERROR13
      *iv_return = GLU_NURBS_ERROR13;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_ERROR2", 16)) {
    /*                               3      */
#ifdef GLU_NURBS_ERROR23
      *iv_return = GLU_NURBS_ERROR23;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_ERROR3", 16)) {
    /*                               3      */
#ifdef GLU_NURBS_ERROR33
      *iv_return = GLU_NURBS_ERROR33;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "GLU_NURBS_ERROR1", 16)) {
    /*                               4      */
#ifdef GLU_NURBS_ERROR14
      *iv_return = GLU_NURBS_ERROR14;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_ERROR2", 16)) {
    /*                               4      */
#ifdef GLU_NURBS_ERROR24
      *iv_return = GLU_NURBS_ERROR24;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_ERROR3", 16)) {
    /*                               4      */
#ifdef GLU_NURBS_ERROR34
      *iv_return = GLU_NURBS_ERROR34;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '5':
    if (memEQ(name, "GLU_NURBS_ERROR1", 16)) {
    /*                               5      */
#ifdef GLU_NURBS_ERROR15
      *iv_return = GLU_NURBS_ERROR15;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_ERROR2", 16)) {
    /*                               5      */
#ifdef GLU_NURBS_ERROR25
      *iv_return = GLU_NURBS_ERROR25;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_ERROR3", 16)) {
    /*                               5      */
#ifdef GLU_NURBS_ERROR35
      *iv_return = GLU_NURBS_ERROR35;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '6':
    if (memEQ(name, "GLU_NURBS_ERROR1", 16)) {
    /*                               6      */
#ifdef GLU_NURBS_ERROR16
      *iv_return = GLU_NURBS_ERROR16;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_ERROR2", 16)) {
    /*                               6      */
#ifdef GLU_NURBS_ERROR26
      *iv_return = GLU_NURBS_ERROR26;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_ERROR3", 16)) {
    /*                               6      */
#ifdef GLU_NURBS_ERROR36
      *iv_return = GLU_NURBS_ERROR36;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '7':
    if (memEQ(name, "GLU_NURBS_ERROR1", 16)) {
    /*                               7      */
#ifdef GLU_NURBS_ERROR17
      *iv_return = GLU_NURBS_ERROR17;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_ERROR2", 16)) {
    /*                               7      */
#ifdef GLU_NURBS_ERROR27
      *iv_return = GLU_NURBS_ERROR27;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_ERROR3", 16)) {
    /*                               7      */
#ifdef GLU_NURBS_ERROR37
      *iv_return = GLU_NURBS_ERROR37;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '8':
    if (memEQ(name, "GLU_NURBS_ERROR1", 16)) {
    /*                               8      */
#ifdef GLU_NURBS_ERROR18
      *iv_return = GLU_NURBS_ERROR18;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_ERROR2", 16)) {
    /*                               8      */
#ifdef GLU_NURBS_ERROR28
      *iv_return = GLU_NURBS_ERROR28;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '9':
    if (memEQ(name, "GLU_NURBS_ERROR1", 16)) {
    /*                               9      */
#ifdef GLU_NURBS_ERROR19
      *iv_return = GLU_NURBS_ERROR19;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_ERROR2", 16)) {
    /*                               9      */
#ifdef GLU_NURBS_ERROR29
      *iv_return = GLU_NURBS_ERROR29;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'A':
    if (memEQ(name, "GLU_TESS_END_DAT", 16)) {
    /*                               A      */
#ifdef GLU_TESS_END_DATA
      *iv_return = GLU_TESS_END_DATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "GLU_INVALID_VALU", 16)) {
    /*                               E      */
#ifdef GLU_INVALID_VALUE
      *iv_return = GLU_INVALID_VALUE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "GLU_OUTLINE_PATC", 16)) {
    /*                               H      */
#ifdef GLU_OUTLINE_PATCH
      *iv_return = GLU_OUTLINE_PATCH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "GLU_NURBS_END_EX", 16)) {
    /*                               T      */
#ifdef GLU_NURBS_END_EXT
      *iv_return = GLU_NURBS_END_EXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "GLU_OUT_OF_MEMOR", 16)) {
    /*                               Y      */
#ifdef GLU_OUT_OF_MEMORY
      *iv_return = GLU_OUT_OF_MEMORY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GLU_NURBS_END_DATA GLU_NURBS_MODE_EXT GLU_NURBS_RENDERER
     GLU_TESS_EDGE_FLAG GLU_TESS_MAX_COORD GLU_TESS_TOLERANCE */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'A':
    if (memEQ(name, "GLU_TESS_MAX_COORD", 18)) {
    /*                         ^              */
#ifdef GLU_TESS_MAX_COORD
      *iv_return = GLU_TESS_MAX_COORD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "GLU_TESS_EDGE_FLAG", 18)) {
    /*                         ^              */
#ifdef GLU_TESS_EDGE_FLAG
      *iv_return = GLU_TESS_EDGE_FLAG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "GLU_NURBS_END_DATA", 18)) {
    /*                         ^              */
#ifdef GLU_NURBS_END_DATA
      *iv_return = GLU_NURBS_END_DATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "GLU_NURBS_MODE_EXT", 18)) {
    /*                         ^              */
#ifdef GLU_NURBS_MODE_EXT
      *iv_return = GLU_NURBS_MODE_EXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "GLU_TESS_TOLERANCE", 18)) {
    /*                         ^              */
#ifdef GLU_TESS_TOLERANCE
      *iv_return = GLU_TESS_TOLERANCE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "GLU_NURBS_RENDERER", 18)) {
    /*                         ^              */
#ifdef GLU_NURBS_RENDERER
      *iv_return = GLU_NURBS_RENDERER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_19 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GLU_DOMAIN_DISTANCE GLU_NURBS_BEGIN_EXT GLU_NURBS_COLOR_EXT
     GLU_OUTLINE_POLYGON GLU_SAMPLING_METHOD GLU_TESS_BEGIN_DATA
     GLU_TESS_ERROR_DATA */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'I':
    if (memEQ(name, "GLU_NURBS_BEGIN_EXT", 19)) {
    /*                            ^            */
#ifdef GLU_NURBS_BEGIN_EXT
      *iv_return = GLU_NURBS_BEGIN_EXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "GLU_SAMPLING_METHOD", 19)) {
    /*                            ^            */
#ifdef GLU_SAMPLING_METHOD
      *iv_return = GLU_SAMPLING_METHOD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "GLU_TESS_BEGIN_DATA", 19)) {
    /*                            ^            */
#ifdef GLU_TESS_BEGIN_DATA
      *iv_return = GLU_TESS_BEGIN_DATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "GLU_NURBS_COLOR_EXT", 19)) {
    /*                            ^            */
#ifdef GLU_NURBS_COLOR_EXT
      *iv_return = GLU_NURBS_COLOR_EXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_OUTLINE_POLYGON", 19)) {
    /*                            ^            */
#ifdef GLU_OUTLINE_POLYGON
      *iv_return = GLU_OUTLINE_POLYGON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "GLU_TESS_ERROR_DATA", 19)) {
    /*                            ^            */
#ifdef GLU_TESS_ERROR_DATA
      *iv_return = GLU_TESS_ERROR_DATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "GLU_DOMAIN_DISTANCE", 19)) {
    /*                            ^            */
#ifdef GLU_DOMAIN_DISTANCE
      *iv_return = GLU_DOMAIN_DISTANCE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_20 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GLU_AUTO_LOAD_MATRIX GLU_NURBS_BEGIN_DATA GLU_NURBS_COLOR_DATA
     GLU_NURBS_NORMAL_EXT GLU_NURBS_VERTEX_EXT GLU_PARAMETRIC_ERROR
     GLU_TESS_VERTEX_DATA GLU_TESS_WINDING_ODD */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'B':
    if (memEQ(name, "GLU_NURBS_BEGIN_DATA", 20)) {
    /*                         ^                */
#ifdef GLU_NURBS_BEGIN_DATA
      *iv_return = GLU_NURBS_BEGIN_DATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "GLU_NURBS_COLOR_DATA", 20)) {
    /*                         ^                */
#ifdef GLU_NURBS_COLOR_DATA
      *iv_return = GLU_NURBS_COLOR_DATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "GLU_TESS_VERTEX_DATA", 20)) {
    /*                         ^                */
#ifdef GLU_TESS_VERTEX_DATA
      *iv_return = GLU_TESS_VERTEX_DATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "GLU_TESS_WINDING_ODD", 20)) {
    /*                         ^                */
#ifdef GLU_TESS_WINDING_ODD
      *iv_return = GLU_TESS_WINDING_ODD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "GLU_NURBS_NORMAL_EXT", 20)) {
    /*                         ^                */
#ifdef GLU_NURBS_NORMAL_EXT
      *iv_return = GLU_NURBS_NORMAL_EXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "GLU_AUTO_LOAD_MATRIX", 20)) {
    /*                         ^                */
#ifdef GLU_AUTO_LOAD_MATRIX
      *iv_return = GLU_AUTO_LOAD_MATRIX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "GLU_PARAMETRIC_ERROR", 20)) {
    /*                         ^                */
#ifdef GLU_PARAMETRIC_ERROR
      *iv_return = GLU_PARAMETRIC_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "GLU_NURBS_VERTEX_EXT", 20)) {
    /*                         ^                */
#ifdef GLU_NURBS_VERTEX_EXT
      *iv_return = GLU_NURBS_VERTEX_EXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_21 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GLU_INVALID_OPERATION GLU_NURBS_NORMAL_DATA GLU_NURBS_TESSELLATOR
     GLU_NURBS_VERTEX_DATA GLU_TESS_COMBINE_DATA GLU_TESS_WINDING_RULE */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'D':
    if (memEQ(name, "GLU_INVALID_OPERATION", 21)) {
    /*                         ^                 */
#ifdef GLU_INVALID_OPERATION
      *iv_return = GLU_INVALID_OPERATION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "GLU_TESS_WINDING_RULE", 21)) {
    /*                         ^                 */
#ifdef GLU_TESS_WINDING_RULE
      *iv_return = GLU_TESS_WINDING_RULE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "GLU_NURBS_NORMAL_DATA", 21)) {
    /*                         ^                 */
#ifdef GLU_NURBS_NORMAL_DATA
      *iv_return = GLU_NURBS_NORMAL_DATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "GLU_TESS_COMBINE_DATA", 21)) {
    /*                         ^                 */
#ifdef GLU_TESS_COMBINE_DATA
      *iv_return = GLU_TESS_COMBINE_DATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "GLU_NURBS_TESSELLATOR", 21)) {
    /*                         ^                 */
#ifdef GLU_NURBS_TESSELLATOR
      *iv_return = GLU_NURBS_TESSELLATOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "GLU_NURBS_VERTEX_DATA", 21)) {
    /*                         ^                 */
#ifdef GLU_NURBS_VERTEX_DATA
      *iv_return = GLU_NURBS_VERTEX_DATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_22 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GLU_NURBS_END_DATA_EXT GLU_NURBS_RENDERER_EXT GLU_OBJECT_PATH_LENGTH
     GLU_SAMPLING_TOLERANCE GLU_TESS_BOUNDARY_ONLY */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'A':
    if (memEQ(name, "GLU_TESS_BOUNDARY_ONLY", 22)) {
    /*                             ^              */
#ifdef GLU_TESS_BOUNDARY_ONLY
      *iv_return = GLU_TESS_BOUNDARY_ONLY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "GLU_NURBS_END_DATA_EXT", 22)) {
    /*                             ^              */
#ifdef GLU_NURBS_END_DATA_EXT
      *iv_return = GLU_NURBS_END_DATA_EXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "GLU_NURBS_RENDERER_EXT", 22)) {
    /*                             ^              */
#ifdef GLU_NURBS_RENDERER_EXT
      *iv_return = GLU_NURBS_RENDERER_EXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "GLU_OBJECT_PATH_LENGTH", 22)) {
    /*                             ^              */
#ifdef GLU_OBJECT_PATH_LENGTH
      *iv_return = GLU_OBJECT_PATH_LENGTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "GLU_SAMPLING_TOLERANCE", 22)) {
    /*                             ^              */
#ifdef GLU_SAMPLING_TOLERANCE
      *iv_return = GLU_SAMPLING_TOLERANCE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_23 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GLU_NURBS_TEXTURE_COORD GLU_NURBS_TEX_COORD_EXT GLU_TESS_EDGE_FLAG_DATA */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'L':
    if (memEQ(name, "GLU_TESS_EDGE_FLAG_DATA", 23)) {
    /*                              ^              */
#ifdef GLU_TESS_EDGE_FLAG_DATA
      *iv_return = GLU_TESS_EDGE_FLAG_DATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "GLU_NURBS_TEX_COORD_EXT", 23)) {
    /*                              ^              */
#ifdef GLU_NURBS_TEX_COORD_EXT
      *iv_return = GLU_NURBS_TEX_COORD_EXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "GLU_NURBS_TEXTURE_COORD", 23)) {
    /*                              ^              */
#ifdef GLU_NURBS_TEXTURE_COORD
      *iv_return = GLU_NURBS_TEXTURE_COORD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_24 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GLU_NURBS_BEGIN_DATA_EXT GLU_NURBS_COLOR_DATA_EXT GLU_PARAMETRIC_TOLERANCE
     GLU_TESS_COORD_TOO_LARGE GLU_TESS_WINDING_NONZERO */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'D':
    if (memEQ(name, "GLU_TESS_WINDING_NONZERO", 24)) {
    /*                           ^                  */
#ifdef GLU_TESS_WINDING_NONZERO
      *iv_return = GLU_TESS_WINDING_NONZERO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "GLU_NURBS_BEGIN_DATA_EXT", 24)) {
    /*                           ^                  */
#ifdef GLU_NURBS_BEGIN_DATA_EXT
      *iv_return = GLU_NURBS_BEGIN_DATA_EXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "GLU_PARAMETRIC_TOLERANCE", 24)) {
    /*                           ^                  */
#ifdef GLU_PARAMETRIC_TOLERANCE
      *iv_return = GLU_PARAMETRIC_TOLERANCE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "GLU_NURBS_COLOR_DATA_EXT", 24)) {
    /*                           ^                  */
#ifdef GLU_NURBS_COLOR_DATA_EXT
      *iv_return = GLU_NURBS_COLOR_DATA_EXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "GLU_TESS_COORD_TOO_LARGE", 24)) {
    /*                           ^                  */
#ifdef GLU_TESS_COORD_TOO_LARGE
      *iv_return = GLU_TESS_COORD_TOO_LARGE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_25 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GLU_EXT_nurbs_tessellator GLU_EXT_object_space_tess
     GLU_NURBS_NORMAL_DATA_EXT GLU_NURBS_TESSELLATOR_EXT
     GLU_NURBS_VERTEX_DATA_EXT GLU_TESS_WINDING_NEGATIVE
     GLU_TESS_WINDING_POSITIVE */
  /* Offset 18 gives the best switch position.  */
  switch (name[18]) {
  case 'A':
    if (memEQ(name, "GLU_NURBS_NORMAL_DATA_EXT", 25)) {
    /*                                 ^             */
#ifdef GLU_NURBS_NORMAL_DATA_EXT
      *iv_return = GLU_NURBS_NORMAL_DATA_EXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "GLU_NURBS_VERTEX_DATA_EXT", 25)) {
    /*                                 ^             */
#ifdef GLU_NURBS_VERTEX_DATA_EXT
      *iv_return = GLU_NURBS_VERTEX_DATA_EXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "GLU_TESS_WINDING_NEGATIVE", 25)) {
    /*                                 ^             */
#ifdef GLU_TESS_WINDING_NEGATIVE
      *iv_return = GLU_TESS_WINDING_NEGATIVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "GLU_TESS_WINDING_POSITIVE", 25)) {
    /*                                 ^             */
#ifdef GLU_TESS_WINDING_POSITIVE
      *iv_return = GLU_TESS_WINDING_POSITIVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "GLU_NURBS_TESSELLATOR_EXT", 25)) {
    /*                                 ^             */
#ifdef GLU_NURBS_TESSELLATOR_EXT
      *iv_return = GLU_NURBS_TESSELLATOR_EXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'c':
    if (memEQ(name, "GLU_EXT_object_space_tess", 25)) {
    /*                                 ^             */
#ifdef GLU_EXT_object_space_tess
      *iv_return = GLU_EXT_object_space_tess;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'e':
    if (memEQ(name, "GLU_EXT_nurbs_tessellator", 25)) {
    /*                                 ^             */
#ifdef GLU_EXT_nurbs_tessellator
      *iv_return = GLU_EXT_nurbs_tessellator;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_28 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GLU_NURBS_TEXTURE_COORD_DATA GLU_NURBS_TEX_COORD_DATA_EXT
     GLU_TESS_MISSING_END_CONTOUR GLU_TESS_MISSING_END_POLYGON
     GLU_TESS_WINDING_ABS_GEQ_TWO */
  /* Offset 26 gives the best switch position.  */
  switch (name[26]) {
  case 'O':
    if (memEQ(name, "GLU_TESS_MISSING_END_POLYGON", 28)) {
    /*                                         ^        */
#ifdef GLU_TESS_MISSING_END_POLYGON
      *iv_return = GLU_TESS_MISSING_END_POLYGON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "GLU_NURBS_TEXTURE_COORD_DATA", 28)) {
    /*                                         ^        */
#ifdef GLU_NURBS_TEXTURE_COORD_DATA
      *iv_return = GLU_NURBS_TEXTURE_COORD_DATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "GLU_TESS_MISSING_END_CONTOUR", 28)) {
    /*                                         ^        */
#ifdef GLU_TESS_MISSING_END_CONTOUR
      *iv_return = GLU_TESS_MISSING_END_CONTOUR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "GLU_TESS_WINDING_ABS_GEQ_TWO", 28)) {
    /*                                         ^        */
#ifdef GLU_TESS_WINDING_ABS_GEQ_TWO
      *iv_return = GLU_TESS_WINDING_ABS_GEQ_TWO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "GLU_NURBS_TEX_COORD_DATA_EXT", 28)) {
    /*                                         ^        */
#ifdef GLU_NURBS_TEX_COORD_DATA_EXT
      *iv_return = GLU_NURBS_TEX_COORD_DATA_EXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_30 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GLU_TESS_MISSING_BEGIN_CONTOUR GLU_TESS_MISSING_BEGIN_POLYGON
     GLU_TESS_NEED_COMBINE_CALLBACK */
  /* Offset 29 gives the best switch position.  */
  switch (name[29]) {
  case 'K':
    if (memEQ(name, "GLU_TESS_NEED_COMBINE_CALLBAC", 29)) {
    /*                                            K      */
#ifdef GLU_TESS_NEED_COMBINE_CALLBACK
      *iv_return = GLU_TESS_NEED_COMBINE_CALLBACK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "GLU_TESS_MISSING_BEGIN_POLYGO", 29)) {
    /*                                            N      */
#ifdef GLU_TESS_MISSING_BEGIN_POLYGON
      *iv_return = GLU_TESS_MISSING_BEGIN_POLYGON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "GLU_TESS_MISSING_BEGIN_CONTOU", 29)) {
    /*                                            R      */
#ifdef GLU_TESS_MISSING_BEGIN_CONTOUR
      *iv_return = GLU_TESS_MISSING_BEGIN_CONTOUR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/usr/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(GLU_AUTO_LOAD_MATRIX GLU_BEGIN GLU_CCW GLU_CULLING GLU_CW
	       GLU_DISPLAY_MODE GLU_DOMAIN_DISTANCE GLU_EDGE_FLAG GLU_END
	       GLU_ERROR GLU_EXTENSIONS GLU_EXTERIOR GLU_EXT_nurbs_tessellator
	       GLU_EXT_object_space_tess GLU_FALSE GLU_FILL GLU_FLAT
	       GLU_INCOMPATIBLE_GL_VERSION GLU_INSIDE GLU_INTERIOR
	       GLU_INVALID_ENUM GLU_INVALID_OPERATION GLU_INVALID_VALUE
	       GLU_LINE GLU_MAP1_TRIM_2 GLU_MAP1_TRIM_3 GLU_NONE
	       GLU_NURBS_BEGIN GLU_NURBS_BEGIN_DATA GLU_NURBS_BEGIN_DATA_EXT
	       GLU_NURBS_BEGIN_EXT GLU_NURBS_COLOR GLU_NURBS_COLOR_DATA
	       GLU_NURBS_COLOR_DATA_EXT GLU_NURBS_COLOR_EXT GLU_NURBS_END
	       GLU_NURBS_END_DATA GLU_NURBS_END_DATA_EXT GLU_NURBS_END_EXT
	       GLU_NURBS_ERROR GLU_NURBS_ERROR1 GLU_NURBS_ERROR10
	       GLU_NURBS_ERROR11 GLU_NURBS_ERROR12 GLU_NURBS_ERROR13
	       GLU_NURBS_ERROR14 GLU_NURBS_ERROR15 GLU_NURBS_ERROR16
	       GLU_NURBS_ERROR17 GLU_NURBS_ERROR18 GLU_NURBS_ERROR19
	       GLU_NURBS_ERROR2 GLU_NURBS_ERROR20 GLU_NURBS_ERROR21
	       GLU_NURBS_ERROR22 GLU_NURBS_ERROR23 GLU_NURBS_ERROR24
	       GLU_NURBS_ERROR25 GLU_NURBS_ERROR26 GLU_NURBS_ERROR27
	       GLU_NURBS_ERROR28 GLU_NURBS_ERROR29 GLU_NURBS_ERROR3
	       GLU_NURBS_ERROR30 GLU_NURBS_ERROR31 GLU_NURBS_ERROR32
	       GLU_NURBS_ERROR33 GLU_NURBS_ERROR34 GLU_NURBS_ERROR35
	       GLU_NURBS_ERROR36 GLU_NURBS_ERROR37 GLU_NURBS_ERROR4
	       GLU_NURBS_ERROR5 GLU_NURBS_ERROR6 GLU_NURBS_ERROR7
	       GLU_NURBS_ERROR8 GLU_NURBS_ERROR9 GLU_NURBS_MODE
	       GLU_NURBS_MODE_EXT GLU_NURBS_NORMAL GLU_NURBS_NORMAL_DATA
	       GLU_NURBS_NORMAL_DATA_EXT GLU_NURBS_NORMAL_EXT
	       GLU_NURBS_RENDERER GLU_NURBS_RENDERER_EXT GLU_NURBS_TESSELLATOR
	       GLU_NURBS_TESSELLATOR_EXT GLU_NURBS_TEXTURE_COORD
	       GLU_NURBS_TEXTURE_COORD_DATA GLU_NURBS_TEX_COORD_DATA_EXT
	       GLU_NURBS_TEX_COORD_EXT GLU_NURBS_VERTEX GLU_NURBS_VERTEX_DATA
	       GLU_NURBS_VERTEX_DATA_EXT GLU_NURBS_VERTEX_EXT
	       GLU_OBJECT_PARAMETRIC_ERROR GLU_OBJECT_PARAMETRIC_ERROR_EXT
	       GLU_OBJECT_PATH_LENGTH GLU_OBJECT_PATH_LENGTH_EXT
	       GLU_OUTLINE_PATCH GLU_OUTLINE_POLYGON GLU_OUTSIDE
	       GLU_OUT_OF_MEMORY GLU_PARAMETRIC_ERROR GLU_PARAMETRIC_TOLERANCE
	       GLU_PATH_LENGTH GLU_POINT GLU_SAMPLING_METHOD
	       GLU_SAMPLING_TOLERANCE GLU_SILHOUETTE GLU_SMOOTH GLU_TESS_BEGIN
	       GLU_TESS_BEGIN_DATA GLU_TESS_BOUNDARY_ONLY GLU_TESS_COMBINE
	       GLU_TESS_COMBINE_DATA GLU_TESS_COORD_TOO_LARGE
	       GLU_TESS_EDGE_FLAG GLU_TESS_EDGE_FLAG_DATA GLU_TESS_END
	       GLU_TESS_END_DATA GLU_TESS_ERROR GLU_TESS_ERROR1 GLU_TESS_ERROR2
	       GLU_TESS_ERROR3 GLU_TESS_ERROR4 GLU_TESS_ERROR5 GLU_TESS_ERROR6
	       GLU_TESS_ERROR7 GLU_TESS_ERROR8 GLU_TESS_ERROR_DATA
	       GLU_TESS_MAX_COORD GLU_TESS_MISSING_BEGIN_CONTOUR
	       GLU_TESS_MISSING_BEGIN_POLYGON GLU_TESS_MISSING_END_CONTOUR
	       GLU_TESS_MISSING_END_POLYGON GLU_TESS_NEED_COMBINE_CALLBACK
	       GLU_TESS_TOLERANCE GLU_TESS_VERTEX GLU_TESS_VERTEX_DATA
	       GLU_TESS_WINDING_ABS_GEQ_TWO GLU_TESS_WINDING_NEGATIVE
	       GLU_TESS_WINDING_NONZERO GLU_TESS_WINDING_ODD
	       GLU_TESS_WINDING_POSITIVE GLU_TESS_WINDING_RULE GLU_TRUE
	       GLU_UNKNOWN GLU_U_STEP GLU_VERSION GLU_VERSION_1_1
	       GLU_VERSION_1_2 GLU_VERSION_1_3 GLU_VERTEX GLU_V_STEP));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("OpenGL::GLU", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("OpenGL::GLU", $types);
__END__
   */

  switch (len) {
  case 6:
    if (memEQ(name, "GLU_CW", 6)) {
#ifdef GLU_CW
      *iv_return = GLU_CW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 7:
    /* Names all of length 7.  */
    /* GLU_CCW GLU_END */
    /* Offset 4 gives the best switch position.  */
    switch (name[4]) {
    case 'C':
      if (memEQ(name, "GLU_CCW", 7)) {
      /*                   ^        */
#ifdef GLU_CCW
        *iv_return = GLU_CCW;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'E':
      if (memEQ(name, "GLU_END", 7)) {
      /*                   ^        */
#ifdef GLU_END
        *iv_return = GLU_END;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 8:
    return constant_8 (aTHX_ name, iv_return);
    break;
  case 9:
    return constant_9 (aTHX_ name, iv_return);
    break;
  case 10:
    return constant_10 (aTHX_ name, iv_return);
    break;
  case 11:
    return constant_11 (aTHX_ name, iv_return);
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    /* Names all of length 13.  */
    /* GLU_EDGE_FLAG GLU_NURBS_END */
    /* Offset 12 gives the best switch position.  */
    switch (name[12]) {
    case 'D':
      if (memEQ(name, "GLU_NURBS_EN", 12)) {
      /*                           D      */
#ifdef GLU_NURBS_END
        *iv_return = GLU_NURBS_END;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'G':
      if (memEQ(name, "GLU_EDGE_FLA", 12)) {
      /*                           G      */
#ifdef GLU_EDGE_FLAG
        *iv_return = GLU_EDGE_FLAG;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    return constant_19 (aTHX_ name, iv_return);
    break;
  case 20:
    return constant_20 (aTHX_ name, iv_return);
    break;
  case 21:
    return constant_21 (aTHX_ name, iv_return);
    break;
  case 22:
    return constant_22 (aTHX_ name, iv_return);
    break;
  case 23:
    return constant_23 (aTHX_ name, iv_return);
    break;
  case 24:
    return constant_24 (aTHX_ name, iv_return);
    break;
  case 25:
    return constant_25 (aTHX_ name, iv_return);
    break;
  case 26:
    if (memEQ(name, "GLU_OBJECT_PATH_LENGTH_EXT", 26)) {
#ifdef GLU_OBJECT_PATH_LENGTH_EXT
      *iv_return = GLU_OBJECT_PATH_LENGTH_EXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 27:
    /* Names all of length 27.  */
    /* GLU_INCOMPATIBLE_GL_VERSION GLU_OBJECT_PARAMETRIC_ERROR */
    /* Offset 23 gives the best switch position.  */
    switch (name[23]) {
    case 'R':
      if (memEQ(name, "GLU_OBJECT_PARAMETRIC_ERROR", 27)) {
      /*                                      ^          */
#ifdef GLU_OBJECT_PARAMETRIC_ERROR
        *iv_return = GLU_OBJECT_PARAMETRIC_ERROR;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "GLU_INCOMPATIBLE_GL_VERSION", 27)) {
      /*                                      ^          */
#ifdef GLU_INCOMPATIBLE_GL_VERSION
        *iv_return = GLU_INCOMPATIBLE_GL_VERSION;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 28:
    return constant_28 (aTHX_ name, iv_return);
    break;
  case 30:
    return constant_30 (aTHX_ name, iv_return);
    break;
  case 31:
    if (memEQ(name, "GLU_OBJECT_PARAMETRIC_ERROR_EXT", 31)) {
#ifdef GLU_OBJECT_PARAMETRIC_ERROR_EXT
      *iv_return = GLU_OBJECT_PARAMETRIC_ERROR_EXT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

