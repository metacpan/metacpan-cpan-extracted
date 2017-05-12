use warnings;
use strict;

use Inline 'Noclean';
use Inline 'C';


__END__
__C__

#include <stdio.h>
#include <wiringPi.h>
#include <wiringPiSPI.h>

int setup (int channel, int speed){
    return wiringPiSPISetup(channel, speed);
}

int dpot_write (int channel, unsigned char * data, int len){
    printf("%d\n", data);
}
