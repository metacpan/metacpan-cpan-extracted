use warnings;
use strict;
use feature 'say';

use RPi::ADC::MCP3008;
use RPi::WiringPi::Constant qw(:all);
use WiringPi::API qw(:all);

my $adc = RPi::ADC::MCP3008->new(26);

say $adc->raw(0x08);
say $adc->percent(0x08);
