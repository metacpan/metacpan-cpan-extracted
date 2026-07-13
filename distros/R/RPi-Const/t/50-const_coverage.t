use strict;
use warnings;

use Test::More;
use RPi::Const ();

# Self-policing coverage guard for RPi::Const. %expected is the single source of
# truth: every export tag, every constant in it, and its value. The structural
# checks below compare this manifest against the module's live %EXPORT_TAGS /
# @EXPORT_OK, so adding a NEW tag - or a NEW constant to any group - fails this
# test until it is declared here, which in turn forces a value assertion. That
# is the "no new untested constant slips in" guard the per-tag files can't give.

my %expected = (
    pwm_mode => {
        PWM_MODE_MS  => 0,
        PWM_MODE_BAL => 1,
    },
    pwm_defaults => {
        PWM_DEFAULT_MODE  => 1,
        PWM_DEFAULT_CLOCK => 32,
        PWM_DEFAULT_RANGE => 1023,
    },
    pinmode => {
        INPUT            => 0,
        OUTPUT           => 1,
        PWM_OUT          => 2,
        GPIO_CLOCK       => 3,
        SOFT_PWM_OUTPUT  => 4,
        SOFT_TONE_OUTPUT => 5,
        PWM_TONE_OUTPUT  => 6,
    },
    altmode => {
        # Deliberately non-sequential (wiringPi funcsel ordering) - a typo here
        # is invisible without an explicit per-value assertion.
        ALT0 => 4,
        ALT1 => 5,
        ALT2 => 6,
        ALT3 => 7,
        ALT4 => 3,
        ALT5 => 2,
    },
    pull => {
        PUD_OFF  => 0,
        PUD_DOWN => 1,
        PUD_UP   => 2,
    },
    state => {
        HIGH => 1,
        LOW  => 0,
        ON   => 1,
        OFF  => 0,
    },
    edge => {
        EDGE_SETUP   => 0,
        EDGE_FALLING => 1,
        EDGE_RISING  => 2,
        EDGE_BOTH    => 3,
    },
    mode => {
        RPI_MODE_WPI      => 0,
        RPI_MODE_GPIO     => 1,
        RPI_MODE_GPIO_SYS => 2,
        RPI_MODE_PHYS     => 3,
        RPI_MODE_UNINIT   => -1,
    },
    mcp23017_registers => {
        MCP23017_IODIRA   => 0x00,
        MCP23017_IODIRB   => 0x01,
        MCP23017_IPOLA    => 0x02,
        MCP23017_IPOLB    => 0x03,
        MCP23017_GPINTENA => 0x04,
        MCP23017_GPINTENB => 0x05,
        MCP23017_DEFVALA  => 0x06,
        MCP23017_DEFVALB  => 0x07,
        MCP23017_INTCONA  => 0x08,
        MCP23017_INTCONB  => 0x09,
        MCP23017_IOCONA   => 0x0A,
        MCP23017_IOCONB   => 0x0B,
        MCP23017_GPPUA    => 0x0C,
        MCP23017_GPPUB    => 0x0D,
        MCP23017_INTFA    => 0x0E,
        MCP23017_INTFB    => 0x0F,
        MCP23017_INTCAPA  => 0x10,
        MCP23017_INTCAPB  => 0x11,
        MCP23017_GPIOA    => 0x12,
        MCP23017_GPIOB    => 0x13,
        MCP23017_OLATA    => 0x14,
        MCP23017_OLATB    => 0x15,
        MCP23017_INPUT    => 1,
        MCP23017_OUTPUT   => 0,
    },
    mcp23017_pins => {
        # Bank A pins 0-7
        A0 => 0,
        A1 => 1,
        A2 => 2,
        A3 => 3,
        A4 => 4,
        A5 => 5,
        A6 => 6,
        A7 => 7,
        # Bank B pins 8-15
        B0 => 8,
        B1 => 9,
        B2 => 10,
        B3 => 11,
        B4 => 12,
        B5 => 13,
        B6 => 14,
        B7 => 15,
    },
    wpi_pin => {
        WPI_PIN_BCM => 1,
        WPI_PIN_WPI => 2,
    },
    wiringpi => {
        WIRINGPI_MIN_VERSION => '3.18',
    },
    int_edge => {
        INT_EDGE_SETUP   => 0,
        INT_EDGE_FALLING => 1,
        INT_EDGE_RISING  => 2,
        INT_EDGE_BOTH    => 3,
    },
);

# The module's live tag list - everything except the ':all' union alias.
my @live_tags = sort grep { $_ ne 'all' } keys %RPi::Const::EXPORT_TAGS;

# 1. Tag set: a new or removed export tag fails here until %expected matches.
is_deeply
    \@live_tags,
    [sort keys %expected],
    'export tag set matches the coverage manifest (no new/removed tag)';

# 2/3. Per tag: the exported constant list matches, and every value is correct.
for my $tag (sort keys %expected) {
    my $live = $RPi::Const::EXPORT_TAGS{$tag} || [];

    is_deeply
        [sort @$live],
        [sort keys %{ $expected{$tag} }],
        "$tag: exported constant list matches manifest (no new/removed constant)";

    for my $name (sort keys %{ $expected{$tag} }) {
        my $sub = RPi::Const->can($name);
        ok $sub, "$tag: $name is defined" or next;
        is $sub->(), $expected{$tag}{$name}, "$tag: $name == $expected{$tag}{$name}";
    }
}

# 4. ':all' (@EXPORT_OK) is exactly the union of every group - catches an orphan
#    constant pushed to @EXPORT_OK without a tag, or a duplicate across groups.
my %union;
$union{$_}++ for map { @{ $RPi::Const::EXPORT_TAGS{$_} } } @live_tags;
is_deeply
    [sort @RPi::Const::EXPORT_OK],
    [sort keys %union],
    ':all (@EXPORT_OK) equals the union of all tag groups';

# 5. int_edge mirrors edge (documented "same values" invariant).
for my $pair (
    ['INT_EDGE_SETUP',   'EDGE_SETUP'],
    ['INT_EDGE_FALLING', 'EDGE_FALLING'],
    ['INT_EDGE_RISING',  'EDGE_RISING'],
    ['INT_EDGE_BOTH',    'EDGE_BOTH'],
) {
    my ($int_name, $edge_name) = @$pair;
    my $int_val  = RPi::Const->can($int_name)->();
    my $edge_val = RPi::Const->can($edge_name)->();
    is $int_val, $edge_val, "$int_name == $edge_name";
}

done_testing();
