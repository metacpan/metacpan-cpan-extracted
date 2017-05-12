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
my @names = (qw(),
            {name=>"found_token", type=>"IV", macro=>"1"},
            {name=>"reached_eol", type=>"IV", macro=>"1"},
            {name=>"tokenizing_fail", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("PPI::XS::Tokenizer::Constants", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("PPI::XS::Tokenizer::Constants", $types);
__END__
   */

  switch (len) {
  case 11:
    /* Names all of length 11.  */
    /* found_token reached_eol */
    /* Offset 10 gives the best switch position.  */
    switch (name[10]) {
    case 'l':
      if (memEQ(name, "reached_eo", 10)) {
      /*                         l      */
        *iv_return = reached_eol;
        return PERL_constant_ISIV;
      }
      break;
    case 'n':
      if (memEQ(name, "found_toke", 10)) {
      /*                         n      */
        *iv_return = found_token;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 15:
    if (memEQ(name, "tokenizing_fail", 15)) {
      *iv_return = tokenizing_fail;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

