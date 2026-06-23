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
#include "rtc.h"
#include "bit.h"

/* top-level register */

#define RTC_REG_DT  0x00

/* sub-level registers */

#define RTC_SEC     0x00 // 0-59
#define RTC_MIN     0x01 // 0-59
#define RTC_HOUR    0x02 // 1-12 (12-hr clock), 0-23 (24-hr clock)
#define RTC_WDAY    0x03 // day of week (1-7)
#define RTC_MDAY    0x04 // day of month (1-31)
#define RTC_MONTH   0x05 // 1-12
#define RTC_YEAR    0x06 // 1-99

#define RTC_TEMP_MSB 0x11
#define RTC_TEMP_LSB 0x12

/* sub-level register bits */

// RTC_HOUR sub-level register bits

#define RTC_AM_PM   0x05
#define RTC_12_24   0x06

/* ---------- BCD field helpers (single source of BCD policy) ----------
 * DS3231 time/date registers hold BCD values, some sharing a register with
 * flag bits (Month 0x05 bit7 = Century; Hours 0x02 bits6-5 = 12/24 + AM/PM).
 * Every BCD read/write routes through these two, so encoding can never be
 * applied inconsistently (the bug that produced raw-not-BCD month/hour writes).
 *   setBcdField: preserve the `keep` bits, BCD-encode `value` into the rest.
 *   getBcdField: read `mask` bits, BCD-decode.
 * Masks are per the DS3231 datasheet (Rev 2; 6/05, Figure 1).
 */
int setBcdField (int fd, int reg, int value, int keep, char* name){
    int preserved = getRegister(fd, reg) & keep;
    return setRegister(fd, reg, preserved | dec2bcd(value), name);
}

int getBcdField (int fd, int reg, int mask){
    return bcd2dec(getRegister(fd, reg) & mask);
}

int getSeconds (int fd){
    return getBcdField(fd, RTC_SEC, 0x7F);
}

void setSeconds (int fd, int value){
    if (value < 0 || value > 59){
        croak("seconds parameter out of bounds. Must be between 0-59\n");
    }
    setBcdField(fd, RTC_SEC, value, 0x00, "seconds");
}

int getMinutes (int fd){
    return getBcdField(fd, RTC_MIN, 0x7F);
}

void setMinutes (int fd, int value){
    if (value < 0 || value > 59){
        croak("minutes parameter out of bounds. Must be between 0-59\n");
    }
    setBcdField(fd, RTC_MIN, value, 0x00, "minutes");
}

int getHour (int fd){
   
    int hour;

    if ((getRegisterBit(fd, RTC_HOUR, RTC_12_24)) == 0){
        // 24 hr clock
        hour = getRegister(fd, RTC_HOUR);
    }
    else {
        // 12 hr clock
        hour = getRegisterBits(fd, RTC_HOUR, 4, 0);
    }
    return bcd2dec(hour);
}

void setHour (int fd, int value){

    if ((getRegisterBit(fd, RTC_HOUR, RTC_12_24)) != 0){
        // 12 hour clock

        if (value > 12 || value < 1){
            char* error =
                "hour (%d) is out of bounds when in 12-hour clock " \
                "mode. Valid values are 1-12";

            croak(error);
        }
        /* 12-h: keep bit6 (12/24 select) + bit5 (AM/PM); BCD hour into bits0-4 */
        setBcdField(fd, RTC_HOUR, value, 0x60, "hour");
    }
    else {
        // 24 hour clock

        if (value > 23 || value < 0){
            char* error =
                "hour (%d) is out of bounds when in 24-hour clock " \
                "mode. Valid values are 0-23";

            croak(error);
        }
        /* 24-h: full BCD (bit6 = 0 selects 24-hour) */
        setBcdField(fd, RTC_HOUR, value, 0x00, "hour");
    }
}

const char* getDayOfWeek (int fd){
    int dow = bcd2dec(getRegister(fd, RTC_WDAY));
    return dayOfWeek[dow - 1];
}

void setDayOfWeek (int fd, int value){

    if (value > 7 || value < 1){
        croak("Day of week (%d) out of bounds. Must be 1-7 (Mon-Sun)\n", value);
    }

    setBcdField(fd, RTC_WDAY, value, 0x00, "wday");
}

int getDayOfMonth (int fd){
    return getBcdField(fd, RTC_MDAY, 0x3F);
}

