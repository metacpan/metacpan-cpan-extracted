use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use SPVM 'TestCase::Math';
use SPVM 'Math';

use SPVM 'Fn';
use SPVM::Math;

use POSIX();
use Math::Complex;

use Math::Trig 'pi';

my $BYTE_MAX = 127;
my $BYTE_MIN = -128;
my $SHORT_MAX = 32767;
my $SHORT_MIN = -32768;
my $INT_MAX = 2147483647;
my $INT_MIN = -2147483648;
my $LONG_MAX = 9223372036854775807;
my $LONG_MIN = -9223372036854775808;
my $FLOAT_PRECICE = 16384.5;
my $DOUBLE_PRECICE = 65536.5;

# Positive infinity(unix like system : inf, Windows : 1.#INF)
my $POSITIVE_INFINITY = 9**9**9;

my $NaN = 9**9**9 / 9**9**9;

my $nan_re = qr/(nan|ind)/i;



# Start objects count
my $start_memory_blocks_count = SPVM::api->get_memory_blocks_count();

# PI
{
  ok(SPVM::TestCase::Math->PI);
  if ($] >= 5.022) {
    my $val = eval "0x1.921fb54442d18p+1";
    cmp_ok(SPVM::Math->PI, '==', $val);
  }
}

# E
{
  ok(SPVM::TestCase::Math->E);
  if ($] >= 5.022) {
    my $val = eval "0x1.5bf0a8b145769p+1";
    cmp_ok(SPVM::Math->E, '==', $val);
  }
}

# Trigonometric functions
ok(SPVM::TestCase::Math->cos);
ok(SPVM::TestCase::Math->cosf);
ok(SPVM::TestCase::Math->sin);
ok(SPVM::TestCase::Math->sinf);
ok(SPVM::TestCase::Math->tan);
ok(SPVM::TestCase::Math->tanf);
ok(SPVM::TestCase::Math->acos);
ok(SPVM::TestCase::Math->acosf);
ok(SPVM::TestCase::Math->asin);
ok(SPVM::TestCase::Math->asinf);
ok(SPVM::TestCase::Math->atan);
ok(SPVM::TestCase::Math->atanf);

# Hyperbolic functions
ok(SPVM::TestCase::Math->cosh);
ok(SPVM::TestCase::Math->coshf);
ok(SPVM::TestCase::Math->sinh);
ok(SPVM::TestCase::Math->sinhf);
ok(SPVM::TestCase::Math->tanh);
ok(SPVM::TestCase::Math->tanhf);
ok(SPVM::TestCase::Math->acosh);
ok(SPVM::TestCase::Math->acoshf);
ok(SPVM::TestCase::Math->asinh);
ok(SPVM::TestCase::Math->asinhf);
ok(SPVM::TestCase::Math->atanh);
ok(SPVM::TestCase::Math->atanhf);

# Exponential and logarithmic functions
ok(SPVM::TestCase::Math->exp);
ok(SPVM::TestCase::Math->expf);
ok(SPVM::TestCase::Math->exp2);
ok(SPVM::TestCase::Math->exp2f);
ok(SPVM::TestCase::Math->expm1);
ok(SPVM::TestCase::Math->expm1f);
ok(SPVM::TestCase::Math->frexp);
ok(SPVM::TestCase::Math->frexpf);
ok(SPVM::TestCase::Math->ilogb);
ok(SPVM::TestCase::Math->ilogbf);
ok(SPVM::TestCase::Math->ldexp);
ok(SPVM::TestCase::Math->ldexpf);
ok(SPVM::TestCase::Math->log);
ok(SPVM::TestCase::Math->logf);
ok(SPVM::TestCase::Math->log10);
ok(SPVM::TestCase::Math->log10f);
ok(SPVM::TestCase::Math->log1p);
ok(SPVM::TestCase::Math->log1pf);
ok(SPVM::TestCase::Math->log2);
ok(SPVM::TestCase::Math->log2f);
ok(SPVM::TestCase::Math->logb);
ok(SPVM::TestCase::Math->logbf);
ok(SPVM::TestCase::Math->modf);
ok(SPVM::TestCase::Math->modff);
ok(SPVM::TestCase::Math->scalbn);
ok(SPVM::TestCase::Math->scalbnf);
ok(SPVM::TestCase::Math->scalbln);
ok(SPVM::TestCase::Math->scalblnf);

