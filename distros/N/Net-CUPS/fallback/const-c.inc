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
     AF_LOCAL HTTP_0_9 HTTP_1_0 HTTP_1_1 HTTP_GET HTTP_PUT IPP_DATA IPP_GONE
     IPP_IDLE IPP_PORT PPD_CS_N */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case '0':
    if (memEQ(name, "HTTP_0_9", 8)) {
    /*                    ^        */
      *iv_return = HTTP_0_9;
      return PERL_constant_ISIV;
    }
    break;
  case '1':
    if (memEQ(name, "HTTP_1_0", 8)) {
    /*                    ^        */
      *iv_return = HTTP_1_0;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_1_1", 8)) {
    /*                    ^        */
      *iv_return = HTTP_1_1;
      return PERL_constant_ISIV;
    }
    break;
  case 'A':
    if (memEQ(name, "IPP_DATA", 8)) {
    /*                    ^        */
      *iv_return = IPP_DATA;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "AF_LOCAL", 8)) {
    /*                    ^        */
      *iv_return = AF_LOCAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "IPP_IDLE", 8)) {
    /*                    ^        */
      *iv_return = IPP_IDLE;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "HTTP_GET", 8)) {
    /*                    ^        */
      *iv_return = HTTP_GET;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "IPP_GONE", 8)) {
    /*                    ^        */
      *iv_return = IPP_GONE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_PORT", 8)) {
    /*                    ^        */
      *iv_return = IPP_PORT;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "HTTP_PUT", 8)) {
    /*                    ^        */
      *iv_return = HTTP_PUT;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "PPD_CS_N", 8)) {
    /*                    ^        */
      *iv_return = PPD_CS_N;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CUPS_UTF8 HTTP_GONE HTTP_HEAD HTTP_POST IPP_ERROR */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'G':
    if (memEQ(name, "HTTP_GONE", 9)) {
    /*                    ^         */
      *iv_return = HTTP_GONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "HTTP_HEAD", 9)) {
    /*                    ^         */
      *iv_return = HTTP_HEAD;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "HTTP_POST", 9)) {
    /*                    ^         */
      *iv_return = HTTP_POST;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "IPP_ERROR", 9)) {
    /*                    ^         */
      *iv_return = IPP_ERROR;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "CUPS_UTF8", 9)) {
    /*                    ^         */
      *iv_return = CUPS_UTF8;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_10 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     HTTP_CLOSE HTTP_ERROR HTTP_TRACE IPP_HEADER PPD_CS_CMY PPD_CS_RGB */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'C':
    if (memEQ(name, "HTTP_TRACE", 10)) {
    /*                       ^        */
      *iv_return = HTTP_TRACE;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "IPP_HEADER", 10)) {
    /*                       ^        */
      *iv_return = IPP_HEADER;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "PPD_CS_RGB", 10)) {
    /*                       ^        */
      *iv_return = PPD_CS_RGB;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "PPD_CS_CMY", 10)) {
    /*                       ^        */
      *iv_return = PPD_CS_CMY;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "HTTP_ERROR", 10)) {
    /*                       ^        */
      *iv_return = HTTP_ERROR;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "HTTP_CLOSE", 10)) {
    /*                       ^        */
      *iv_return = HTTP_CLOSE;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_11 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CUPS_EUC_CN CUPS_EUC_JP CUPS_EUC_KR CUPS_EUC_TW CUPS_KOI8_R CUPS_KOI8_U
     HTTP_DELETE HTTP_STATUS HTTP_URI_OK IPP_CHARSET IPP_PRIVATE IPP_TAG_END
     IPP_TAG_JOB IPP_TAG_URI IPP_TIMEOUT PPD_CS_CMYK PPD_CS_GRAY PPD_CS_RGBK
     PPD_VERSION */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'B':
    if (memEQ(name, "IPP_TAG_JO", 10)) {
    /*                         B      */
      *iv_return = IPP_TAG_JOB;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "IPP_TAG_EN", 10)) {
    /*                         D      */
      *iv_return = IPP_TAG_END;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "HTTP_DELET", 10)) {
    /*                         E      */
      *iv_return = HTTP_DELETE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_PRIVAT", 10)) {
    /*                         E      */
      *iv_return = IPP_PRIVATE;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "IPP_TAG_UR", 10)) {
    /*                         I      */
      *iv_return = IPP_TAG_URI;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "HTTP_URI_O", 10)) {
    /*                         K      */
      *iv_return = HTTP_URI_OK;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_CS_CMY", 10)) {
    /*                         K      */
      *iv_return = PPD_CS_CMYK;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_CS_RGB", 10)) {
    /*                         K      */
      *iv_return = PPD_CS_RGBK;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "CUPS_EUC_C", 10)) {
    /*                         N      */
      *iv_return = CUPS_EUC_CN;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_VERSIO", 10)) {
    /*                         N      */
      *iv_return = PPD_VERSION;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "CUPS_EUC_J", 10)) {
    /*                         P      */
      *iv_return = CUPS_EUC_JP;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "CUPS_EUC_K", 10)) {
    /*                         R      */
      *iv_return = CUPS_EUC_KR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_KOI8_", 10)) {
    /*                         R      */
      *iv_return = CUPS_KOI8_R;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "HTTP_STATU", 10)) {
    /*                         S      */
      *iv_return = HTTP_STATUS;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "IPP_CHARSE", 10)) {
    /*                         T      */
      *iv_return = IPP_CHARSET;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TIMEOU", 10)) {
    /*                         T      */
      *iv_return = IPP_TIMEOUT;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "CUPS_KOI8_", 10)) {
    /*                         U      */
      *iv_return = CUPS_KOI8_U;
      return PERL_constant_ISIV;
    }
    break;
  case 'W':
    if (memEQ(name, "CUPS_EUC_T", 10)) {
    /*                         W      */
      *iv_return = CUPS_EUC_TW;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "PPD_CS_GRA", 10)) {
    /*                         Y      */
      *iv_return = PPD_CS_GRAY;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_12 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CUPS_VERSION HTTP_CREATED HTTP_MAX_URI HTTP_OPTIONS HTTP_WAITING
     IPP_CONFLICT IPP_GET_JOBS IPP_HOLD_JOB IPP_JOB_HELD IPP_MAX_NAME
     IPP_OK_SUBST IPP_PORTRAIT IPP_SEND_URI IPP_TAG_COPY IPP_TAG_DATE
     IPP_TAG_ENUM IPP_TAG_MASK IPP_TAG_NAME IPP_TAG_TEXT IPP_TAG_ZERO
     PPD_MAX_LINE PPD_MAX_NAME PPD_MAX_TEXT */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'A':
    if (memEQ(name, "HTTP_CREATED", 12)) {
    /*                       ^          */
      *iv_return = HTTP_CREATED;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "IPP_TAG_COPY", 12)) {
    /*                       ^          */
      *iv_return = IPP_TAG_COPY;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "IPP_TAG_DATE", 12)) {
    /*                       ^          */
      *iv_return = IPP_TAG_DATE;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "IPP_TAG_ENUM", 12)) {
    /*                       ^          */
      *iv_return = IPP_TAG_ENUM;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "IPP_JOB_HELD", 12)) {
    /*                       ^          */
      *iv_return = IPP_JOB_HELD;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "HTTP_OPTIONS", 12)) {
    /*                       ^          */
      *iv_return = HTTP_OPTIONS;
      return PERL_constant_ISIV;
    }
    break;
  case 'J':
    if (memEQ(name, "IPP_GET_JOBS", 12)) {
    /*                       ^          */
      *iv_return = IPP_GET_JOBS;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "IPP_CONFLICT", 12)) {
    /*                       ^          */
      *iv_return = IPP_CONFLICT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_MAX_LINE", 12)) {
    /*                       ^          */
      *iv_return = PPD_MAX_LINE;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "IPP_TAG_MASK", 12)) {
    /*                       ^          */
      *iv_return = IPP_TAG_MASK;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "IPP_MAX_NAME", 12)) {
    /*                       ^          */
      *iv_return = IPP_MAX_NAME;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_NAME", 12)) {
    /*                       ^          */
      *iv_return = IPP_TAG_NAME;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_MAX_NAME", 12)) {
    /*                       ^          */
      *iv_return = PPD_MAX_NAME;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "IPP_PORTRAIT", 12)) {
    /*                       ^          */
      *iv_return = IPP_PORTRAIT;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "CUPS_VERSION", 12)) {
    /*                       ^          */
      *iv_return = CUPS_VERSION;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "HTTP_WAITING", 12)) {
    /*                       ^          */
      *iv_return = HTTP_WAITING;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_TEXT", 12)) {
    /*                       ^          */
      *iv_return = IPP_TAG_TEXT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_MAX_TEXT", 12)) {
    /*                       ^          */
      *iv_return = PPD_MAX_TEXT;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "IPP_OK_SUBST", 12)) {
    /*                       ^          */
      *iv_return = IPP_OK_SUBST;
      return PERL_constant_ISIV;
    }
    break;
  case 'Z':
    if (memEQ(name, "IPP_TAG_ZERO", 12)) {
    /*                       ^          */
      *iv_return = IPP_TAG_ZERO;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "HTTP_MAX_URI", 12)) {
    /*                       ^          */
      *iv_return = HTTP_MAX_URI;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_HOLD_JOB", 12)) {
    /*                       ^          */
      *iv_return = IPP_HOLD_JOB;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_SEND_URI", 12)) {
    /*                       ^          */
      *iv_return = IPP_SEND_URI;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CUPS_DATE_ANY CUPS_GET_PPDS CUPS_MOVE_JOB CUPS_US_ASCII HTTP_ACCEPTED
     HTTP_AUTH_MD5 HTTP_CONFLICT HTTP_CONTINUE HTTP_GET_SEND HTTP_MAX_HOST
     HTTP_PUT_RECV IPP_ATTRIBUTE IPP_FORBIDDEN IPP_LANDSCAPE IPP_NOT_FOUND
     IPP_PRINT_JOB IPP_PRINT_URI IPP_TAG_RANGE PPD_NULL_FILE PPD_ORDER_ANY
     PPD_ORDER_JCL */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'A':
    if (memEQ(name, "CUPS_DATE_ANY", 13)) {
    /*                     ^             */
      *iv_return = CUPS_DATE_ANY;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_MAX_HOST", 13)) {
    /*                     ^             */
      *iv_return = HTTP_MAX_HOST;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "HTTP_ACCEPTED", 13)) {
    /*                     ^             */
      *iv_return = HTTP_ACCEPTED;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "PPD_ORDER_ANY", 13)) {
    /*                     ^             */
      *iv_return = PPD_ORDER_ANY;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_ORDER_JCL", 13)) {
    /*                     ^             */
      *iv_return = PPD_ORDER_JCL;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "CUPS_GET_PPDS", 13)) {
    /*                     ^             */
      *iv_return = CUPS_GET_PPDS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_GET_SEND", 13)) {
    /*                     ^             */
      *iv_return = HTTP_GET_SEND;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "IPP_TAG_RANGE", 13)) {
    /*                     ^             */
      *iv_return = IPP_TAG_RANGE;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "IPP_PRINT_JOB", 13)) {
    /*                     ^             */
      *iv_return = IPP_PRINT_JOB;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_PRINT_URI", 13)) {
    /*                     ^             */
      *iv_return = IPP_PRINT_URI;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "PPD_NULL_FILE", 13)) {
    /*                     ^             */
      *iv_return = PPD_NULL_FILE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "IPP_LANDSCAPE", 13)) {
    /*                     ^             */
      *iv_return = IPP_LANDSCAPE;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "CUPS_MOVE_JOB", 13)) {
    /*                     ^             */
      *iv_return = CUPS_MOVE_JOB;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_CONFLICT", 13)) {
    /*                     ^             */
      *iv_return = HTTP_CONFLICT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_CONTINUE", 13)) {
    /*                     ^             */
      *iv_return = HTTP_CONTINUE;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "IPP_FORBIDDEN", 13)) {
    /*                     ^             */
      *iv_return = IPP_FORBIDDEN;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "CUPS_US_ASCII", 13)) {
    /*                     ^             */
      *iv_return = CUPS_US_ASCII;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "IPP_ATTRIBUTE", 13)) {
    /*                     ^             */
      *iv_return = IPP_ATTRIBUTE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_NOT_FOUND", 13)) {
    /*                     ^             */
      *iv_return = IPP_NOT_FOUND;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "HTTP_AUTH_MD5", 13)) {
    /*                     ^             */
      *iv_return = HTTP_AUTH_MD5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_PUT_RECV", 13)) {
    /*                     ^             */
      *iv_return = HTTP_PUT_RECV;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CUPS_ADD_CLASS CUPS_FILE_GZIP CUPS_FILE_NONE CUPS_IMAGE_CMY CUPS_IMAGE_RGB
     CUPS_ISO8859_1 CUPS_ISO8859_2 CUPS_ISO8859_3 CUPS_ISO8859_4 CUPS_ISO8859_5
     CUPS_ISO8859_6 CUPS_ISO8859_7 CUPS_ISO8859_8 CUPS_ISO8859_9 CUPS_MAC_ROMAN
     HTTP_AUTH_NONE HTTP_FIELD_MAX HTTP_FORBIDDEN HTTP_MAX_VALUE HTTP_NOT_FOUND
     HTTP_POST_RECV HTTP_POST_SEND HTTP_SEE_OTHER HTTP_USE_PROXY IPP_ATTRIBUTES
     IPP_CANCEL_JOB IPP_CREATE_JOB IPP_MAX_VALUES IPP_PURGE_JOBS IPP_RESUME_JOB
     IPP_RES_PER_CM IPP_TAG_STRING IPP_URI_SCHEME PPD_CUSTOM_INT PPD_ORDER_EXIT
     PPD_ORDER_PAGE PPD_UI_BOOLEAN PPD_UI_PICKONE */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case '1':
    if (memEQ(name, "CUPS_ISO8859_", 13)) {
    /*                            1      */
      *iv_return = CUPS_ISO8859_1;
      return PERL_constant_ISIV;
    }
    break;
  case '2':
    if (memEQ(name, "CUPS_ISO8859_", 13)) {
    /*                            2      */
      *iv_return = CUPS_ISO8859_2;
      return PERL_constant_ISIV;
    }
    break;
  case '3':
    if (memEQ(name, "CUPS_ISO8859_", 13)) {
    /*                            3      */
      *iv_return = CUPS_ISO8859_3;
      return PERL_constant_ISIV;
    }
    break;
  case '4':
    if (memEQ(name, "CUPS_ISO8859_", 13)) {
    /*                            4      */
      *iv_return = CUPS_ISO8859_4;
      return PERL_constant_ISIV;
    }
    break;
  case '5':
    if (memEQ(name, "CUPS_ISO8859_", 13)) {
    /*                            5      */
      *iv_return = CUPS_ISO8859_5;
      return PERL_constant_ISIV;
    }
    break;
  case '6':
    if (memEQ(name, "CUPS_ISO8859_", 13)) {
    /*                            6      */
      *iv_return = CUPS_ISO8859_6;
      return PERL_constant_ISIV;
    }
    break;
  case '7':
    if (memEQ(name, "CUPS_ISO8859_", 13)) {
    /*                            7      */
      *iv_return = CUPS_ISO8859_7;
      return PERL_constant_ISIV;
    }
    break;
  case '8':
    if (memEQ(name, "CUPS_ISO8859_", 13)) {
    /*                            8      */
      *iv_return = CUPS_ISO8859_8;
      return PERL_constant_ISIV;
    }
    break;
  case '9':
    if (memEQ(name, "CUPS_ISO8859_", 13)) {
    /*                            9      */
      *iv_return = CUPS_ISO8859_9;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "CUPS_IMAGE_RG", 13)) {
    /*                            B      */
      *iv_return = CUPS_IMAGE_RGB;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_CANCEL_JO", 13)) {
    /*                            B      */
      *iv_return = IPP_CANCEL_JOB;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_CREATE_JO", 13)) {
    /*                            B      */
      *iv_return = IPP_CREATE_JOB;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_RESUME_JO", 13)) {
    /*                            B      */
      *iv_return = IPP_RESUME_JOB;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "HTTP_NOT_FOUN", 13)) {
    /*                            D      */
      *iv_return = HTTP_NOT_FOUND;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_POST_SEN", 13)) {
    /*                            D      */
      *iv_return = HTTP_POST_SEND;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "CUPS_FILE_NON", 13)) {
    /*                            E      */
      *iv_return = CUPS_FILE_NONE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_AUTH_NON", 13)) {
    /*                            E      */
      *iv_return = HTTP_AUTH_NONE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_MAX_VALU", 13)) {
    /*                            E      */
      *iv_return = HTTP_MAX_VALUE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_URI_SCHEM", 13)) {
    /*                            E      */
      *iv_return = IPP_URI_SCHEME;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_ORDER_PAG", 13)) {
    /*                            E      */
      *iv_return = PPD_ORDER_PAGE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_UI_PICKON", 13)) {
    /*                            E      */
      *iv_return = PPD_UI_PICKONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "IPP_TAG_STRIN", 13)) {
    /*                            G      */
      *iv_return = IPP_TAG_STRING;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "IPP_RES_PER_C", 13)) {
    /*                            M      */
      *iv_return = IPP_RES_PER_CM;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "CUPS_MAC_ROMA", 13)) {
    /*                            N      */
      *iv_return = CUPS_MAC_ROMAN;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_FORBIDDE", 13)) {
    /*                            N      */
      *iv_return = HTTP_FORBIDDEN;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_UI_BOOLEA", 13)) {
    /*                            N      */
      *iv_return = PPD_UI_BOOLEAN;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "CUPS_FILE_GZI", 13)) {
    /*                            P      */
      *iv_return = CUPS_FILE_GZIP;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "HTTP_SEE_OTHE", 13)) {
    /*                            R      */
      *iv_return = HTTP_SEE_OTHER;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "CUPS_ADD_CLAS", 13)) {
    /*                            S      */
      *iv_return = CUPS_ADD_CLASS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_ATTRIBUTE", 13)) {
    /*                            S      */
      *iv_return = IPP_ATTRIBUTES;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_MAX_VALUE", 13)) {
    /*                            S      */
      *iv_return = IPP_MAX_VALUES;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_PURGE_JOB", 13)) {
    /*                            S      */
      *iv_return = IPP_PURGE_JOBS;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "PPD_CUSTOM_IN", 13)) {
    /*                            T      */
      *iv_return = PPD_CUSTOM_INT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_ORDER_EXI", 13)) {
    /*                            T      */
      *iv_return = PPD_ORDER_EXIT;
      return PERL_constant_ISIV;
    }
    break;
  case 'V':
    if (memEQ(name, "HTTP_POST_REC", 13)) {
    /*                            V      */
      *iv_return = HTTP_POST_RECV;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "HTTP_FIELD_MA", 13)) {
    /*                            X      */
      *iv_return = HTTP_FIELD_MAX;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "CUPS_IMAGE_CM", 13)) {
    /*                            Y      */
      *iv_return = CUPS_IMAGE_CMY;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_USE_PROX", 13)) {
    /*                            Y      */
      *iv_return = HTTP_USE_PROXY;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CUPS_BACKEND_OK CUPS_IMAGE_CMYK CUPS_ISO8859_10 CUPS_ISO8859_11
     CUPS_ISO8859_13 CUPS_ISO8859_14 CUPS_ISO8859_15 CUPS_ISO8859_16
     CUPS_PRINTER_BW HTTP_AUTH_BASIC HTTP_FIELD_DATE HTTP_FIELD_HOST
     HTTP_FIELD_LINK HTTP_MAX_BUFFER HTTP_NO_CONTENT IPP_BAD_REQUEST
     IPP_JOB_ABORTED IPP_JOB_PENDING IPP_JOB_STOPPED IPP_OK_CONFLICT
     IPP_PROMOTE_JOB IPP_RELEASE_JOB IPP_RESTART_JOB IPP_TAG_BOOLEAN
     IPP_TAG_CHARSET IPP_TAG_DEFAULT IPP_TAG_INTEGER IPP_TAG_KEYWORD
     IPP_TAG_NOVALUE IPP_TAG_PRINTER IPP_TAG_UNKNOWN PPD_ALLOC_ERROR
     PPD_BAD_OPEN_UI PPD_CUSTOM_REAL PPD_UI_PICKMANY */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case '0':
    if (memEQ(name, "CUPS_ISO8859_1", 14)) {
    /*                             0      */
      *iv_return = CUPS_ISO8859_10;
      return PERL_constant_ISIV;
    }
    break;
  case '1':
    if (memEQ(name, "CUPS_ISO8859_1", 14)) {
    /*                             1      */
      *iv_return = CUPS_ISO8859_11;
      return PERL_constant_ISIV;
    }
    break;
  case '3':
    if (memEQ(name, "CUPS_ISO8859_1", 14)) {
    /*                             3      */
      *iv_return = CUPS_ISO8859_13;
      return PERL_constant_ISIV;
    }
    break;
  case '4':
    if (memEQ(name, "CUPS_ISO8859_1", 14)) {
    /*                             4      */
      *iv_return = CUPS_ISO8859_14;
      return PERL_constant_ISIV;
    }
    break;
  case '5':
    if (memEQ(name, "CUPS_ISO8859_1", 14)) {
    /*                             5      */
      *iv_return = CUPS_ISO8859_15;
      return PERL_constant_ISIV;
    }
    break;
  case '6':
    if (memEQ(name, "CUPS_ISO8859_1", 14)) {
    /*                             6      */
      *iv_return = CUPS_ISO8859_16;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "IPP_PROMOTE_JO", 14)) {
    /*                             B      */
      *iv_return = IPP_PROMOTE_JOB;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_RELEASE_JO", 14)) {
    /*                             B      */
      *iv_return = IPP_RELEASE_JOB;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_RESTART_JO", 14)) {
    /*                             B      */
      *iv_return = IPP_RESTART_JOB;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "HTTP_AUTH_BASI", 14)) {
    /*                             C      */
      *iv_return = HTTP_AUTH_BASIC;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "IPP_JOB_ABORTE", 14)) {
    /*                             D      */
      *iv_return = IPP_JOB_ABORTED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_JOB_STOPPE", 14)) {
    /*                             D      */
      *iv_return = IPP_JOB_STOPPED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_KEYWOR", 14)) {
    /*                             D      */
      *iv_return = IPP_TAG_KEYWORD;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "HTTP_FIELD_DAT", 14)) {
    /*                             E      */
      *iv_return = HTTP_FIELD_DATE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_NOVALU", 14)) {
    /*                             E      */
      *iv_return = IPP_TAG_NOVALUE;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "IPP_JOB_PENDIN", 14)) {
    /*                             G      */
      *iv_return = IPP_JOB_PENDING;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "PPD_BAD_OPEN_U", 14)) {
    /*                             I      */
      *iv_return = PPD_BAD_OPEN_UI;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "CUPS_BACKEND_O", 14)) {
    /*                             K      */
      *iv_return = CUPS_BACKEND_OK;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_IMAGE_CMY", 14)) {
    /*                             K      */
      *iv_return = CUPS_IMAGE_CMYK;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_FIELD_LIN", 14)) {
    /*                             K      */
      *iv_return = HTTP_FIELD_LINK;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "PPD_CUSTOM_REA", 14)) {
    /*                             L      */
      *iv_return = PPD_CUSTOM_REAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "IPP_TAG_BOOLEA", 14)) {
    /*                             N      */
      *iv_return = IPP_TAG_BOOLEAN;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_UNKNOW", 14)) {
    /*                             N      */
      *iv_return = IPP_TAG_UNKNOWN;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "HTTP_MAX_BUFFE", 14)) {
    /*                             R      */
      *iv_return = HTTP_MAX_BUFFER;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_INTEGE", 14)) {
    /*                             R      */
      *iv_return = IPP_TAG_INTEGER;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_PRINTE", 14)) {
    /*                             R      */
      *iv_return = IPP_TAG_PRINTER;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_ALLOC_ERRO", 14)) {
    /*                             R      */
      *iv_return = PPD_ALLOC_ERROR;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "HTTP_FIELD_HOS", 14)) {
    /*                             T      */
      *iv_return = HTTP_FIELD_HOST;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_NO_CONTEN", 14)) {
    /*                             T      */
      *iv_return = HTTP_NO_CONTENT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_BAD_REQUES", 14)) {
    /*                             T      */
      *iv_return = IPP_BAD_REQUEST;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_OK_CONFLIC", 14)) {
    /*                             T      */
      *iv_return = IPP_OK_CONFLICT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_CHARSE", 14)) {
    /*                             T      */
      *iv_return = IPP_TAG_CHARSET;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_DEFAUL", 14)) {
    /*                             T      */
      *iv_return = IPP_TAG_DEFAULT;
      return PERL_constant_ISIV;
    }
    break;
  case 'W':
    if (memEQ(name, "CUPS_PRINTER_B", 14)) {
    /*                             W      */
      *iv_return = CUPS_PRINTER_BW;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "PPD_UI_PICKMAN", 14)) {
    /*                             Y      */
      *iv_return = PPD_UI_PICKMANY;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CUPS_ACCEPT_JOBS CUPS_ADD_PRINTER CUPS_GET_CLASSES CUPS_GET_DEFAULT
     CUPS_GET_DEVICES CUPS_IMAGE_BLACK CUPS_IMAGE_WHITE CUPS_MAX_USTRING
     CUPS_PRINTER_FAX CUPS_REJECT_JOBS CUPS_SET_DEFAULT CUPS_WINDOWS_874
     CUPS_WINDOWS_932 CUPS_WINDOWS_936 CUPS_WINDOWS_949 CUPS_WINDOWS_950
     HTTP_BAD_GATEWAY HTTP_BAD_REQUEST HTTP_FIELD_RANGE HTTP_URI_BAD_URI
     IPP_DEVICE_ERROR IPP_JOB_CANCELED IPP_NOT_POSSIBLE IPP_PRINTER_BUSY
     IPP_PRINTER_IDLE IPP_QUALITY_HIGH IPP_RES_PER_INCH IPP_TAG_LANGUAGE
     IPP_TAG_MIMETYPE IPP_TAG_NAMELANG IPP_TAG_TEXTLANG IPP_VALIDATE_JOB
     PPD_CUSTOM_CURVE PPD_ORDER_PROLOG */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case '8':
    if (memEQ(name, "CUPS_WINDOWS_874", 16)) {
    /*                            ^         */
      *iv_return = CUPS_WINDOWS_874;
      return PERL_constant_ISIV;
    }
    break;
  case '9':
    if (memEQ(name, "CUPS_WINDOWS_932", 16)) {
    /*                            ^         */
      *iv_return = CUPS_WINDOWS_932;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_WINDOWS_936", 16)) {
    /*                            ^         */
      *iv_return = CUPS_WINDOWS_936;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_WINDOWS_949", 16)) {
    /*                            ^         */
      *iv_return = CUPS_WINDOWS_949;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_WINDOWS_950", 16)) {
    /*                            ^         */
      *iv_return = CUPS_WINDOWS_950;
      return PERL_constant_ISIV;
    }
    break;
  case 'A':
    if (memEQ(name, "CUPS_IMAGE_BLACK", 16)) {
    /*                            ^         */
      *iv_return = CUPS_IMAGE_BLACK;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_LANGUAGE", 16)) {
    /*                            ^         */
      *iv_return = IPP_TAG_LANGUAGE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_NAMELANG", 16)) {
    /*                            ^         */
      *iv_return = IPP_TAG_NAMELANG;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_TEXTLANG", 16)) {
    /*                            ^         */
      *iv_return = IPP_TAG_TEXTLANG;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "IPP_NOT_POSSIBLE", 16)) {
    /*                            ^         */
      *iv_return = IPP_NOT_POSSIBLE;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "CUPS_GET_DEVICES", 16)) {
    /*                            ^         */
      *iv_return = CUPS_GET_DEVICES;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "IPP_PRINTER_IDLE", 16)) {
    /*                            ^         */
      *iv_return = IPP_PRINTER_IDLE;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "HTTP_BAD_REQUEST", 16)) {
    /*                            ^         */
      *iv_return = HTTP_BAD_REQUEST;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "CUPS_PRINTER_FAX", 16)) {
    /*                            ^         */
      *iv_return = CUPS_PRINTER_FAX;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "CUPS_IMAGE_WHITE", 16)) {
    /*                            ^         */
      *iv_return = CUPS_IMAGE_WHITE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_MAX_USTRING", 16)) {
    /*                            ^         */
      *iv_return = CUPS_MAX_USTRING;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_QUALITY_HIGH", 16)) {
    /*                            ^         */
      *iv_return = IPP_QUALITY_HIGH;
      return PERL_constant_ISIV;
    }
    break;
  case 'J':
    if (memEQ(name, "IPP_VALIDATE_JOB", 16)) {
    /*                            ^         */
      *iv_return = IPP_VALIDATE_JOB;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "IPP_JOB_CANCELED", 16)) {
    /*                            ^         */
      *iv_return = IPP_JOB_CANCELED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_ORDER_PROLOG", 16)) {
    /*                            ^         */
      *iv_return = PPD_ORDER_PROLOG;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "HTTP_FIELD_RANGE", 16)) {
    /*                            ^         */
      *iv_return = HTTP_FIELD_RANGE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_RES_PER_INCH", 16)) {
    /*                            ^         */
      *iv_return = IPP_RES_PER_INCH;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "CUPS_ACCEPT_JOBS", 16)) {
    /*                            ^         */
      *iv_return = CUPS_ACCEPT_JOBS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_REJECT_JOBS", 16)) {
    /*                            ^         */
      *iv_return = CUPS_REJECT_JOBS;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "IPP_DEVICE_ERROR", 16)) {
    /*                            ^         */
      *iv_return = IPP_DEVICE_ERROR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_CUSTOM_CURVE", 16)) {
    /*                            ^         */
      *iv_return = PPD_CUSTOM_CURVE;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "CUPS_GET_CLASSES", 16)) {
    /*                            ^         */
      *iv_return = CUPS_GET_CLASSES;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "CUPS_ADD_PRINTER", 16)) {
    /*                            ^         */
      *iv_return = CUPS_ADD_PRINTER;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "CUPS_GET_DEFAULT", 16)) {
    /*                            ^         */
      *iv_return = CUPS_GET_DEFAULT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_SET_DEFAULT", 16)) {
    /*                            ^         */
      *iv_return = CUPS_SET_DEFAULT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_URI_BAD_URI", 16)) {
    /*                            ^         */
      *iv_return = HTTP_URI_BAD_URI;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_PRINTER_BUSY", 16)) {
    /*                            ^         */
      *iv_return = IPP_PRINTER_BUSY;
      return PERL_constant_ISIV;
    }
    break;
  case 'W':
    if (memEQ(name, "HTTP_BAD_GATEWAY", 16)) {
    /*                            ^         */
      *iv_return = HTTP_BAD_GATEWAY;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "IPP_TAG_MIMETYPE", 16)) {
    /*                            ^         */
      *iv_return = IPP_TAG_MIMETYPE;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CUPS_BACKEND_HOLD CUPS_BACKEND_STOP CUPS_DELETE_CLASS CUPS_GET_PRINTERS
     CUPS_PRINTER_BIND CUPS_PRINTER_SORT CUPS_WINDOWS_1250 CUPS_WINDOWS_1251
     CUPS_WINDOWS_1252 CUPS_WINDOWS_1253 CUPS_WINDOWS_1254 CUPS_WINDOWS_1255
     CUPS_WINDOWS_1256 CUPS_WINDOWS_1257 CUPS_WINDOWS_1258 CUPS_WINDOWS_1361
     HTTP_AUTH_MD5_INT HTTP_KEEPALIVE_ON HTTP_NOT_MODIFIED HTTP_PRECONDITION
     HTTP_SERVER_ERROR HTTP_UNAUTHORIZED HTTP_URI_BAD_PORT HTTP_URI_OVERFLOW
     HTTP_URI_TOO_LONG IPP_HOLD_NEW_JOBS IPP_JOB_CANCELLED IPP_JOB_COMPLETED
     IPP_NOT_ACCEPTING IPP_PAUSE_PRINTER IPP_QUALITY_DRAFT IPP_REPROCESS_JOB
     IPP_REQUEST_VALUE IPP_SEND_DOCUMENT IPP_TAG_OPERATION IPP_TAG_URISCHEME
     PPD_CUSTOM_POINTS PPD_CUSTOM_STRING PPD_LINE_TOO_LONG PPD_MISSING_VALUE */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case '0':
    if (memEQ(name, "CUPS_WINDOWS_125", 16)) {
    /*                               0      */
      *iv_return = CUPS_WINDOWS_1250;
      return PERL_constant_ISIV;
    }
    break;
  case '1':
    if (memEQ(name, "CUPS_WINDOWS_125", 16)) {
    /*                               1      */
      *iv_return = CUPS_WINDOWS_1251;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_WINDOWS_136", 16)) {
    /*                               1      */
      *iv_return = CUPS_WINDOWS_1361;
      return PERL_constant_ISIV;
    }
    break;
  case '2':
    if (memEQ(name, "CUPS_WINDOWS_125", 16)) {
    /*                               2      */
      *iv_return = CUPS_WINDOWS_1252;
      return PERL_constant_ISIV;
    }
    break;
  case '3':
    if (memEQ(name, "CUPS_WINDOWS_125", 16)) {
    /*                               3      */
      *iv_return = CUPS_WINDOWS_1253;
      return PERL_constant_ISIV;
    }
    break;
  case '4':
    if (memEQ(name, "CUPS_WINDOWS_125", 16)) {
    /*                               4      */
      *iv_return = CUPS_WINDOWS_1254;
      return PERL_constant_ISIV;
    }
    break;
  case '5':
    if (memEQ(name, "CUPS_WINDOWS_125", 16)) {
    /*                               5      */
      *iv_return = CUPS_WINDOWS_1255;
      return PERL_constant_ISIV;
    }
    break;
  case '6':
    if (memEQ(name, "CUPS_WINDOWS_125", 16)) {
    /*                               6      */
      *iv_return = CUPS_WINDOWS_1256;
      return PERL_constant_ISIV;
    }
    break;
  case '7':
    if (memEQ(name, "CUPS_WINDOWS_125", 16)) {
    /*                               7      */
      *iv_return = CUPS_WINDOWS_1257;
      return PERL_constant_ISIV;
    }
    break;
  case '8':
    if (memEQ(name, "CUPS_WINDOWS_125", 16)) {
    /*                               8      */
      *iv_return = CUPS_WINDOWS_1258;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "IPP_REPROCESS_JO", 16)) {
    /*                               B      */
      *iv_return = IPP_REPROCESS_JOB;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "CUPS_BACKEND_HOL", 16)) {
    /*                               D      */
      *iv_return = CUPS_BACKEND_HOLD;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_PRINTER_BIN", 16)) {
    /*                               D      */
      *iv_return = CUPS_PRINTER_BIND;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_NOT_MODIFIE", 16)) {
    /*                               D      */
      *iv_return = HTTP_NOT_MODIFIED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_UNAUTHORIZE", 16)) {
    /*                               D      */
      *iv_return = HTTP_UNAUTHORIZED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_JOB_CANCELLE", 16)) {
    /*                               D      */
      *iv_return = IPP_JOB_CANCELLED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_JOB_COMPLETE", 16)) {
    /*                               D      */
      *iv_return = IPP_JOB_COMPLETED;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "IPP_REQUEST_VALU", 16)) {
    /*                               E      */
      *iv_return = IPP_REQUEST_VALUE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_URISCHEM", 16)) {
    /*                               E      */
      *iv_return = IPP_TAG_URISCHEME;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_MISSING_VALU", 16)) {
    /*                               E      */
      *iv_return = PPD_MISSING_VALUE;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "HTTP_URI_TOO_LON", 16)) {
    /*                               G      */
      *iv_return = HTTP_URI_TOO_LONG;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_NOT_ACCEPTIN", 16)) {
    /*                               G      */
      *iv_return = IPP_NOT_ACCEPTING;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_CUSTOM_STRIN", 16)) {
    /*                               G      */
      *iv_return = PPD_CUSTOM_STRING;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_LINE_TOO_LON", 16)) {
    /*                               G      */
      *iv_return = PPD_LINE_TOO_LONG;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "HTTP_KEEPALIVE_O", 16)) {
    /*                               N      */
      *iv_return = HTTP_KEEPALIVE_ON;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_PRECONDITIO", 16)) {
    /*                               N      */
      *iv_return = HTTP_PRECONDITION;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_OPERATIO", 16)) {
    /*                               N      */
      *iv_return = IPP_TAG_OPERATION;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "CUPS_BACKEND_STO", 16)) {
    /*                               P      */
      *iv_return = CUPS_BACKEND_STOP;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "HTTP_SERVER_ERRO", 16)) {
    /*                               R      */
      *iv_return = HTTP_SERVER_ERROR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_PAUSE_PRINTE", 16)) {
    /*                               R      */
      *iv_return = IPP_PAUSE_PRINTER;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "CUPS_DELETE_CLAS", 16)) {
    /*                               S      */
      *iv_return = CUPS_DELETE_CLASS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_GET_PRINTER", 16)) {
    /*                               S      */
      *iv_return = CUPS_GET_PRINTERS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_HOLD_NEW_JOB", 16)) {
    /*                               S      */
      *iv_return = IPP_HOLD_NEW_JOBS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_CUSTOM_POINT", 16)) {
    /*                               S      */
      *iv_return = PPD_CUSTOM_POINTS;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "CUPS_PRINTER_SOR", 16)) {
    /*                               T      */
      *iv_return = CUPS_PRINTER_SORT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_AUTH_MD5_IN", 16)) {
    /*                               T      */
      *iv_return = HTTP_AUTH_MD5_INT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_URI_BAD_POR", 16)) {
    /*                               T      */
      *iv_return = HTTP_URI_BAD_PORT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_QUALITY_DRAF", 16)) {
    /*                               T      */
      *iv_return = IPP_QUALITY_DRAFT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_SEND_DOCUMEN", 16)) {
    /*                               T      */
      *iv_return = IPP_SEND_DOCUMENT;
      return PERL_constant_ISIV;
    }
    break;
  case 'W':
    if (memEQ(name, "HTTP_URI_OVERFLO", 16)) {
    /*                               W      */
      *iv_return = HTTP_URI_OVERFLOW;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CUPS_AUTO_ENCODING CUPS_PRINTER_CLASS CUPS_PRINTER_COLOR
     CUPS_PRINTER_COVER CUPS_PRINTER_LARGE CUPS_PRINTER_LOCAL
     CUPS_PRINTER_PUNCH CUPS_PRINTER_SMALL CUPS_VERSION_MAJOR
     CUPS_VERSION_MINOR CUPS_VERSION_PATCH HTTP_AUTH_MD5_SESS
     HTTP_ENCODE_FIELDS HTTP_ENCODE_LENGTH HTTP_ENCRYPT_NEVER
     HTTP_FIELD_REFERER HTTP_FIELD_UNKNOWN HTTP_FIELD_UPGRADE
     HTTP_KEEPALIVE_OFF HTTP_NOT_SUPPORTED HTTP_RESET_CONTENT
     IPP_ENABLE_PRINTER IPP_INTERNAL_ERROR IPP_JOB_PROCESSING
     IPP_NOT_AUTHORIZED IPP_QUALITY_NORMAL IPP_REQUEST_ENTITY
     IPP_RESUME_PRINTER IPP_TAG_DELETEATTR IPP_TAG_MEMBERNAME
     IPP_TAG_RESOLUTION PPD_BAD_OPEN_GROUP PPD_CONFORM_STRICT
     PPD_INTERNAL_ERROR PPD_NESTED_OPEN_UI PPD_ORDER_DOCUMENT */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'C':
    if (memEQ(name, "CUPS_PRINTER_CLASS", 18)) {
    /*                            ^           */
      *iv_return = CUPS_PRINTER_CLASS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_PRINTER_COLOR", 18)) {
    /*                            ^           */
      *iv_return = CUPS_PRINTER_COLOR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_PRINTER_COVER", 18)) {
    /*                            ^           */
      *iv_return = CUPS_PRINTER_COVER;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "HTTP_ENCODE_LENGTH", 18)) {
    /*                            ^           */
      *iv_return = HTTP_ENCODE_LENGTH;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_KEEPALIVE_OFF", 18)) {
    /*                            ^           */
      *iv_return = HTTP_KEEPALIVE_OFF;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_INTERNAL_ERROR", 18)) {
    /*                            ^           */
      *iv_return = IPP_INTERNAL_ERROR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_DELETEATTR", 18)) {
    /*                            ^           */
      *iv_return = IPP_TAG_DELETEATTR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_INTERNAL_ERROR", 18)) {
    /*                            ^           */
      *iv_return = PPD_INTERNAL_ERROR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_NESTED_OPEN_UI", 18)) {
    /*                            ^           */
      *iv_return = PPD_NESTED_OPEN_UI;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "HTTP_FIELD_REFERER", 18)) {
    /*                            ^           */
      *iv_return = HTTP_FIELD_REFERER;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "HTTP_FIELD_UPGRADE", 18)) {
    /*                            ^           */
      *iv_return = HTTP_FIELD_UPGRADE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_BAD_OPEN_GROUP", 18)) {
    /*                            ^           */
      *iv_return = PPD_BAD_OPEN_GROUP;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "HTTP_ENCODE_FIELDS", 18)) {
    /*                            ^           */
      *iv_return = HTTP_ENCODE_FIELDS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_ENABLE_PRINTER", 18)) {
    /*                            ^           */
      *iv_return = IPP_ENABLE_PRINTER;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_RESUME_PRINTER", 18)) {
    /*                            ^           */
      *iv_return = IPP_RESUME_PRINTER;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "HTTP_FIELD_UNKNOWN", 18)) {
    /*                            ^           */
      *iv_return = HTTP_FIELD_UNKNOWN;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "CUPS_PRINTER_LARGE", 18)) {
    /*                            ^           */
      *iv_return = CUPS_PRINTER_LARGE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_PRINTER_LOCAL", 18)) {
    /*                            ^           */
      *iv_return = CUPS_PRINTER_LOCAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "CUPS_VERSION_MAJOR", 18)) {
    /*                            ^           */
      *iv_return = CUPS_VERSION_MAJOR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_VERSION_MINOR", 18)) {
    /*                            ^           */
      *iv_return = CUPS_VERSION_MINOR;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "HTTP_ENCRYPT_NEVER", 18)) {
    /*                            ^           */
      *iv_return = HTTP_ENCRYPT_NEVER;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_RESET_CONTENT", 18)) {
    /*                            ^           */
      *iv_return = HTTP_RESET_CONTENT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_REQUEST_ENTITY", 18)) {
    /*                            ^           */
      *iv_return = IPP_REQUEST_ENTITY;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "CUPS_AUTO_ENCODING", 18)) {
    /*                            ^           */
      *iv_return = CUPS_AUTO_ENCODING;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_NOT_SUPPORTED", 18)) {
    /*                            ^           */
      *iv_return = HTTP_NOT_SUPPORTED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_QUALITY_NORMAL", 18)) {
    /*                            ^           */
      *iv_return = IPP_QUALITY_NORMAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "CUPS_PRINTER_PUNCH", 18)) {
    /*                            ^           */
      *iv_return = CUPS_PRINTER_PUNCH;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_VERSION_PATCH", 18)) {
    /*                            ^           */
      *iv_return = CUPS_VERSION_PATCH;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "IPP_NOT_AUTHORIZED", 18)) {
    /*                            ^           */
      *iv_return = IPP_NOT_AUTHORIZED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_MEMBERNAME", 18)) {
    /*                            ^           */
      *iv_return = IPP_TAG_MEMBERNAME;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "CUPS_PRINTER_SMALL", 18)) {
    /*                            ^           */
      *iv_return = CUPS_PRINTER_SMALL;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_JOB_PROCESSING", 18)) {
    /*                            ^           */
      *iv_return = IPP_JOB_PROCESSING;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "PPD_CONFORM_STRICT", 18)) {
    /*                            ^           */
      *iv_return = PPD_CONFORM_STRICT;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "IPP_TAG_RESOLUTION", 18)) {
    /*                            ^           */
      *iv_return = IPP_TAG_RESOLUTION;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_ORDER_DOCUMENT", 18)) {
    /*                            ^           */
      *iv_return = PPD_ORDER_DOCUMENT;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "HTTP_AUTH_MD5_SESS", 18)) {
    /*                            ^           */
      *iv_return = HTTP_AUTH_MD5_SESS;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_19 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CUPS_BACKEND_CANCEL CUPS_BACKEND_FAILED CUPS_DELETE_PRINTER
     CUPS_IMAGE_RGB_CMYK CUPS_PRINTER_COPIES CUPS_PRINTER_DELETE
     CUPS_PRINTER_DUPLEX CUPS_PRINTER_MEDIUM CUPS_PRINTER_REMOTE
     CUPS_PRINTER_STAPLE HTTP_ENCODE_CHUNKED HTTP_ENCRYPT_ALWAYS
     HTTP_FIELD_LOCATION HTTP_NOT_ACCEPTABLE HTTP_URI_BAD_SCHEME
     HTTP_URI_CODING_ALL IPP_DISABLE_PRINTER IPP_DOCUMENT_FORMAT
     IPP_FINISHINGS_BALE IPP_FINISHINGS_BIND IPP_FINISHINGS_FOLD
     IPP_FINISHINGS_NONE IPP_FINISHINGS_TRIM IPP_PRINTER_STOPPED
     IPP_RESTART_PRINTER IPP_STARTUP_PRINTER IPP_TAG_ADMINDEFINE
     IPP_TAG_NOTSETTABLE IPP_TEMPORARY_ERROR PPD_CONFORM_RELAXED
     PPD_CUSTOM_INVCURVE PPD_CUSTOM_PASSCODE PPD_CUSTOM_PASSWORD
     PPD_FILE_OPEN_ERROR */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'A':
    if (memEQ(name, "CUPS_PRINTER_STAPLE", 19)) {
    /*                              ^          */
      *iv_return = CUPS_PRINTER_STAPLE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_NOT_ACCEPTABLE", 19)) {
    /*                              ^          */
      *iv_return = HTTP_NOT_ACCEPTABLE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_NOTSETTABLE", 19)) {
    /*                              ^          */
      *iv_return = IPP_TAG_NOTSETTABLE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_CONFORM_RELAXED", 19)) {
    /*                              ^          */
      *iv_return = PPD_CONFORM_RELAXED;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "IPP_FINISHINGS_BALE", 19)) {
    /*                              ^          */
      *iv_return = IPP_FINISHINGS_BALE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_FINISHINGS_BIND", 19)) {
    /*                              ^          */
      *iv_return = IPP_FINISHINGS_BIND;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "CUPS_IMAGE_RGB_CMYK", 19)) {
    /*                              ^          */
      *iv_return = CUPS_IMAGE_RGB_CMYK;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_CUSTOM_PASSCODE", 19)) {
    /*                              ^          */
      *iv_return = PPD_CUSTOM_PASSCODE;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "CUPS_PRINTER_MEDIUM", 19)) {
    /*                              ^          */
      *iv_return = CUPS_PRINTER_MEDIUM;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "IPP_FINISHINGS_FOLD", 19)) {
    /*                              ^          */
      *iv_return = IPP_FINISHINGS_FOLD;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_ADMINDEFINE", 19)) {
    /*                              ^          */
      *iv_return = IPP_TAG_ADMINDEFINE;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "HTTP_URI_BAD_SCHEME", 19)) {
    /*                              ^          */
      *iv_return = HTTP_URI_BAD_SCHEME;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "CUPS_BACKEND_FAILED", 19)) {
    /*                              ^          */
      *iv_return = CUPS_BACKEND_FAILED;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "CUPS_PRINTER_DELETE", 19)) {
    /*                              ^          */
      *iv_return = CUPS_PRINTER_DELETE;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "CUPS_PRINTER_REMOTE", 19)) {
    /*                              ^          */
      *iv_return = CUPS_PRINTER_REMOTE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "CUPS_BACKEND_CANCEL", 19)) {
    /*                              ^          */
      *iv_return = CUPS_BACKEND_CANCEL;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_DELETE_PRINTER", 19)) {
    /*                              ^          */
      *iv_return = CUPS_DELETE_PRINTER;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_ENCODE_CHUNKED", 19)) {
    /*                              ^          */
      *iv_return = HTTP_ENCODE_CHUNKED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_DISABLE_PRINTER", 19)) {
    /*                              ^          */
      *iv_return = IPP_DISABLE_PRINTER;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_FINISHINGS_NONE", 19)) {
    /*                              ^          */
      *iv_return = IPP_FINISHINGS_NONE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_RESTART_PRINTER", 19)) {
    /*                              ^          */
      *iv_return = IPP_RESTART_PRINTER;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_STARTUP_PRINTER", 19)) {
    /*                              ^          */
      *iv_return = IPP_STARTUP_PRINTER;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "CUPS_PRINTER_COPIES", 19)) {
    /*                              ^          */
      *iv_return = CUPS_PRINTER_COPIES;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_PRINTER_DUPLEX", 19)) {
    /*                              ^          */
      *iv_return = CUPS_PRINTER_DUPLEX;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_PRINTER_STOPPED", 19)) {
    /*                              ^          */
      *iv_return = IPP_PRINTER_STOPPED;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "IPP_DOCUMENT_FORMAT", 19)) {
    /*                              ^          */
      *iv_return = IPP_DOCUMENT_FORMAT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TEMPORARY_ERROR", 19)) {
    /*                              ^          */
      *iv_return = IPP_TEMPORARY_ERROR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_FILE_OPEN_ERROR", 19)) {
    /*                              ^          */
      *iv_return = PPD_FILE_OPEN_ERROR;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "HTTP_FIELD_LOCATION", 19)) {
    /*                              ^          */
      *iv_return = HTTP_FIELD_LOCATION;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_FINISHINGS_TRIM", 19)) {
    /*                              ^          */
      *iv_return = IPP_FINISHINGS_TRIM;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "PPD_CUSTOM_INVCURVE", 19)) {
    /*                              ^          */
      *iv_return = PPD_CUSTOM_INVCURVE;
      return PERL_constant_ISIV;
    }
    break;
  case 'W':
    if (memEQ(name, "HTTP_ENCRYPT_ALWAYS", 19)) {
    /*                              ^          */
      *iv_return = HTTP_ENCRYPT_ALWAYS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_CUSTOM_PASSWORD", 19)) {
    /*                              ^          */
      *iv_return = PPD_CUSTOM_PASSWORD;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "HTTP_URI_CODING_ALL", 19)) {
    /*                              ^          */
      *iv_return = HTTP_URI_CODING_ALL;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_20 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CUPS_PRINTER_COLLATE CUPS_PRINTER_DEFAULT CUPS_PRINTER_OPTIONS
     HTTP_GATEWAY_TIMEOUT HTTP_LENGTH_REQUIRED HTTP_NOT_IMPLEMENTED
     HTTP_PARTIAL_CONTENT HTTP_REQUESTED_RANGE HTTP_REQUEST_TIMEOUT
     HTTP_URI_CODING_MOST HTTP_URI_CODING_NONE IPP_ACTIVATE_PRINTER
     IPP_FINISHINGS_COVER IPP_FINISHINGS_PUNCH IPP_REVERSE_PORTRAIT
     IPP_SHUTDOWN_PRINTER IPP_TAG_SUBSCRIPTION PPD_BAD_CUSTOM_PARAM
     PPD_MISSING_ASTERISK */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'C':
    if (memEQ(name, "IPP_FINISHINGS_COVER", 20)) {
    /*                              ^           */
      *iv_return = IPP_FINISHINGS_COVER;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "HTTP_NOT_IMPLEMENTED", 20)) {
    /*                              ^           */
      *iv_return = HTTP_NOT_IMPLEMENTED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_MISSING_ASTERISK", 20)) {
    /*                              ^           */
      *iv_return = PPD_MISSING_ASTERISK;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "CUPS_PRINTER_DEFAULT", 20)) {
    /*                              ^           */
      *iv_return = CUPS_PRINTER_DEFAULT;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "IPP_ACTIVATE_PRINTER", 20)) {
    /*                              ^           */
      *iv_return = IPP_ACTIVATE_PRINTER;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_SHUTDOWN_PRINTER", 20)) {
    /*                              ^           */
      *iv_return = IPP_SHUTDOWN_PRINTER;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "CUPS_PRINTER_COLLATE", 20)) {
    /*                              ^           */
      *iv_return = CUPS_PRINTER_COLLATE;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "HTTP_GATEWAY_TIMEOUT", 20)) {
    /*                              ^           */
      *iv_return = HTTP_GATEWAY_TIMEOUT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_REQUEST_TIMEOUT", 20)) {
    /*                              ^           */
      *iv_return = HTTP_REQUEST_TIMEOUT;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "HTTP_PARTIAL_CONTENT", 20)) {
    /*                              ^           */
      *iv_return = HTTP_PARTIAL_CONTENT;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "IPP_FINISHINGS_PUNCH", 20)) {
    /*                              ^           */
      *iv_return = IPP_FINISHINGS_PUNCH;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_SUBSCRIPTION", 20)) {
    /*                              ^           */
      *iv_return = IPP_TAG_SUBSCRIPTION;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_BAD_CUSTOM_PARAM", 20)) {
    /*                              ^           */
      *iv_return = PPD_BAD_CUSTOM_PARAM;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "HTTP_REQUESTED_RANGE", 20)) {
    /*                              ^           */
      *iv_return = HTTP_REQUESTED_RANGE;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "CUPS_PRINTER_OPTIONS", 20)) {
    /*                              ^           */
      *iv_return = CUPS_PRINTER_OPTIONS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_REVERSE_PORTRAIT", 20)) {
    /*                              ^           */
      *iv_return = IPP_REVERSE_PORTRAIT;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "HTTP_LENGTH_REQUIRED", 20)) {
    /*                              ^           */
      *iv_return = HTTP_LENGTH_REQUIRED;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "HTTP_URI_CODING_MOST", 20)) {
    /*                              ^           */
      *iv_return = HTTP_URI_CODING_MOST;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_URI_CODING_NONE", 20)) {
    /*                              ^           */
      *iv_return = HTTP_URI_CODING_NONE;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_21 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CUPS_ADD_MODIFY_CLASS CUPS_AUTHENTICATE_JOB CUPS_PRINTER_COMMANDS
     CUPS_PRINTER_IMPLICIT CUPS_PRINTER_VARIABLE HTTP_ENCRYPT_REQUIRED
     HTTP_FIELD_CONNECTION HTTP_FIELD_KEEP_ALIVE HTTP_FIELD_USER_AGENT
     HTTP_MULTIPLE_CHOICES HTTP_PAYMENT_REQUIRED HTTP_UPGRADE_REQUIRED
     HTTP_URI_BAD_HOSTNAME HTTP_URI_BAD_RESOURCE HTTP_URI_BAD_USERNAME
     HTTP_URI_CODING_QUERY IPP_COMPRESSION_ERROR IPP_FINISHINGS_STAPLE
     IPP_GET_NOTIFICATIONS IPP_GET_SUBSCRIPTIONS IPP_NOT_AUTHENTICATED
     IPP_REVERSE_LANDSCAPE PPD_ILLEGAL_CHARACTER PPD_MISSING_PPDADOBE4
     PPD_NESTED_OPEN_GROUP */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'A':
    if (memEQ(name, "CUPS_AUTHENTICATE_JOB", 21)) {
    /*                             ^             */
      *iv_return = CUPS_AUTHENTICATE_JOB;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_PRINTER_VARIABLE", 21)) {
    /*                             ^             */
      *iv_return = CUPS_PRINTER_VARIABLE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_ILLEGAL_CHARACTER", 21)) {
    /*                             ^             */
      *iv_return = PPD_ILLEGAL_CHARACTER;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "HTTP_MULTIPLE_CHOICES", 21)) {
    /*                             ^             */
      *iv_return = HTTP_MULTIPLE_CHOICES;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_GET_NOTIFICATIONS", 21)) {
    /*                             ^             */
      *iv_return = IPP_GET_NOTIFICATIONS;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "PPD_MISSING_PPDADOBE4", 21)) {
    /*                             ^             */
      *iv_return = PPD_MISSING_PPDADOBE4;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "HTTP_ENCRYPT_REQUIRED", 21)) {
    /*                             ^             */
      *iv_return = HTTP_ENCRYPT_REQUIRED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_PAYMENT_REQUIRED", 21)) {
    /*                             ^             */
      *iv_return = HTTP_PAYMENT_REQUIRED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_UPGRADE_REQUIRED", 21)) {
    /*                             ^             */
      *iv_return = HTTP_UPGRADE_REQUIRED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_URI_BAD_RESOURCE", 21)) {
    /*                             ^             */
      *iv_return = HTTP_URI_BAD_RESOURCE;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "HTTP_URI_CODING_QUERY", 21)) {
    /*                             ^             */
      *iv_return = HTTP_URI_CODING_QUERY;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "IPP_GET_SUBSCRIPTIONS", 21)) {
    /*                             ^             */
      *iv_return = IPP_GET_SUBSCRIPTIONS;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "CUPS_PRINTER_IMPLICIT", 21)) {
    /*                             ^             */
      *iv_return = CUPS_PRINTER_IMPLICIT;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "HTTP_FIELD_CONNECTION", 21)) {
    /*                             ^             */
      *iv_return = HTTP_FIELD_CONNECTION;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_COMPRESSION_ERROR", 21)) {
    /*                             ^             */
      *iv_return = IPP_COMPRESSION_ERROR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_REVERSE_LANDSCAPE", 21)) {
    /*                             ^             */
      *iv_return = IPP_REVERSE_LANDSCAPE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_NESTED_OPEN_GROUP", 21)) {
    /*                             ^             */
      *iv_return = PPD_NESTED_OPEN_GROUP;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "CUPS_PRINTER_COMMANDS", 21)) {
    /*                             ^             */
      *iv_return = CUPS_PRINTER_COMMANDS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_URI_BAD_HOSTNAME", 21)) {
    /*                             ^             */
      *iv_return = HTTP_URI_BAD_HOSTNAME;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "HTTP_FIELD_KEEP_ALIVE", 21)) {
    /*                             ^             */
      *iv_return = HTTP_FIELD_KEEP_ALIVE;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "HTTP_FIELD_USER_AGENT", 21)) {
    /*                             ^             */
      *iv_return = HTTP_FIELD_USER_AGENT;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "HTTP_URI_BAD_USERNAME", 21)) {
    /*                             ^             */
      *iv_return = HTTP_URI_BAD_USERNAME;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "IPP_NOT_AUTHENTICATED", 21)) {
    /*                             ^             */
      *iv_return = IPP_NOT_AUTHENTICATED;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "CUPS_ADD_MODIFY_CLASS", 21)) {
    /*                             ^             */
      *iv_return = CUPS_ADD_MODIFY_CLASS;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "IPP_FINISHINGS_STAPLE", 21)) {
    /*                             ^             */
      *iv_return = IPP_FINISHINGS_STAPLE;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_22 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CUPS_ENCODING_DBCS_END CUPS_ENCODING_SBCS_END CUPS_ENCODING_VBCS_END
     CUPS_PRINTER_REJECTING HTTP_AUTH_MD5_SESS_INT HTTP_FIELD_CONTENT_MD5
     HTTP_FIELD_RETRY_AFTER HTTP_MOVED_PERMANENTLY HTTP_MOVED_TEMPORARILY
     HTTP_NOT_AUTHORITATIVE HTTP_REQUEST_TOO_LARGE HTTP_URI_BAD_ARGUMENTS
     IPP_CANCEL_CURRENT_JOB IPP_DEACTIVATE_PRINTER IPP_ERROR_JOB_CANCELED
     IPP_GET_JOB_ATTRIBUTES IPP_OK_EVENTS_COMPLETE IPP_OK_TOO_MANY_EVENTS
     IPP_PRINTER_PROCESSING IPP_RENEW_SUBSCRIPTION IPP_SCHEDULE_JOB_AFTER
     IPP_SEND_NOTIFICATIONS IPP_SET_JOB_ATTRIBUTES IPP_TAG_END_COLLECTION
     PPD_BAD_UI_CONSTRAINTS PPD_ILLEGAL_WHITESPACE */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case '5':
    if (memEQ(name, "HTTP_AUTH_MD5_SESS_INT", 22)) {
    /*                           ^                */
      *iv_return = HTTP_AUTH_MD5_SESS_INT;
      return PERL_constant_ISIV;
    }
    break;
  case 'A':
    if (memEQ(name, "IPP_GET_JOB_ATTRIBUTES", 22)) {
    /*                           ^                */
      *iv_return = IPP_GET_JOB_ATTRIBUTES;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_OK_TOO_MANY_EVENTS", 22)) {
    /*                           ^                */
      *iv_return = IPP_OK_TOO_MANY_EVENTS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_SET_JOB_ATTRIBUTES", 22)) {
    /*                           ^                */
      *iv_return = IPP_SET_JOB_ATTRIBUTES;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "IPP_ERROR_JOB_CANCELED", 22)) {
    /*                           ^                */
      *iv_return = IPP_ERROR_JOB_CANCELED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_RENEW_SUBSCRIPTION", 22)) {
    /*                           ^                */
      *iv_return = IPP_RENEW_SUBSCRIPTION;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "IPP_TAG_END_COLLECTION", 22)) {
    /*                           ^                */
      *iv_return = IPP_TAG_END_COLLECTION;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "HTTP_FIELD_RETRY_AFTER", 22)) {
    /*                           ^                */
      *iv_return = HTTP_FIELD_RETRY_AFTER;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_MOVED_PERMANENTLY", 22)) {
    /*                           ^                */
      *iv_return = HTTP_MOVED_PERMANENTLY;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_MOVED_TEMPORARILY", 22)) {
    /*                           ^                */
      *iv_return = HTTP_MOVED_TEMPORARILY;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "CUPS_ENCODING_DBCS_END", 22)) {
    /*                           ^                */
      *iv_return = CUPS_ENCODING_DBCS_END;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_ENCODING_SBCS_END", 22)) {
    /*                           ^                */
      *iv_return = CUPS_ENCODING_SBCS_END;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "CUPS_ENCODING_VBCS_END", 22)) {
    /*                           ^                */
      *iv_return = CUPS_ENCODING_VBCS_END;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "HTTP_NOT_AUTHORITATIVE", 22)) {
    /*                           ^                */
      *iv_return = HTTP_NOT_AUTHORITATIVE;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "IPP_SEND_NOTIFICATIONS", 22)) {
    /*                           ^                */
      *iv_return = IPP_SEND_NOTIFICATIONS;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "HTTP_FIELD_CONTENT_MD5", 22)) {
    /*                           ^                */
      *iv_return = HTTP_FIELD_CONTENT_MD5;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "PPD_BAD_UI_CONSTRAINTS", 22)) {
    /*                           ^                */
      *iv_return = PPD_BAD_UI_CONSTRAINTS;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "IPP_PRINTER_PROCESSING", 22)) {
    /*                           ^                */
      *iv_return = IPP_PRINTER_PROCESSING;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "IPP_OK_EVENTS_COMPLETE", 22)) {
    /*                           ^                */
      *iv_return = IPP_OK_EVENTS_COMPLETE;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "IPP_DEACTIVATE_PRINTER", 22)) {
    /*                           ^                */
      *iv_return = IPP_DEACTIVATE_PRINTER;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "IPP_CANCEL_CURRENT_JOB", 22)) {
    /*                           ^                */
      *iv_return = IPP_CANCEL_CURRENT_JOB;
      return PERL_constant_ISIV;
    }
    break;
  case 'W':
    if (memEQ(name, "PPD_ILLEGAL_WHITESPACE", 22)) {
    /*                           ^                */
      *iv_return = PPD_ILLEGAL_WHITESPACE;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "CUPS_PRINTER_REJECTING", 22)) {
    /*                           ^                */
      *iv_return = CUPS_PRINTER_REJECTING;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_REQUEST_TOO_LARGE", 22)) {
    /*                           ^                */
      *iv_return = HTTP_REQUEST_TOO_LARGE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_URI_BAD_ARGUMENTS", 22)) {
    /*                           ^                */
      *iv_return = HTTP_URI_BAD_ARGUMENTS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_SCHEDULE_JOB_AFTER", 22)) {
    /*                           ^                */
      *iv_return = IPP_SCHEDULE_JOB_AFTER;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_23 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CUPS_ADD_MODIFY_PRINTER CUPS_PRINTER_NOT_SHARED HTTP_EXPECTATION_FAILED
     HTTP_FIELD_CONTENT_TYPE HTTP_METHOD_NOT_ALLOWED HTTP_URI_MISSING_SCHEME
     HTTP_URI_UNKNOWN_SCHEME IPP_CANCEL_SUBSCRIPTION IPP_ERROR_JOB_CANCELLED
     IPP_FINISHINGS_BIND_TOP IPP_SERVICE_UNAVAILABLE IPP_SUSPEND_CURRENT_JOB
     PPD_ILLEGAL_TRANSLATION */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'A':
    if (memEQ(name, "PPD_ILLEGAL_TRANSLATION", 23)) {
    /*                        ^                    */
      *iv_return = PPD_ILLEGAL_TRANSLATION;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "HTTP_EXPECTATION_FAILED", 23)) {
    /*                        ^                    */
      *iv_return = HTTP_EXPECTATION_FAILED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_SERVICE_UNAVAILABLE", 23)) {
    /*                        ^                    */
      *iv_return = IPP_SERVICE_UNAVAILABLE;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "HTTP_FIELD_CONTENT_TYPE", 23)) {
    /*                        ^                    */
      *iv_return = HTTP_FIELD_CONTENT_TYPE;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "IPP_FINISHINGS_BIND_TOP", 23)) {
    /*                        ^                    */
      *iv_return = IPP_FINISHINGS_BIND_TOP;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "IPP_CANCEL_SUBSCRIPTION", 23)) {
    /*                        ^                    */
      *iv_return = IPP_CANCEL_SUBSCRIPTION;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "CUPS_ADD_MODIFY_PRINTER", 23)) {
    /*                        ^                    */
      *iv_return = CUPS_ADD_MODIFY_PRINTER;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_URI_MISSING_SCHEME", 23)) {
    /*                        ^                    */
      *iv_return = HTTP_URI_MISSING_SCHEME;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "IPP_SUSPEND_CURRENT_JOB", 23)) {
    /*                        ^                    */
      *iv_return = IPP_SUSPEND_CURRENT_JOB;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "HTTP_METHOD_NOT_ALLOWED", 23)) {
    /*                        ^                    */
      *iv_return = HTTP_METHOD_NOT_ALLOWED;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "CUPS_PRINTER_NOT_SHARED", 23)) {
    /*                        ^                    */
      *iv_return = CUPS_PRINTER_NOT_SHARED;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "HTTP_URI_UNKNOWN_SCHEME", 23)) {
    /*                        ^                    */
      *iv_return = HTTP_URI_UNKNOWN_SCHEME;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "IPP_ERROR_JOB_CANCELLED", 23)) {
    /*                        ^                    */
      *iv_return = IPP_ERROR_JOB_CANCELLED;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_24 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     HTTP_FIELD_ACCEPT_RANGES HTTP_FIELD_AUTHORIZATION HTTP_FIELD_CONTENT_RANGE
     HTTP_FIELD_LAST_MODIFIED HTTP_SERVICE_UNAVAILABLE HTTP_SWITCHING_PROTOCOLS
     HTTP_URI_CODING_HOSTNAME HTTP_URI_CODING_RESOURCE HTTP_URI_CODING_USERNAME
     IPP_FINISHINGS_BIND_LEFT IPP_TAG_BEGIN_COLLECTION PPD_BAD_ORDER_DEPENDENCY
     PPD_ILLEGAL_MAIN_KEYWORD */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'H':
    if (memEQ(name, "HTTP_URI_CODING_HOSTNAME", 24)) {
    /*                               ^              */
      *iv_return = HTTP_URI_CODING_HOSTNAME;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "IPP_FINISHINGS_BIND_LEFT", 24)) {
    /*                               ^              */
      *iv_return = IPP_FINISHINGS_BIND_LEFT;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "IPP_TAG_BEGIN_COLLECTION", 24)) {
    /*                               ^              */
      *iv_return = IPP_TAG_BEGIN_COLLECTION;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "HTTP_FIELD_LAST_MODIFIED", 24)) {
    /*                               ^              */
      *iv_return = HTTP_FIELD_LAST_MODIFIED;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "HTTP_FIELD_CONTENT_RANGE", 24)) {
    /*                               ^              */
      *iv_return = HTTP_FIELD_CONTENT_RANGE;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "PPD_BAD_ORDER_DEPENDENCY", 24)) {
    /*                               ^              */
      *iv_return = PPD_BAD_ORDER_DEPENDENCY;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "HTTP_FIELD_AUTHORIZATION", 24)) {
    /*                               ^              */
      *iv_return = HTTP_FIELD_AUTHORIZATION;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_SWITCHING_PROTOCOLS", 24)) {
    /*                               ^              */
      *iv_return = HTTP_SWITCHING_PROTOCOLS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_URI_CODING_RESOURCE", 24)) {
    /*                               ^              */
      *iv_return = HTTP_URI_CODING_RESOURCE;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "HTTP_FIELD_ACCEPT_RANGES", 24)) {
    /*                               ^              */
      *iv_return = HTTP_FIELD_ACCEPT_RANGES;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "HTTP_URI_CODING_USERNAME", 24)) {
    /*                               ^              */
      *iv_return = HTTP_URI_CODING_USERNAME;
      return PERL_constant_ISIV;
    }
    break;
  case 'V':
    if (memEQ(name, "HTTP_SERVICE_UNAVAILABLE", 24)) {
    /*                               ^              */
      *iv_return = HTTP_SERVICE_UNAVAILABLE;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "PPD_ILLEGAL_MAIN_KEYWORD", 24)) {
    /*                               ^              */
      *iv_return = PPD_ILLEGAL_MAIN_KEYWORD;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_25 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     HTTP_ENCRYPT_IF_REQUESTED HTTP_FIELD_CONTENT_LENGTH
     HTTP_PROXY_AUTHENTICATION HTTP_URI_MISSING_RESOURCE
     IPP_DOCUMENT_ACCESS_ERROR IPP_DOCUMENT_FORMAT_ERROR
     IPP_FINISHINGS_BIND_RIGHT IPP_FINISHINGS_JOB_OFFSET
     IPP_RELEASE_HELD_NEW_JOBS IPP_TAG_UNSUPPORTED_GROUP
     IPP_TAG_UNSUPPORTED_VALUE IPP_VERSION_NOT_SUPPORTED */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'A':
    if (memEQ(name, "IPP_DOCUMENT_ACCESS_ERROR", 25)) {
    /*                            ^                  */
      *iv_return = IPP_DOCUMENT_ACCESS_ERROR;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "IPP_RELEASE_HELD_NEW_JOBS", 25)) {
    /*                            ^                  */
      *iv_return = IPP_RELEASE_HELD_NEW_JOBS;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "IPP_DOCUMENT_FORMAT_ERROR", 25)) {
    /*                            ^                  */
      *iv_return = IPP_DOCUMENT_FORMAT_ERROR;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "HTTP_ENCRYPT_IF_REQUESTED", 25)) {
    /*                            ^                  */
      *iv_return = HTTP_ENCRYPT_IF_REQUESTED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_URI_MISSING_RESOURCE", 25)) {
    /*                            ^                  */
      *iv_return = HTTP_URI_MISSING_RESOURCE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "HTTP_FIELD_CONTENT_LENGTH", 25)) {
    /*                            ^                  */
      *iv_return = HTTP_FIELD_CONTENT_LENGTH;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "IPP_VERSION_NOT_SUPPORTED", 25)) {
    /*                            ^                  */
      *iv_return = IPP_VERSION_NOT_SUPPORTED;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "IPP_TAG_UNSUPPORTED_GROUP", 25)) {
    /*                            ^                  */
      *iv_return = IPP_TAG_UNSUPPORTED_GROUP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_TAG_UNSUPPORTED_VALUE", 25)) {
    /*                            ^                  */
      *iv_return = IPP_TAG_UNSUPPORTED_VALUE;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "IPP_FINISHINGS_BIND_RIGHT", 25)) {
    /*                            ^                  */
      *iv_return = IPP_FINISHINGS_BIND_RIGHT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_FINISHINGS_JOB_OFFSET", 25)) {
    /*                            ^                  */
      *iv_return = IPP_FINISHINGS_JOB_OFFSET;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "HTTP_PROXY_AUTHENTICATION", 25)) {
    /*                            ^                  */
      *iv_return = HTTP_PROXY_AUTHENTICATION;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_26 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CUPS_BACKEND_AUTH_REQUIRED CUPS_PRINTER_AUTHENTICATED
     HTTP_FIELD_ACCEPT_LANGUAGE HTTP_FIELD_CONTENT_VERSION
     HTTP_UNSUPPORTED_MEDIATYPE IPP_FINISHINGS_BIND_BOTTOM
     IPP_FINISHINGS_EDGE_STITCH IPP_GET_PRINTER_ATTRIBUTES
     IPP_PRINTER_IS_DEACTIVATED IPP_REDIRECTION_OTHER_SITE
     IPP_SET_PRINTER_ATTRIBUTES IPP_TAG_EVENT_NOTIFICATION
     IPP_TOO_MANY_SUBSCRIPTIONS PPD_ILLEGAL_OPTION_KEYWORD */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'E':
    if (memEQ(name, "IPP_TAG_EVENT_NOTIFICATION", 26)) {
    /*                       ^                        */
      *iv_return = IPP_TAG_EVENT_NOTIFICATION;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "PPD_ILLEGAL_OPTION_KEYWORD", 26)) {
    /*                       ^                        */
      *iv_return = PPD_ILLEGAL_OPTION_KEYWORD;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "CUPS_BACKEND_AUTH_REQUIRED", 26)) {
    /*                       ^                        */
      *iv_return = CUPS_BACKEND_AUTH_REQUIRED;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "HTTP_FIELD_ACCEPT_LANGUAGE", 26)) {
    /*                       ^                        */
      *iv_return = HTTP_FIELD_ACCEPT_LANGUAGE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_FIELD_CONTENT_VERSION", 26)) {
    /*                       ^                        */
      *iv_return = HTTP_FIELD_CONTENT_VERSION;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "IPP_TOO_MANY_SUBSCRIPTIONS", 26)) {
    /*                       ^                        */
      *iv_return = IPP_TOO_MANY_SUBSCRIPTIONS;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "CUPS_PRINTER_AUTHENTICATED", 26)) {
    /*                       ^                        */
      *iv_return = CUPS_PRINTER_AUTHENTICATED;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "IPP_GET_PRINTER_ATTRIBUTES", 26)) {
    /*                       ^                        */
      *iv_return = IPP_GET_PRINTER_ATTRIBUTES;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_SET_PRINTER_ATTRIBUTES", 26)) {
    /*                       ^                        */
      *iv_return = IPP_SET_PRINTER_ATTRIBUTES;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "IPP_REDIRECTION_OTHER_SITE", 26)) {
    /*                       ^                        */
      *iv_return = IPP_REDIRECTION_OTHER_SITE;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "IPP_FINISHINGS_BIND_BOTTOM", 26)) {
    /*                       ^                        */
      *iv_return = IPP_FINISHINGS_BIND_BOTTOM;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_FINISHINGS_EDGE_STITCH", 26)) {
    /*                       ^                        */
      *iv_return = IPP_FINISHINGS_EDGE_STITCH;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "IPP_PRINTER_IS_DEACTIVATED", 26)) {
    /*                       ^                        */
      *iv_return = IPP_PRINTER_IS_DEACTIVATED;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "HTTP_UNSUPPORTED_MEDIATYPE", 26)) {
    /*                       ^                        */
      *iv_return = HTTP_UNSUPPORTED_MEDIATYPE;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_27 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     HTTP_FIELD_CONTENT_ENCODING HTTP_FIELD_CONTENT_LANGUAGE
     HTTP_FIELD_CONTENT_LOCATION HTTP_FIELD_WWW_AUTHENTICATE
     IPP_ATTRIBUTES_NOT_SETTABLE IPP_CREATE_JOB_SUBSCRIPTION
     IPP_GET_PRINT_SUPPORT_FILES IPP_OPERATION_NOT_SUPPORTED */
  /* Offset 20 gives the best switch position.  */
  switch (name[20]) {
  case 'A':
    if (memEQ(name, "HTTP_FIELD_CONTENT_LANGUAGE", 27)) {
    /*                                   ^             */
      *iv_return = HTTP_FIELD_CONTENT_LANGUAGE;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "IPP_ATTRIBUTES_NOT_SETTABLE", 27)) {
    /*                                   ^             */
      *iv_return = IPP_ATTRIBUTES_NOT_SETTABLE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "HTTP_FIELD_CONTENT_ENCODING", 27)) {
    /*                                   ^             */
      *iv_return = HTTP_FIELD_CONTENT_ENCODING;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HTTP_FIELD_WWW_AUTHENTICATE", 27)) {
    /*                                   ^             */
      *iv_return = HTTP_FIELD_WWW_AUTHENTICATE;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "HTTP_FIELD_CONTENT_LOCATION", 27)) {
    /*                                   ^             */
      *iv_return = HTTP_FIELD_CONTENT_LOCATION;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "IPP_OPERATION_NOT_SUPPORTED", 27)) {
    /*                                   ^             */
      *iv_return = IPP_OPERATION_NOT_SUPPORTED;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "IPP_CREATE_JOB_SUBSCRIPTION", 27)) {
    /*                                   ^             */
      *iv_return = IPP_CREATE_JOB_SUBSCRIPTION;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "IPP_GET_PRINT_SUPPORT_FILES", 27)) {
    /*                                   ^             */
      *iv_return = IPP_GET_PRINT_SUPPORT_FILES;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_28 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     HTTP_FIELD_IF_MODIFIED_SINCE HTTP_FIELD_TRANSFER_ENCODING
     IPP_FINISHINGS_BOOKLET_MAKER IPP_FINISHINGS_SADDLE_STITCH
     IPP_OK_IGNORED_NOTIFICATIONS IPP_OK_IGNORED_SUBSCRIPTIONS */
  /* Offset 18 gives the best switch position.  */
  switch (name[18]) {
  case 'D':
    if (memEQ(name, "IPP_FINISHINGS_SADDLE_STITCH", 28)) {
    /*                                 ^                */
      *iv_return = IPP_FINISHINGS_SADDLE_STITCH;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "HTTP_FIELD_IF_MODIFIED_SINCE", 28)) {
    /*                                 ^                */
      *iv_return = HTTP_FIELD_IF_MODIFIED_SINCE;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "IPP_OK_IGNORED_NOTIFICATIONS", 28)) {
    /*                                 ^                */
      *iv_return = IPP_OK_IGNORED_NOTIFICATIONS;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "IPP_FINISHINGS_BOOKLET_MAKER", 28)) {
    /*                                 ^                */
      *iv_return = IPP_FINISHINGS_BOOKLET_MAKER;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "HTTP_FIELD_TRANSFER_ENCODING", 28)) {
    /*                                 ^                */
      *iv_return = HTTP_FIELD_TRANSFER_ENCODING;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "IPP_OK_IGNORED_SUBSCRIPTIONS", 28)) {
    /*                                 ^                */
      *iv_return = IPP_OK_IGNORED_SUBSCRIPTIONS;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_29 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     IPP_COMPRESSION_NOT_SUPPORTED IPP_IGNORED_ALL_NOTIFICATIONS
     IPP_IGNORED_ALL_SUBSCRIPTIONS */
  /* Offset 21 gives the best switch position.  */
  switch (name[21]) {
  case 'I':
    if (memEQ(name, "IPP_IGNORED_ALL_NOTIFICATIONS", 29)) {
    /*                                    ^              */
      *iv_return = IPP_IGNORED_ALL_NOTIFICATIONS;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "IPP_IGNORED_ALL_SUBSCRIPTIONS", 29)) {
    /*                                    ^              */
      *iv_return = IPP_IGNORED_ALL_SUBSCRIPTIONS;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "IPP_COMPRESSION_NOT_SUPPORTED", 29)) {
    /*                                    ^              */
      *iv_return = IPP_COMPRESSION_NOT_SUPPORTED;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_30 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     HTTP_FIELD_IF_UNMODIFIED_SINCE IPP_FINISHINGS_EDGE_STITCH_TOP
     IPP_FINISHINGS_STAPLE_DUAL_TOP IPP_FINISHINGS_STAPLE_TOP_LEFT
     IPP_OK_BUT_CANCEL_SUBSCRIPTION */
  /* Offset 22 gives the best switch position.  */
  switch (name[22]) {
  case 'C':
    if (memEQ(name, "IPP_OK_BUT_CANCEL_SUBSCRIPTION", 30)) {
    /*                                     ^              */
      *iv_return = IPP_OK_BUT_CANCEL_SUBSCRIPTION;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "IPP_FINISHINGS_STAPLE_DUAL_TOP", 30)) {
    /*                                     ^              */
      *iv_return = IPP_FINISHINGS_STAPLE_DUAL_TOP;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "HTTP_FIELD_IF_UNMODIFIED_SINCE", 30)) {
    /*                                     ^              */
      *iv_return = HTTP_FIELD_IF_UNMODIFIED_SINCE;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "IPP_FINISHINGS_EDGE_STITCH_TOP", 30)) {
    /*                                     ^              */
      *iv_return = IPP_FINISHINGS_EDGE_STITCH_TOP;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "IPP_FINISHINGS_STAPLE_TOP_LEFT", 30)) {
    /*                                     ^              */
      *iv_return = IPP_FINISHINGS_STAPLE_TOP_LEFT;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_31 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     IPP_CREATE_PRINTER_SUBSCRIPTION IPP_FINISHINGS_EDGE_STITCH_LEFT
     IPP_FINISHINGS_STAPLE_DUAL_LEFT IPP_FINISHINGS_STAPLE_TOP_RIGHT
     IPP_GET_SUBSCRIPTION_ATTRIBUTES IPP_MULTIPLE_JOBS_NOT_SUPPORTED */
  /* Offset 27 gives the best switch position.  */
  switch (name[27]) {
  case 'I':
    if (memEQ(name, "IPP_FINISHINGS_STAPLE_TOP_RIGHT", 31)) {
    /*                                          ^          */
      *iv_return = IPP_FINISHINGS_STAPLE_TOP_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "IPP_FINISHINGS_EDGE_STITCH_LEFT", 31)) {
    /*                                          ^          */
      *iv_return = IPP_FINISHINGS_EDGE_STITCH_LEFT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPP_FINISHINGS_STAPLE_DUAL_LEFT", 31)) {
    /*                                          ^          */
      *iv_return = IPP_FINISHINGS_STAPLE_DUAL_LEFT;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "IPP_MULTIPLE_JOBS_NOT_SUPPORTED", 31)) {
    /*                                          ^          */
      *iv_return = IPP_MULTIPLE_JOBS_NOT_SUPPORTED;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "IPP_CREATE_PRINTER_SUBSCRIPTION", 31)) {
    /*                                          ^          */
      *iv_return = IPP_CREATE_PRINTER_SUBSCRIPTION;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "IPP_GET_SUBSCRIPTION_ATTRIBUTES", 31)) {
    /*                                          ^          */
      *iv_return = IPP_GET_SUBSCRIPTION_ATTRIBUTES;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_32 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     IPP_FINISHINGS_EDGE_STITCH_RIGHT IPP_FINISHINGS_STAPLE_DUAL_RIGHT
     IPP_GET_PRINTER_SUPPORTED_VALUES IPP_PRINT_SUPPORT_FILE_NOT_FOUND */
  /* Offset 20 gives the best switch position.  */
  switch (name[20]) {
  case 'E':
    if (memEQ(name, "IPP_FINISHINGS_STAPLE_DUAL_RIGHT", 32)) {
    /*                                   ^                  */
      *iv_return = IPP_FINISHINGS_STAPLE_DUAL_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "IPP_PRINT_SUPPORT_FILE_NOT_FOUND", 32)) {
    /*                                   ^                  */
      *iv_return = IPP_PRINT_SUPPORT_FILE_NOT_FOUND;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "IPP_GET_PRINTER_SUPPORTED_VALUES", 32)) {
    /*                                   ^                  */
      *iv_return = IPP_GET_PRINTER_SUPPORTED_VALUES;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "IPP_FINISHINGS_EDGE_STITCH_RIGHT", 32)) {
    /*                                   ^                  */
      *iv_return = IPP_FINISHINGS_EDGE_STITCH_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_33 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     IPP_FINISHINGS_EDGE_STITCH_BOTTOM IPP_FINISHINGS_STAPLE_BOTTOM_LEFT
     IPP_FINISHINGS_STAPLE_DUAL_BOTTOM */
  /* Offset 23 gives the best switch position.  */
  switch (name[23]) {
  case 'O':
    if (memEQ(name, "IPP_FINISHINGS_STAPLE_BOTTOM_LEFT", 33)) {
    /*                                      ^                */
      *iv_return = IPP_FINISHINGS_STAPLE_BOTTOM_LEFT;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "IPP_FINISHINGS_EDGE_STITCH_BOTTOM", 33)) {
    /*                                      ^                */
      *iv_return = IPP_FINISHINGS_EDGE_STITCH_BOTTOM;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "IPP_FINISHINGS_STAPLE_DUAL_BOTTOM", 33)) {
    /*                                      ^                */
      *iv_return = IPP_FINISHINGS_STAPLE_DUAL_BOTTOM;
      return PERL_constant_ISIV;
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
my @names = (qw(INET6),
            {name=>"AF_LOCAL", type=>"IV", macro=>"1"},
            {name=>"CUPS_ACCEPT_JOBS", type=>"IV", macro=>"1"},
            {name=>"CUPS_ADD_CLASS", type=>"IV", macro=>"1"},
            {name=>"CUPS_ADD_MODIFY_CLASS", type=>"IV", macro=>"1"},
            {name=>"CUPS_ADD_MODIFY_PRINTER", type=>"IV", macro=>"1"},
            {name=>"CUPS_ADD_PRINTER", type=>"IV", macro=>"1"},
            {name=>"CUPS_AUTHENTICATE_JOB", type=>"IV", macro=>"1"},
            {name=>"CUPS_AUTO_ENCODING", type=>"IV", macro=>"1"},
            {name=>"CUPS_BACKEND_AUTH_REQUIRED", type=>"IV", macro=>"1"},
            {name=>"CUPS_BACKEND_CANCEL", type=>"IV", macro=>"1"},
            {name=>"CUPS_BACKEND_FAILED", type=>"IV", macro=>"1"},
            {name=>"CUPS_BACKEND_HOLD", type=>"IV", macro=>"1"},
            {name=>"CUPS_BACKEND_OK", type=>"IV", macro=>"1"},
            {name=>"CUPS_BACKEND_STOP", type=>"IV", macro=>"1"},
            {name=>"CUPS_DATE_ANY", type=>"IV", macro=>"1"},
            {name=>"CUPS_DELETE_CLASS", type=>"IV", macro=>"1"},
            {name=>"CUPS_DELETE_PRINTER", type=>"IV", macro=>"1"},
            {name=>"CUPS_ENCODING_DBCS_END", type=>"IV", macro=>"1"},
            {name=>"CUPS_ENCODING_SBCS_END", type=>"IV", macro=>"1"},
            {name=>"CUPS_ENCODING_VBCS_END", type=>"IV", macro=>"1"},
            {name=>"CUPS_EUC_CN", type=>"IV", macro=>"1"},
            {name=>"CUPS_EUC_JP", type=>"IV", macro=>"1"},
            {name=>"CUPS_EUC_KR", type=>"IV", macro=>"1"},
            {name=>"CUPS_EUC_TW", type=>"IV", macro=>"1"},
            {name=>"CUPS_FILE_GZIP", type=>"IV", macro=>"1"},
            {name=>"CUPS_FILE_NONE", type=>"IV", macro=>"1"},
            {name=>"CUPS_GET_CLASSES", type=>"IV", macro=>"1"},
            {name=>"CUPS_GET_DEFAULT", type=>"IV", macro=>"1"},
            {name=>"CUPS_GET_DEVICES", type=>"IV", macro=>"1"},
            {name=>"CUPS_GET_PPDS", type=>"IV", macro=>"1"},
            {name=>"CUPS_GET_PRINTERS", type=>"IV", macro=>"1"},
            {name=>"CUPS_IMAGE_BLACK", type=>"IV", macro=>"1"},
            {name=>"CUPS_IMAGE_CMY", type=>"IV", macro=>"1"},
            {name=>"CUPS_IMAGE_CMYK", type=>"IV", macro=>"1"},
            {name=>"CUPS_IMAGE_RGB", type=>"IV", macro=>"1"},
            {name=>"CUPS_IMAGE_RGB_CMYK", type=>"IV", macro=>"1"},
            {name=>"CUPS_IMAGE_WHITE", type=>"IV", macro=>"1"},
            {name=>"CUPS_ISO8859_1", type=>"IV", macro=>"1"},
            {name=>"CUPS_ISO8859_10", type=>"IV", macro=>"1"},
            {name=>"CUPS_ISO8859_11", type=>"IV", macro=>"1"},
            {name=>"CUPS_ISO8859_13", type=>"IV", macro=>"1"},
            {name=>"CUPS_ISO8859_14", type=>"IV", macro=>"1"},
            {name=>"CUPS_ISO8859_15", type=>"IV", macro=>"1"},
            {name=>"CUPS_ISO8859_16", type=>"IV", macro=>"1"},
            {name=>"CUPS_ISO8859_2", type=>"IV", macro=>"1"},
            {name=>"CUPS_ISO8859_3", type=>"IV", macro=>"1"},
            {name=>"CUPS_ISO8859_4", type=>"IV", macro=>"1"},
            {name=>"CUPS_ISO8859_5", type=>"IV", macro=>"1"},
            {name=>"CUPS_ISO8859_6", type=>"IV", macro=>"1"},
            {name=>"CUPS_ISO8859_7", type=>"IV", macro=>"1"},
            {name=>"CUPS_ISO8859_8", type=>"IV", macro=>"1"},
            {name=>"CUPS_ISO8859_9", type=>"IV", macro=>"1"},
            {name=>"CUPS_KOI8_R", type=>"IV", macro=>"1"},
            {name=>"CUPS_KOI8_U", type=>"IV", macro=>"1"},
            {name=>"CUPS_MAC_ROMAN", type=>"IV", macro=>"1"},
            {name=>"CUPS_MAX_USTRING", type=>"IV", macro=>"1"},
            {name=>"CUPS_MOVE_JOB", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_AUTHENTICATED", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_BIND", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_BW", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_CLASS", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_COLLATE", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_COLOR", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_COMMANDS", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_COPIES", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_COVER", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_DEFAULT", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_DELETE", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_DUPLEX", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_FAX", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_IMPLICIT", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_LARGE", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_LOCAL", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_MEDIUM", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_NOT_SHARED", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_OPTIONS", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_PUNCH", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_REJECTING", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_REMOTE", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_SMALL", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_SORT", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_STAPLE", type=>"IV", macro=>"1"},
            {name=>"CUPS_PRINTER_VARIABLE", type=>"IV", macro=>"1"},
            {name=>"CUPS_REJECT_JOBS", type=>"IV", macro=>"1"},
            {name=>"CUPS_SET_DEFAULT", type=>"IV", macro=>"1"},
            {name=>"CUPS_US_ASCII", type=>"IV", macro=>"1"},
            {name=>"CUPS_UTF8", type=>"IV", macro=>"1"},
            {name=>"CUPS_VERSION", type=>"IV", macro=>"1"},
            {name=>"CUPS_VERSION_MAJOR", type=>"IV", macro=>"1"},
            {name=>"CUPS_VERSION_MINOR", type=>"IV", macro=>"1"},
            {name=>"CUPS_VERSION_PATCH", type=>"IV", macro=>"1"},
            {name=>"CUPS_WINDOWS_1250", type=>"IV", macro=>"1"},
            {name=>"CUPS_WINDOWS_1251", type=>"IV", macro=>"1"},
            {name=>"CUPS_WINDOWS_1252", type=>"IV", macro=>"1"},
            {name=>"CUPS_WINDOWS_1253", type=>"IV", macro=>"1"},
            {name=>"CUPS_WINDOWS_1254", type=>"IV", macro=>"1"},
            {name=>"CUPS_WINDOWS_1255", type=>"IV", macro=>"1"},
            {name=>"CUPS_WINDOWS_1256", type=>"IV", macro=>"1"},
            {name=>"CUPS_WINDOWS_1257", type=>"IV", macro=>"1"},
            {name=>"CUPS_WINDOWS_1258", type=>"IV", macro=>"1"},
            {name=>"CUPS_WINDOWS_1361", type=>"IV", macro=>"1"},
            {name=>"CUPS_WINDOWS_874", type=>"IV", macro=>"1"},
            {name=>"CUPS_WINDOWS_932", type=>"IV", macro=>"1"},
            {name=>"CUPS_WINDOWS_936", type=>"IV", macro=>"1"},
            {name=>"CUPS_WINDOWS_949", type=>"IV", macro=>"1"},
            {name=>"CUPS_WINDOWS_950", type=>"IV", macro=>"1"},
            {name=>"HTTP_0_9", type=>"IV", macro=>"1"},
            {name=>"HTTP_1_0", type=>"IV", macro=>"1"},
            {name=>"HTTP_1_1", type=>"IV", macro=>"1"},
            {name=>"HTTP_ACCEPTED", type=>"IV", macro=>"1"},
            {name=>"HTTP_AUTH_BASIC", type=>"IV", macro=>"1"},
            {name=>"HTTP_AUTH_MD5", type=>"IV", macro=>"1"},
            {name=>"HTTP_AUTH_MD5_INT", type=>"IV", macro=>"1"},
            {name=>"HTTP_AUTH_MD5_SESS", type=>"IV", macro=>"1"},
            {name=>"HTTP_AUTH_MD5_SESS_INT", type=>"IV", macro=>"1"},
            {name=>"HTTP_AUTH_NONE", type=>"IV", macro=>"1"},
            {name=>"HTTP_BAD_GATEWAY", type=>"IV", macro=>"1"},
            {name=>"HTTP_BAD_REQUEST", type=>"IV", macro=>"1"},
            {name=>"HTTP_CLOSE", type=>"IV", macro=>"1"},
            {name=>"HTTP_CONFLICT", type=>"IV", macro=>"1"},
            {name=>"HTTP_CONTINUE", type=>"IV", macro=>"1"},
            {name=>"HTTP_CREATED", type=>"IV", macro=>"1"},
            {name=>"HTTP_DELETE", type=>"IV", macro=>"1"},
            {name=>"HTTP_ENCODE_CHUNKED", type=>"IV", macro=>"1"},
            {name=>"HTTP_ENCODE_FIELDS", type=>"IV", macro=>"1"},
            {name=>"HTTP_ENCODE_LENGTH", type=>"IV", macro=>"1"},
            {name=>"HTTP_ENCRYPT_ALWAYS", type=>"IV", macro=>"1"},
            {name=>"HTTP_ENCRYPT_IF_REQUESTED", type=>"IV", macro=>"1"},
            {name=>"HTTP_ENCRYPT_NEVER", type=>"IV", macro=>"1"},
            {name=>"HTTP_ENCRYPT_REQUIRED", type=>"IV", macro=>"1"},
            {name=>"HTTP_ERROR", type=>"IV", macro=>"1"},
            {name=>"HTTP_EXPECTATION_FAILED", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_ACCEPT_LANGUAGE", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_ACCEPT_RANGES", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_AUTHORIZATION", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_CONNECTION", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_CONTENT_ENCODING", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_CONTENT_LANGUAGE", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_CONTENT_LENGTH", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_CONTENT_LOCATION", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_CONTENT_MD5", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_CONTENT_RANGE", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_CONTENT_TYPE", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_CONTENT_VERSION", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_DATE", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_HOST", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_IF_MODIFIED_SINCE", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_IF_UNMODIFIED_SINCE", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_KEEP_ALIVE", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_LAST_MODIFIED", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_LINK", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_LOCATION", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_MAX", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_RANGE", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_REFERER", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_RETRY_AFTER", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_TRANSFER_ENCODING", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_UNKNOWN", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_UPGRADE", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_USER_AGENT", type=>"IV", macro=>"1"},
            {name=>"HTTP_FIELD_WWW_AUTHENTICATE", type=>"IV", macro=>"1"},
            {name=>"HTTP_FORBIDDEN", type=>"IV", macro=>"1"},
            {name=>"HTTP_GATEWAY_TIMEOUT", type=>"IV", macro=>"1"},
            {name=>"HTTP_GET", type=>"IV", macro=>"1"},
            {name=>"HTTP_GET_SEND", type=>"IV", macro=>"1"},
            {name=>"HTTP_GONE", type=>"IV", macro=>"1"},
            {name=>"HTTP_HEAD", type=>"IV", macro=>"1"},
            {name=>"HTTP_KEEPALIVE_OFF", type=>"IV", macro=>"1"},
            {name=>"HTTP_KEEPALIVE_ON", type=>"IV", macro=>"1"},
            {name=>"HTTP_LENGTH_REQUIRED", type=>"IV", macro=>"1"},
            {name=>"HTTP_MAX_BUFFER", type=>"IV", macro=>"1"},
            {name=>"HTTP_MAX_HOST", type=>"IV", macro=>"1"},
            {name=>"HTTP_MAX_URI", type=>"IV", macro=>"1"},
            {name=>"HTTP_MAX_VALUE", type=>"IV", macro=>"1"},
            {name=>"HTTP_METHOD_NOT_ALLOWED", type=>"IV", macro=>"1"},
            {name=>"HTTP_MOVED_PERMANENTLY", type=>"IV", macro=>"1"},
            {name=>"HTTP_MOVED_TEMPORARILY", type=>"IV", macro=>"1"},
            {name=>"HTTP_MULTIPLE_CHOICES", type=>"IV", macro=>"1"},
            {name=>"HTTP_NOT_ACCEPTABLE", type=>"IV", macro=>"1"},
            {name=>"HTTP_NOT_AUTHORITATIVE", type=>"IV", macro=>"1"},
            {name=>"HTTP_NOT_FOUND", type=>"IV", macro=>"1"},
            {name=>"HTTP_NOT_IMPLEMENTED", type=>"IV", macro=>"1"},
            {name=>"HTTP_NOT_MODIFIED", type=>"IV", macro=>"1"},
            {name=>"HTTP_NOT_SUPPORTED", type=>"IV", macro=>"1"},
            {name=>"HTTP_NO_CONTENT", type=>"IV", macro=>"1"},
            {name=>"HTTP_OK", type=>"IV", macro=>"1"},
            {name=>"HTTP_OPTIONS", type=>"IV", macro=>"1"},
            {name=>"HTTP_PARTIAL_CONTENT", type=>"IV", macro=>"1"},
            {name=>"HTTP_PAYMENT_REQUIRED", type=>"IV", macro=>"1"},
            {name=>"HTTP_POST", type=>"IV", macro=>"1"},
            {name=>"HTTP_POST_RECV", type=>"IV", macro=>"1"},
            {name=>"HTTP_POST_SEND", type=>"IV", macro=>"1"},
            {name=>"HTTP_PRECONDITION", type=>"IV", macro=>"1"},
            {name=>"HTTP_PROXY_AUTHENTICATION", type=>"IV", macro=>"1"},
            {name=>"HTTP_PUT", type=>"IV", macro=>"1"},
            {name=>"HTTP_PUT_RECV", type=>"IV", macro=>"1"},
            {name=>"HTTP_REQUESTED_RANGE", type=>"IV", macro=>"1"},
            {name=>"HTTP_REQUEST_TIMEOUT", type=>"IV", macro=>"1"},
            {name=>"HTTP_REQUEST_TOO_LARGE", type=>"IV", macro=>"1"},
            {name=>"HTTP_RESET_CONTENT", type=>"IV", macro=>"1"},
            {name=>"HTTP_SEE_OTHER", type=>"IV", macro=>"1"},
            {name=>"HTTP_SERVER_ERROR", type=>"IV", macro=>"1"},
            {name=>"HTTP_SERVICE_UNAVAILABLE", type=>"IV", macro=>"1"},
            {name=>"HTTP_STATUS", type=>"IV", macro=>"1"},
            {name=>"HTTP_SWITCHING_PROTOCOLS", type=>"IV", macro=>"1"},
            {name=>"HTTP_TRACE", type=>"IV", macro=>"1"},
            {name=>"HTTP_UNAUTHORIZED", type=>"IV", macro=>"1"},
            {name=>"HTTP_UNSUPPORTED_MEDIATYPE", type=>"IV", macro=>"1"},
            {name=>"HTTP_UPGRADE_REQUIRED", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_BAD_ARGUMENTS", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_BAD_HOSTNAME", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_BAD_PORT", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_BAD_RESOURCE", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_BAD_SCHEME", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_BAD_URI", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_BAD_USERNAME", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_CODING_ALL", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_CODING_HOSTNAME", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_CODING_MOST", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_CODING_NONE", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_CODING_QUERY", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_CODING_RESOURCE", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_CODING_USERNAME", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_MISSING_RESOURCE", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_MISSING_SCHEME", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_OK", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_OVERFLOW", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_TOO_LONG", type=>"IV", macro=>"1"},
            {name=>"HTTP_URI_UNKNOWN_SCHEME", type=>"IV", macro=>"1"},
            {name=>"HTTP_USE_PROXY", type=>"IV", macro=>"1"},
            {name=>"HTTP_WAITING", type=>"IV", macro=>"1"},
            {name=>"IPP_ACTIVATE_PRINTER", type=>"IV", macro=>"1"},
            {name=>"IPP_ATTRIBUTE", type=>"IV", macro=>"1"},
            {name=>"IPP_ATTRIBUTES", type=>"IV", macro=>"1"},
            {name=>"IPP_ATTRIBUTES_NOT_SETTABLE", type=>"IV", macro=>"1"},
            {name=>"IPP_BAD_REQUEST", type=>"IV", macro=>"1"},
            {name=>"IPP_CANCEL_CURRENT_JOB", type=>"IV", macro=>"1"},
            {name=>"IPP_CANCEL_JOB", type=>"IV", macro=>"1"},
            {name=>"IPP_CANCEL_SUBSCRIPTION", type=>"IV", macro=>"1"},
            {name=>"IPP_CHARSET", type=>"IV", macro=>"1"},
            {name=>"IPP_COMPRESSION_ERROR", type=>"IV", macro=>"1"},
            {name=>"IPP_COMPRESSION_NOT_SUPPORTED", type=>"IV", macro=>"1"},
            {name=>"IPP_CONFLICT", type=>"IV", macro=>"1"},
            {name=>"IPP_CREATE_JOB", type=>"IV", macro=>"1"},
            {name=>"IPP_CREATE_JOB_SUBSCRIPTION", type=>"IV", macro=>"1"},
            {name=>"IPP_CREATE_PRINTER_SUBSCRIPTION", type=>"IV", macro=>"1"},
            {name=>"IPP_DATA", type=>"IV", macro=>"1"},
            {name=>"IPP_DEACTIVATE_PRINTER", type=>"IV", macro=>"1"},
            {name=>"IPP_DEVICE_ERROR", type=>"IV", macro=>"1"},
            {name=>"IPP_DISABLE_PRINTER", type=>"IV", macro=>"1"},
            {name=>"IPP_DOCUMENT_ACCESS_ERROR", type=>"IV", macro=>"1"},
            {name=>"IPP_DOCUMENT_FORMAT", type=>"IV", macro=>"1"},
            {name=>"IPP_DOCUMENT_FORMAT_ERROR", type=>"IV", macro=>"1"},
            {name=>"IPP_ENABLE_PRINTER", type=>"IV", macro=>"1"},
            {name=>"IPP_ERROR", type=>"IV", macro=>"1"},
            {name=>"IPP_ERROR_JOB_CANCELED", type=>"IV", macro=>"1"},
            {name=>"IPP_ERROR_JOB_CANCELLED", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_BALE", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_BIND", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_BIND_BOTTOM", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_BIND_LEFT", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_BIND_RIGHT", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_BIND_TOP", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_BOOKLET_MAKER", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_COVER", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_EDGE_STITCH", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_EDGE_STITCH_BOTTOM", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_EDGE_STITCH_LEFT", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_EDGE_STITCH_RIGHT", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_EDGE_STITCH_TOP", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_FOLD", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_JOB_OFFSET", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_NONE", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_PUNCH", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_SADDLE_STITCH", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_STAPLE", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_STAPLE_BOTTOM_LEFT", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_STAPLE_BOTTOM_RIGHT", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_STAPLE_DUAL_BOTTOM", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_STAPLE_DUAL_LEFT", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_STAPLE_DUAL_RIGHT", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_STAPLE_DUAL_TOP", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_STAPLE_TOP_LEFT", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_STAPLE_TOP_RIGHT", type=>"IV", macro=>"1"},
            {name=>"IPP_FINISHINGS_TRIM", type=>"IV", macro=>"1"},
            {name=>"IPP_FORBIDDEN", type=>"IV", macro=>"1"},
            {name=>"IPP_GET_JOBS", type=>"IV", macro=>"1"},
            {name=>"IPP_GET_JOB_ATTRIBUTES", type=>"IV", macro=>"1"},
            {name=>"IPP_GET_NOTIFICATIONS", type=>"IV", macro=>"1"},
            {name=>"IPP_GET_PRINTER_ATTRIBUTES", type=>"IV", macro=>"1"},
            {name=>"IPP_GET_PRINTER_SUPPORTED_VALUES", type=>"IV", macro=>"1"},
            {name=>"IPP_GET_PRINT_SUPPORT_FILES", type=>"IV", macro=>"1"},
            {name=>"IPP_GET_SUBSCRIPTIONS", type=>"IV", macro=>"1"},
            {name=>"IPP_GET_SUBSCRIPTION_ATTRIBUTES", type=>"IV", macro=>"1"},
            {name=>"IPP_GONE", type=>"IV", macro=>"1"},
            {name=>"IPP_HEADER", type=>"IV", macro=>"1"},
            {name=>"IPP_HOLD_JOB", type=>"IV", macro=>"1"},
            {name=>"IPP_HOLD_NEW_JOBS", type=>"IV", macro=>"1"},
            {name=>"IPP_IDLE", type=>"IV", macro=>"1"},
            {name=>"IPP_IGNORED_ALL_NOTIFICATIONS", type=>"IV", macro=>"1"},
            {name=>"IPP_IGNORED_ALL_SUBSCRIPTIONS", type=>"IV", macro=>"1"},
            {name=>"IPP_INTERNAL_ERROR", type=>"IV", macro=>"1"},
            {name=>"IPP_JOB_ABORTED", type=>"IV", macro=>"1"},
            {name=>"IPP_JOB_CANCELED", type=>"IV", macro=>"1"},
            {name=>"IPP_JOB_CANCELLED", type=>"IV", macro=>"1"},
            {name=>"IPP_JOB_COMPLETED", type=>"IV", macro=>"1"},
            {name=>"IPP_JOB_HELD", type=>"IV", macro=>"1"},
            {name=>"IPP_JOB_PENDING", type=>"IV", macro=>"1"},
            {name=>"IPP_JOB_PROCESSING", type=>"IV", macro=>"1"},
            {name=>"IPP_JOB_STOPPED", type=>"IV", macro=>"1"},
            {name=>"IPP_LANDSCAPE", type=>"IV", macro=>"1"},
            {name=>"IPP_MAX_NAME", type=>"IV", macro=>"1"},
            {name=>"IPP_MAX_VALUES", type=>"IV", macro=>"1"},
            {name=>"IPP_MULTIPLE_JOBS_NOT_SUPPORTED", type=>"IV", macro=>"1"},
            {name=>"IPP_NOT_ACCEPTING", type=>"IV", macro=>"1"},
            {name=>"IPP_NOT_AUTHENTICATED", type=>"IV", macro=>"1"},
            {name=>"IPP_NOT_AUTHORIZED", type=>"IV", macro=>"1"},
            {name=>"IPP_NOT_FOUND", type=>"IV", macro=>"1"},
            {name=>"IPP_NOT_POSSIBLE", type=>"IV", macro=>"1"},
            {name=>"IPP_OK", type=>"IV", macro=>"1"},
            {name=>"IPP_OK_BUT_CANCEL_SUBSCRIPTION", type=>"IV", macro=>"1"},
            {name=>"IPP_OK_CONFLICT", type=>"IV", macro=>"1"},
            {name=>"IPP_OK_EVENTS_COMPLETE", type=>"IV", macro=>"1"},
            {name=>"IPP_OK_IGNORED_NOTIFICATIONS", type=>"IV", macro=>"1"},
            {name=>"IPP_OK_IGNORED_SUBSCRIPTIONS", type=>"IV", macro=>"1"},
            {name=>"IPP_OK_SUBST", type=>"IV", macro=>"1"},
            {name=>"IPP_OK_TOO_MANY_EVENTS", type=>"IV", macro=>"1"},
            {name=>"IPP_OPERATION_NOT_SUPPORTED", type=>"IV", macro=>"1"},
            {name=>"IPP_PAUSE_PRINTER", type=>"IV", macro=>"1"},
            {name=>"IPP_PAUSE_PRINTER_AFTER_CURRENT_JOB", type=>"IV", macro=>"1"},
            {name=>"IPP_PORT", type=>"IV", macro=>"1"},
            {name=>"IPP_PORTRAIT", type=>"IV", macro=>"1"},
            {name=>"IPP_PRINTER_BUSY", type=>"IV", macro=>"1"},
            {name=>"IPP_PRINTER_IDLE", type=>"IV", macro=>"1"},
            {name=>"IPP_PRINTER_IS_DEACTIVATED", type=>"IV", macro=>"1"},
            {name=>"IPP_PRINTER_PROCESSING", type=>"IV", macro=>"1"},
            {name=>"IPP_PRINTER_STOPPED", type=>"IV", macro=>"1"},
            {name=>"IPP_PRINT_JOB", type=>"IV", macro=>"1"},
            {name=>"IPP_PRINT_SUPPORT_FILE_NOT_FOUND", type=>"IV", macro=>"1"},
            {name=>"IPP_PRINT_URI", type=>"IV", macro=>"1"},
            {name=>"IPP_PRIVATE", type=>"IV", macro=>"1"},
            {name=>"IPP_PROMOTE_JOB", type=>"IV", macro=>"1"},
            {name=>"IPP_PURGE_JOBS", type=>"IV", macro=>"1"},
            {name=>"IPP_QUALITY_DRAFT", type=>"IV", macro=>"1"},
            {name=>"IPP_QUALITY_HIGH", type=>"IV", macro=>"1"},
            {name=>"IPP_QUALITY_NORMAL", type=>"IV", macro=>"1"},
            {name=>"IPP_REDIRECTION_OTHER_SITE", type=>"IV", macro=>"1"},
            {name=>"IPP_RELEASE_HELD_NEW_JOBS", type=>"IV", macro=>"1"},
            {name=>"IPP_RELEASE_JOB", type=>"IV", macro=>"1"},
            {name=>"IPP_RENEW_SUBSCRIPTION", type=>"IV", macro=>"1"},
            {name=>"IPP_REPROCESS_JOB", type=>"IV", macro=>"1"},
            {name=>"IPP_REQUEST_ENTITY", type=>"IV", macro=>"1"},
            {name=>"IPP_REQUEST_VALUE", type=>"IV", macro=>"1"},
            {name=>"IPP_RESTART_JOB", type=>"IV", macro=>"1"},
            {name=>"IPP_RESTART_PRINTER", type=>"IV", macro=>"1"},
            {name=>"IPP_RESUME_JOB", type=>"IV", macro=>"1"},
            {name=>"IPP_RESUME_PRINTER", type=>"IV", macro=>"1"},
            {name=>"IPP_RES_PER_CM", type=>"IV", macro=>"1"},
            {name=>"IPP_RES_PER_INCH", type=>"IV", macro=>"1"},
            {name=>"IPP_REVERSE_LANDSCAPE", type=>"IV", macro=>"1"},
            {name=>"IPP_REVERSE_PORTRAIT", type=>"IV", macro=>"1"},
            {name=>"IPP_SCHEDULE_JOB_AFTER", type=>"IV", macro=>"1"},
            {name=>"IPP_SEND_DOCUMENT", type=>"IV", macro=>"1"},
            {name=>"IPP_SEND_NOTIFICATIONS", type=>"IV", macro=>"1"},
            {name=>"IPP_SEND_URI", type=>"IV", macro=>"1"},
            {name=>"IPP_SERVICE_UNAVAILABLE", type=>"IV", macro=>"1"},
            {name=>"IPP_SET_JOB_ATTRIBUTES", type=>"IV", macro=>"1"},
            {name=>"IPP_SET_PRINTER_ATTRIBUTES", type=>"IV", macro=>"1"},
            {name=>"IPP_SHUTDOWN_PRINTER", type=>"IV", macro=>"1"},
            {name=>"IPP_STARTUP_PRINTER", type=>"IV", macro=>"1"},
            {name=>"IPP_SUSPEND_CURRENT_JOB", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_ADMINDEFINE", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_BEGIN_COLLECTION", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_BOOLEAN", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_CHARSET", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_COPY", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_DATE", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_DEFAULT", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_DELETEATTR", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_END", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_END_COLLECTION", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_ENUM", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_EVENT_NOTIFICATION", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_INTEGER", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_JOB", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_KEYWORD", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_LANGUAGE", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_MASK", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_MEMBERNAME", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_MIMETYPE", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_NAME", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_NAMELANG", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_NOTSETTABLE", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_NOVALUE", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_OPERATION", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_PRINTER", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_RANGE", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_RESOLUTION", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_STRING", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_SUBSCRIPTION", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_TEXT", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_TEXTLANG", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_UNKNOWN", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_UNSUPPORTED_GROUP", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_UNSUPPORTED_VALUE", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_URI", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_URISCHEME", type=>"IV", macro=>"1"},
            {name=>"IPP_TAG_ZERO", type=>"IV", macro=>"1"},
            {name=>"IPP_TEMPORARY_ERROR", type=>"IV", macro=>"1"},
            {name=>"IPP_TIMEOUT", type=>"IV", macro=>"1"},
            {name=>"IPP_TOO_MANY_SUBSCRIPTIONS", type=>"IV", macro=>"1"},
            {name=>"IPP_URI_SCHEME", type=>"IV", macro=>"1"},
            {name=>"IPP_VALIDATE_JOB", type=>"IV", macro=>"1"},
            {name=>"IPP_VERSION_NOT_SUPPORTED", type=>"IV", macro=>"1"},
            {name=>"PPD_ALLOC_ERROR", type=>"IV", macro=>"1"},
            {name=>"PPD_BAD_CUSTOM_PARAM", type=>"IV", macro=>"1"},
            {name=>"PPD_BAD_OPEN_GROUP", type=>"IV", macro=>"1"},
            {name=>"PPD_BAD_OPEN_UI", type=>"IV", macro=>"1"},
            {name=>"PPD_BAD_ORDER_DEPENDENCY", type=>"IV", macro=>"1"},
            {name=>"PPD_BAD_UI_CONSTRAINTS", type=>"IV", macro=>"1"},
            {name=>"PPD_CONFORM_RELAXED", type=>"IV", macro=>"1"},
            {name=>"PPD_CONFORM_STRICT", type=>"IV", macro=>"1"},
            {name=>"PPD_CS_CMY", type=>"IV", macro=>"1"},
            {name=>"PPD_CS_CMYK", type=>"IV", macro=>"1"},
            {name=>"PPD_CS_GRAY", type=>"IV", macro=>"1"},
            {name=>"PPD_CS_N", type=>"IV", macro=>"1"},
            {name=>"PPD_CS_RGB", type=>"IV", macro=>"1"},
            {name=>"PPD_CS_RGBK", type=>"IV", macro=>"1"},
            {name=>"PPD_CUSTOM_CURVE", type=>"IV", macro=>"1"},
            {name=>"PPD_CUSTOM_INT", type=>"IV", macro=>"1"},
            {name=>"PPD_CUSTOM_INVCURVE", type=>"IV", macro=>"1"},
            {name=>"PPD_CUSTOM_PASSCODE", type=>"IV", macro=>"1"},
            {name=>"PPD_CUSTOM_PASSWORD", type=>"IV", macro=>"1"},
            {name=>"PPD_CUSTOM_POINTS", type=>"IV", macro=>"1"},
            {name=>"PPD_CUSTOM_REAL", type=>"IV", macro=>"1"},
            {name=>"PPD_CUSTOM_STRING", type=>"IV", macro=>"1"},
            {name=>"PPD_FILE_OPEN_ERROR", type=>"IV", macro=>"1"},
            {name=>"PPD_ILLEGAL_CHARACTER", type=>"IV", macro=>"1"},
            {name=>"PPD_ILLEGAL_MAIN_KEYWORD", type=>"IV", macro=>"1"},
            {name=>"PPD_ILLEGAL_OPTION_KEYWORD", type=>"IV", macro=>"1"},
            {name=>"PPD_ILLEGAL_TRANSLATION", type=>"IV", macro=>"1"},
            {name=>"PPD_ILLEGAL_WHITESPACE", type=>"IV", macro=>"1"},
            {name=>"PPD_INTERNAL_ERROR", type=>"IV", macro=>"1"},
            {name=>"PPD_LINE_TOO_LONG", type=>"IV", macro=>"1"},
            {name=>"PPD_MAX_LINE", type=>"IV", macro=>"1"},
            {name=>"PPD_MAX_NAME", type=>"IV", macro=>"1"},
            {name=>"PPD_MAX_TEXT", type=>"IV", macro=>"1"},
            {name=>"PPD_MISSING_ASTERISK", type=>"IV", macro=>"1"},
            {name=>"PPD_MISSING_PPDADOBE4", type=>"IV", macro=>"1"},
            {name=>"PPD_MISSING_VALUE", type=>"IV", macro=>"1"},
            {name=>"PPD_NESTED_OPEN_GROUP", type=>"IV", macro=>"1"},
            {name=>"PPD_NESTED_OPEN_UI", type=>"IV", macro=>"1"},
            {name=>"PPD_NULL_FILE", type=>"IV", macro=>"1"},
            {name=>"PPD_OK", type=>"IV", macro=>"1"},
            {name=>"PPD_ORDER_ANY", type=>"IV", macro=>"1"},
            {name=>"PPD_ORDER_DOCUMENT", type=>"IV", macro=>"1"},
            {name=>"PPD_ORDER_EXIT", type=>"IV", macro=>"1"},
            {name=>"PPD_ORDER_JCL", type=>"IV", macro=>"1"},
            {name=>"PPD_ORDER_PAGE", type=>"IV", macro=>"1"},
            {name=>"PPD_ORDER_PROLOG", type=>"IV", macro=>"1"},
            {name=>"PPD_UI_BOOLEAN", type=>"IV", macro=>"1"},
            {name=>"PPD_UI_PICKMANY", type=>"IV", macro=>"1"},
            {name=>"PPD_UI_PICKONE", type=>"IV", macro=>"1"},
            {name=>"PPD_VERSION", type=>"IV", macro=>"1"});

print constant_types(); # macro defs
foreach (C_constant ("Net::CUPS", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Net::CUPS", $types);
__END__
   */

  switch (len) {
  case 5:
    if (memEQ(name, "INET6", 5)) {
#ifdef INET6
      *iv_return = INET6;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 6:
    /* Names all of length 6.  */
    /* IPP_OK PPD_OK */
    /* Offset 0 gives the best switch position.  */
    switch (*name++) {
    case 'I':
      if (memEQ(name, "PP_OK", 5)) {
      /*                I           */
        *iv_return = IPP_OK;
        return PERL_constant_ISIV;
      }
      break;
    case 'P':
      if (memEQ(name, "PD_OK", 5)) {
      /*                P           */
        *iv_return = PPD_OK;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 7:
    if (memEQ(name, "HTTP_OK", 7)) {
      *iv_return = HTTP_OK;
      return PERL_constant_ISIV;
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
    return constant_13 (aTHX_ name, iv_return);
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
    return constant_26 (aTHX_ name, iv_return);
    break;
  case 27:
    return constant_27 (aTHX_ name, iv_return);
    break;
  case 28:
    return constant_28 (aTHX_ name, iv_return);
    break;
  case 29:
    return constant_29 (aTHX_ name, iv_return);
    break;
  case 30:
    return constant_30 (aTHX_ name, iv_return);
    break;
  case 31:
    return constant_31 (aTHX_ name, iv_return);
    break;
  case 32:
    return constant_32 (aTHX_ name, iv_return);
    break;
  case 33:
    return constant_33 (aTHX_ name, iv_return);
    break;
  case 34:
    if (memEQ(name, "IPP_FINISHINGS_STAPLE_BOTTOM_RIGHT", 34)) {
      *iv_return = IPP_FINISHINGS_STAPLE_BOTTOM_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 35:
    if (memEQ(name, "IPP_PAUSE_PRINTER_AFTER_CURRENT_JOB", 35)) {
      *iv_return = IPP_PAUSE_PRINTER_AFTER_CURRENT_JOB;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