void setDayOfMonth (int fd, int value){

    if (value < 1 || value > 31){
        croak("Month day (%d) out of range. Must be between 1-31\n", value);
    }

    setBcdField(fd, RTC_MDAY, value, 0x00, "dayofmonth");
}

int getMonth (int fd){
    return getBcdField(fd, RTC_MONTH, 0x1F);
}

void setMonth (int fd, int value){

    if (value < 1 || value > 12){
        croak("Month (%d) out of range. Must be between 1-12\n", value);
    }

    /* keep bit7 (Century); BCD month into bits0-4 */
    setBcdField(fd, RTC_MONTH, value, 0x80, "month");
}

int getYear (int fd){
    return getBcdField(fd, RTC_YEAR, 0xFF) + 2000;
}

void setYear (int fd, int value){

    if (value < 2000 || value > 2099){
        croak("Year (%d) out of range. Must be between 2000-2099\n", value);
    }

    int year = value - 2000;

    setBcdField(fd, RTC_YEAR, year, 0x00, "year");
}

float getTemp (int fd){

    int msb = getRegister(fd, RTC_TEMP_MSB);
    int lsb = getRegister(fd, RTC_TEMP_LSB);

    /* 0x11 is a signed 8-bit two's-complement integer (deg C); 0x12 bits 7-6
       are the 0.25-deg fraction. Read the MSB as int8_t so sub-zero temps
       sign-extend correctly (DS3231 Rev 2 temperature registers). */
    float celcius = (int8_t)msb + (lsb >> 6) * 0.25;

    return celcius;
}

int getMeridien (int fd){

    if ((getRegisterBit(fd, RTC_HOUR, RTC_12_24)) == 0){
        croak(
            "AM/PM functionality not available when in 24-hour clock mode\n"
        );
    }
    return getRegisterBit(fd, RTC_HOUR, RTC_AM_PM);
}

void setMeridien (int fd, int value){

    if ((getRegisterBit(fd, RTC_HOUR, RTC_12_24)) == 0){
        croak(
            "AM/PM can not be set when in 24-hour clock mode\n"
        );
    }

    if (value == 1){
        enableRegisterBit(fd, RTC_HOUR, RTC_AM_PM);
    }
    else if (value == 0){
        disableRegisterBit(fd, RTC_HOUR, RTC_AM_PM);
    }
    else {
        croak(
            "AM/PM value (%d) out of bounds. Send 1 for enable, 0 for disable",
            value
        );
    }
}

int getMilitary (int fd){
    return getRegisterBit(fd, RTC_HOUR, RTC_12_24);
}

void setMilitary (int fd, int value){

    int militaryTime = getMilitary(fd);
    int hour = getHour(fd);

    if (militaryTime == value){
        // nothing to do
        return;
    }

    if (value == 1){
        // enable 12 hr clock
        if (hour == 0){
            // AM, at hour zero
            setHour(fd, 12);
            disableRegisterBit(fd, RTC_HOUR, RTC_AM_PM);
        }
        else if (getHour(fd) <= 12){
            // AM
            setHour(fd, hour);
            disableRegisterBit(fd, RTC_HOUR, RTC_AM_PM);
        }
        else {
            // PM
            setHour(fd, hour - 12);
            enableRegisterBit(fd, RTC_HOUR, RTC_AM_PM);
        }

        enableRegisterBit(fd, RTC_HOUR, RTC_12_24);
    }
    else {
        // enable 24 hr clock
        int meridien = getMeridien(fd);
        disableRegisterBit(fd, RTC_HOUR, RTC_12_24);

        if (meridien == 0){
            // AM
            if (hour == 12){
                setHour(fd, 0);
            }
            else {
                setHour(fd, hour);
            }
        }
        else {
            // PM
            if (hour < 12){
                setHour(fd, hour + 12);
            }
            else {
                setHour(fd, hour);
            }
        }
    }
}

int getFh (int rtcAddr){

    int fd;

    if ((fd = open("/dev/i2c-1", O_RDWR)) < 0) {
        close(fd);
        croak("Couldn't open the device: %s\n", strerror(errno));
	}

	if (ioctl(fd, I2C_SLAVE_FORCE, rtcAddr) < 0) {
        close(fd);
        croak(
            "Couldn't find device at addr %d: %s\n",
            rtcAddr,
            strerror(errno)
        );
	}

    _establishI2C(fd);

    return fd;
}

