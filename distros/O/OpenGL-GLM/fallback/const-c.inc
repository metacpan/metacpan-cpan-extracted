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
my @names = (qw(GLM_2_SIDED GLM_COLOR GLM_FLAT GLM_MATERIAL GLM_MAX_SHININESS
	       GLM_MAX_TEXTURE_SIZE GLM_NONE GLM_SMOOTH GLM_TEXTURE M_PI));

print constant_types(); # macro defs
foreach (C_constant ("OpenGL::GLM", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("OpenGL::GLM", $types);
__END__
   */

  switch (len) {
  case 4:
    if (memEQ(name, "M_PI", 4)) {
#ifdef M_PI
      *iv_return = M_PI;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 8:
    /* Names all of length 8.  */
    /* GLM_FLAT GLM_NONE */
    /* Offset 5 gives the best switch position.  */
    switch (name[5]) {
    case 'L':
      if (memEQ(name, "GLM_FLAT", 8)) {
      /*                    ^        */
#ifdef GLM_FLAT
        *iv_return = GLM_FLAT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'O':
      if (memEQ(name, "GLM_NONE", 8)) {
      /*                    ^        */
#ifdef GLM_NONE
        *iv_return = GLM_NONE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 9:
    if (memEQ(name, "GLM_COLOR", 9)) {
#ifdef GLM_COLOR
      *iv_return = GLM_COLOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 10:
    if (memEQ(name, "GLM_SMOOTH", 10)) {
#ifdef GLM_SMOOTH
      *iv_return = GLM_SMOOTH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 11:
    /* Names all of length 11.  */
    /* GLM_2_SIDED GLM_TEXTURE */
    /* Offset 10 gives the best switch position.  */
    switch (name[10]) {
    case 'D':
      if (memEQ(name, "GLM_2_SIDE", 10)) {
      /*                         D      */
#ifdef GLM_2_SIDED
        *iv_return = GLM_2_SIDED;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'E':
      if (memEQ(name, "GLM_TEXTUR", 10)) {
      /*                         E      */
#ifdef GLM_TEXTURE
        *iv_return = GLM_TEXTURE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 12:
    if (memEQ(name, "GLM_MATERIAL", 12)) {
#ifdef GLM_MATERIAL
      *iv_return = GLM_MATERIAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 17:
    if (memEQ(name, "GLM_MAX_SHININESS", 17)) {
#ifdef GLM_MAX_SHININESS
      *iv_return = GLM_MAX_SHININESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 20:
    if (memEQ(name, "GLM_MAX_TEXTURE_SIZE", 20)) {
#ifdef GLM_MAX_TEXTURE_SIZE
      *iv_return = GLM_MAX_TEXTURE_SIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

