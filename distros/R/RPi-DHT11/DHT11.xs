#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <wiringPi.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define false 0
#define true 1

#define MAXTIMINGS  85

//wiringPi setup modes

#define RPI_MODE_WPI 0
#define RPI_MODE_GPIO 1
#define RPI_MODE_GPIO_SYS 2 // unused
#define RPI_MODE_PHYS 3
#define RPI_MODE_UNINIT -1

typedef struct env_data {
    int temp;
    int humidity;
} EnvData;

int debug = 0;

EnvData read_env(int pin);

int c_temp(int pin);
int c_humidity(int pin);
int c_cleanup(int pin);
int c_debug(int flag);
bool noboard_test(); // unit testing with no RPi board
bool setup();

EnvData read_env(int pin){
    int data[5] = {0, 0, 0, 0, 0};
    
    uint8_t laststate = HIGH;
    uint8_t counter = 0;
    uint8_t j = 0, i;

    data[0] = data[1] = data[2] = data[3] = data[4] = 0;
    
    pinMode(pin, OUTPUT);
    digitalWrite(pin, LOW);
    delay(18);
    
    digitalWrite(pin, HIGH);
    delayMicroseconds(40);
    
    pinMode(pin, INPUT);

    for (i = 0; i < MAXTIMINGS; i++){
        counter = 0;
        while (digitalRead(pin) == laststate){
            counter++;
            delayMicroseconds(1);
            if (counter == 255){
                break;
            }
        }
        laststate = digitalRead(pin);

        if (counter == 255)
            break;

        if ((i >= 4) && (i % 2 == 0)){
            data[j / 8] <<= 1;
            if (counter > 16)
                data[j / 8] |= 1;
            j++;
        }
    }

    EnvData env_data;
    
    if ((j >= 40) &&
         (data[4] == ((data[0] + data[1] + data[2] + data[3]) & 0xFF))){

         //printf( "Humidity = %d.%d %% Temperature = %d.%d *C (%.1f *F)\n",
         //data[0], data[1], data[2], data[3], f );

        int t = data[2];
        int h = data[0];

        env_data.temp = t;
        env_data.humidity = h;
    }
    else {
        env_data.temp = -1;
        env_data.humidity = -1;
    }
    return env_data;
}

int c_temp(int pin){
    // get & return temperature

    if (debug)
        printf("DHT11 exec temp\n");

    if (noboard_test())
        return 0;

    EnvData env_data;
    int data = -1;

    while (data == -1 && data != 0){
        env_data = read_env(pin);
        data = env_data.temp;
        if (data == -1){
            sleep(1);
        }
        if (debug)
            printf("temp data: %d\n", data);
    }
    if (debug)
        printf("temp: %d\n", env_data.temp);

    return env_data.temp;
}

int c_humidity(int pin){
    // get & return humidity

    if (debug)
        printf("DHT11 exec humidity\n");

    if (noboard_test())
        return 0;

    EnvData env_data;
    int data = -1;

    while (data == -1 && data != 0){
        env_data = read_env(pin);
        if (data == -1){
            sleep(1);
        }
        data = env_data.humidity;
        if (debug)
            printf("humidity data: %d\n", data);
    }
    if (debug)
        printf("humidity: %d\n", env_data.humidity);

    return env_data.humidity;
}

int c_cleanup(int pin){
    // reset the pin to default status

    digitalWrite(pin, LOW);
    pinMode(pin, INPUT);

    return(0);
}

bool noboard_test(){
    if (getenv("RDE_NOBOARD_TEST") && atoi(getenv("RDE_NOBOARD_TEST")) == 1)
        return true;
    return false;
}

int c_debug(int flag){
    debug = flag;
    return debug;
}
     
bool setup(){

    if (! noboard_test()){
        int setupMode = -1;

        if (getenv("RPI_PIN_MODE"))
            setupMode = atoi(getenv("RPI_PIN_MODE"));

        if (setupMode == -1){
            if (wiringPiSetupGpio() == -1)
                exit(1);
        }
        else {
            char modeEnvVar[20];
            sprintf(modeEnvVar, "RPI_PIN_MODE=%d", setupMode);
            putenv(modeEnvVar);
        }
    }
    return true;
}

MODULE = RPi::DHT11  PACKAGE = RPi::DHT11

PROTOTYPES: DISABLE

int
c_temp (pin)
	int	pin

int
c_humidity (pin)
	int	pin

int
c_cleanup (pin)
	int	pin

int
c_debug (flag)
    int flag

bool
setup()