void disableRegisterBit (int fd, int reg, int bit){
    int data = bitOff(getRegister(fd, reg), bit);
    setRegister(fd, reg, data, "disabling bit");
}

void enableRegisterBit (int fd, int reg, int bit){
    int data = bitOn(getRegister(fd, reg), bit);
    setRegister(fd, reg, data, "enabling bit");
}

int getRegister (int fd, int reg){

    char buf[1];
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

int getRegisterBit (int fd, int reg, int bit){
    int regData = getRegister(fd, reg);
    return bitGet(regData, bit, bit);
}

int getRegisterBits (int fd, int reg, int msb, int lsb){
    return bitGet(getRegister(fd, reg), msb, lsb);
}

int setRegister(int fd, int reg, int value, char* name){
    /*
        always call dec2bcd(value) before sending
        in the value to this function
    */

    char buf[2] = {reg, value};

    if ((write(fd, buf, sizeof(buf))) != 2){
        close(fd);
        croak(
            "Could not write to the %s register: %s\n",
            name,
            strerror(errno)
        );
    }

    return 0;
}

int setRegisterBits(int fd, int reg, int lsb, int nbits, int value, char* name){
    /*
        never call dec2bcd(value) before sending
        in the value to this function
    */

    int data = getRegister(fd, reg);

    data = bitSet(data, lsb, nbits, value);

    char buf[2] = {reg, data};

    if ((write(fd, buf, sizeof(buf))) != 2){
        croak(
            "Could not write to the %s register: %s\n",
            name,
            strerror(errno)
        );
    }

    return 0;
}

int bcd2dec (int num){
  return (((num & 0xF0) >> 4) * 10) + (num & 0x0F);
}

int dec2bcd(int num){
   return((num/10) * 16 + (num%10));
}

void _establishI2C (int fd){

    int buf[1] = { 0x00 };

    if (write(fd, buf, 1) != 1){
        close(fd);
		croak("Error: Received no ACK bit, couldn't establish connection!");
    }
}

void _close (int fd){
    close(fd);
}

MODULE = RPi::RTC::DS3231  PACKAGE = RPi::RTC::DS3231

PROTOTYPES: DISABLE

void
setSeconds (fd, value)
    int fd
    int value

void
setMinutes (fd, value)
    int fd
    int value

void
setMilitary (fd, value)
    int fd
    int value

int
getMilitary (fd)
    int fd

void
setMeridien (fd, value)
    int fd
    int value

int
getMeridien (fd)
    int fd

int
getHour (fd)
	int	fd

int
getSeconds (fd)
    int fd

int
getMinutes (fd)
    int fd

void
setHour (fd, value)
    int fd
    int value

const char*
getDayOfWeek (fd)
    int fd

void
setDayOfWeek (fd, value)
    int fd
    int value

int
getDayOfMonth (fd)
    int fd

void
setDayOfMonth (fd, value)
    int fd
    int value

int getMonth (fd)
    int fd

void setMonth (fd, value)
    int fd
    int value

int getYear (fd)
    int fd

void setYear (fd, value)
    int fd
    int value

float getTemp (fd)
    int fd

int
getFh (rtcAddr)
    int rtcAddr

void
disableRegisterBit (fd, reg, bit)
	int	fd
	int	reg
	int	bit
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        disableRegisterBit(fd, reg, bit);
        if (PL_markstack_ptr != temp) {
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY;
        }
        return;

void
enableRegisterBit (fd, reg, bit)
	int	fd
	int	reg
	int	bit
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        enableRegisterBit(fd, reg, bit);
        if (PL_markstack_ptr != temp) {
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY;
        }
        return;

int
getRegister (fd, reg)
	int	fd
	int	reg

int
getRegisterBit (fd, reg, bit)
	int	fd
	int	reg
	int	bit

int
getRegisterBits (fd, reg, msb, lsb)
	int	fd
	int	reg
	int	msb
	int	lsb

int
setRegister (fd, reg, value, name)
	int	fd
	int	reg
	int	value
	char*	name

int
setRegisterBits(fd, reg, lsb, nbits, value, name)
    int fd
    int reg
    int lsb
    int nbits
    int value
    char* name

int
bcd2dec (num)
	int	num

int
dec2bcd (num)
	int	num

void
_establishI2C (fd)
	int	fd

void
_close (fd)
    int fd
