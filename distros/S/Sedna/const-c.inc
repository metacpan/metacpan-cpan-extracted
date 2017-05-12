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
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SEDNA_DEBUG_ON SEDNA_LOG_FULL SEDNA_LOG_LESS */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'F':
    if (memEQ(name, "SEDNA_LOG_FULL", 14)) {
    /*                         ^          */
#ifdef SEDNA_LOG_FULL
      *iv_return = SEDNA_LOG_FULL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "SEDNA_DEBUG_ON", 14)) {
    /*                         ^          */
#ifdef SEDNA_DEBUG_ON
      *iv_return = SEDNA_DEBUG_ON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "SEDNA_LOG_LESS", 14)) {
    /*                         ^          */
#ifdef SEDNA_LOG_LESS
      *iv_return = SEDNA_LOG_LESS;
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
     SEDNA_AUTOCOMMIT_ON SEDNA_CONNECTION_OK SEDNA_UPDATE_FAILED */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'O':
    if (memEQ(name, "SEDNA_CONNECTION_OK", 19)) {
    /*                      ^                  */
#ifdef SEDNA_CONNECTION_OK
      *iv_return = SEDNA_CONNECTION_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "SEDNA_UPDATE_FAILED", 19)) {
    /*                      ^                  */
#ifdef SEDNA_UPDATE_FAILED
      *iv_return = SEDNA_UPDATE_FAILED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "SEDNA_AUTOCOMMIT_ON", 19)) {
    /*                      ^                  */
#ifdef SEDNA_AUTOCOMMIT_ON
      *iv_return = SEDNA_AUTOCOMMIT_ON;
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
     QUERY_EXECUTION_TIME SEDNA_AUTOCOMMIT_OFF SEDNA_NO_TRANSACTION
     SEDNA_SESSION_CLOSED */
  /* Offset 19 gives the best switch position.  */
  switch (name[19]) {
  case 'D':
    if (memEQ(name, "SEDNA_SESSION_CLOSE", 19)) {
    /*                                  D      */
#ifdef SEDNA_SESSION_CLOSED
      *iv_return = SEDNA_SESSION_CLOSED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "QUERY_EXECUTION_TIM", 19)) {
    /*                                  E      */
#ifdef QUERY_EXECUTION_TIME
      *iv_return = QUERY_EXECUTION_TIME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "SEDNA_AUTOCOMMIT_OF", 19)) {
    /*                                  F      */
#ifdef SEDNA_AUTOCOMMIT_OFF
      *iv_return = SEDNA_AUTOCOMMIT_OFF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "SEDNA_NO_TRANSACTIO", 19)) {
    /*                                  N      */
#ifdef SEDNA_NO_TRANSACTION
      *iv_return = SEDNA_NO_TRANSACTION;
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
     SEDNA_BULK_LOAD_FAILED SEDNA_NEXT_ITEM_FAILED SEDNA_UPDATE_SUCCEEDED */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'E':
    if (memEQ(name, "SEDNA_UPDATE_SUCCEEDED", 22)) {
    /*                          ^                 */
#ifdef SEDNA_UPDATE_SUCCEEDED
      *iv_return = SEDNA_UPDATE_SUCCEEDED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "SEDNA_NEXT_ITEM_FAILED", 22)) {
    /*                          ^                 */
#ifdef SEDNA_NEXT_ITEM_FAILED
      *iv_return = SEDNA_NEXT_ITEM_FAILED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "SEDNA_BULK_LOAD_FAILED", 22)) {
    /*                          ^                 */
#ifdef SEDNA_BULK_LOAD_FAILED
      *iv_return = SEDNA_BULK_LOAD_FAILED;
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
     SEDNA_CONNECTION_CLOSED SEDNA_CONNECTION_FAILED SEDNA_DATA_CHUNK_LOADED */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case 'C':
    if (memEQ(name, "SEDNA_CONNECTION_CLOSED", 23)) {
    /*                                ^            */
#ifdef SEDNA_CONNECTION_CLOSED
      *iv_return = SEDNA_CONNECTION_CLOSED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "SEDNA_CONNECTION_FAILED", 23)) {
    /*                                ^            */
#ifdef SEDNA_CONNECTION_FAILED
      *iv_return = SEDNA_CONNECTION_FAILED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "SEDNA_DATA_CHUNK_LOADED", 23)) {
    /*                                ^            */
#ifdef SEDNA_DATA_CHUNK_LOADED
      *iv_return = SEDNA_DATA_CHUNK_LOADED;
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
     SEDNA_BULK_LOAD_SUCCEEDED SEDNA_NEXT_ITEM_SUCCEEDED
     SEDNA_OPEN_SESSION_FAILED SEDNA_OPERATION_SUCCEEDED */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'K':
    if (memEQ(name, "SEDNA_BULK_LOAD_SUCCEEDED", 25)) {
    /*                        ^                      */
#ifdef SEDNA_BULK_LOAD_SUCCEEDED
      *iv_return = SEDNA_BULK_LOAD_SUCCEEDED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "SEDNA_OPEN_SESSION_FAILED", 25)) {
    /*                        ^                      */
#ifdef SEDNA_OPEN_SESSION_FAILED
      *iv_return = SEDNA_OPEN_SESSION_FAILED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "SEDNA_OPERATION_SUCCEEDED", 25)) {
    /*                        ^                      */
#ifdef SEDNA_OPERATION_SUCCEEDED
      *iv_return = SEDNA_OPERATION_SUCCEEDED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "SEDNA_NEXT_ITEM_SUCCEEDED", 25)) {
    /*                        ^                      */
#ifdef SEDNA_NEXT_ITEM_SUCCEEDED
      *iv_return = SEDNA_NEXT_ITEM_SUCCEEDED;
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
constant_33 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SEDNA_BEGIN_TRANSACTION_SUCCEEDED SEDNA_BOUNDARY_SPACE_PRESERVE_OFF
     SEDNA_ROLLBACK_TRANSACTION_FAILED */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'P':
    if (memEQ(name, "SEDNA_BOUNDARY_SPACE_PRESERVE_OFF", 33)) {
    /*                               ^                       */
#ifdef SEDNA_BOUNDARY_SPACE_PRESERVE_OFF
      *iv_return = SEDNA_BOUNDARY_SPACE_PRESERVE_OFF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "SEDNA_ROLLBACK_TRANSACTION_FAILED", 33)) {
    /*                               ^                       */
#ifdef SEDNA_ROLLBACK_TRANSACTION_FAILED
      *iv_return = SEDNA_ROLLBACK_TRANSACTION_FAILED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "SEDNA_BEGIN_TRANSACTION_SUCCEEDED", 33)) {
    /*                               ^                       */
#ifdef SEDNA_BEGIN_TRANSACTION_SUCCEEDED
      *iv_return = SEDNA_BEGIN_TRANSACTION_SUCCEEDED;
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

#!/home/ruoso/perl5/perlbrew/perls/perl-5.12.1/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(BULK_LOAD_PORTION QUERY_EXECUTION_TIME
	       SEDNA_AUTHENTICATION_FAILED SEDNA_AUTOCOMMIT_OFF
	       SEDNA_AUTOCOMMIT_ON SEDNA_BEGIN_TRANSACTION_FAILED
	       SEDNA_BEGIN_TRANSACTION_SUCCEEDED
	       SEDNA_BOUNDARY_SPACE_PRESERVE_OFF
	       SEDNA_BOUNDARY_SPACE_PRESERVE_ON SEDNA_BULK_LOAD_FAILED
	       SEDNA_BULK_LOAD_SUCCEEDED SEDNA_CLOSE_SESSION_FAILED
	       SEDNA_COMMIT_TRANSACTION_FAILED
	       SEDNA_COMMIT_TRANSACTION_SUCCEEDED SEDNA_CONNECTION_CLOSED
	       SEDNA_CONNECTION_FAILED SEDNA_CONNECTION_OK
	       SEDNA_DATA_CHUNK_LOADED SEDNA_DEBUG_OFF SEDNA_DEBUG_ON
	       SEDNA_ERROR SEDNA_GET_ATTRIBUTE_SUCCEEDED SEDNA_LOG_FULL
	       SEDNA_LOG_LESS SEDNA_NEXT_ITEM_FAILED SEDNA_NEXT_ITEM_SUCCEEDED
	       SEDNA_NO_ITEM SEDNA_NO_TRANSACTION SEDNA_OPEN_SESSION_FAILED
	       SEDNA_OPERATION_SUCCEEDED SEDNA_QUERY_FAILED
	       SEDNA_QUERY_SUCCEEDED SEDNA_READONLY_TRANSACTION
	       SEDNA_RESET_ATTRIBUTES_SUCCEEDED SEDNA_RESULT_END
	       SEDNA_ROLLBACK_TRANSACTION_FAILED
	       SEDNA_ROLLBACK_TRANSACTION_SUCCEEDED SEDNA_SESSION_CLOSED
	       SEDNA_SESSION_OPEN SEDNA_SET_ATTRIBUTE_SUCCEEDED
	       SEDNA_TRANSACTION_ACTIVE SEDNA_UPDATE_FAILED
	       SEDNA_UPDATE_SUCCEEDED SEDNA_UPDATE_TRANSACTION));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Sedna", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Sedna", $types);
