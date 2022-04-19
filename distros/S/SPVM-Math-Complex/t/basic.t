use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More 'no_plan';

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

use SPVM 'TestCase::Math::Complex';

# Start objects count
my $start_memory_blocks_count = SPVM::get_memory_blocks_count();

# Complex Operations
{
  ok(SPVM::TestCase::Math::Complex->test_complexf);
  ok(SPVM::TestCase::Math::Complex->test_complex);
  ok(SPVM::TestCase::Math::Complex->test_caddf);
  ok(SPVM::TestCase::Math::Complex->test_cadd);
  ok(SPVM::TestCase::Math::Complex->test_csubf);
  ok(SPVM::TestCase::Math::Complex->test_csub);
  ok(SPVM::TestCase::Math::Complex->test_cmulf);
  ok(SPVM::TestCase::Math::Complex->test_cmul);
  ok(SPVM::TestCase::Math::Complex->test_cscamulf);
  ok(SPVM::TestCase::Math::Complex->test_cscamul);
  ok(SPVM::TestCase::Math::Complex->test_cdivf);
  ok(SPVM::TestCase::Math::Complex->test_cdiv);
}

# Complex Functions
{
  ok(SPVM::TestCase::Math::Complex->test_cacos);
  ok(SPVM::TestCase::Math::Complex->test_cacosf);

  ok(SPVM::TestCase::Math::Complex->test_casin);
  ok(SPVM::TestCase::Math::Complex->test_casinf);
  
  ok(SPVM::TestCase::Math::Complex->test_catan);
  ok(SPVM::TestCase::Math::Complex->test_catanf);

  ok(SPVM::TestCase::Math::Complex->test_ccos);
  ok(SPVM::TestCase::Math::Complex->test_ccosf);

  ok(SPVM::TestCase::Math::Complex->test_csin);
  ok(SPVM::TestCase::Math::Complex->test_csinf);

  ok(SPVM::TestCase::Math::Complex->test_ctan);
  ok(SPVM::TestCase::Math::Complex->test_ctanf);

  ok(SPVM::TestCase::Math::Complex->test_cacosh);
  ok(SPVM::TestCase::Math::Complex->test_cacoshf);

  ok(SPVM::TestCase::Math::Complex->test_casinh);
  ok(SPVM::TestCase::Math::Complex->test_casinhf);
  
  ok(SPVM::TestCase::Math::Complex->test_catanh);
  ok(SPVM::TestCase::Math::Complex->test_catanhf);

  ok(SPVM::TestCase::Math::Complex->test_ccosh);
  ok(SPVM::TestCase::Math::Complex->test_ccoshf);

  ok(SPVM::TestCase::Math::Complex->test_csinh);
  ok(SPVM::TestCase::Math::Complex->test_csinhf);

  ok(SPVM::TestCase::Math::Complex->test_ctanh);
  ok(SPVM::TestCase::Math::Complex->test_ctanhf);

  ok(SPVM::TestCase::Math::Complex->test_clog);
  ok(SPVM::TestCase::Math::Complex->test_clogf);

  ok(SPVM::TestCase::Math::Complex->test_cabs);
  ok(SPVM::TestCase::Math::Complex->test_cabsf);

  ok(SPVM::TestCase::Math::Complex->test_carg);
  ok(SPVM::TestCase::Math::Complex->test_cargf);

  ok(SPVM::TestCase::Math::Complex->test_conj);
  ok(SPVM::TestCase::Math::Complex->test_conjf);

  ok(SPVM::TestCase::Math::Complex->test_cexp);
  ok(SPVM::TestCase::Math::Complex->test_cexpf);

  ok(SPVM::TestCase::Math::Complex->test_cpow);
  ok(SPVM::TestCase::Math::Complex->test_cpowf);

  ok(SPVM::TestCase::Math::Complex->test_csqrt);
  ok(SPVM::TestCase::Math::Complex->test_csqrtf);
}

# All object is freed
my $end_memory_blocks_count = SPVM::get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

