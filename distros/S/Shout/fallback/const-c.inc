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
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SHOUTERR_INSANE SHOUTERR_MALLOC SHOUTERR_SOCKET */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'I':
    if (memEQ(name, "SHOUTERR_INSANE", 15)) {
    /*                        ^            */
#ifdef SHOUTERR_INSANE
      *iv_return = SHOUTERR_INSANE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "SHOUTERR_MALLOC", 15)) {
    /*                        ^            */
#ifdef SHOUTERR_MALLOC
      *iv_return = SHOUTERR_MALLOC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "SHOUTERR_SOCKET", 15)) {
    /*                        ^            */
#ifdef SHOUTERR_SOCKET
      *iv_return = SHOUTERR_SOCKET;
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
     SHOUTERR_NOLOGIN SHOUTERR_SUCCESS SHOUT_FORMAT_MP3 SHOUT_FORMAT_OGG
     SHOUT_THREADSAFE */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'F':
    if (memEQ(name, "SHOUT_THREADSAFE", 16)) {
    /*                             ^        */
#ifdef SHOUT_THREADSAFE
      *iv_return = SHOUT_THREADSAFE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "SHOUT_FORMAT_OGG", 16)) {
    /*                             ^        */
#ifdef SHOUT_FORMAT_OGG
      *iv_return = SHOUT_FORMAT_OGG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "SHOUTERR_NOLOGIN", 16)) {
    /*                             ^        */
#ifdef SHOUTERR_NOLOGIN
      *iv_return = SHOUTERR_NOLOGIN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "SHOUT_FORMAT_MP3", 16)) {
    /*                             ^        */
#ifdef SHOUT_FORMAT_MP3
      *iv_return = SHOUT_FORMAT_MP3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "SHOUTERR_SUCCESS", 16)) {
    /*                             ^        */
#ifdef SHOUTERR_SUCCESS
      *iv_return = SHOUTERR_SUCCESS;
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
     SHOUTERR_CONNECTED SHOUTERR_NOCONNECT SHOUT_PROTOCOL_ICY */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'E':
    if (memEQ(name, "SHOUTERR_CONNECTED", 18)) {
    /*                            ^           */
#ifdef SHOUTERR_CONNECTED
      *iv_return = SHOUTERR_CONNECTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "SHOUT_PROTOCOL_ICY", 18)) {
    /*                            ^           */
#ifdef SHOUT_PROTOCOL_ICY
      *iv_return = SHOUT_PROTOCOL_ICY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "SHOUTERR_NOCONNECT", 18)) {
    /*                            ^           */
#ifdef SHOUTERR_NOCONNECT
      *iv_return = SHOUTERR_NOCONNECT;
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
my @names = (qw(SHOUTERR_BUSY SHOUTERR_CONNECTED SHOUTERR_INSANE
	       SHOUTERR_MALLOC SHOUTERR_METADATA SHOUTERR_NOCONNECT
	       SHOUTERR_NOLOGIN SHOUTERR_SOCKET SHOUTERR_SUCCESS
	       SHOUTERR_UNCONNECTED SHOUTERR_UNSUPPORTED SHOUT_FORMAT_MP3
	       SHOUT_FORMAT_OGG SHOUT_FORMAT_VORBIS SHOUT_PROTOCOL_HTTP
	       SHOUT_PROTOCOL_ICY SHOUT_PROTOCOL_XAUDIOCAST SHOUT_THREADSAFE));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Shout", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Shout", $types);
__END__
   */

  switch (len) {
  case 13:
    if (memEQ(name, "SHOUTERR_BUSY", 13)) {
#ifdef SHOUTERR_BUSY
      *iv_return = SHOUTERR_BUSY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    if (memEQ(name, "SHOUTERR_METADATA", 17)) {
#ifdef SHOUTERR_METADATA
      *iv_return = SHOUTERR_METADATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    /* Names all of length 19.  */
    /* SHOUT_FORMAT_VORBIS SHOUT_PROTOCOL_HTTP */
    /* Offset 18 gives the best switch position.  */
    switch (name[18]) {
    case 'P':
      if (memEQ(name, "SHOUT_PROTOCOL_HTT", 18)) {
      /*                                 P      */
#ifdef SHOUT_PROTOCOL_HTTP
        *iv_return = SHOUT_PROTOCOL_HTTP;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "SHOUT_FORMAT_VORBI", 18)) {
      /*                                 S      */
#ifdef SHOUT_FORMAT_VORBIS
        *iv_return = SHOUT_FORMAT_VORBIS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 20:
    /* Names all of length 20.  */
    /* SHOUTERR_UNCONNECTED SHOUTERR_UNSUPPORTED */
    /* Offset 13 gives the best switch position.  */
    switch (name[13]) {
    case 'N':
      if (memEQ(name, "SHOUTERR_UNCONNECTED", 20)) {
      /*                            ^             */
#ifdef SHOUTERR_UNCONNECTED
        *iv_return = SHOUTERR_UNCONNECTED;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'P':
      if (memEQ(name, "SHOUTERR_UNSUPPORTED", 20)) {
      /*                            ^             */
#ifdef SHOUTERR_UNSUPPORTED
        *iv_return = SHOUTERR_UNSUPPORTED;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 25:
    if (memEQ(name, "SHOUT_PROTOCOL_XAUDIOCAST", 25)) {
#ifdef SHOUT_PROTOCOL_XAUDIOCAST
      *iv_return = SHOUT_PROTOCOL_XAUDIOCAST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

