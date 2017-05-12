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
constant_5 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     H_ADD H_END H_SET */
  /* Offset 3 gives the best switch position.  */
  switch (name[3]) {
  case 'D':
    if (memEQ(name, "H_ADD", 5)) {
    /*                  ^       */
#ifdef H_ADD
      *iv_return = H_ADD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "H_SET", 5)) {
    /*                  ^       */
#ifdef H_SET
      *iv_return = H_SET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "H_END", 5)) {
    /*                  ^       */
#ifdef H_END
      *iv_return = H_END;
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
constant_6 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CC_EOF H_CURR H_FUNC H_LAST H_LOAD H_NEXT H_PREV H_SAVE */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'A':
    if (memEQ(name, "H_LOAD", 6)) {
    /*                   ^       */
#ifdef H_LOAD
      *iv_return = H_LOAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "H_PREV", 6)) {
    /*                   ^       */
#ifdef H_PREV
      *iv_return = H_PREV;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "H_FUNC", 6)) {
    /*                   ^       */
#ifdef H_FUNC
      *iv_return = H_FUNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "CC_EOF", 6)) {
    /*                   ^       */
#ifdef CC_EOF
      *iv_return = CC_EOF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "H_CURR", 6)) {
    /*                   ^       */
#ifdef H_CURR
      *iv_return = H_CURR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "H_LAST", 6)) {
    /*                   ^       */
#ifdef H_LAST
      *iv_return = H_LAST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "H_SAVE", 6)) {
    /*                   ^       */
#ifdef H_SAVE
      *iv_return = H_SAVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "H_NEXT", 6)) {
    /*                   ^       */
#ifdef H_NEXT
      *iv_return = H_NEXT;
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
constant_7 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CC_NORM EL_BIND EL_HIST H_CLEAR H_ENTER H_FIRST */
  /* Offset 3 gives the best switch position.  */
  switch (name[3]) {
  case 'B':
    if (memEQ(name, "EL_BIND", 7)) {
    /*                  ^         */
#ifdef EL_BIND
      *iv_return = EL_BIND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "EL_HIST", 7)) {
    /*                  ^         */
#ifdef EL_HIST
      *iv_return = EL_HIST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "H_FIRST", 7)) {
    /*                  ^         */
#ifdef H_FIRST
      *iv_return = H_FIRST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "H_CLEAR", 7)) {
    /*                  ^         */
#ifdef H_CLEAR
      *iv_return = H_CLEAR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "CC_NORM", 7)) {
    /*                  ^         */
#ifdef CC_NORM
      *iv_return = CC_NORM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "H_ENTER", 7)) {
    /*                  ^         */
#ifdef H_ENTER
      *iv_return = H_ENTER;
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
constant_8 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     CC_ERROR CC_FATAL EL_ADDFN EL_SETTC EL_SETTY H_APPEND */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'C':
    if (memEQ(name, "EL_SETTC", 8)) {
    /*                      ^      */
#ifdef EL_SETTC
      *iv_return = EL_SETTC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "H_APPEND", 8)) {
    /*                      ^      */
#ifdef H_APPEND
      *iv_return = H_APPEND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "CC_FATAL", 8)) {
    /*                      ^      */
#ifdef CC_FATAL
      *iv_return = CC_FATAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "EL_ADDFN", 8)) {
    /*                      ^      */
#ifdef EL_ADDFN
      *iv_return = EL_ADDFN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CC_ERROR", 8)) {
    /*                      ^      */
#ifdef CC_ERROR
      *iv_return = CC_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "EL_SETTY", 8)) {
    /*                      ^      */
#ifdef EL_SETTY
      *iv_return = EL_SETTY;
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
     CC_CURSOR EL_ECHOTC EL_EDITOR EL_GETCFN EL_PROMPT EL_SIGNAL EL_TELLTC
     H_GETSIZE H_SETSIZE */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'G':
    if (memEQ(name, "EL_SIGNAL", 9)) {
    /*                    ^         */
#ifdef EL_SIGNAL
      *iv_return = EL_SIGNAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "EL_ECHOTC", 9)) {
    /*                    ^         */
#ifdef EL_ECHOTC
      *iv_return = EL_ECHOTC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "EL_EDITOR", 9)) {
    /*                    ^         */
#ifdef EL_EDITOR
      *iv_return = EL_EDITOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "EL_TELLTC", 9)) {
    /*                    ^         */
#ifdef EL_TELLTC
      *iv_return = EL_TELLTC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "EL_PROMPT", 9)) {
    /*                    ^         */
#ifdef EL_PROMPT
      *iv_return = EL_PROMPT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "CC_CURSOR", 9)) {
    /*                    ^         */
#ifdef CC_CURSOR
      *iv_return = CC_CURSOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "H_GETSIZE", 9)) {
    /*                    ^         */
#ifdef H_GETSIZE
      *iv_return = H_GETSIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "H_SETSIZE", 9)) {
    /*                    ^         */
#ifdef H_SETSIZE
      *iv_return = H_SETSIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "EL_GETCFN", 9)) {
    /*                    ^         */
#ifdef EL_GETCFN
      *iv_return = EL_GETCFN;
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
     CC_ARGHACK CC_NEWLINE CC_REFRESH EL_RPROMPT H_NEXT_STR H_PREV_STR */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'F':
    if (memEQ(name, "CC_REFRESH", 10)) {
    /*                    ^           */
#ifdef CC_REFRESH
      *iv_return = CC_REFRESH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "CC_ARGHACK", 10)) {
    /*                    ^           */
#ifdef CC_ARGHACK
      *iv_return = CC_ARGHACK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "EL_RPROMPT", 10)) {
    /*                    ^           */
#ifdef EL_RPROMPT
      *iv_return = EL_RPROMPT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "H_NEXT_STR", 10)) {
    /*                    ^           */
#ifdef H_NEXT_STR
      *iv_return = H_NEXT_STR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "H_PREV_STR", 10)) {
    /*                    ^           */
#ifdef H_PREV_STR
      *iv_return = H_PREV_STR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "CC_NEWLINE", 10)) {
    /*                    ^           */
#ifdef CC_NEWLINE
      *iv_return = CC_NEWLINE;
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
     CC_REDISPLAY H_NEXT_EVENT H_PREV_EVENT */
  /* Offset 2 gives the best switch position.  */
  switch (name[2]) {
  case 'N':
    if (memEQ(name, "H_NEXT_EVENT", 12)) {
    /*                 ^                */
#ifdef H_NEXT_EVENT
      *iv_return = H_NEXT_EVENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "H_PREV_EVENT", 12)) {
    /*                 ^                */
#ifdef H_PREV_EVENT
      *iv_return = H_PREV_EVENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "CC_REDISPLAY", 12)) {
    /*                 ^                */
#ifdef CC_REDISPLAY
      *iv_return = CC_REDISPLAY;
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
my @names = (qw(CC_ARGHACK CC_CURSOR CC_EOF CC_ERROR CC_FATAL CC_NEWLINE
	       CC_NORM CC_REDISPLAY CC_REFRESH CC_REFRESH_BEEP EL_ADDFN EL_BIND
	       EL_BUILTIN_GETCFN EL_CLIENTDATA EL_ECHOTC EL_EDITMODE EL_EDITOR
	       EL_GETCFN EL_HIST EL_PROMPT EL_RPROMPT EL_SETTC EL_SETTY
	       EL_SIGNAL EL_TELLTC EL_TERMINAL H_ADD H_APPEND H_CLEAR H_CURR
	       H_END H_ENTER H_FIRST H_FUNC H_GETSIZE H_LAST H_LOAD H_NEXT
	       H_NEXT_EVENT H_NEXT_STR H_PREV H_PREV_EVENT H_PREV_STR H_SAVE
	       H_SET H_SETSIZE));

print constant_types(); # macro defs
foreach (C_constant ("Term::EditLine", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Term::EditLine", $types);
__END__
   */

  switch (len) {
  case 5:
    return constant_5 (aTHX_ name, iv_return);
    break;
  case 6:
    return constant_6 (aTHX_ name, iv_return);
    break;
  case 7:
    return constant_7 (aTHX_ name, iv_return);
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
    /* Names all of length 11.  */
    /* EL_EDITMODE EL_TERMINAL */
    /* Offset 4 gives the best switch position.  */
    switch (name[4]) {
    case 'D':
      if (memEQ(name, "EL_EDITMODE", 11)) {
      /*                   ^             */
#ifdef EL_EDITMODE
        *iv_return = EL_EDITMODE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'E':
      if (memEQ(name, "EL_TERMINAL", 11)) {
      /*                   ^             */
#ifdef EL_TERMINAL
        *iv_return = EL_TERMINAL;
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
    if (memEQ(name, "EL_CLIENTDATA", 13)) {
#ifdef EL_CLIENTDATA
      *iv_return = EL_CLIENTDATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 15:
    if (memEQ(name, "CC_REFRESH_BEEP", 15)) {
#ifdef CC_REFRESH_BEEP
      *iv_return = CC_REFRESH_BEEP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 17:
    if (memEQ(name, "EL_BUILTIN_GETCFN", 17)) {
#ifdef EL_BUILTIN_GETCFN
      *iv_return = EL_BUILTIN_GETCFN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

