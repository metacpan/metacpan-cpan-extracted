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
#include "bit.h"

#define MCP23017_ADDR       0x20

#define MCP23017_IODIRA     0x00
#define MCP23017_IODIRB     0x01

#define MCP23017_IOCON_A    0x0A
#define MCP23017_IOCON_B    0x0B

#define MCP23017_GPIOA      0x12
#define MCP23017_GPIOB      0x13

#define MCP23017_OUTPUT     0x00
#define MCP23017_INPUT      0x01

int getFd (int expanderAddr);
int getRegister (int fd, int reg);

void _establishI2C (int fd);
void _close (int fd);


int getFd (int expanderAddr){

    int fd;

    if ((fd = open("/dev/i2c-1", O_RDWR)) < 0) {
        close(fd);
        printf("Couldn't open the device: %s\n", strerror(errno));
        exit(-1);
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

void _close (int fd){
    close(fd);
}

int getRegister (int fd, int reg){

    int buf[1];
    buf[0] = reg;

    if ((write(fd, buf, 1)) != 1){
        close(fd);
        printf(
                "Could not write register pointer %d: %s\n",
                reg,
                strerror(errno)
        );
        exit(-1);
    }

    if ((read(fd, buf, 1)) != 1){
        close(fd);
        printf("Could not read register %d: %s\n", reg, strerror(errno));
        exit(-1);
    }

    return buf[0];
}

int getRegisterBit (int fd, int reg, int bit){
    int regData = getRegister(fd, reg);

    return bitGet((unsigned int) regData, bit, bit);
}

int getRegisterBits (int fd, int reg, int msb, int lsb){
    return bitGet((unsigned int) getRegister(fd, reg), msb, lsb);
}

int setRegister(int fd, int reg, int value, char* name){

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

void cleanup (int fd){

    for (uint8_t i = 0; i < 0x16; i++){
        if (i == MCP23017_IOCON_A || i == MCP23017_IOCON_B){
            // never do anything with the shared control registers
            continue;
        }
        if (i == MCP23017_IODIRA || i == MCP23017_IODIRB){
            // direction registers get set back to INPUT
            setRegister(fd, i, 0xFF, "IODIR");
            continue;
        }
        setRegister(fd, i, 0x00, "rest");
    }
}
void main (){
    int fd = getFd(MCP23017_ADDR);

    for (uint8_t i = 0; i < 0x16; i++) {
        printf("%d reg: %d\n", i, getRegister(fd, i));
    }

/*    cleanup(fd);

    for (uint8_t i = 0; i < 0x16; i++) {
        printf("%d reg: %d\n", i, getRegister(fd, i));
    }
*/
}
