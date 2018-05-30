#ifndef _RTC_H_
#define _RTC_H_
#endif

const char* dayOfWeek[7] = {
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
};

void  _establishI2C (int fd);

int getFh ();

int getSeconds (int fd);
int getMinutes (int fd);
int getHour (int fd);

int getMeridien (int fd);
int getMilitary (int fd);

void setSeconds (int fd, int value);
void setMinutes (int fd, int value);
void setHour (int fd, int value);

void setMeridien (int fd, int value);
void setMilitary (int fd, int value);

void disableRegisterBit (int fd, int reg, int bit);
void enableRegisterBit (int fd, int reg, int bit);

int getRegister (int fd, int reg);
int getRegisterBit (int fd, int reg, int bit);
int getRegisterBits (int fd, int reg, int msb, int lsb);

int setRegister(int fd, int reg, int value, char* name);
int setRegisterBits(int fd, int reg, int lsb, int nbits, int value, char* name);

int bcd2dec(int num);
int dec2bcd(int num);
