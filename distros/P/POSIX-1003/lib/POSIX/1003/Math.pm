# Copyrights 2011-2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package POSIX::1003::Math;
use vars '$VERSION';
$VERSION = '0.98';

use base 'POSIX::1003::Module';

# Block respectively from float.h, math.h, stdlib.h, limits.h
my @constants = qw/
 DBL_DIG DBL_EPSILON DBL_MANT_DIG DBL_MAX DBL_MAX_10_EXP
 DBL_MAX_EXP DBL_MIN DBL_MIN_10_EXP DBL_MIN_EXP FLT_DIG FLT_EPSILON
 FLT_MANT_DIG FLT_MAX FLT_MAX_10_EXP FLT_MAX_EXP FLT_MIN FLT_MIN_10_EXP
 FLT_MIN_EXP FLT_RADIX FLT_ROUNDS LDBL_DIG LDBL_EPSILON LDBL_MANT_DIG
 LDBL_MAX LDBL_MAX_10_EXP LDBL_MAX_EXP LDBL_MIN LDBL_MIN_10_EXP
 LDBL_MIN_EXP

 HUGE_VAL

 RAND_MAX

 CHAR_BIT CHAR_MAX CHAR_MIN UCHAR_MAX SCHAR_MAX SCHAR_MIN
 SHRT_MAX SHRT_MIN USHRT_MAX
 INT_MAX INT_MIN UINT_MAX
 LONG_MAX LONG_MIN ULONG_MAX
 /;

# Only from math.h.  The first block are defined in POSIX.xs, the
# second block present in Core. The last is from string.h
our @IN_CORE = qw/abs exp log sqrt sin cos atan2 rand srand int/;

my @functions = qw/
 acos asin atan ceil cosh floor fmod frexp
 ldexp log10 modf sinh tan tanh

 div rint pow
 strtod strtol strtoul
/;
push @functions, @IN_CORE;

our %EXPORT_TAGS =
  ( constants => \@constants
  , functions => \@functions
  );


# the argument to be optional is important for expression priority!
sub acos(_)  { goto &POSIX::acos  }
sub asin(_)  { goto &POSIX::asin  }
sub atan(_)  { goto &POSIX::atan  }
sub ceil(_)  { goto &POSIX::ceil  }
sub cosh(_)  { goto &POSIX::cosh  }
sub floor(_) { goto &POSIX::floor }
sub frexp(_) { goto &POSIX::frexp }
sub ldexp(_) { goto &POSIX::ldexp }
sub log10(_) { goto &POSIX::log10 }
sub sinh(_)  { goto &POSIX::sinh  }
sub tan(_)   { goto &POSIX::tan   }
sub tanh(_)  { goto &POSIX::tanh  }

sub modf($$) { goto &POSIX::modf }
sub fmod($$) { goto &POSIX::fmod }

# All provided by POSIX.xs


sub div($$) { ( int($_[0]/$_[1]), ($_[0] % $_[1]) ) }


sub rint(;$) { my $v = @_ ? shift : $_; int($v + 0.5) }


sub pow($$) { $_[0] ** $_[1] }


#------------------------------


1;
