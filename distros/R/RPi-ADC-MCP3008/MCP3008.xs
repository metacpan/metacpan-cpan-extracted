#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <errno.h>

#include <wiringPi.h>
#include <wiringPiSPI.h>

const unsigned char inputs[16] = {
    0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, // single-ended
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07  // differential
};

void spi_setup (const int channel){
    if (wiringPiSPISetup(channel, 1000000) < 0){
        printf("can't open the SPI bus: %s\n", strerror(errno)) ;
        exit(errno) ;
    }
}

void wpi_setup () {
    if (wiringPiSetupGpio() < 0){
        printf("failed to load wiringPi: %s\n", strerror(errno)) ;
        exit(errno);
    }
}

int fetch (int channel, const int input){

    if (input < 0 || input > 15){
        croak("ADC input channel must be 0-15\n");
    }

    // check if we're using GPIO CS

    char cs = 0;

    if (channel > 1){
        cs = channel;

        /*
         * FIXME
         * because we're using GPIO, we 'dummy' out
         * the channel back to zero, so core can work.
         * I don't think wiringPi can understand this,
         * so using a GPIO along with sending 0 as a
         * channel will likely cause havoc if something
         * is at CE0.
         * *** need to investigate
         */

        channel = 0;
    }

    unsigned char buf[3];

    buf[0] = 0x01; // start bit
    buf[1] = inputs[input] << 4;
    buf[2] = 0x00;
   
    if (cs){
        digitalWrite(cs, LOW);  // start conversation
        wiringPiSPIDataRW(channel, buf, 3);
        digitalWrite(cs, HIGH); // end conversation
    }
    else {
        wiringPiSPIDataRW(channel, buf, 3);
    }

    return ((buf[1] & 0x03) << 8) + buf[2]; // last 10 bits
}

MODULE = RPi::ADC::MCP3008  PACKAGE = RPi::ADC::MCP3008

PROTOTYPES: DISABLE

void
spi_setup (channel)
    int channel

void
wpi_setup ()

int
fetch (channel, input)
    int channel
    int input
