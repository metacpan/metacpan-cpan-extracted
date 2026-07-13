use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);

use RPi::Const::BuildCheck;

my $mod = 'RPi::Const::BuildCheck';

# --- the minimum is absorbed from RPi::Const, not a private literal ---------

is $RPi::Const::BuildCheck::MIN_WIRINGPI_VERSION, RPi::Const::WIRINGPI_MIN_VERSION(),
    'MIN_WIRINGPI_VERSION is read from RPi::Const::WIRINGPI_MIN_VERSION';
is $RPi::Const::BuildCheck::MIN_WIRINGPI_VERSION, '3.18', '...which is 3.18';

# --- version_ge: integer (major, minor) tuple compare (F2 fix) -------------

ok  $mod->can('version_ge'), 'version_ge exists';
ok  RPi::Const::BuildCheck::version_ge('3.18', '3.18'), '3.18 >= 3.18';
ok  RPi::Const::BuildCheck::version_ge('3.20', '3.18'), '3.20 >= 3.18';
ok  RPi::Const::BuildCheck::version_ge('4.0',  '3.18'), '4.0  >= 3.18 (higher major)';
ok! RPi::Const::BuildCheck::version_ge('3.8',  '3.18'), '3.8  <  3.18 (F2: NOT a decimal compare)';
ok! RPi::Const::BuildCheck::version_ge('3.17', '3.18'), '3.17 <  3.18';
ok! RPi::Const::BuildCheck::version_ge('2.36', '3.18'), '2.36 <  3.18 (lower major)';
ok! RPi::Const::BuildCheck::version_ge('garbage', '3.18'), 'unparseable have -> false';
ok! RPi::Const::BuildCheck::version_ge('3.18', undef),     'undef want -> false';

# --- _parse_gpio_version ---------------------------------------------------

is RPi::Const::BuildCheck::_parse_gpio_version("gpio version: 3.18\nCopyright...\n"),
    '3.18', 'parses a real gpio -v banner';
is RPi::Const::BuildCheck::_parse_gpio_version('no version here'), undef,
    'unparseable output -> undef';
is RPi::Const::BuildCheck::_parse_gpio_version(''), undef, 'empty output -> undef';

# --- wiringpi_build_check via injected paths/output (no wiringPi needed) ----

# a fake include dir that "has" wiringPi.h
my $inc = tempdir(CLEANUP => 1);
open my $wh, '>', "$inc/wiringPi.h" or die $!;
close $wh;

my @na;
my $na = sub { push @na, $_[0]; return 'NA' };
my $reset = sub { @na = () };

# RPI_DIST_RELEASE bypass: satisfied without any checks
$reset->();
is RPi::Const::BuildCheck::wiringpi_build_check(env_release => 1, na => $na), 1,
    'RPI_DIST_RELEASE bypass returns true';
is scalar @na, 0, '...and never invokes the NA action';

# missing header -> NA
$reset->();
RPi::Const::BuildCheck::wiringpi_build_check(
    include_dirs => ["$inc/nope"], env_release => 0, na => $na,
);
is scalar @na, 1, 'missing wiringPi.h invokes NA';
like $na[0], qr/not installed/, '...with the "not installed" message';

# present header + adequate version -> satisfied
$reset->();
is RPi::Const::BuildCheck::wiringpi_build_check(
    include_dirs => [$inc], gpio_output => "gpio version: 3.18\n",
    min_version => '3.18', env_release => 0, na => $na,
), 1, 'header present + version 3.18 vs min 3.18 -> satisfied';
is scalar @na, 0, '...no NA';

# present header + too-old version (the F2 case) -> NA
$reset->();
RPi::Const::BuildCheck::wiringpi_build_check(
    include_dirs => [$inc], gpio_output => "gpio version: 3.8\n",
    min_version => '3.18', env_release => 0, na => $na,
);
is scalar @na, 1, '3.8 vs a 3.18 minimum -> NA (F2: 3.8 is older)';
like $na[0], qr/must have wiringPi version 3\.18/, '...too-old message';

# 2.36 -> NA
$reset->();
RPi::Const::BuildCheck::wiringpi_build_check(
    include_dirs => [$inc], gpio_output => "gpio version: 2.36\n",
    min_version => '3.18', env_release => 0, na => $na,
);
is scalar @na, 1, '2.36 vs 3.18 -> NA';

