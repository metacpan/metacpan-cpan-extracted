#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <stdint.h>
#include <wiringPi.h>
#include <wiringPiSPI.h>

#define MULT 2
#define SPI_BYTES 2

#define DAC_BIT  15
#define BUF_BIT  14
#define GAIN_BIT 13
#define SHDN_BIT 12

int _reg_init (int buf, int gain);
int _disable_hw (int shdn);
int _disable_sw (int channel, int cs, int dac, int buf);
int _enable_hw (int shdn);
int _enable_sw (int channel, int cs, int dac, int buf);
void _set (int channel, int cs, int dac, int lsb, int buf, int data);
int _write_dac (int channel, int cs, int buf);
int __set_dac (int buf, int dac);

int _reg_init (int buf, int gain){

    /* sets the initial register values */

    int bits = 0;

    if (buf){
        bits |= 1 << BUF_BIT;
    }

    if (gain){
        bits |= 1 << GAIN_BIT;
    }

    bits |=1 << SHDN_BIT;

    return bits;
}

void _set(int channel, int cs, int dac, int lsb, int buf, int data){
    
    /* prepares the register for sending to a DAC */

    buf = __set_dac(buf, dac);
    int mask = ((int)pow(MULT, 12) -1) >> lsb;

    buf = (buf & ~(mask)) | (data << lsb);
   
    _write_dac(channel, cs, buf);
}

int _enable_hw (int shdn){

    /* hardware un-shutdown of both DACs */

    digitalWrite(shdn, HIGH);
    return 0;
}

int _enable_sw (int channel, int cs, int dac, int buf){

    /* software enable of a DAC */
    
    buf = __set_dac(buf, dac);
    buf |= 1 << SHDN_BIT;
   
    _write_dac(channel, cs, buf);

    return 0;
}

int _disable_hw (int shdn){

    /* hardware shutdown of both DACs */

    digitalWrite(shdn, LOW);
    return 0;
}

int _disable_sw (int channel, int cs, int dac, int buf){

    /* software shutdown of a DAC */
    
    buf = __set_dac(buf, dac);
    buf &= ~(1 << SHDN_BIT);

    _write_dac(channel, cs, buf);

    return 0;
}

int __set_dac (int buf, int dac){

    /* set the DAC register bit */

    if (dac)
        buf |= 1 << DAC_BIT;
    else
        buf &= ~(1 << DAC_BIT);
  
    return buf;
}

int _write_dac (int channel, int cs, int buf){

    unsigned char reg[2];
    
    reg[0] = (buf >> 8) & 0xFF;
    reg[1] = buf & 0xFF;

    digitalWrite(cs, LOW);
    wiringPiSPIDataRW(channel, reg, SPI_BYTES);
    digitalWrite(cs, HIGH);

    return 0;
}

MODULE = RPi::DAC::MCP4922  PACKAGE = RPi::DAC::MCP4922

PROTOTYPES: DISABLE


int
_reg_init (buf, gain)
	int	buf
	int	gain

void
_set (channel, cs, dac, lsb, buf, data)
	int	channel
	int	cs
	int	dac
	int	lsb
	int	buf
	int	data

int
_disable_hw (shdn)
    int shdn

int
_disable_sw (channel, cs, dac, buf)
	int	channel
	int	cs
	int	dac
	int	buf

int
_enable_hw (shdn)
    int shdn

int
_enable_sw (channel, cs, dac, buf)
	int	channel
	int	cs
	int	dac
	int	buf

int
__set_dac (buf, dac)
	int	buf
	int	dac

void 
_write_dac (channel, cs, buf)
    int channel
    int cs
    int buf

