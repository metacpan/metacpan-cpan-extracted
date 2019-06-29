use warnings;
use strict;
use feature 'say';

use Inline Config =>
           disable => clean_after_build =>
           name => 'RPi::EEPROM::AT24C32';
use Inline 'C';

use constant {
    I2C_DEV          => "/dev/i2c-1",
    I2C_ADDR         => 0x57,
    WRITE_CYCLE_TIME => 1
};

my $fd = eeprom_init(I2C_DEV, I2C_ADDR, WRITE_CYCLE_TIME);

for (100..110) {
    eeprom_write_byte($fd, $_, $_);
    say eeprom_read_byte($fd, $_);
}

eeprom_close($fd);


__END__
__C__

#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <linux/fs.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <assert.h>
#include <string.h>
#include "eeprom.h"

int write_cycle_time = 0;

static int _writeAddress(int fd, __u8 buf[2]){
	int r = i2c_smbus_write_byte_data(fd, buf[0], buf[1]);
	if(r < 0)
		fprintf(stderr, "Error _writeAddress: %s\n", strerror(errno));
	usleep(10);
	return r;
}

static int _writeByte(int fd, __u8 buf[3]){
	int r;
	r = i2c_smbus_write_word_data(fd, buf[0], buf[2] << 8 | buf[1]);
	if(r < 0)
		fprintf(stderr, "Error _writeByte: %s\n", strerror(errno));
	usleep(10);
	return r;
}

static int _writeBlock(int fd, __u8 eepromAddr, int len, __u8 *data)
{
	int r;
	r = i2c_smbus_write_block_data(fd, eepromAddr, len, data);
	if(r < 0)
		fprintf(stderr, "Error _write_block: %s\n", strerror(errno));
	usleep(10);
	return r;
}

int eeprom_init(char *dev_fqn, int addr, int delay){
	int funcs, fd, r;

	fd = open(dev_fqn, O_RDWR);
	if(fd <= 0)
	{
		fprintf(stderr, "Error eeprom_init: %s\n", strerror(errno));
		return -1;
	}

	// set working device
	if( ( r = ioctl(fd, I2C_SLAVE, addr)) < 0)
	{
		fprintf(stderr, "Error opening EEPROM i2c connection: %s\n", strerror(errno));
		return -1;
	}

    write_cycle_time = delay;

	return fd;
}

int eeprom_close(int fd){
	close(fd);
	return 0;
}

int eeprom_read_current_byte(int fd){
	ioctl(fd, BLKFLSBUF); // clear kernel read buffer
	return i2c_smbus_read_byte(fd);
}

int eeprom_read_byte(int fd, int mem_addr){
	int r;
	ioctl(fd, BLKFLSBUF); // clear kernel read buffer

	__u8 buf[2] = { (mem_addr >> 8) & 0x0ff, mem_addr & 0x0ff };

    r = _writeAddress(fd, buf);

    if (r < 0){
		return r;
    }

    return(i2c_smbus_read_byte(fd));
}

int eeprom_write_byte(int fd, int mem_addr, int data){
    __u8 buf[3] = {
        (__u8)(mem_addr >> 8) & 0x00ff,
        (__u8)mem_addr & 0x00ff,
        (__u8)data
    };

    int ret = _writeByte(fd, buf);
    if (ret == 0 && write_cycle_time != 0) {
        usleep(1000 * write_cycle_time);
    }
    return ret;
}

int eeprom_write_block(int fd, int mem_addr, int data){

    __u8 addr_msb = (mem_addr >> 8) & 0x00ff;
    __u8 buf[2] = {
        mem_addr & 0x00ff,
        data
    };

    int ret = _writeByte(fd, buf);

    if (ret == 0 && write_cycle_time != 0) {
        usleep(1000 * write_cycle_time);
    }
    return ret;
}
