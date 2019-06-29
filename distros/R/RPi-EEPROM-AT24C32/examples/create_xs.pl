use warnings;
use strict;
use feature 'say';

use Inline Config =>
           disable => clean_after_build =>
           name => 'RPi::EEPROM::AT24C32';
use Inline 'C';

use constant {
    EEPROM_ADDR => 0x57
};

my $fd = XS_init(EEPROM_ADDR);

say $fd;

say XS_writeByte($fd, 25, 8);

say XS_readByte($fd, 25);

XS_close($fd);


__END__
__C__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <errno.h>
#include <fcntl.h>
//#include <linux/i2c.h>
//#include <linux/i2c-dev.h>
#include "i2c-dev.h"
#include <linux/fs.h>
#include <sys/ioctl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int XS_readByte (int fd, int addr){
    ioctl(fd, BLKFLSBUF);
    _writeAddress(fd, addr);
    usleep(10);
    return i2c_smbus_read_byte(fd);
}    

int _writeAddress (int fd, int addr){

    __u8 buf[2] = { (addr >> 8) & 0x0FF, addr & 0xFF };

    if (i2c_smbus_write_byte_data(fd, buf[0], buf[1]) < 0){
        printf("%s\n", strerror(errno));
        croak("failed to write address to EEPROM\n");
    }
    usleep(10);
    return 0;
}


int XS_writeByte (int fd, int addr, int data){

    __u8 msb = addr >> 8;
    __u8 buf[2] = { addr & 0xFF, data };

    if (i2c_smbus_write_block_data(fd, msb, 2, buf) < 0){
        croak("failed to write byte data to EEPROM\n");
    }
    usleep(10);
    return 0;
}

int XS_init (int addr){

    int fd;

    if ((fd = open("/dev/i2c-1", O_RDWR)) < 0) {
        close(fd);
        croak("Couldn't open the EEPROM i2c device: %s\n", strerror(errno));
	}

	if (ioctl(fd, I2C_SLAVE_FORCE, addr) < 0) {
        close(fd);
        croak(
            "Couldn't find the EEPROM i2c device at addr %d: %s\n",
            addr,
            strerror(errno)
        );
	}

//    _establishI2C(fd);

    return fd;
}

void _establishI2C (int fd){
    /* CURRENTLY UNUSED */
    int buf[1] = { 0x00 };

    if (write(fd, buf, 1) != 1){
        close(fd);
		croak("Error: Received no ACK bit, couldn't establish connection!");
    }
}

void XS_close (int fd){
    close(fd);
}
