use warnings;
use strict;
use feature 'say';

use RPi::WiringPi;

my $pi = RPi::WiringPi->new;

{ # cpu percent
    my $cpu_percent = $pi->cpu_percent;
    say "CPU utilization: $cpu_percent%";
}

{ # mem percent
    my $mem_percent = $pi->mem_percent;
    say "RAM utilization: $mem_percent%";
}
{ # core temp

    my $tC = $pi->core_temp;
    my $tF = $pi->core_temp('f');

    say "Core CPU temperature: $tC C : $tF F";
}

{ # gpio

    my $pin_21_info = $pi->gpio_info([21]);

    my $multi_pin_info = $pi->gpio_info([2, 4, 6]);

    say "Pin 21 info:";
    say "$pin_21_info\n";

    say "Multi-pin info:";
    say $multi_pin_info;

}

{ # config.txt
    say $pi->raspi_config;
}

{ # net info
    say $pi->network_info;
}

{ # file sys
    say $pi->file_system;
}

{ # pi details
    say $pi->pi_details;
}
