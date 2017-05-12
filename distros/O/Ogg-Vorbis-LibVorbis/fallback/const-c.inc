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
constant_7 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     INITSET NOTOPEN OV_HOLE */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'O':
    if (memEQ(name, "OV_HOLE", 7)) {
    /*                   ^        */
#ifdef OV_HOLE
      *iv_return = OV_HOLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "NOTOPEN", 7)) {
    /*                   ^        */
#ifdef NOTOPEN
      *iv_return = NOTOPEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "INITSET", 7)) {
    /*                   ^        */
#ifdef INITSET
      *iv_return = INITSET;
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
     OV_EIMPL OV_EREAD OV_FALSE PARTOPEN */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'D':
    if (memEQ(name, "OV_EREA", 7)) {
    /*                      D     */
#ifdef OV_EREAD
      *iv_return = OV_EREAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "OV_FALS", 7)) {
    /*                      E     */
#ifdef OV_FALSE
      *iv_return = OV_FALSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "OV_EIMP", 7)) {
    /*                      L     */
#ifdef OV_EIMPL
      *iv_return = OV_EIMPL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "PARTOPE", 7)) {
    /*                      N     */
#ifdef PARTOPEN
      *iv_return = PARTOPEN;
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
     OV_EFAULT OV_EINVAL STREAMSET */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'S':
    if (memEQ(name, "STREAMSET", 9)) {
    /*                     ^        */
#ifdef STREAMSET
      *iv_return = STREAMSET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "OV_EFAULT", 9)) {
    /*                     ^        */
#ifdef OV_EFAULT
      *iv_return = OV_EFAULT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "OV_EINVAL", 9)) {
    /*                     ^        */
#ifdef OV_EINVAL
      *iv_return = OV_EINVAL;
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
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     OV_EBADHEADER OV_EBADPACKET OV_ENOTVORBIS */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'R':
    if (memEQ(name, "OV_EBADHEADE", 12)) {
    /*                           R      */
#ifdef OV_EBADHEADER
      *iv_return = OV_EBADHEADER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "OV_ENOTVORBI", 12)) {
    /*                           S      */
#ifdef OV_ENOTVORBIS
      *iv_return = OV_ENOTVORBIS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "OV_EBADPACKE", 12)) {
    /*                           T      */
#ifdef OV_EBADPACKET
      *iv_return = OV_EBADPACKET;
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
     OV_ECTL_RATEMANAGE_AVG OV_ECTL_RATEMANAGE_GET OV_ECTL_RATEMANAGE_SET */
  /* Offset 19 gives the best switch position.  */
  switch (name[19]) {
  case 'A':
    if (memEQ(name, "OV_ECTL_RATEMANAGE_AVG", 22)) {
    /*                                  ^         */
#ifdef OV_ECTL_RATEMANAGE_AVG
      *iv_return = OV_ECTL_RATEMANAGE_AVG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "OV_ECTL_RATEMANAGE_GET", 22)) {
    /*                                  ^         */
#ifdef OV_ECTL_RATEMANAGE_GET
      *iv_return = OV_ECTL_RATEMANAGE_GET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "OV_ECTL_RATEMANAGE_SET", 22)) {
    /*                                  ^         */
#ifdef OV_ECTL_RATEMANAGE_SET
      *iv_return = OV_ECTL_RATEMANAGE_SET;
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
     OV_ECTL_RATEMANAGE2_GET OV_ECTL_RATEMANAGE2_SET OV_ECTL_RATEMANAGE_HARD */
  /* Offset 20 gives the best switch position.  */
  switch (name[20]) {
  case 'A':
    if (memEQ(name, "OV_ECTL_RATEMANAGE_HARD", 23)) {
    /*                                   ^         */
#ifdef OV_ECTL_RATEMANAGE_HARD
      *iv_return = OV_ECTL_RATEMANAGE_HARD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "OV_ECTL_RATEMANAGE2_GET", 23)) {
    /*                                   ^         */
#ifdef OV_ECTL_RATEMANAGE2_GET
      *iv_return = OV_ECTL_RATEMANAGE2_GET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "OV_ECTL_RATEMANAGE2_SET", 23)) {
    /*                                   ^         */
#ifdef OV_ECTL_RATEMANAGE2_SET
      *iv_return = OV_ECTL_RATEMANAGE2_SET;
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

#!/opt/local/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(INITSET NOTOPEN OPENED OV_EBADHEADER OV_EBADLINK OV_EBADPACKET
	       OV_ECTL_IBLOCK_GET OV_ECTL_IBLOCK_SET OV_ECTL_LOWPASS_GET
	       OV_ECTL_LOWPASS_SET OV_ECTL_RATEMANAGE2_GET
	       OV_ECTL_RATEMANAGE2_SET OV_ECTL_RATEMANAGE_AVG
	       OV_ECTL_RATEMANAGE_GET OV_ECTL_RATEMANAGE_HARD
	       OV_ECTL_RATEMANAGE_SET OV_EFAULT OV_EIMPL OV_EINVAL OV_ENOSEEK
	       OV_ENOTAUDIO OV_ENOTVORBIS OV_EOF OV_EREAD OV_EVERSION OV_FALSE
	       OV_HOLE PARTOPEN STREAMSET));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Ogg::Vorbis::LibVorbis", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Ogg::Vorbis::LibVorbis", $types);
