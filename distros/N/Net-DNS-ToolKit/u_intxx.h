/*
 *	u_intxx.h
 *
 */
#ifndef _SYS_TYPES_H
#include <sys/types.h>
#endif

#include "localStuff.h"

#ifndef _U_INTXX_DEFINES_H
#define _U_INTXX_DEFINES_H

/* If sys/types.h does not supply u_intXX_t, supply them ourselves */
#ifdef HAVE_U_INTXX_T
# if (HAVE_U_INTXX_T == 2)
  #include <sys/socket.h>
# endif
#else
# ifdef HAVE_UINTXX_T
#  if (HAVE_UINTXX_T ==2)
   #include <stdint.h>
#  endif
typedef uint8_t u_int8_t;
typedef uint16_t u_int16_t;
typedef uint32_t u_int32_t;
# define HAVE_U_INTXX_T 1
# else
#  if (SIZEOF_CHAR == 1)
typedef unsigned char u_int8_t;
#  else
#   error "8 bit int type not found."
#  endif
#  if (SIZEOF_SHORT_INT == 2)
typedef unsigned short int u_int16_t;
#  else
#   ifdef _UNICOS
#    if (SIZEOF_SHORT_INT == 4)
typedef unsigned short u_int16_t;
#    else
typedef unsigned long  u_int16_t;
#    endif
#   else
#    error "16 bit int type not found."
#   endif
#  endif
#  if (SIZEOF_INT == 4)
typedef unsigned int u_int32_t;
#  else
#   ifdef _UNICOS
typedef unsigned long  u_int32_t;
#   else
#    error "32 bit int type not found."
#   endif
#  endif
# endif
#endif

#endif /* _U_INTXX_DEFINES_H */
