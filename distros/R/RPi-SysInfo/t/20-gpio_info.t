use warnings;
use strict;

use RPi::SysInfo qw(:all);
use Test::More;

if (! $ENV{RPI_BOARD}){
    plan skip_all => "Not on a Pi board";
}

# gpio_info() drives pinctrl on current Raspberry Pi OS (raspi-gpio was removed,
# and never existed on the Pi 5/RP1), falling back to raspi-gpio on older
# systems. Each line looks like: "20: no    pd | -- // GPIO20 = none"

# --- tool detection ---------------------------------------------------------

my $tool = RPi::SysInfo::_gpio_tool();

ok defined $tool, "_gpio_tool() located a gpio tool";
like $tool, qr/^(?:pinctrl|raspi-gpio)\z/, "_gpio_tool() returns a known tool ($tool)";

my $sys = RPi::SysInfo->new;

# --- all pins (functional + OO) ---------------------------------------------

for my $case ([gpio_info(), 'function'], [$sys->gpio_info, 'method']){
    my ($info, $form) = @$case;

    ok length $info, "gpio_info() $form returns data with no params";

    my @lines = split /\n/, $info;
    cmp_ok scalar(@lines), '>=', 28, "gpio_info() $form returns the full set of pins";

    like $info, qr/GPIO\d+ = /, "gpio_info() $form output is in the expected format";
    like $info, qr/GPIO2 = /, "gpio_info() $form includes a known header pin (2)";
}

# --- a single pin -----------------------------------------------------------

for my $case (['function', sub { gpio_info(@_) }], ['method', sub { $sys->gpio_info(@_) }]){
    my ($form, $code) = @$case;

    my $one = $code->([20]);
    like $one, qr/GPIO20 = /, "single pin ($form) returns pin 20";

    my @lines = split /\n/, $one;
    is scalar(@lines), 1, "single pin ($form) returns exactly one line";
}

# --- multiple pins, with an exclusion ---------------------------------------

for my $case (['function', sub { gpio_info(@_) }], ['method', sub { $sys->gpio_info(@_) }]){
    my ($form, $code) = @$case;

    my $ret = $code->([2, 4, 6, 8]);

    like $ret, qr/GPIO2 = /, "multi pin ($form) includes pin 2";
    like $ret, qr/GPIO4 = /, "multi pin ($form) includes pin 4";
    like $ret, qr/GPIO6 = /, "multi pin ($form) includes pin 6";
    like $ret, qr/GPIO8 = /, "multi pin ($form) includes pin 8";
    unlike $ret, qr/GPIO9 = /, "multi pin ($form) excludes pin 9";

    my @lines = split /\n/, $ret;
    is scalar(@lines), 4, "multi pin ($form) returns exactly four lines";
}

done_testing();