__END__
   */

  switch (len) {
  case 6:
    /* Names all of length 6.  */
    /* OPENED OV_EOF */
    /* Offset 5 gives the best switch position.  */
    switch (name[5]) {
    case 'D':
      if (memEQ(name, "OPENE", 5)) {
      /*                    D     */
#ifdef OPENED
        *iv_return = OPENED;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'F':
      if (memEQ(name, "OV_EO", 5)) {
      /*                    F     */
#ifdef OV_EOF
        *iv_return = OV_EOF;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
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
    if (memEQ(name, "OV_ENOSEEK", 10)) {
#ifdef OV_ENOSEEK
      *iv_return = OV_ENOSEEK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 11:
    /* Names all of length 11.  */
    /* OV_EBADLINK OV_EVERSION */
    /* Offset 9 gives the best switch position.  */
    switch (name[9]) {
    case 'N':
      if (memEQ(name, "OV_EBADLINK", 11)) {
      /*                        ^        */
#ifdef OV_EBADLINK
        *iv_return = OV_EBADLINK;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'O':
      if (memEQ(name, "OV_EVERSION", 11)) {
      /*                        ^        */
#ifdef OV_EVERSION
        *iv_return = OV_EVERSION;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 12:
    if (memEQ(name, "OV_ENOTAUDIO", 12)) {
#ifdef OV_ENOTAUDIO
      *iv_return = OV_ENOTAUDIO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 18:
    /* Names all of length 18.  */
    /* OV_ECTL_IBLOCK_GET OV_ECTL_IBLOCK_SET */
    /* Offset 15 gives the best switch position.  */
    switch (name[15]) {
    case 'G':
      if (memEQ(name, "OV_ECTL_IBLOCK_GET", 18)) {
      /*                              ^         */
#ifdef OV_ECTL_IBLOCK_GET
        *iv_return = OV_ECTL_IBLOCK_GET;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "OV_ECTL_IBLOCK_SET", 18)) {
      /*                              ^         */
#ifdef OV_ECTL_IBLOCK_SET
        *iv_return = OV_ECTL_IBLOCK_SET;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 19:
    /* Names all of length 19.  */
    /* OV_ECTL_LOWPASS_GET OV_ECTL_LOWPASS_SET */
    /* Offset 16 gives the best switch position.  */
    switch (name[16]) {
    case 'G':
      if (memEQ(name, "OV_ECTL_LOWPASS_GET", 19)) {
      /*                               ^         */
#ifdef OV_ECTL_LOWPASS_GET
        *iv_return = OV_ECTL_LOWPASS_GET;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "OV_ECTL_LOWPASS_SET", 19)) {
      /*                               ^         */
#ifdef OV_ECTL_LOWPASS_SET
        *iv_return = OV_ECTL_LOWPASS_SET;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 22:
    return constant_22 (aTHX_ name, iv_return);
    break;
  case 23:
    return constant_23 (aTHX_ name, iv_return);
    break;
  }
  return PERL_constant_NOTFOUND;
}

