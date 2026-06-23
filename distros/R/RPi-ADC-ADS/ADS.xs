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

// ADC full-scale positive code: 16-bit (ADS111x), and the 12-bit (ADS101x)
// value after fetch() right-shifts the reading into 12 bits.
#define ADS_FS_16 32767.0
#define ADS_FS_12 2048.0

// Reference for percent(): the input as a percentage of the Pi's 3.3V GPIO
// range, so a gain-1 reading of 3.3V is 100% (the historical scale).
#define ADS_VREF 3.3

// Per-conversion i2c retry cap. The Pi bus intermittently throws transient
// errors (e.g. EREMOTEIO); we retry the conversion rather than abort, but bail
// loudly if the bus is persistently unresponsive.
#define MAX_I2C_ATTEMPTS 1000

int fetch(int addr, char * dev, char * wbuf1, char * wbuf2, int res, int samples){

    uint8_t write_buf[3];
    uint8_t read_buf[2];

    if (samples < 1){
        samples = 1;
    }

    int i2c_file = open(dev, O_RDWR);

    if (i2c_file == -1){
        perror(dev);
        exit(1);
    }

    if (ioctl(i2c_file, I2C_SLAVE, addr) < 0){
        perror("failed to acquire bus access and/or talk to slave");
        exit(1);
    }

    // Average `samples` single-shot conversions, returning the mean. The i2c
    // device is opened once for the whole batch (the open/ioctl/close dominate
    // the per-conversion cost), so averaging N samples here is far cheaper than
    // taking N separate single reads. Averaging in the raw conversion domain is
    // exact: the volts/percent scaling that the callers apply is linear.

    long sum = 0;

    for (int s = 0; s < samples; s++){

        int16_t conversion = 0;
        int got = 0;
        int attempts = 0;

        // Acquire one conversion, retrying on a transient i2c error rather than
        // aborting. Averaging many conversions makes a single bus glitch likely,
        // and a conversion-ready poll must tolerate the odd failed read; we only
        // bail (loudly) if the bus stays unresponsive past MAX_I2C_ATTEMPTS.

        while (! got){

            if (++attempts > MAX_I2C_ATTEMPTS){
                fprintf(stderr, "fetch: i2c bus unresponsive after %d attempts\n",
                        attempts);
                exit(1);
            }

            write_buf[0] = 1; // set pointer to config register
            write_buf[1] = strtol(wbuf1, NULL, 0);
            write_buf[2] = strtol(wbuf2, NULL, 0);

            read_buf[0] = 0;
            read_buf[1] = 0;

            if (write(i2c_file, write_buf, 3) != 3){
                continue;
            }

            // AND with 10000000 and wait for bit 15 of the config register to
            // go false. This bit stores the "conversion complete" indicator.

            int ready = 1;

            while ((read_buf[0] & 0x80) == 0){
                if (read(i2c_file, read_buf, 2) != 2){
                    ready = 0;
                    break;
                }
            }

            if (! ready){
                continue;
            }

            // 0: conversion register
            // 1: configuration register

            write_buf[0] = 0;
            if (write(i2c_file, write_buf, 1) != 1){
                continue;
            }

            if (read(i2c_file, read_buf, 2) != 2){
                continue;
            }

            conversion = read_buf[0] << 8 | read_buf[1];

            if (res == 12){
                conversion = conversion >> 4;
            }

            got = 1;
        }

        sum += conversion;
    }

    close(i2c_file);

    return (int)(sum / samples);
}

// Full-scale range (volts) of the programmed PGA gain (config bits 11-9),
// per the ADS111x datasheet (SBAS444, Table). The gain bits sit in the config
// register's most significant byte (wbuf1): bits 3-1 of that byte.
static float pga_fsr(char * wbuf1){

    int pga = (strtol(wbuf1, NULL, 0) >> 1) & 0x07;

    switch (pga){
        case 0:  return 6.144;
        case 1:  return 4.096;  // default
        case 2:  return 2.048;
        case 3:  return 1.024;
        case 4:  return 0.512;
        default: return 0.256;  // 5, 6, 7
    }
}

float voltage_c (int addr, char * dev, char * wbuf1, char * wbuf2, int res, int samples){

    int conversion = fetch(addr, dev, wbuf1, wbuf2, res, samples);

    float fsr = pga_fsr(wbuf1);
    float fs  = (res == 12) ? ADS_FS_12 : ADS_FS_16;

    return (float)conversion * fsr / fs;
}

int raw_c (int addr, char * dev, char * wbuf1, char * wbuf2, int res, int samples){

    int conversion = fetch(addr, dev, wbuf1, wbuf2, res, samples);

    return conversion;
}

float percent_c (int addr, char * dev, char * wbuf1, char * wbuf2, int res, int samples){

    int conversion = fetch(addr, dev, wbuf1, wbuf2, res, samples);

    float fsr = pga_fsr(wbuf1);
    float fs  = (res == 12) ? ADS_FS_12 : ADS_FS_16;

    // The input as a percentage of the 3.3V GPIO range, now scaled by the
    // programmed PGA's full-scale range rather than a constant 4.096V.
    return (float)conversion * fsr / fs / ADS_VREF * 100.0;
}

MODULE = RPi::ADC::ADS  PACKAGE = RPi::ADC::ADS

PROTOTYPES: DISABLE

int
fetch (addr, dev, wbuf1, wbuf2, res, samples)
    int addr
    char * dev
    char * wbuf1
    char * wbuf2
    int res
    int samples

float
voltage_c (addr, dev, wbuf1, wbuf2, res, samples)
    int addr
    char * dev
    char * wbuf1
    char * wbuf2
    int res
    int samples

int
raw_c (addr, dev, wbuf1, wbuf2, res, samples)
    int addr
    char * dev
    char * wbuf1
    char * wbuf2
    int res
    int samples

float
percent_c (addr, dev, wbuf1, wbuf2, res, samples)
    int addr
    char * dev
    char * wbuf1
    char * wbuf2
    int res
    int samples
