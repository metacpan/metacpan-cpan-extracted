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

# These tests are for SPVM core, not for Math class.
# The reason is that it's a lot of work to write tests for NaN and Inf in SPVM core.

# Start objects count
my $start_memory_blocks_count = SPVM::api->get_memory_blocks_count();

ok(SPVM::TestCase::Math->spvm_core_double_to_string_nan);
ok(SPVM::TestCase::Math->spvm_core_double_to_string_inf);
ok(SPVM::TestCase::Math->spvm_core_float_to_string_nan);
ok(SPVM::TestCase::Math->spvm_core_float_to_string_inf);

# All object is freed
my $end_memory_blocks_count = SPVM::api->get_memory_blocks_count();
is($end_memory_blocks_count, $start_memory_blocks_count);

done_testing;
