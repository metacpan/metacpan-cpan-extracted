#include <SoftwareSerial.h>
#include <millisDelay.h>
#include <stdint.h>
#include <stdlib.h>

extern "C" {
    #include "crc16.h"
}

#define SERIAL_DEBUG    1

#define PIR_PIN         5
#define BSMT_DOOR_PIN   6
#define TRIPWIRE_PIN    7

const char *pirOff      = "50";
const char *pirOn       = "51"; // basement movement

const char *bsmtClosed  = "60";
const char *bsmtOpen    = "61"; // basement door breached

const char *tripClosed  = "70";
const char *tripOpen    = "71"; // laser beam breached

const uint8_t rxPin = 8;
const uint8_t txPin = 9;

const unsigned long waitTime = 500;
unsigned long startTime = millis();

const char startChar = '[';
const char endChar   = ']';

SoftwareSerial hc12(txPin, rxPin);

void setup() {
    Serial.begin(9600);
    hc12.begin(9600);

    pinMode(BSMT_DOOR_PIN, INPUT_PULLUP);
}

void loop() {

    if (millis () - startTime >= waitTime) {

        switch (digitalRead(PIR_PIN)) {
            case HIGH:
                    hc12Send(pirOn);
                break;
            case LOW:
                    hc12Send(pirOff);
                break;
        }
        switch (digitalRead(BSMT_DOOR_PIN)) {
            case LOW:
                hc12Send(bsmtClosed);
                break;
            case HIGH:
                hc12Send(bsmtOpen);
                break;
        }
/*
        switch (digitalRead(TRIPWIRE_PIN)) {
            case LOW:
                hc12Send(tripOpen);
                break;
            case HIGH:
                hc12Send(tripClosed);
                break;
        }
*/
        startTime = millis();
    }
}

void hc12Send (char *data){

    uint8_t len = strlen(data);

    unsigned short crc = crc16(data, len);
    uint8_t msb = crc >> 8;
    uint8_t lsb = crc & 0xFF;

    if (SERIAL_DEBUG){
        serialDebug(data, len, msb, lsb);
    }

    hc12.write(startChar);

    for (int i=0; i<len; i++){
        hc12.write(data[i]);
    }

    hc12.write(endChar);

    hc12.write(msb);
    hc12.write(lsb);
}
void serialDebug (char *data, uint8_t len, uint8_t msb, uint8_t lsb){

    Serial.print(startChar);
    Serial.print(data);
    Serial.print(endChar);
    Serial.print(crc16(data, len));

    Serial.print(F(", msb: "));
    Serial.print(msb);
    Serial.print(F(", lsb: "));
    Serial.println(lsb);
}
