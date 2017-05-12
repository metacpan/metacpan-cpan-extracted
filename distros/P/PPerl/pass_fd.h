/* Our own header, to be included *after* all standard system headers */

#ifndef	__pass_fd_h
#define	__pass_fd_h

#include	<sys/types.h>	/* required for some of our prototypes */

void    setlogfile(char *);

int	recv_fd(int);
int	send_fd(int, int);

#endif