#absolute value functions
{
  ok(SPVM::TestCase::Math->abs);
  ok(SPVM::TestCase::Math->labs);
  ok(SPVM::TestCase::Math->fabs);
  ok(SPVM::TestCase::Math->fabsf);
}

# Power function
ok(SPVM::TestCase::Math->cbrt);
ok(SPVM::TestCase::Math->cbrtf);
ok(SPVM::TestCase::Math->hypot);
ok(SPVM::TestCase::Math->hypotf);
ok(SPVM::TestCase::Math->pow);
ok(SPVM::TestCase::Math->powf);
ok(SPVM::TestCase::Math->sqrt);
ok(SPVM::TestCase::Math->sqrtf);

# Error function and gamma functions
ok(SPVM::TestCase::Math->erf);
ok(SPVM::TestCase::Math->erff);
ok(SPVM::TestCase::Math->erfc);
ok(SPVM::TestCase::Math->erfcf);
ok(SPVM::TestCase::Math->lgamma);
ok(SPVM::TestCase::Math->lgammaf);
ok(SPVM::TestCase::Math->tgamma);
ok(SPVM::TestCase::Math->tgammaf);

# Nearest integer functions
ok(SPVM::TestCase::Math->ceil);
ok(SPVM::TestCase::Math->ceilf);
ok(SPVM::TestCase::Math->floor);
ok(SPVM::TestCase::Math->floorf);
ok(SPVM::TestCase::Math->nearbyint);
ok(SPVM::TestCase::Math->nearbyintf);
ok(SPVM::TestCase::Math->round);
ok(SPVM::TestCase::Math->roundf);
ok(SPVM::TestCase::Math->lround);
ok(SPVM::TestCase::Math->lroundf);
ok(SPVM::TestCase::Math->trunc);
ok(SPVM::TestCase::Math->truncf);

# Surplus functions
ok(SPVM::TestCase::Math->fmod);
ok(SPVM::TestCase::Math->fmodf);
ok(SPVM::TestCase::Math->remainder);
ok(SPVM::TestCase::Math->remainderf);
ok(SPVM::TestCase::Math->remquo);
ok(SPVM::TestCase::Math->remquof);

# Real number operation functions
ok(SPVM::TestCase::Math->copysign);
ok(SPVM::TestCase::Math->copysignf);
ok(SPVM::TestCase::Math->nan);
ok(SPVM::TestCase::Math->nanf);
ok(SPVM::TestCase::Math->nextafter);
ok(SPVM::TestCase::Math->nextafterf);
ok(SPVM::TestCase::Math->nexttoward);
ok(SPVM::TestCase::Math->nexttowardf);

# Maximum, minimum and positive difference functions
ok(SPVM::TestCase::Math->fdim);
ok(SPVM::TestCase::Math->fdimf);
ok(SPVM::TestCase::Math->fmax);
ok(SPVM::TestCase::Math->fmaxf);
ok(SPVM::TestCase::Math->fmin);
ok(SPVM::TestCase::Math->fminf);

# Floating point multiplication and additions
ok(SPVM::TestCase::Math->fma);
ok(SPVM::TestCase::Math->fmaf);

# Classification
ok(SPVM::TestCase::Math->fpclassify);
ok(SPVM::TestCase::Math->fpclassifyf);
ok(SPVM::TestCase::Math->isfinite);
ok(SPVM::TestCase::Math->isfinitef);
ok(SPVM::TestCase::Math->isinf);
ok(SPVM::TestCase::Math->isinff);
ok(SPVM::TestCase::Math->isnan);
ok(SPVM::TestCase::Math->isnanf);
ok(SPVM::TestCase::Math->signbit);
ok(SPVM::TestCase::Math->signbitf);

