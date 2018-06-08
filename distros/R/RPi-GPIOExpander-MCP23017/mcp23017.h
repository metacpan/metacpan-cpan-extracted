#ifndef RPI_GPIOEXPANDER_MCP23017_MCP23017_H
#define RPI_GPIOEXPANDER_MCP23017_MCP23017_H
#endif //RPI_GPIOEXPANDER_MCP23017_MCP23017_H

#define OUTPUT              0x00
#define INPUT               0x01

#define HIGH                0x01
#define LOW                 0x00

#define MCP23017_IODIRA     0x00
#define MCP23017_IODIRB     0x01

#define MCP23017_IOCON_A    0x0A
#define MCP23017_IOCON_B    0x0B

#define MCP23017_GPPUA      0x0C
#define MCP23017_GPPUB      0x0D

#define MCP23017_GPIOA      0x12
#define MCP23017_GPIOB      0x13

#define MCP23017_OUTPUT     0x00
#define MCP23017_INPUT      0x01

// setup functions

int GPIO_getFd (int expanderAddr);
void _establishI2C (int fd);

// register functions

void _checkRegisterReadOnly (uint8_t reg);
int _skipRegisterReadOnly (uint8_t reg);
int GPIO_getRegister (int fd, int reg);
int GPIO_getRegisterBit (int fd, int reg, int bit);
int GPIO_getRegisterBits (int fd, int reg, int msb, int lsb);
int GPIO_setRegister (int fd, int reg, int value, char* name);

// pin functions

int GPIO__pinBit (int pin);
bool GPIO_readPin (int fd, int pin);
void GPIO_writePin (int fd, int pin, bool state);
void GPIO_pinMode (int fd, int pin, int mode);
void GPIO_pullUp (int fd, int pin, int state);

// operational functions

void GPIO_clean (int fd);

