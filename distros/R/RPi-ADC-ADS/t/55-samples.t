use strict;
use warnings;

use RPi::ADC::ADS;
use Test::More;

my $mod = 'RPi::ADC::ADS';

{ # default
    my $obj = $mod->new;
    is $obj->samples, 1, "samples() default is 1";
}

{ # set via the constructor
    my $obj = $mod->new(samples => 25);
    is $obj->samples, 25, "samples set via new() ok";
}

{ # accessor set/get
    my $obj = $mod->new;
    is $obj->samples(64), 64, "samples() set returns the new value";
    is $obj->samples, 64, "...and reads back ok";
}

{ # validation: must be a positive integer
    my $obj = $mod->new;

    for my $bad (0, -1, '1.5', 'x', ''){
        my $ok = eval { $obj->samples($bad); 1 };
        is $ok, undef, "samples('$bad') croaks ok";
        like $@, qr/positive integer/, "...and the error is sane";
    }

    is $obj->samples, 1, "samples() left at the default after the failed sets";
}

done_testing();
