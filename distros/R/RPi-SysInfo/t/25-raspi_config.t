use warnings;
use strict;

use RPi::SysInfo qw(:all);
use Test::More;

if (! $ENV{RPI_BOARD}){
    plan skip_all => "Not on a Pi board";
}

my $sys = RPi::SysInfo->new;

# --- the live vcgencmd portion ----------------------------------------------

like $sys->raspi_config, qr/core_freq/, "method includes vcgencmd data ok";
like raspi_config,       qr/core_freq/, "function includes vcgencmd data ok";

# --- the config.txt portion (path resolved by _config_file) -----------------

my $config_file = RPi::SysInfo::_config_file();

ok defined $config_file && -f $config_file,
    "_config_file() resolves to an existing config.txt ($config_file)";

# config.txt directives must be appended; every Pi config.txt carries at least
# one dtparam= or dtoverlay= line. (The old code read the wrong path on
# Bookworm+ and so never included these.)

like
    $sys->raspi_config,
    qr/^dt(?:param|overlay)=/m,
    "method includes config.txt directives";

like
    raspi_config,
    qr/^dt(?:param|overlay)=/m,
    "function includes config.txt directives";

# comment and blank lines from config.txt must be stripped

unlike raspi_config, qr/^\s*#/m, "config.txt comment lines are stripped";

done_testing();
