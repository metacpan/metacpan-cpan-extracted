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
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AUTH_PASS AUTH_USER By_NOTIFY By_NOTSET By_RETURN */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'N':
    if (memEQ(name, "By_RETUR", 8)) {
    /*                       N     */
      *iv_return = By_RETURN;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "AUTH_USE", 8)) {
    /*                       R     */
#if defined(_auth_client_h)
      *iv_return = AUTH_USER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "AUTH_PAS", 8)) {
    /*                       S     */
#if defined(_auth_client_h)
      *iv_return = AUTH_PASS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "By_NOTSE", 8)) {
    /*                       T     */
      *iv_return = By_NOTSET;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "By_NOTIF", 8)) {
    /*                       Y     */
      *iv_return = By_NOTIFY;
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
     Hdr_OVERRIDE Hdr_PROHIBIT Notify_DELAY Notify_NEVER Timeout_DATA */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'A':
    if (memEQ(name, "Notify_DELAY", 12)) {
    /*                         ^        */
      *iv_return = Notify_DELAY;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "Hdr_OVERRIDE", 12)) {
    /*                         ^        */
      *iv_return = Hdr_OVERRIDE;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "Notify_NEVER", 12)) {
    /*                         ^        */
      *iv_return = Notify_NEVER;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "Hdr_PROHIBIT", 12)) {
    /*                         ^        */
      *iv_return = Hdr_PROHIBIT;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "Timeout_DATA", 12)) {
    /*                         ^        */
      *iv_return = Timeout_DATA;
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
     AUTH_CLEARTEXT E8bitmime_7BIT Notify_FAILURE Notify_SUCCESS SMTP_ERR_INVAL
     */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'A':
    if (memEQ(name, "SMTP_ERR_INVAL", 14)) {
    /*                           ^        */
#ifdef SMTP_ERR_INVAL
      *iv_return = SMTP_ERR_INVAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "E8bitmime_7BIT", 14)) {
    /*                           ^        */
      *iv_return = E8bitmime_7BIT;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "Notify_FAILURE", 14)) {
    /*                           ^        */
      *iv_return = Notify_FAILURE;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "Notify_SUCCESS", 14)) {
    /*                           ^        */
      *iv_return = Notify_SUCCESS;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "AUTH_CLEARTEXT", 14)) {
    /*                           ^        */
#if defined(_auth_client_h)
      *iv_return = AUTH_CLEARTEXT;
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
     SMTP_CB_HEADERS SMTP_CB_READING SMTP_CB_WRITING SMTP_EV_CONNECT */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'C':
    if (memEQ(name, "SMTP_EV_CONNECT", 15)) {
    /*                       ^             */
      *iv_return = SMTP_EV_CONNECT;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "SMTP_CB_HEADERS", 15)) {
    /*                       ^             */
#ifdef SMTP_CB_HEADERS
      *iv_return = SMTP_CB_HEADERS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "SMTP_CB_READING", 15)) {
    /*                       ^             */
#ifdef SMTP_CB_READING
      *iv_return = SMTP_CB_READING;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "SMTP_CB_WRITING", 15)) {
    /*                       ^             */
#ifdef SMTP_CB_WRITING
      *iv_return = SMTP_CB_WRITING;
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
     E8bitmime_NOTSET Starttls_ENABLED Timeout_ENVELOPE Timeout_GREETING
     Timeout_TRANSFER */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'F':
    if (memEQ(name, "Timeout_TRANSFER", 16)) {
    /*                            ^         */
      *iv_return = Timeout_TRANSFER;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "Timeout_GREETING", 16)) {
    /*                            ^         */
      *iv_return = Timeout_GREETING;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "Starttls_ENABLED", 16)) {
    /*                            ^         */
      *iv_return = Starttls_ENABLED;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "Timeout_ENVELOPE", 16)) {
    /*                            ^         */
      *iv_return = Timeout_ENVELOPE;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "E8bitmime_NOTSET", 16)) {
    /*                            ^         */
      *iv_return = E8bitmime_NOTSET;
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
     AUTH_PLUGIN_PLAIN SMTP_ERR_EAI_FAIL SMTP_EV_EXTNA_DSN Starttls_DISABLED
     Starttls_REQUIRED */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'A':
    if (memEQ(name, "SMTP_ERR_EAI_FAIL", 17)) {
    /*                         ^             */
#ifdef SMTP_ERR_EAI_FAIL
      *iv_return = SMTP_ERR_EAI_FAIL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "Starttls_REQUIRED", 17)) {
    /*                         ^             */
      *iv_return = Starttls_REQUIRED;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "Starttls_DISABLED", 17)) {
    /*                         ^             */
      *iv_return = Starttls_DISABLED;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "AUTH_PLUGIN_PLAIN", 17)) {
    /*                         ^             */
#if defined(_auth_client_h)
      *iv_return = AUTH_PLUGIN_PLAIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "SMTP_EV_EXTNA_DSN", 17)) {
    /*                         ^             */
      *iv_return = SMTP_EV_EXTNA_DSN;
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
     E8bitmime_8BITMIME SMTP_ERR_EAI_AGAIN SMTP_ERR_TRY_AGAIN
     SMTP_EV_DISCONNECT SMTP_EV_ETRNSTATUS SMTP_EV_EXTNA_ETRN
     SMTP_EV_MAILSTATUS SMTP_EV_RCPTSTATUS */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'B':
    if (memEQ(name, "E8bitmime_8BITMIME", 18)) {
    /*                          ^             */
      *iv_return = E8bitmime_8BITMIME;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "SMTP_EV_DISCONNECT", 18)) {
    /*                          ^             */
      *iv_return = SMTP_EV_DISCONNECT;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "SMTP_ERR_EAI_AGAIN", 18)) {
    /*                          ^             */
#ifdef SMTP_ERR_EAI_AGAIN
      *iv_return = SMTP_ERR_EAI_AGAIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "SMTP_EV_MAILSTATUS", 18)) {
    /*                          ^             */
      *iv_return = SMTP_EV_MAILSTATUS;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "SMTP_EV_ETRNSTATUS", 18)) {
    /*                          ^             */
      *iv_return = SMTP_EV_ETRNSTATUS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "SMTP_EV_EXTNA_ETRN", 18)) {
    /*                          ^             */
      *iv_return = SMTP_EV_EXTNA_ETRN;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "SMTP_EV_RCPTSTATUS", 18)) {
    /*                          ^             */
      *iv_return = SMTP_EV_RCPTSTATUS;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "SMTP_ERR_TRY_AGAIN", 18)) {
    /*                          ^             */
#ifdef SMTP_ERR_TRY_AGAIN
      *iv_return = SMTP_ERR_TRY_AGAIN;
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
     SMTP_ERR_EAI_FAMILY SMTP_ERR_EAI_MEMORY SMTP_ERR_EAI_NODATA
     SMTP_ERR_EAI_NONAME SMTP_ERR_NO_ADDRESS SMTP_EV_MESSAGEDATA
     SMTP_EV_MESSAGESENT SMTP_EV_STARTTLS_OK SMTP_EV_WEAK_CIPHER */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case 'E':
    if (memEQ(name, "SMTP_EV_WEAK_CIPHER", 19)) {
    /*                                ^        */
      *iv_return = SMTP_EV_WEAK_CIPHER;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "SMTP_ERR_EAI_FAMILY", 19)) {
    /*                                ^        */
#ifdef SMTP_ERR_EAI_FAMILY
      *iv_return = SMTP_ERR_EAI_FAMILY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "SMTP_ERR_EAI_NONAME", 19)) {
    /*                                ^        */
#ifdef SMTP_ERR_EAI_NONAME
      *iv_return = SMTP_ERR_EAI_NONAME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "SMTP_EV_MESSAGESENT", 19)) {
    /*                                ^        */
      *iv_return = SMTP_EV_MESSAGESENT;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "SMTP_EV_STARTTLS_OK", 19)) {
    /*                                ^        */
      *iv_return = SMTP_EV_STARTTLS_OK;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "SMTP_ERR_EAI_MEMORY", 19)) {
    /*                                ^        */
#ifdef SMTP_ERR_EAI_MEMORY
      *iv_return = SMTP_ERR_EAI_MEMORY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "SMTP_ERR_NO_ADDRESS", 19)) {
    /*                                ^        */
#ifdef SMTP_ERR_NO_ADDRESS
      *iv_return = SMTP_ERR_NO_ADDRESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "SMTP_ERR_EAI_NODATA", 19)) {
    /*                                ^        */
#ifdef SMTP_ERR_EAI_NODATA
      *iv_return = SMTP_ERR_EAI_NODATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SMTP_EV_MESSAGEDATA", 19)) {
    /*                                ^        */
      *iv_return = SMTP_EV_MESSAGEDATA;
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
     AUTH_PLUGIN_EXTERNAL E8bitmime_BINARYMIME SMTP_ERR_EAI_SERVICE
     SMTP_ERR_NO_RECOVERY */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'A':
    if (memEQ(name, "SMTP_ERR_EAI_SERVICE", 20)) {
    /*                         ^                */
#ifdef SMTP_ERR_EAI_SERVICE
      *iv_return = SMTP_ERR_EAI_SERVICE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "E8bitmime_BINARYMIME", 20)) {
    /*                         ^                */
      *iv_return = E8bitmime_BINARYMIME;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "AUTH_PLUGIN_EXTERNAL", 20)) {
    /*                         ^                */
#if defined(_auth_client_h)
      *iv_return = AUTH_PLUGIN_EXTERNAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "SMTP_ERR_NO_RECOVERY", 20)) {
    /*                         ^                */
#ifdef SMTP_ERR_NO_RECOVERY
      *iv_return = SMTP_ERR_NO_RECOVERY;
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
     AUTH_PLUGIN_ANONYMOUS SMTP_ERR_EAI_BADFLAGS SMTP_ERR_EAI_SOCKTYPE */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case 'L':
    if (memEQ(name, "SMTP_ERR_EAI_BADFLAGS", 21)) {
    /*                                ^          */
#ifdef SMTP_ERR_EAI_BADFLAGS
      *iv_return = SMTP_ERR_EAI_BADFLAGS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "AUTH_PLUGIN_ANONYMOUS", 21)) {
    /*                                ^          */
#if defined(_auth_client_h)
      *iv_return = AUTH_PLUGIN_ANONYMOUS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "SMTP_ERR_EAI_SOCKTYPE", 21)) {
    /*                                ^          */
#ifdef SMTP_ERR_EAI_SOCKTYPE
      *iv_return = SMTP_ERR_EAI_SOCKTYPE;
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
     SMTP_ERR_NOTHING_TO_DO SMTP_EV_EXTNA_8BITMIME SMTP_EV_EXTNA_CHUNKING
     SMTP_EV_EXTNA_STARTTLS */
  /* Offset 18 gives the best switch position.  */
  switch (name[18]) {
  case 'K':
    if (memEQ(name, "SMTP_EV_EXTNA_CHUNKING", 22)) {
    /*                                 ^          */
      *iv_return = SMTP_EV_EXTNA_CHUNKING;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "SMTP_EV_EXTNA_8BITMIME", 22)) {
    /*                                 ^          */
      *iv_return = SMTP_EV_EXTNA_8BITMIME;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "SMTP_ERR_NOTHING_TO_DO", 22)) {
    /*                                 ^          */
#ifdef SMTP_ERR_NOTHING_TO_DO
      *iv_return = SMTP_ERR_NOTHING_TO_DO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "SMTP_EV_EXTNA_STARTTLS", 22)) {
    /*                                 ^          */
      *iv_return = SMTP_EV_EXTNA_STARTTLS;
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
     SMTP_ERR_STATUS_MISMATCH SMTP_EV_EXTNA_BINARYMIME SMTP_EV_UNUSABLE_CA_LIST
     */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case 'A':
    if (memEQ(name, "SMTP_EV_EXTNA_BINARYMIME", 24)) {
    /*                                ^             */
      *iv_return = SMTP_EV_EXTNA_BINARYMIME;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "SMTP_EV_UNUSABLE_CA_LIST", 24)) {
    /*                                ^             */
      *iv_return = SMTP_EV_UNUSABLE_CA_LIST;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "SMTP_ERR_STATUS_MISMATCH", 24)) {
    /*                                ^             */
#ifdef SMTP_ERR_STATUS_MISMATCH
      *iv_return = SMTP_ERR_STATUS_MISMATCH;
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
constant_32 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SMTP_ERR_EXTENSION_NOT_AVAILABLE SMTP_ERR_INVALID_RESPONSE_STATUS
     SMTP_ERR_INVALID_RESPONSE_SYNTAX SMTP_EV_INVALID_PEER_CERTIFICATE
     Timeout_OVERRIDE_RFC2822_MINIMUM */
  /* Offset 27 gives the best switch position.  */
  switch (name[27]) {
  case 'I':
    if (memEQ(name, "SMTP_EV_INVALID_PEER_CERTIFICATE", 32)) {
    /*                                          ^           */
      *iv_return = SMTP_EV_INVALID_PEER_CERTIFICATE;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "SMTP_ERR_EXTENSION_NOT_AVAILABLE", 32)) {
    /*                                          ^           */
#ifdef SMTP_ERR_EXTENSION_NOT_AVAILABLE
      *iv_return = SMTP_ERR_EXTENSION_NOT_AVAILABLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "Timeout_OVERRIDE_RFC2822_MINIMUM", 32)) {
    /*                                          ^           */
#ifdef Timeout_OVERRIDE_RFC2822_MINIMUM
      *iv_return = Timeout_OVERRIDE_RFC2822_MINIMUM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "SMTP_ERR_INVALID_RESPONSE_STATUS", 32)) {
    /*                                          ^           */
#ifdef SMTP_ERR_INVALID_RESPONSE_STATUS
      *iv_return = SMTP_ERR_INVALID_RESPONSE_STATUS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "SMTP_ERR_INVALID_RESPONSE_SYNTAX", 32)) {
    /*                                          ^           */
#ifdef SMTP_ERR_INVALID_RESPONSE_SYNTAX
      *iv_return = SMTP_ERR_INVALID_RESPONSE_SYNTAX;
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
my @names = (qw(SMTP_CB_HEADERS SMTP_CB_READING SMTP_CB_WRITING
	       SMTP_ERR_DROPPED_CONNECTION SMTP_ERR_EAI_ADDRFAMILY
	       SMTP_ERR_EAI_AGAIN SMTP_ERR_EAI_BADFLAGS SMTP_ERR_EAI_FAIL
	       SMTP_ERR_EAI_FAMILY SMTP_ERR_EAI_MEMORY SMTP_ERR_EAI_NODATA
	       SMTP_ERR_EAI_NONAME SMTP_ERR_EAI_SERVICE SMTP_ERR_EAI_SOCKTYPE
	       SMTP_ERR_EXTENSION_NOT_AVAILABLE SMTP_ERR_HOST_NOT_FOUND
	       SMTP_ERR_INVAL SMTP_ERR_INVALID_RESPONSE_STATUS
	       SMTP_ERR_INVALID_RESPONSE_SYNTAX SMTP_ERR_NOTHING_TO_DO
	       SMTP_ERR_NO_ADDRESS SMTP_ERR_NO_RECOVERY
	       SMTP_ERR_STATUS_MISMATCH SMTP_ERR_TRY_AGAIN
	       SMTP_ERR_UNTERMINATED_RESPONSE Timeout_OVERRIDE_RFC2822_MINIMUM),
            {name=>"AUTH_CLEARTEXT", type=>"IV", macro=>["#if defined(_auth_client_h)\n", "#endif\n"]},
            {name=>"AUTH_PASS", type=>"IV", macro=>["#if defined(_auth_client_h)\n", "#endif\n"]},
            {name=>"AUTH_PLUGIN_ANONYMOUS", type=>"IV", macro=>["#if defined(_auth_client_h)\n", "#endif\n"]},
            {name=>"AUTH_PLUGIN_EXTERNAL", type=>"IV", macro=>["#if defined(_auth_client_h)\n", "#endif\n"]},
            {name=>"AUTH_PLUGIN_PLAIN", type=>"IV", macro=>["#if defined(_auth_client_h)\n", "#endif\n"]},
            {name=>"AUTH_REALM", type=>"IV", macro=>["#if defined(_auth_client_h)\n", "#endif\n"]},
            {name=>"AUTH_USER", type=>"IV", macro=>["#if defined(_auth_client_h)\n", "#endif\n"]},
            {name=>"By_NOTIFY", type=>"IV", macro=>"1"},
            {name=>"By_NOTSET", type=>"IV", macro=>"1"},
            {name=>"By_RETURN", type=>"IV", macro=>"1"},
            {name=>"E8bitmime_7BIT", type=>"IV", macro=>"1"},
            {name=>"E8bitmime_8BITMIME", type=>"IV", macro=>"1"},
            {name=>"E8bitmime_BINARYMIME", type=>"IV", macro=>"1"},
            {name=>"E8bitmime_NOTSET", type=>"IV", macro=>"1"},
            {name=>"Hdr_OVERRIDE", type=>"IV", macro=>"1"},
            {name=>"Hdr_PROHIBIT", type=>"IV", macro=>"1"},
            {name=>"Notify_DELAY", type=>"IV", macro=>"1"},
            {name=>"Notify_FAILURE", type=>"IV", macro=>"1"},
            {name=>"Notify_NEVER", type=>"IV", macro=>"1"},
            {name=>"Notify_NOTSET", type=>"IV", macro=>"1"},
            {name=>"Notify_SUCCESS", type=>"IV", macro=>"1"},
            {name=>"Ret_FULL", type=>"IV", macro=>"1"},
            {name=>"Ret_HDRS", type=>"IV", macro=>"1"},
            {name=>"Ret_NOTSET", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_CONNECT", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_DELIVERBY_EXPIRED", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_DISCONNECT", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_ETRNSTATUS", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_EXTNA_8BITMIME", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_EXTNA_BINARYMIME", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_EXTNA_CHUNKING", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_EXTNA_DSN", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_EXTNA_ETRN", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_EXTNA_STARTTLS", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_INVALID_PEER_CERTIFICATE", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_MAILSTATUS", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_MESSAGEDATA", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_MESSAGESENT", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_NO_CLIENT_CERTIFICATE", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_NO_PEER_CERTIFICATE", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_RCPTSTATUS", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_STARTTLS_OK", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_UNUSABLE_CA_LIST", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_UNUSABLE_CLIENT_CERTIFICATE", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_WEAK_CIPHER", type=>"IV", macro=>"1"},
            {name=>"SMTP_EV_WRONG_PEER_CERTIFICATE", type=>"IV", macro=>"1"},
            {name=>"Starttls_DISABLED", type=>"IV", macro=>"1"},
            {name=>"Starttls_ENABLED", type=>"IV", macro=>"1"},
            {name=>"Starttls_REQUIRED", type=>"IV", macro=>"1"},
            {name=>"Timeout_DATA", type=>"IV", macro=>"1"},
            {name=>"Timeout_DATA2", type=>"IV", macro=>"1"},
            {name=>"Timeout_ENVELOPE", type=>"IV", macro=>"1"},
            {name=>"Timeout_GREETING", type=>"IV", macro=>"1"},
            {name=>"Timeout_TRANSFER", type=>"IV", macro=>"1"});

print constant_types(); # macro defs
foreach (C_constant ("Net::ESMTP", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Net::ESMTP", $types);
__END__
   */

  switch (len) {
  case 8:
    /* Names all of length 8.  */
    /* Ret_FULL Ret_HDRS */
    /* Offset 4 gives the best switch position.  */
    switch (name[4]) {
    case 'F':
      if (memEQ(name, "Ret_FULL", 8)) {
      /*                   ^         */
        *iv_return = Ret_FULL;
        return PERL_constant_ISIV;
      }
      break;
    case 'H':
      if (memEQ(name, "Ret_HDRS", 8)) {
      /*                   ^         */
        *iv_return = Ret_HDRS;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 9:
    return constant_9 (aTHX_ name, iv_return);
    break;
  case 10:
    /* Names all of length 10.  */
    /* AUTH_REALM Ret_NOTSET */
    /* Offset 5 gives the best switch position.  */
    switch (name[5]) {
    case 'O':
      if (memEQ(name, "Ret_NOTSET", 10)) {
      /*                    ^           */
        *iv_return = Ret_NOTSET;
        return PERL_constant_ISIV;
      }
      break;
    case 'R':
      if (memEQ(name, "AUTH_REALM", 10)) {
      /*                    ^           */
#if defined(_auth_client_h)
        *iv_return = AUTH_REALM;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    /* Names all of length 13.  */
    /* Notify_NOTSET Timeout_DATA2 */
    /* Offset 10 gives the best switch position.  */
    switch (name[10]) {
    case 'S':
      if (memEQ(name, "Notify_NOTSET", 13)) {
      /*                         ^         */
        *iv_return = Notify_NOTSET;
        return PERL_constant_ISIV;
      }
      break;
    case 'T':
      if (memEQ(name, "Timeout_DATA2", 13)) {
      /*                         ^         */
        *iv_return = Timeout_DATA2;
        return PERL_constant_ISIV;
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
    /* Names all of length 23.  */
    /* SMTP_ERR_EAI_ADDRFAMILY SMTP_ERR_HOST_NOT_FOUND */
    /* Offset 16 gives the best switch position.  */
    switch (name[16]) {
    case 'R':
      if (memEQ(name, "SMTP_ERR_EAI_ADDRFAMILY", 23)) {
      /*                               ^             */
#ifdef SMTP_ERR_EAI_ADDRFAMILY
        *iv_return = SMTP_ERR_EAI_ADDRFAMILY;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "SMTP_ERR_HOST_NOT_FOUND", 23)) {
      /*                               ^             */
#ifdef SMTP_ERR_HOST_NOT_FOUND
        *iv_return = SMTP_ERR_HOST_NOT_FOUND;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 24:
    return constant_24 (aTHX_ name, iv_return);
    break;
  case 25:
    if (memEQ(name, "SMTP_EV_DELIVERBY_EXPIRED", 25)) {
      *iv_return = SMTP_EV_DELIVERBY_EXPIRED;
      return PERL_constant_ISIV;
    }
    break;
  case 27:
    /* Names all of length 27.  */
    /* SMTP_ERR_DROPPED_CONNECTION SMTP_EV_NO_PEER_CERTIFICATE */
    /* Offset 11 gives the best switch position.  */
    switch (name[11]) {
    case 'O':
      if (memEQ(name, "SMTP_ERR_DROPPED_CONNECTION", 27)) {
      /*                          ^                      */
#ifdef SMTP_ERR_DROPPED_CONNECTION
        *iv_return = SMTP_ERR_DROPPED_CONNECTION;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'P':
      if (memEQ(name, "SMTP_EV_NO_PEER_CERTIFICATE", 27)) {
      /*                          ^                      */
        *iv_return = SMTP_EV_NO_PEER_CERTIFICATE;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 29:
    if (memEQ(name, "SMTP_EV_NO_CLIENT_CERTIFICATE", 29)) {
      *iv_return = SMTP_EV_NO_CLIENT_CERTIFICATE;
      return PERL_constant_ISIV;
    }
    break;
  case 30:
    /* Names all of length 30.  */
    /* SMTP_ERR_UNTERMINATED_RESPONSE SMTP_EV_WRONG_PEER_CERTIFICATE */
    /* Offset 10 gives the best switch position.  */
    switch (name[10]) {
    case 'N':
      if (memEQ(name, "SMTP_ERR_UNTERMINATED_RESPONSE", 30)) {
      /*                         ^                          */
#ifdef SMTP_ERR_UNTERMINATED_RESPONSE
        *iv_return = SMTP_ERR_UNTERMINATED_RESPONSE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'O':
      if (memEQ(name, "SMTP_EV_WRONG_PEER_CERTIFICATE", 30)) {
      /*                         ^                          */
        *iv_return = SMTP_EV_WRONG_PEER_CERTIFICATE;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 32:
    return constant_32 (aTHX_ name, iv_return);
    break;
  case 35:
    if (memEQ(name, "SMTP_EV_UNUSABLE_CLIENT_CERTIFICATE", 35)) {
      *iv_return = SMTP_EV_UNUSABLE_CLIENT_CERTIFICATE;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