# Comparison
ok(SPVM::TestCase::Math->isgreater);
ok(SPVM::TestCase::Math->isgreaterf);
ok(SPVM::TestCase::Math->isgreaterequal);
ok(SPVM::TestCase::Math->isgreaterequalf);
ok(SPVM::TestCase::Math->isless);
ok(SPVM::TestCase::Math->islessf);
ok(SPVM::TestCase::Math->islessequal);
ok(SPVM::TestCase::Math->islessequalf);
ok(SPVM::TestCase::Math->islessgreater);
ok(SPVM::TestCase::Math->islessgreaterf);
ok(SPVM::TestCase::Math->isunordered);
ok(SPVM::TestCase::Math->isunorderedf);

# Complex Operations
{
  ok(SPVM::TestCase::Math->complexf);
  ok(SPVM::TestCase::Math->complex);
  ok(SPVM::TestCase::Math->caddf);
  ok(SPVM::TestCase::Math->cadd);
  ok(SPVM::TestCase::Math->csubf);
  ok(SPVM::TestCase::Math->csub);
  ok(SPVM::TestCase::Math->cmulf);
  ok(SPVM::TestCase::Math->cmul);
  ok(SPVM::TestCase::Math->cscamulf);
  ok(SPVM::TestCase::Math->cscamul);
  ok(SPVM::TestCase::Math->cdivf);
  ok(SPVM::TestCase::Math->cdiv);
}

# Complex Functions
{
  ok(SPVM::TestCase::Math->cacos);
  ok(SPVM::TestCase::Math->cacosf);

  ok(SPVM::TestCase::Math->casin);
  ok(SPVM::TestCase::Math->casinf);
  
  ok(SPVM::TestCase::Math->catan);
  ok(SPVM::TestCase::Math->catanf);

  ok(SPVM::TestCase::Math->ccos);
  ok(SPVM::TestCase::Math->ccosf);

  ok(SPVM::TestCase::Math->csin);
  ok(SPVM::TestCase::Math->csinf);

  ok(SPVM::TestCase::Math->ctan);
  ok(SPVM::TestCase::Math->ctanf);

  ok(SPVM::TestCase::Math->cacosh);
  ok(SPVM::TestCase::Math->cacoshf);

  ok(SPVM::TestCase::Math->casinh);
  ok(SPVM::TestCase::Math->casinhf);
  
  ok(SPVM::TestCase::Math->catanh);
  ok(SPVM::TestCase::Math->catanhf);

  ok(SPVM::TestCase::Math->ccosh);
  ok(SPVM::TestCase::Math->ccoshf);

  ok(SPVM::TestCase::Math->csinh);
  ok(SPVM::TestCase::Math->csinhf);

  ok(SPVM::TestCase::Math->ctanh);
  ok(SPVM::TestCase::Math->ctanhf);

  ok(SPVM::TestCase::Math->clog);
  ok(SPVM::TestCase::Math->clogf);

  ok(SPVM::TestCase::Math->cabs);
  ok(SPVM::TestCase::Math->cabsf);

  ok(SPVM::TestCase::Math->carg);
  ok(SPVM::TestCase::Math->cargf);

  ok(SPVM::TestCase::Math->conj);
  ok(SPVM::TestCase::Math->conjf);

  ok(SPVM::TestCase::Math->cexp);
  ok(SPVM::TestCase::Math->cexpf);

  ok(SPVM::TestCase::Math->cpow);
  ok(SPVM::TestCase::Math->cpowf);

  ok(SPVM::TestCase::Math->csqrt);
  ok(SPVM::TestCase::Math->csqrtf);
}

# Version
{
  is($SPVM::Math::VERSION, SPVM::Fn->get_version_string('Math'));
}
# All object is freed
my $end_memory_blocks_count = SPVM::api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
