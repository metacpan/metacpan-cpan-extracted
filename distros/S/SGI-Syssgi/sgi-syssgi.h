#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/syssgi.h>
#include <time.h>


/*  -------------------------------------------------------------------------- */
/*  Definitions                                                                */ 
/*  -------------------------------------------------------------------------- */

#define 	PROM_BUFFER_SIZE	256
#define     RDNAME_BUFFER_SIZE  1024
#define		NVRAM_INITSTATE		"initstate"
#define		NVRAM_PATH		    "path"
#define		NVRAM_SHOWCONFIG	"showconfig"
#define		NVRAM_SWAP		    "swap"
#define		NVRAM_VERBOSE		"verbose"

                             
/*  -------------------------------------------------------------------------- */
/*  Functions                                                                  */ 
/*  -------------------------------------------------------------------------- */
char *_SGI_SYSID (void);
char *_SGI_RDNAME (long process_id);
char *_SGI_GETNVRAM (char *prom_variable);
int   _SGI_SETLED (int led_state);
int   _SGI_SETNVRAM (char *prom_variable, char *prom_value);
int   _SGI_SSYNC (void);
int   _SGI_BDFLUSHCNT (unsigned int kern_write_delay);
int   _SGI_SET_AUTOPWRON (double power_on);
int   _SGI_GETTIMETRIM (void);
int   _SGI_SETTIMETRIM (int timetrim_value);

