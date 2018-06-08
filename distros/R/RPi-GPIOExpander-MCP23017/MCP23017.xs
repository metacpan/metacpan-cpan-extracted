#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <errno.h>
#include <fcntl.h>
#include <linux/i2c.h>
#include <linux/i2c-dev.h>
#include <sys/ioctl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "mcp23017.h"
#include "bit.h"

/* setup functions */

int GPIO_getFd (int expanderAddr){

    int fd;

    if ((fd = open("/dev/i2c-1", O_RDWR)) < 0) {
        close(fd);
        printf("Couldn't open the device: %s\n", strerror(errno));
        croak("...this is a fatal error\n");
    }

    if (ioctl(fd, I2C_SLAVE_FORCE, expanderAddr) < 0) {
        close(fd);
        printf(
                "Couldn't find device at addr %d: %s\n",
                expanderAddr,
                strerror(errno)
        );
        exit(-1);
    }

    _establishI2C(fd);

    return fd;
}

void _establishI2C (int fd){

    int buf[1] = { 0x00 };

    if (write(fd, buf, 1) != 1){
        close(fd);
        printf("Error: Received no ACK bit, couldn't establish connection!");
        exit(-1);
    }
}

/* register operations */

void _checkRegisterReadOnly (uint8_t reg){
    uint8_t readOnlyRegisters[6] = {0x0A, 0X0B, 0x0E, 0x0F, 0x10, 0x11};

    for (int i=0; i < sizeof(readOnlyRegisters); i++){
        if (reg == readOnlyRegisters[i]){
            warn("error: register 0x%x is read-only...\n", reg);
            croak("Attempt to write to read-only register failed\n");
        }
    }
}

int _skipRegisterReadOnly (uint8_t reg){
    uint8_t readOnlyRegisters[6] = {0x0A, 0X0B, 0x0E, 0x0F, 0x10, 0x11};

    for (int i=0; i < sizeof(readOnlyRegisters); i++){
        if (reg == readOnlyRegisters[i]){
            return 1;
        }
    }
    return 0;
}

int GPIO_getRegister (int fd, int reg){

    uint8_t buf[1];
    buf[0] = reg;

    if ((write(fd, buf, 1)) != 1){
        close(fd);
        croak(
            "Could not write register pointer %d: %s\n",
            reg,
            strerror(errno)
        );
    }

    if ((read(fd, buf, 1)) != 1){
        close(fd);
        croak("Could not read register %d: %s\n", reg, strerror(errno));
    }

    return buf[0];
}

int GPIO_getRegisterBit (int fd, int reg, int bit){
    bit = GPIO__pinBit(bit);
    int regData = GPIO_getRegister(fd, (int) reg);
    return bitGet(regData, bit, bit);
}

int GPIO_getRegisterBits (int fd, int reg, int msb, int lsb){
    return bitGet(GPIO_getRegister(fd, reg), msb, lsb);
}

int GPIO_setRegister(int fd, int reg, int value, char* name){
    _checkRegisterReadOnly(reg);

    uint8_t buf[2] = {reg, value};

    if ((write(fd, buf, sizeof(buf))) != 2){
        close(fd);
        printf(
                "Could not write to the %s register: %s\n",
                name,
                strerror(errno)
        );
        exit(-1);
    }

    return 0;
}

/* pin functions */

int GPIO__pinBit (int pin){
    if (pin < 0 || pin > 15){
        croak("pin '%d' is out of bounds. Pins 0-15 are available\n");
    }

    // since we're dealing with a register per bank,
    // We need to know where in the double register to
    // look

    return pin < 8 ? pin : pin - 8;
}

bool GPIO_readPin (int fd, int pin){
    int reg = pin < 8 ? reg = MCP23017_GPIOA : MCP23017_GPIOB;
    int bit = GPIO__pinBit(pin);

    return (bool) GPIO_getRegisterBit(fd, reg, bit);
}

void GPIO_writePin (int fd, int pin, bool state){
    int reg = pin < 8 ? reg = MCP23017_GPIOA : MCP23017_GPIOB;
    int bit = GPIO__pinBit(pin);
    int value;

    if (state == HIGH){
        value = bitOn(GPIO_getRegister(fd, reg), bit);
    }
    else {
        value = bitOff(GPIO_getRegister(fd, reg), bit);
    }

    GPIO_setRegister(fd, reg, value, "writePin()");
}

void GPIO_pinMode (int fd, int pin, int mode){
    int reg = pin < 8 ? (int) MCP23017_IODIRA : (int) MCP23017_IODIRB;
    int bit = GPIO__pinBit(pin);
    int value;

    if (mode == INPUT){
        value = bitOn(GPIO_getRegister(fd, reg), bit);

    }
    else {
        value = bitOff(GPIO_getRegister(fd, reg), bit);
    }

    GPIO_setRegister(fd, reg, value, "pinMode()");
}

void GPIO_pullUp (int fd, int pin, int state){
    int reg = pin < 8 ? MCP23017_GPPUA : MCP23017_GPPUB;
    int bit = GPIO__pinBit(pin);
    int value;

    if (state == HIGH){
        value = bitOn(GPIO_getRegister(fd, reg), bit);
    }
    else {
        value = bitOff(GPIO_getRegister(fd, reg), bit);
    }

    GPIO_setRegister(fd, reg, value, "pullUp()");
}

/* operational functions */

void GPIO_clean (int fd){

    for (int i = 0; i < 0x16; i++){
        if (_skipRegisterReadOnly(i)){
            continue;
        }

        if (i == MCP23017_IODIRA || i == MCP23017_IODIRB){
            // direction registers get set back to INPUT
            GPIO_setRegister(fd, (int) i, (int) 0xFF, "IODIR");
            continue;
        }
        GPIO_setRegister(fd, i, 0x00, "rest");
    }
}

MODULE = RPi::GPIOExpander::MCP23017  PACKAGE = RPi::GPIOExpander::MCP23017 PREFIX = GPIO_

PROTOTYPES: DISABLE

# setup functions

int
GPIO_getFd (expanderAddr)
	int	expanderAddr

# register functions

int
GPIO_getRegister (fd, reg)
	int	fd
	int	reg

int
GPIO_getRegisterBit (fd, reg, bit)
	int	fd
	int	reg
	int	bit

int
GPIO_getRegisterBits (fd, reg, msb, lsb)
	int	fd
	int	reg
	int	msb
	int	lsb

int
GPIO_setRegister (fd, reg, value, name)
	int	fd
	int	reg
	int	value
	char* name

# pin functions

int
GPIO__pinBit (pin)
    int pin

int
GPIO_readPin (fd, pin)
    int fd
    int pin

void
GPIO_writePin (fd, pin, state)
    int fd
    int pin
    int state

void
GPIO_pinMode (fd, pin, mode)
    int fd
    int pin
    int mode

void
GPIO_pullUp (fd, pin, state)
    int fd
    int pin
    int state

# operational functions

void
GPIO_clean (fd)
	int	fd
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        GPIO_clean(fd);
        if (PL_markstack_ptr != temp) {
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY;
        }
        return;