__END__
   */

  switch (len) {
  case 11:
    if (memEQ(name, "SEDNA_ERROR", 11)) {
#ifdef SEDNA_ERROR
      *iv_return = SEDNA_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 13:
    if (memEQ(name, "SEDNA_NO_ITEM", 13)) {
#ifdef SEDNA_NO_ITEM
      *iv_return = SEDNA_NO_ITEM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    if (memEQ(name, "SEDNA_DEBUG_OFF", 15)) {
#ifdef SEDNA_DEBUG_OFF
      *iv_return = SEDNA_DEBUG_OFF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 16:
    if (memEQ(name, "SEDNA_RESULT_END", 16)) {
#ifdef SEDNA_RESULT_END
      *iv_return = SEDNA_RESULT_END;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 17:
    if (memEQ(name, "BULK_LOAD_PORTION", 17)) {
#ifdef BULK_LOAD_PORTION
      *iv_return = BULK_LOAD_PORTION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 18:
    /* Names all of length 18.  */
    /* SEDNA_QUERY_FAILED SEDNA_SESSION_OPEN */
    /* Offset 9 gives the best switch position.  */
    switch (name[9]) {
    case 'R':
      if (memEQ(name, "SEDNA_QUERY_FAILED", 18)) {
      /*                        ^               */
#ifdef SEDNA_QUERY_FAILED
        *iv_return = SEDNA_QUERY_FAILED;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "SEDNA_SESSION_OPEN", 18)) {
      /*                        ^               */
#ifdef SEDNA_SESSION_OPEN
        *iv_return = SEDNA_SESSION_OPEN;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 19:
    return constant_19 (aTHX_ name, iv_return);
    break;
  case 20:
    return constant_20 (aTHX_ name, iv_return);
    break;
  case 21:
    if (memEQ(name, "SEDNA_QUERY_SUCCEEDED", 21)) {
#ifdef SEDNA_QUERY_SUCCEEDED
      *iv_return = SEDNA_QUERY_SUCCEEDED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 22:
    return constant_22 (aTHX_ name, iv_return);
    break;
  case 23:
    return constant_23 (aTHX_ name, iv_return);
    break;
  case 24:
    /* Names all of length 24.  */
    /* SEDNA_TRANSACTION_ACTIVE SEDNA_UPDATE_TRANSACTION */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case 'T':
      if (memEQ(name, "SEDNA_TRANSACTION_ACTIVE", 24)) {
      /*                     ^                        */
#ifdef SEDNA_TRANSACTION_ACTIVE
        *iv_return = SEDNA_TRANSACTION_ACTIVE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'U':
      if (memEQ(name, "SEDNA_UPDATE_TRANSACTION", 24)) {
      /*                     ^                        */
#ifdef SEDNA_UPDATE_TRANSACTION
        *iv_return = SEDNA_UPDATE_TRANSACTION;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 25:
    return constant_25 (aTHX_ name, iv_return);
    break;
  case 26:
    /* Names all of length 26.  */
    /* SEDNA_CLOSE_SESSION_FAILED SEDNA_READONLY_TRANSACTION */
    /* Offset 15 gives the best switch position.  */
    switch (name[15]) {
    case 'S':
      if (memEQ(name, "SEDNA_CLOSE_SESSION_FAILED", 26)) {
      /*                              ^                 */
#ifdef SEDNA_CLOSE_SESSION_FAILED
        *iv_return = SEDNA_CLOSE_SESSION_FAILED;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "SEDNA_READONLY_TRANSACTION", 26)) {
      /*                              ^                 */
#ifdef SEDNA_READONLY_TRANSACTION
        *iv_return = SEDNA_READONLY_TRANSACTION;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 27:
    if (memEQ(name, "SEDNA_AUTHENTICATION_FAILED", 27)) {
#ifdef SEDNA_AUTHENTICATION_FAILED
      *iv_return = SEDNA_AUTHENTICATION_FAILED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 29:
    /* Names all of length 29.  */
    /* SEDNA_GET_ATTRIBUTE_SUCCEEDED SEDNA_SET_ATTRIBUTE_SUCCEEDED */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case 'G':
      if (memEQ(name, "SEDNA_GET_ATTRIBUTE_SUCCEEDED", 29)) {
      /*                     ^                             */
#ifdef SEDNA_GET_ATTRIBUTE_SUCCEEDED
        *iv_return = SEDNA_GET_ATTRIBUTE_SUCCEEDED;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "SEDNA_SET_ATTRIBUTE_SUCCEEDED", 29)) {
      /*                     ^                             */
#ifdef SEDNA_SET_ATTRIBUTE_SUCCEEDED
        *iv_return = SEDNA_SET_ATTRIBUTE_SUCCEEDED;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 30:
    if (memEQ(name, "SEDNA_BEGIN_TRANSACTION_FAILED", 30)) {
#ifdef SEDNA_BEGIN_TRANSACTION_FAILED
      *iv_return = SEDNA_BEGIN_TRANSACTION_FAILED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 31:
    if (memEQ(name, "SEDNA_COMMIT_TRANSACTION_FAILED", 31)) {
#ifdef SEDNA_COMMIT_TRANSACTION_FAILED
      *iv_return = SEDNA_COMMIT_TRANSACTION_FAILED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 32:
    /* Names all of length 32.  */
    /* SEDNA_BOUNDARY_SPACE_PRESERVE_ON SEDNA_RESET_ATTRIBUTES_SUCCEEDED */
    /* Offset 15 gives the best switch position.  */
    switch (name[15]) {
    case 'R':
      if (memEQ(name, "SEDNA_RESET_ATTRIBUTES_SUCCEEDED", 32)) {
      /*                              ^                       */
#ifdef SEDNA_RESET_ATTRIBUTES_SUCCEEDED
        *iv_return = SEDNA_RESET_ATTRIBUTES_SUCCEEDED;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "SEDNA_BOUNDARY_SPACE_PRESERVE_ON", 32)) {
      /*                              ^                       */
#ifdef SEDNA_BOUNDARY_SPACE_PRESERVE_ON
        *iv_return = SEDNA_BOUNDARY_SPACE_PRESERVE_ON;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 33:
    return constant_33 (aTHX_ name, iv_return);
    break;
  case 34:
    if (memEQ(name, "SEDNA_COMMIT_TRANSACTION_SUCCEEDED", 34)) {
#ifdef SEDNA_COMMIT_TRANSACTION_SUCCEEDED
      *iv_return = SEDNA_COMMIT_TRANSACTION_SUCCEEDED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 36:
    if (memEQ(name, "SEDNA_ROLLBACK_TRANSACTION_SUCCEEDED", 36)) {
#ifdef SEDNA_ROLLBACK_TRANSACTION_SUCCEEDED
      *iv_return = SEDNA_ROLLBACK_TRANSACTION_SUCCEEDED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

