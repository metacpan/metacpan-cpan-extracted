use strict;
use warnings;

use lib 't/';

use RPi::Const qw(:all);
use RPiTest;
use Test::More;

rpi_running_test(__FILE__);

my $mod = 'RPi::WiringPi';

my $pi = $mod->new(label => 't/104-core_regressions.t', shm_key => 'rpit');

{ # gpio_layout() must dispatch to WiringPi::API, not recurse into itself

    my $layout = $pi->gpio_layout;
    ok defined $layout,
        "gpio_layout() returns a defined value ($layout) without recursing";
}

{ # pwm_mode()/pwm_range() getter forms (and their constified defaults)

    if ($> == 0) {
        is $pi->pwm_mode, PWM_DEFAULT_MODE,
            "pwm_mode() getter returns the default without croaking";
        is $pi->pwm_range, PWM_DEFAULT_RANGE,
            "pwm_range() getter default is PWM_DEFAULT_RANGE";
    }
    else {
        my $err = do { local $@; eval { $pi->pwm_mode }; $@ };
        like $err, qr/root/,
            "pwm_mode() getter still enforces the root requirement";
    }
}

{ # _pwm_in_use() must not write meta unless BOTH registration flags are on

    my $obj = $mod->new(
        label             => 't/104-pwm-guard',
        shm_key           => 'rpit',
        rpi_register_pins => 0,
        rpi_register      => 1,
    );

    $obj->_pwm_in_use(1);

    $obj->meta_lock;
    my $meta = $obj->meta_fetch;
    $obj->meta_unlock;

    ok ! exists $meta->{pwm}{users}{$obj->uuid},
        "_pwm_in_use() writes no meta when pin registration is disabled";

    $obj->cleanup;
}

{ # A falsy RPI_PIN_MODE (RPI_MODE_WPI == 0) must not be re-initialized

    local $ENV{RPI_PIN_MODE} = RPI_MODE_WPI;

    my $obj = $mod->new(label => 't/104-wpi-env', shm_key => 'rpit');

    is $obj->pin_scheme, RPI_MODE_WPI,
        "new() honours an existing falsy (WPI) RPI_PIN_MODE scheme";
    is $ENV{RPI_PIN_MODE}, RPI_MODE_WPI,
        "RPI_PIN_MODE env var is not restamped to GPIO";

    $obj->cleanup;
}

{ # new()'s 'setup' param: case-insensitive, croaks on unrecognized values

    {
        # The setup branch only runs when no scheme is already established

        delete local $ENV{RPI_PIN_MODE};

        my $obj = $mod->new(
            label   => 't/104-setup-gpio',
            shm_key => 'rpit',
            setup   => 'Gpio',
        );

        is $obj->pin_scheme, RPI_MODE_GPIO,
            "setup => 'Gpio' (mixed case) initializes GPIO scheme";

        $obj->cleanup;
    }

    {
        delete local $ENV{RPI_PIN_MODE};

        my $obj = $mod->new(
            label   => 't/104-setup-none',
            shm_key => 'rpit',
            setup   => 'NONE',
        );

        is $obj->pin_scheme, RPI_MODE_UNINIT,
            "setup => 'NONE' (case-insensitive) leaves the scheme uninitialized";

        $obj->cleanup;
    }

    {
        delete local $ENV{RPI_PIN_MODE};

        my $err = do {
            local $@;
            eval {
                $mod->new(
                    label             => 't/104-setup-bogus',
                    shm_key           => 'rpit',
                    setup             => 'bogus',
                    rpi_register      => 0,
                    rpi_register_pins => 0,
                );
            };
            $@;
        };

        like $err, qr/unrecognized 'setup' param value 'bogus'/,
            "new() croaks on an unrecognized setup param value";
    }
}

{ # _led_cmd() surfaces command failures instead of silently no-opping

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    $pi->_led_cmd('false');

    like $warnings[0], qr/LED command 'false' failed/,
        "_led_cmd() warns when the underlying command fails";
}

$pi->cleanup;

rpi_check_pin_status();

done_testing();
