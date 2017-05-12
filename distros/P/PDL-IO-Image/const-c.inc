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
     EXR_B44 EXR_PIZ EXR_ZIP PSD_LAB */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'B':
    if (memEQ(name, "EXR_B44", 7)) {
    /*                   ^        */
      *iv_return = EXR_B44;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "PSD_LAB", 7)) {
    /*                   ^        */
      *iv_return = PSD_LAB;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "EXR_PIZ", 7)) {
    /*                   ^        */
      *iv_return = EXR_PIZ;
      return PERL_constant_ISIV;
    }
    break;
  case 'Z':
    if (memEQ(name, "EXR_ZIP", 7)) {
    /*                   ^        */
      *iv_return = EXR_ZIP;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_8 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EXR_NONE PCD_BASE PSD_CMYK TIFF_LZW */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'N':
    if (memEQ(name, "EXR_NONE", 8)) {
    /*                     ^       */
      *iv_return = EXR_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "PCD_BASE", 8)) {
    /*                     ^       */
      *iv_return = PCD_BASE;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "PSD_CMYK", 8)) {
    /*                     ^       */
      *iv_return = PSD_CMYK;
      return PERL_constant_ISIV;
    }
    break;
  case 'Z':
    if (memEQ(name, "TIFF_LZW", 8)) {
    /*                     ^       */
      *iv_return = TIFF_LZW;
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
     EXR_FLOAT EXR_PXR24 JPEG_CMYK JPEG_FAST TIFF_CMYK TIFF_JPEG TIFF_NONE */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'C':
    if (memEQ(name, "JPEG_CMYK", 9)) {
    /*                    ^         */
      *iv_return = JPEG_CMYK;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "TIFF_CMYK", 9)) {
    /*                    ^         */
      *iv_return = TIFF_CMYK;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "JPEG_FAST", 9)) {
    /*                    ^         */
      *iv_return = JPEG_FAST;
      return PERL_constant_ISIV;
    }
    break;
  case 'J':
    if (memEQ(name, "TIFF_JPEG", 9)) {
    /*                    ^         */
      *iv_return = TIFF_JPEG;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "EXR_FLOAT", 9)) {
    /*                    ^         */
      *iv_return = EXR_FLOAT;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "TIFF_NONE", 9)) {
    /*                    ^         */
      *iv_return = TIFF_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "EXR_PXR24", 9)) {
    /*                    ^         */
      *iv_return = EXR_PXR24;
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
     GIF_LOAD256 RAW_DISPLAY RAW_PREVIEW TIFF_LOGLUV */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'I':
    if (memEQ(name, "RAW_DISPLAY", 11)) {
    /*                    ^            */
      *iv_return = RAW_DISPLAY;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "TIFF_LOGLUV", 11)) {
    /*                    ^            */
      *iv_return = TIFF_LOGLUV;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "GIF_LOAD256", 11)) {
    /*                    ^            */
      *iv_return = GIF_LOAD256;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "RAW_PREVIEW", 11)) {
    /*                    ^            */
      *iv_return = RAW_PREVIEW;
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
     BMP_SAVE_RLE GIF_PLAYBACK JXR_LOSSLESS PCD_BASEDIV4 RAW_HALFSIZE
     TIFF_DEFLATE */
  /* Offset 0 gives the best switch position.  */
  switch (*name++) {
  case 'B':
    if (memEQ(name, "MP_SAVE_RLE", 11)) {
    /*                B                  */
      *iv_return = BMP_SAVE_RLE;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "IF_PLAYBACK", 11)) {
    /*                G                  */
      *iv_return = GIF_PLAYBACK;
      return PERL_constant_ISIV;
    }
    break;
  case 'J':
    if (memEQ(name, "XR_LOSSLESS", 11)) {
    /*                J                  */
      *iv_return = JXR_LOSSLESS;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "CD_BASEDIV4", 11)) {
    /*                P                  */
      *iv_return = PCD_BASEDIV4;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "AW_HALFSIZE", 11)) {
    /*                R                  */
      *iv_return = RAW_HALFSIZE;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "IFF_DEFLATE", 11)) {
    /*                T                  */
      *iv_return = TIFF_DEFLATE;
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
     ICO_MAKEALPHA JPEG_ACCURATE JPEG_BASELINE JPEG_OPTIMIZE PCD_BASEDIV16
     TIFF_PACKBITS WEBP_LOSSLESS */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'A':
    if (memEQ(name, "ICO_MAKEALPHA", 13)) {
    /*                       ^           */
      *iv_return = ICO_MAKEALPHA;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "PCD_BASEDIV16", 13)) {
    /*                       ^           */
      *iv_return = PCD_BASEDIV16;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "JPEG_BASELINE", 13)) {
    /*                       ^           */
      *iv_return = JPEG_BASELINE;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "JPEG_OPTIMIZE", 13)) {
    /*                       ^           */
      *iv_return = JPEG_OPTIMIZE;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "TIFF_PACKBITS", 13)) {
    /*                       ^           */
      *iv_return = TIFF_PACKBITS;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "WEBP_LOSSLESS", 13)) {
    /*                       ^           */
      *iv_return = WEBP_LOSSLESS;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "JPEG_ACCURATE", 13)) {
    /*                       ^           */
      *iv_return = JPEG_ACCURATE;
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
     JPEG_GREYSCALE PNG_INTERLACED PNM_SAVE_ASCII TARGA_SAVE_RLE TIFF_CCITTFAX3
     TIFF_CCITTFAX4 */
  /* Offset 2 gives the best switch position.  */
  switch (name[2]) {
  case 'E':
    if (memEQ(name, "JPEG_GREYSCALE", 14)) {
    /*                 ^                  */
      *iv_return = JPEG_GREYSCALE;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "TIFF_CCITTFAX3", 14)) {
    /*                 ^                  */
      *iv_return = TIFF_CCITTFAX3;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "TIFF_CCITTFAX4", 14)) {
    /*                 ^                  */
      *iv_return = TIFF_CCITTFAX4;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "PNG_INTERLACED", 14)) {
    /*                 ^                  */
      *iv_return = PNG_INTERLACED;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "PNM_SAVE_ASCII", 14)) {
    /*                 ^                  */
      *iv_return = PNM_SAVE_ASCII;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "TARGA_SAVE_RLE", 14)) {
    /*                 ^                  */
      *iv_return = TARGA_SAVE_RLE;
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
     JPEG_EXIFROTATE JPEG_QUALITYBAD JXR_PROGRESSIVE PNG_IGNOREGAMMA */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'N':
    if (memEQ(name, "PNG_IGNOREGAMMA", 15)) {
    /*                     ^               */
      *iv_return = PNG_IGNOREGAMMA;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "JXR_PROGRESSIVE", 15)) {
    /*                     ^               */
      *iv_return = JXR_PROGRESSIVE;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "JPEG_QUALITYBAD", 15)) {
    /*                     ^               */
      *iv_return = JPEG_QUALITYBAD;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "JPEG_EXIFROTATE", 15)) {
    /*                     ^               */
      *iv_return = JPEG_EXIFROTATE;
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
     JPEG_PROGRESSIVE JPEG_QUALITYGOOD PNG_Z_BEST_SPEED */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'E':
    if (memEQ(name, "PNG_Z_BEST_SPEED", 16)) {
    /*                            ^         */
      *iv_return = PNG_Z_BEST_SPEED;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "JPEG_PROGRESSIVE", 16)) {
    /*                            ^         */
      *iv_return = JPEG_PROGRESSIVE;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "JPEG_QUALITYGOOD", 16)) {
    /*                            ^         */
      *iv_return = JPEG_QUALITYGOOD;
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
     JPEG_QUALITYNORMAL JPEG_QUALITYSUPERB TIFF_ADOBE_DEFLATE */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'L':
    if (memEQ(name, "TIFF_ADOBE_DEFLATE", 18)) {
    /*                             ^          */
      *iv_return = TIFF_ADOBE_DEFLATE;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "JPEG_QUALITYSUPERB", 18)) {
    /*                             ^          */
      *iv_return = JPEG_QUALITYSUPERB;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "JPEG_QUALITYNORMAL", 18)) {
    /*                             ^          */
      *iv_return = JPEG_QUALITYNORMAL;
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
     JPEG_SUBSAMPLING_411 JPEG_SUBSAMPLING_420 JPEG_SUBSAMPLING_422
     JPEG_SUBSAMPLING_444 PNG_Z_NO_COMPRESSION */
  /* Offset 19 gives the best switch position.  */
  switch (name[19]) {
  case '0':
    if (memEQ(name, "JPEG_SUBSAMPLING_42", 19)) {
    /*                                  0      */
      *iv_return = JPEG_SUBSAMPLING_420;
      return PERL_constant_ISIV;
    }
    break;
  case '1':
    if (memEQ(name, "JPEG_SUBSAMPLING_41", 19)) {
    /*                                  1      */
      *iv_return = JPEG_SUBSAMPLING_411;
      return PERL_constant_ISIV;
    }
    break;
  case '2':
    if (memEQ(name, "JPEG_SUBSAMPLING_42", 19)) {
    /*                                  2      */
      *iv_return = JPEG_SUBSAMPLING_422;
      return PERL_constant_ISIV;
    }
    break;
  case '4':
    if (memEQ(name, "JPEG_SUBSAMPLING_44", 19)) {
    /*                                  4      */
      *iv_return = JPEG_SUBSAMPLING_444;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "PNG_Z_NO_COMPRESSIO", 19)) {
    /*                                  N      */
      *iv_return = PNG_Z_NO_COMPRESSION;
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

#!D:\strawberry32\perl\bin\perl.exe -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(),
            {name=>"BMP_SAVE_RLE", type=>"IV", macro=>"1"},
            {name=>"EXR_B44", type=>"IV", macro=>"1"},
            {name=>"EXR_FLOAT", type=>"IV", macro=>"1"},
            {name=>"EXR_LC", type=>"IV", macro=>"1"},
            {name=>"EXR_NONE", type=>"IV", macro=>"1"},
            {name=>"EXR_PIZ", type=>"IV", macro=>"1"},
            {name=>"EXR_PXR24", type=>"IV", macro=>"1"},
            {name=>"EXR_ZIP", type=>"IV", macro=>"1"},
            {name=>"GIF_LOAD256", type=>"IV", macro=>"1"},
            {name=>"GIF_PLAYBACK", type=>"IV", macro=>"1"},
            {name=>"ICO_MAKEALPHA", type=>"IV", macro=>"1"},
            {name=>"JPEG_ACCURATE", type=>"IV", macro=>"1"},
            {name=>"JPEG_BASELINE", type=>"IV", macro=>"1"},
            {name=>"JPEG_CMYK", type=>"IV", macro=>"1"},
            {name=>"JPEG_EXIFROTATE", type=>"IV", macro=>"1"},
            {name=>"JPEG_FAST", type=>"IV", macro=>"1"},
            {name=>"JPEG_GREYSCALE", type=>"IV", macro=>"1"},
            {name=>"JPEG_OPTIMIZE", type=>"IV", macro=>"1"},
            {name=>"JPEG_PROGRESSIVE", type=>"IV", macro=>"1"},
            {name=>"JPEG_QUALITYAVERAGE", type=>"IV", macro=>"1"},
            {name=>"JPEG_QUALITYBAD", type=>"IV", macro=>"1"},
            {name=>"JPEG_QUALITYGOOD", type=>"IV", macro=>"1"},
            {name=>"JPEG_QUALITYNORMAL", type=>"IV", macro=>"1"},
            {name=>"JPEG_QUALITYSUPERB", type=>"IV", macro=>"1"},
            {name=>"JPEG_SUBSAMPLING_411", type=>"IV", macro=>"1"},
            {name=>"JPEG_SUBSAMPLING_420", type=>"IV", macro=>"1"},
            {name=>"JPEG_SUBSAMPLING_422", type=>"IV", macro=>"1"},
            {name=>"JPEG_SUBSAMPLING_444", type=>"IV", macro=>"1"},
            {name=>"JXR_LOSSLESS", type=>"IV", macro=>"1"},
            {name=>"JXR_PROGRESSIVE", type=>"IV", macro=>"1"},
            {name=>"PCD_BASE", type=>"IV", macro=>"1"},
            {name=>"PCD_BASEDIV16", type=>"IV", macro=>"1"},
            {name=>"PCD_BASEDIV4", type=>"IV", macro=>"1"},
            {name=>"PNG_IGNOREGAMMA", type=>"IV", macro=>"1"},
            {name=>"PNG_INTERLACED", type=>"IV", macro=>"1"},
            {name=>"PNG_Z_BEST_COMPRESSION", type=>"IV", macro=>"1"},
            {name=>"PNG_Z_BEST_SPEED", type=>"IV", macro=>"1"},
            {name=>"PNG_Z_DEFAULT_COMPRESSION", type=>"IV", macro=>"1"},
            {name=>"PNG_Z_NO_COMPRESSION", type=>"IV", macro=>"1"},
            {name=>"PNM_SAVE_ASCII", type=>"IV", macro=>"1"},
            {name=>"PSD_CMYK", type=>"IV", macro=>"1"},
            {name=>"PSD_LAB", type=>"IV", macro=>"1"},
            {name=>"RAW_DISPLAY", type=>"IV", macro=>"1"},
            {name=>"RAW_HALFSIZE", type=>"IV", macro=>"1"},
            {name=>"RAW_PREVIEW", type=>"IV", macro=>"1"},
            {name=>"TARGA_LOAD_RGB888", type=>"IV", macro=>"1"},
            {name=>"TARGA_SAVE_RLE", type=>"IV", macro=>"1"},
            {name=>"TIFF_ADOBE_DEFLATE", type=>"IV", macro=>"1"},
            {name=>"TIFF_CCITTFAX3", type=>"IV", macro=>"1"},
            {name=>"TIFF_CCITTFAX4", type=>"IV", macro=>"1"},
            {name=>"TIFF_CMYK", type=>"IV", macro=>"1"},
            {name=>"TIFF_DEFLATE", type=>"IV", macro=>"1"},
            {name=>"TIFF_JPEG", type=>"IV", macro=>"1"},
            {name=>"TIFF_LOGLUV", type=>"IV", macro=>"1"},
            {name=>"TIFF_LZW", type=>"IV", macro=>"1"},
            {name=>"TIFF_NONE", type=>"IV", macro=>"1"},
            {name=>"TIFF_PACKBITS", type=>"IV", macro=>"1"},
            {name=>"WEBP_LOSSLESS", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("PDL::IO::Image", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("PDL::IO::Image", $types);
__END__
   */

  switch (len) {
  case 6:
    if (memEQ(name, "EXR_LC", 6)) {
      *iv_return = EXR_LC;
      return PERL_constant_ISIV;
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
    if (memEQ(name, "TARGA_LOAD_RGB888", 17)) {
      *iv_return = TARGA_LOAD_RGB888;
      return PERL_constant_ISIV;
    }
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    if (memEQ(name, "JPEG_QUALITYAVERAGE", 19)) {
      *iv_return = JPEG_QUALITYAVERAGE;
      return PERL_constant_ISIV;
    }
    break;
  case 20:
    return constant_20 (aTHX_ name, iv_return);
    break;
  case 22:
    if (memEQ(name, "PNG_Z_BEST_COMPRESSION", 22)) {
      *iv_return = PNG_Z_BEST_COMPRESSION;
      return PERL_constant_ISIV;
    }
    break;
  case 25:
    if (memEQ(name, "PNG_Z_DEFAULT_COMPRESSION", 25)) {
      *iv_return = PNG_Z_DEFAULT_COMPRESSION;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

