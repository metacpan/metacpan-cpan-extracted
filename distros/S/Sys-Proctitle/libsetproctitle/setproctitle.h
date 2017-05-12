#ifndef SETPROCTITLE_H_
#define SETPROCTITLE_H_

extern int setproctitle( const char *buf, int len );
extern int getproctitle( char *buf, int len );
extern int setproctitle_max( void );

#endif /* SETPROCTITLE_H_ */
