#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <inttypes.h>
#include <linux/i2c-dev.h>
#include <unistd.h>
#include <sys/ioctl.h>

#define BIT_MAX_12 1650
#define BIT_MAX_16 26400

int fetch(int addr, char * dev, char * wbuf1, char * wbuf2, int res){

    uint8_t write_buf[3];
    uint8_t read_buf[2];

    int i2c_file = open(dev, O_RDWR);

    if (i2c_file == -1){
        perror(dev);
        exit(1);
    }
   
    if (ioctl(i2c_file, I2C_SLAVE, addr) < 0){
        perror("failed to acquire bus access and/or talk to slave");
        exit(1);
    }

    write_buf[0] = 1; // set pointer to config register
    write_buf[1] = strtol(wbuf1, NULL, 0);
    write_buf[2] = strtol(wbuf2, NULL, 0);

    read_buf[0]= 0;
    read_buf[1]= 0;
    
    if (write(i2c_file, write_buf, 3) != 3){
        perror("failed to write to the i2c bus");
        exit(1);
    }

    // AND with 10000000 and wait for bit 15 of the config register to go true
    // This bit stores the "conversion complete" indicator

    while ((read_buf[0] & 0x80) == 0){
        read(i2c_file, read_buf, 2);
    }

    write_buf[0] = 0; // set to conversion register
    write(i2c_file, write_buf, 1);

    read(i2c_file, read_buf, 2);

    int16_t conversion = read_buf[0] << 8 | read_buf[1];

    if (res == 12){
        conversion = conversion >> 4;
    }
   
    close(i2c_file);

    return conversion;
}

float voltage_c (int addr, char * dev, char * wbuf1, char * wbuf2, int res){
   
    int conversion = fetch(addr, dev, wbuf1, wbuf2, res);
    
    float volts;
     
    if (res == 12){
        volts = (float)conversion * 4.096 / 2048.0;
    }
    else {
        volts = (float)conversion * 4.096 / 32767.0;
    }

    return volts;
}

int raw_c (int addr, char * dev, char * wbuf1, char * wbuf2, int res){
   
    int conversion = fetch(addr, dev, wbuf1, wbuf2, res);

    return conversion;
}

float percent_c (int addr, char * dev, char * wbuf1, char * wbuf2, int res){

    int conversion = fetch(addr, dev, wbuf1, wbuf2, res);

    float percent;

    if (res == 12){
        percent = (float)conversion / BIT_MAX_12 * 100;
    }
    else {
        percent = (float)conversion / BIT_MAX_16 * 100;
    }

    return percent;
}

MODULE = RPi::ADC::ADS  PACKAGE = RPi::ADC::ADS

PROTOTYPES: DISABLE

int
fetch (addr, dev, wbuf1, wbuf2, res)
    int addr
    char * dev
    char * wbuf1
    char * wbuf2
    int res

float
voltage_c (addr, dev, wbuf1, wbuf2, res)
    int addr
    char * dev
    char * wbuf1
    char * wbuf2
    int res

int
raw_c (addr, dev, wbuf1, wbuf2, res)
    int addr
    char * dev
    char * wbuf1
    char * wbuf2
    int res

float
percent_c (addr, dev, wbuf1, wbuf2, res)
    int addr
    char * dev
    char * wbuf1
    char * wbuf2
    int res
