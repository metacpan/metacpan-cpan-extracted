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
     Audio EE_OK Start */
  /* Offset 2 gives the best switch position.  */
  switch (name[2]) {
  case '_':
    if (memEQ(name, "EE_OK", 5)) {
    /*                 ^        */
#ifdef EE_OK
      *iv_return = EE_OK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'a':
    if (memEQ(name, "Start", 5)) {
    /*                 ^        */
#ifdef Start
      *iv_return = Start;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'd':
    if (memEQ(name, "Audio", 5)) {
    /*                 ^        */
#ifdef Audio
      *iv_return = Audio;
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
     EE_BUFFER_FULL N_SPEECH_PARAM espeakCAPITALS espeakEMPHASIS espeakENDPAUSE
     espeakPHONEMES */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'A':
    if (memEQ(name, "espeakCAPITALS", 14)) {
    /*                      ^             */
#ifdef espeakCAPITALS
      *iv_return = espeakCAPITALS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "EE_BUFFER_FULL", 14)) {
    /*                      ^             */
#ifdef EE_BUFFER_FULL
      *iv_return = EE_BUFFER_FULL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "N_SPEECH_PARAM", 14)) {
    /*                      ^             */
#ifdef N_SPEECH_PARAM
      *iv_return = N_SPEECH_PARAM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "espeakPHONEMES", 14)) {
    /*                      ^             */
#ifdef espeakPHONEMES
      *iv_return = espeakPHONEMES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "espeakEMPHASIS", 14)) {
    /*                      ^             */
#ifdef espeakEMPHASIS
      *iv_return = espeakEMPHASIS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "espeakENDPAUSE", 14)) {
    /*                      ^             */
#ifdef espeakENDPAUSE
      *iv_return = espeakENDPAUSE;
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
     espeakCHARS_8BIT espeakCHARS_AUTO espeakCHARS_UTF8 espeakLINELENGTH
     espeakPUNCT_NONE espeakPUNCT_SOME */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'F':
    if (memEQ(name, "espeakCHARS_UTF8", 16)) {
    /*                             ^        */
#ifdef espeakCHARS_UTF8
      *iv_return = espeakCHARS_UTF8;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "espeakCHARS_8BIT", 16)) {
    /*                             ^        */
#ifdef espeakCHARS_8BIT
      *iv_return = espeakCHARS_8BIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "espeakPUNCT_SOME", 16)) {
    /*                             ^        */
#ifdef espeakPUNCT_SOME
      *iv_return = espeakPUNCT_SOME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "espeakPUNCT_NONE", 16)) {
    /*                             ^        */
#ifdef espeakPUNCT_NONE
      *iv_return = espeakPUNCT_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "espeakCHARS_AUTO", 16)) {
    /*                             ^        */
#ifdef espeakCHARS_AUTO
      *iv_return = espeakCHARS_AUTO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "espeakLINELENGTH", 16)) {
    /*                             ^        */
#ifdef espeakLINELENGTH
      *iv_return = espeakLINELENGTH;
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
     EE_INTERNAL_ERROR espeakCHARS_WCHAR espeakPUNCTUATION */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'L':
    if (memEQ(name, "EE_INTERNAL_ERROR", 17)) {
    /*                         ^             */
#ifdef EE_INTERNAL_ERROR
      *iv_return = EE_INTERNAL_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "espeakCHARS_WCHAR", 17)) {
    /*                         ^             */
#ifdef espeakCHARS_WCHAR
      *iv_return = espeakCHARS_WCHAR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "espeakPUNCTUATION", 17)) {
    /*                         ^             */
#ifdef espeakPUNCTUATION
      *iv_return = espeakPUNCTUATION;
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
my @names = (qw(AUDIO_OUTPUT_PLAYBACK AUDIO_OUTPUT_RETRIEVAL
	       AUDIO_OUTPUT_SYNCHRONOUS Audio EE_BUFFER_FULL EE_INTERNAL_ERROR
	       EE_OK End Mark N_SPEECH_PARAM POS_CHARACTER POS_SENTENCE
	       POS_WORD Retrieval Start espeakCAPITALS espeakCHARS_8BIT
	       espeakCHARS_AUTO espeakCHARS_UTF8 espeakCHARS_WCHAR
	       espeakEMPHASIS espeakENDPAUSE espeakEVENT_LIST_TERMINATED
	       espeakKEEP_NAMEDATA espeakLINELENGTH espeakPHONEMES espeakPITCH
	       espeakPUNCTUATION espeakPUNCT_ALL espeakPUNCT_NONE
	       espeakPUNCT_SOME espeakRANGE espeakRATE espeakSILENCE espeakSSML
	       espeakVOLUME));

print constant_types(); # macro defs
foreach (C_constant ("Speech::eSpeak", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Speech::eSpeak", $types);
__END__
   */

  switch (len) {
  case 3:
    if (memEQ(name, "End", 3)) {
#ifdef End
      *iv_return = End;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 4:
    if (memEQ(name, "Mark", 4)) {
#ifdef Mark
      *iv_return = Mark;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 5:
    return constant_5 (aTHX_ name, iv_return);
    break;
  case 8:
    if (memEQ(name, "POS_WORD", 8)) {
#ifdef POS_WORD
      *iv_return = POS_WORD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 9:
    if (memEQ(name, "Retrieval", 9)) {
#ifdef Retrieval
      *iv_return = Retrieval;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 10:
    /* Names all of length 10.  */
    /* espeakRATE espeakSSML */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case 'R':
      if (memEQ(name, "espeakRATE", 10)) {
      /*                     ^          */
#ifdef espeakRATE
        *iv_return = espeakRATE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "espeakSSML", 10)) {
      /*                     ^          */
#ifdef espeakSSML
        *iv_return = espeakSSML;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 11:
    /* Names all of length 11.  */
    /* espeakPITCH espeakRANGE */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case 'P':
      if (memEQ(name, "espeakPITCH", 11)) {
      /*                     ^           */
#ifdef espeakPITCH
        *iv_return = espeakPITCH;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'R':
      if (memEQ(name, "espeakRANGE", 11)) {
      /*                     ^           */
#ifdef espeakRANGE
        *iv_return = espeakRANGE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 12:
    /* Names all of length 12.  */
    /* POS_SENTENCE espeakVOLUME */
    /* Offset 7 gives the best switch position.  */
    switch (name[7]) {
    case 'O':
      if (memEQ(name, "espeakVOLUME", 12)) {
      /*                      ^           */
#ifdef espeakVOLUME
        *iv_return = espeakVOLUME;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "POS_SENTENCE", 12)) {
      /*                      ^           */
#ifdef POS_SENTENCE
        *iv_return = POS_SENTENCE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 13:
    /* Names all of length 13.  */
    /* POS_CHARACTER espeakSILENCE */
    /* Offset 9 gives the best switch position.  */
    switch (name[9]) {
    case 'C':
      if (memEQ(name, "POS_CHARACTER", 13)) {
      /*                        ^          */
#ifdef POS_CHARACTER
        *iv_return = POS_CHARACTER;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'E':
      if (memEQ(name, "espeakSILENCE", 13)) {
      /*                        ^          */
#ifdef espeakSILENCE
        *iv_return = espeakSILENCE;
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
    if (memEQ(name, "espeakPUNCT_ALL", 15)) {
#ifdef espeakPUNCT_ALL
      *iv_return = espeakPUNCT_ALL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 19:
    if (memEQ(name, "espeakKEEP_NAMEDATA", 19)) {
#ifdef espeakKEEP_NAMEDATA
      *iv_return = espeakKEEP_NAMEDATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 21:
    if (memEQ(name, "AUDIO_OUTPUT_PLAYBACK", 21)) {
#ifdef AUDIO_OUTPUT_PLAYBACK
      *iv_return = AUDIO_OUTPUT_PLAYBACK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 22:
    if (memEQ(name, "AUDIO_OUTPUT_RETRIEVAL", 22)) {
#ifdef AUDIO_OUTPUT_RETRIEVAL
      *iv_return = AUDIO_OUTPUT_RETRIEVAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 24:
    if (memEQ(name, "AUDIO_OUTPUT_SYNCHRONOUS", 24)) {
#ifdef AUDIO_OUTPUT_SYNCHRONOUS
      *iv_return = AUDIO_OUTPUT_SYNCHRONOUS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 27:
    if (memEQ(name, "espeakEVENT_LIST_TERMINATED", 27)) {
#ifdef espeakEVENT_LIST_TERMINATED
      *iv_return = espeakEVENT_LIST_TERMINATED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

