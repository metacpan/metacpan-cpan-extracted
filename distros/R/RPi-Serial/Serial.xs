#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <termios.h>
#include <sys/ioctl.h>

void tty_close (int fd){
  printf("%d\n", fd);
  close (fd) ;
}

int tty_available (int fd){
    int bytes_available;
    ioctl(fd, FIONREAD, &bytes_available);
    return bytes_available;
}

int tty_putc(int fd, char b){
    int n = write(fd,&b,1);
    if( n!=1)
        return -1;
    return 0;
}

int tty_puts(int fd, const char* str){
    int len = strlen(str);
    int n = write(fd, str, len);
    if( n!=len )
        return -1;
    return 0;
}

int tty_getc (int fd){
  uint8_t x;

  if (read (fd, &x, 1) != 1)
    return -1;

  return ((int)x) & 0xFF;
}

char* tty_gets(int fd, char* buf, int nbytes){
    int bytes_read = 0;

    while (bytes_read < nbytes){
        int result = read(fd, buf + bytes_read, nbytes - bytes_read);

        if (0 >= result){
            if (0 > result){
                exit(-1);
            }
            break;
        }
        bytes_read += result;
    }

    return buf;
}

int tty_open(const char *serialport, int baud){
    struct termios toptions;
    int fd;

    fd = open(serialport, O_RDWR | O_NOCTTY | O_NDELAY);

    if (fd == -1)  {
        perror("open(): Unable to open port ");
        return -1;
    }

    if (tcgetattr(fd, &toptions) < 0) {
        perror("init_serialport: Couldn't get term attributes");
        return -1;
    }
    speed_t brate = baud;
    switch(baud) {
    case 4800:   brate=B4800;   break;
    case 9600:   brate=B9600;   break;
#ifdef B14400
    case 14400:  brate=B14400;  break;
#endif
    case 19200:  brate=B19200;  break;
#ifdef B28800
    case 28800:  brate=B28800;  break;
#endif
    case 38400:  brate=B38400;  break;
    case 57600:  brate=B57600;  break;
    case 115200: brate=B115200; break;
    }

    cfsetispeed(&toptions, brate);
    cfsetospeed(&toptions, brate);

    // 8N1
    toptions.c_cflag &= ~PARENB;
    toptions.c_cflag &= ~CSTOPB;
    toptions.c_cflag &= ~CSIZE;
    toptions.c_cflag |= CS8;
    // no flow control
    toptions.c_cflag &= ~CRTSCTS;

    toptions.c_cflag |= CREAD | CLOCAL;  // turn on READ & ignore ctrl lines
    toptions.c_iflag &= ~(IXON | IXOFF | IXANY); // turn off s/w flow ctrl

    toptions.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG); // make raw
    toptions.c_oflag &= ~OPOST; // make raw

    toptions.c_cc[VMIN]  = 0;
    toptions.c_cc[VTIME] = 10;

    if( tcsetattr(fd, TCSANOW, &toptions) < 0) {
        perror("init_serialport: Couldn't set term attributes");
        return -1;
    }

    return fd;
}

MODULE = RPi::Serial  PACKAGE = RPi::Serial

PROTOTYPES: DISABLE

int
tty_available (fd)
	int	fd

int
tty_putc (fd, b)
	int	fd
	char	b

int
tty_puts (fd, str)
	int	fd
	const char *	str

int
tty_getc (fd)
	int	fd

char *
tty_gets (fd, buf, nbytes)
	int	fd
	char *	buf
	int	nbytes

int
tty_open (serialport, baud)
	const char *	serialport
	int	baud

void
tty_close (fd)
    int fd