# unparseable gpio -v (the F3 case) -> NA, NOT a silent pass
$reset->();
RPi::Const::BuildCheck::wiringpi_build_check(
    include_dirs => [$inc], gpio_output => "wiringpi is great\n",
    min_version => '3.18', env_release => 0, na => $na,
);
is scalar @na, 1, 'unparseable gpio -v -> NA (F3: not a silent pass)';
like $na[0], qr/could not parse/, '...parse-failure message';

# gpio absent entirely -> NA
$reset->();
RPi::Const::BuildCheck::wiringpi_build_check(
    include_dirs => [$inc], gpio_output => undef, gpio_path => '/nonexistent/gpio',
    min_version => '3.18', env_release => 0, na => $na,
);
is scalar @na, 1, 'no gpio version determinable -> NA';
like $na[0], qr/can not determine/, '...cannot-determine message';

# --- i2c_build_check -------------------------------------------------------

my $i2c_inc = tempdir(CLEANUP => 1);
mkdir "$i2c_inc/linux";
open my $h1, '>', "$i2c_inc/linux/i2c-dev.h" or die $!; close $h1;
open my $h2, '>', "$i2c_inc/linux/i2c.h"     or die $!; close $h2;

$reset->();
is RPi::Const::BuildCheck::i2c_build_check(env_release => 1, na => $na), 1,
    'i2c: RPI_DIST_RELEASE bypass returns true';
is scalar @na, 0, '...no NA';

$reset->();
is RPi::Const::BuildCheck::i2c_build_check(
    include_dirs => [$i2c_inc], env_release => 0, na => $na,
), 1, 'i2c: headers present -> satisfied';
is scalar @na, 0, '...no NA';

$reset->();
RPi::Const::BuildCheck::i2c_build_check(
    include_dirs => ["$i2c_inc/nope"], env_release => 0, na => $na,
);
is scalar @na, 1, 'i2c: missing header -> NA';
like $na[0], qr/I2C development header/, '...i2c message';

# --- the default NA action really exits 0 (NA-not-FAIL) --------------------

my $pid = fork;
if (defined $pid && $pid == 0) {
    # Child: a failing check with the DEFAULT na must exit 0, not reach below.
    open STDOUT, '>', '/dev/null';
    RPi::Const::BuildCheck::wiringpi_build_check(
        include_dirs => ['/nonexistent'], env_release => 0,
    );
    exit 99;   # unreachable if the default NA exits
}
if (defined $pid) {
    waitpid $pid, 0;
    is $? >> 8, 0, 'default NA action exits 0 (NA-not-FAIL) on a failed check';
}
else {
    ok 1, 'fork unavailable - skipping default-NA exit check';
}

# --- broadened header discovery via the C compiler's search path (B3) -------

# _compiler_include_dirs parses the verbose preprocessor output, keeping only
# real directories from the "<...> search starts here" block.
{
    my $real = tempdir(CLEANUP => 1);
    my $cc_out = <<"OUT";
ignore this preamble line
#include "..." search starts here:
 $real/quote-only-should-be-ignored
#include <...> search starts here:
 $real
 /no/such/dir/xyzzy
End of search list.
 /trailing/junk/ignored
OUT
    my @dirs = RPi::Const::BuildCheck::_compiler_include_dirs(cc_output => $cc_out);
    is_deeply \@dirs, [$real],
        '_compiler_include_dirs: keeps real <...> dirs, drops quote-list/missing/after-end';

    is_deeply [RPi::Const::BuildCheck::_compiler_include_dirs(cc_output => '')], [],
        '_compiler_include_dirs: empty output -> empty list';
    is_deeply [RPi::Const::BuildCheck::_compiler_include_dirs(cc_output => undef)], [],
        '_compiler_include_dirs: undef output -> empty list';
}

# _header_found: a header outside the default prefixes is discovered through
# the compiler search path; an explicit include_dirs is the exact list and the
# compiler probe is NOT consulted.
{
    my $cc_inc = tempdir(CLEANUP => 1);
    open my $h, '>', "$cc_inc/zzunique_probe.h" or die $!; close $h;
    my $cc_out = "#include <...> search starts here:\n $cc_inc\nEnd of search list.\n";

    ok RPi::Const::BuildCheck::_header_found('zzunique_probe.h', cc_output => $cc_out),
        '_header_found: header found via the compiler search path (outside defaults)';

    ok ! RPi::Const::BuildCheck::_header_found('zzunique_probe.h', cc_output => ''),
        '_header_found: not found when the compiler reports no such dir';

    ok ! RPi::Const::BuildCheck::_header_found(
        'zzunique_probe.h', include_dirs => ['/nonexistent'], cc_output => $cc_out,
    ), '_header_found: explicit include_dirs is exact - compiler probe skipped';
}

done_testing();
