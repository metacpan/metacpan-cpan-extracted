#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <wiringPi.h>

bool setup(int trig, int echo){
 
    int setup_mode = -1;

    if (getenv("RPI_PIN_MODE"))
        setup_mode = atoi(getenv("RPI_PIN_MODE"));

    if (setup_mode == -1){
        if (wiringPiSetupGpio() == -1)
            exit(1);
    }
    else {
        char mode_env_var[20];
        sprintf(mode_env_var, "RPI_PIN_MODE=%d", setup_mode);
        putenv(mode_env_var);
    }

    pinMode(trig, OUTPUT);
    pinMode(echo, INPUT);

    digitalWrite(trig, LOW);
    
    delay(30);
   
    return 1;
}
 
long fetch(int trig, int echo) {

    digitalWrite(trig, HIGH);
    delayMicroseconds(20);
    digitalWrite(trig, LOW);

    // wait for echo

    while(digitalRead(echo) == LOW);

    // wait for echo end

    long start_time = micros();
    while(digitalRead(echo) == HIGH);
    long travel_time = micros() - start_time;

    return travel_time;
}

float inch_c (int trig, int echo){
    int raw = fetch(trig, echo);
    float res = ((float)raw / 2) / 74;
    return res;
}

float cm_c (int trig, int echo){
    float inches = inch_c(trig, echo);
    return inches * 2.54;
}

long raw_c (int trig, int echo){
    return fetch(trig, echo);
}

MODULE = RPi::HCSR04  PACKAGE = RPi::HCSR04

PROTOTYPES: DISABLE

bool
setup(trig, echo)
    int trig
    int echo

float
inch_c(trig, echo)
    int trig
    int echo

float
cm_c (trig, echo)
    int trig
    int echo

int
raw_c (trig, echo)
    int trig
    int echo
