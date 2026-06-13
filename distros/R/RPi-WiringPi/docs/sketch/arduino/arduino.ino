/*
 * examples/arduino.ino
 *
 * Copyright (c) 2017 by Steve Bertrand
 *
 * This file is part of the RPi::WiringPi Perl 5 distribution.
 *
 * This Arduino sketch provides several pseudo registers for testing the various
 * read and write functions within the RPi::I2C distribution. Each function has
 * its own dedicated register.
 *
 * In essence, each 'register' performs its own dedicated functionality when
 * addressed by its register address. The list of register addresses are listed
 * below as #define statements under the "pseudo registers" comment.
 *
 */

#include <EEPROM.h>
#include <Wire.h>

#define EEPROM_SIZE 4
#define SLAVE_ADDR 0x04

// pseudo registers

#define READ        0
#define READ_BYTE   5
#define READ_BLOCK  10

#define WRITE       25
#define WRITE_BYTE  30
#define WRITE_BLOCK 35

#define READ_A0     80
#define READ_A1     81

#define EEPROM_READ 99

int8_t reg;

void eeprom_read (byte* buf, int count){

    uint16_t addr = 0;

    for (int8_t i=0; i<count; i++){
        EEPROM.get(addr, buf[i]);
        addr += sizeof(byte);
    }
}

void eeprom_read_byte (byte* data){
    EEPROM.get(0, *data);
}

void eeprom_save (byte buf[], int len){

    uint16_t addr = 0;

    Serial.println("eeprom_save()");

    for (int8_t i=0; i<len; i++){
        EEPROM.put(addr, buf[i]);
        addr += sizeof(byte);
    }
}

void eeprom_save_byte (byte data){
    Serial.println("eeprom_save_byte()");
    EEPROM.put(0, data);
}

void send_data (){

    switch (reg) {

        case EEPROM_READ: {
            Serial.println("eeprom_read()");
            byte eeprom_data [4];
            eeprom_read(eeprom_data, EEPROM_SIZE);
            Wire.write(eeprom_data, EEPROM_SIZE);
            break;
        }
        case READ: {
            Serial.println("read()");
            Wire.write(reg);
            break;
        }
        case READ_BYTE: {
            Serial.println("read_byte()");
            Wire.write(reg);
            break;
        }
        case READ_BLOCK: {
            Serial.println("read_block()");
            int value = 1023;
            uint8_t buf[2];

            // reverse endian so we're little on the way out, and separate the
            // 16-bit word

            buf[1] = value & 0xFF;
            buf[0] = (value & 0xFF00) >> 8;

            Wire.write(buf, 2);
            break;
        }
        case READ_A0: {
            Serial.println("Analog 0");
            read_analog(A0);
            break;
        }
        case READ_A1: {
            Serial.println("Analog 1");
            read_analog(A1);
            break;
        }
    }
}

int read_analog (int pin){
    int val = analogRead(pin);

    uint8_t buf[2];

    // reverse endian so we're little endian going out

    buf[1] = val & 0xFF;
    buf[0] = (val & 0xFF00) >> 8;

    Wire.write(buf, 2);
}

void receive_data (int num_bytes){

    while(Wire.available()){

        // save the register value for use later

        reg = Wire.read();

        switch (reg) {

            case WRITE: {
                Serial.println("write()");
                byte data = reg;
                eeprom_save_byte(data);
                break;
            }
            case WRITE_BYTE: {
                Serial.println("write_byte()");
                byte data = Wire.read();

                eeprom_save_byte(data);

                break;
            }
            case WRITE_BLOCK: {
                Serial.println("write_block()");
                byte buf[EEPROM_SIZE];

                for (byte i=0; i<EEPROM_SIZE; i++){
                    buf[i] = Wire.read();
                }

                eeprom_save(buf, EEPROM_SIZE);
                break;
            }
        }
    }
    Serial.println("\n");
}

void setup() {
    Serial.begin(9600);
    Wire.begin(SLAVE_ADDR);
    Wire.onReceive(receive_data);
    Wire.onRequest(send_data);
}

void loop() {
    delay(1000);
}