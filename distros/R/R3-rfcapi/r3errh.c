/*
	r3errh.c
	Copyright (c) 1999 Johan Schoen. All rights reserved.

	revision history:

	0.20	1999-10-28	schoen
		last changes before first upload to CPAN

	0.32	1999-11-15	schoen
		better handling of "unknown" exceptions in function calls

*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <saprfc.h>
#include "r3rfc.h"

static int e_error;
static char * e_exception_type;
static char * e_exception;
static RFC_ERROR_INFO e_rfc_error_info;

void r3_rfc_clear_error()
{
	e_error=0;	
}

void r3_set_rfc_exception(char * exception)
{
	e_error=1;
	e_exception_type="RFC_EXCEPTION";
	e_exception=exception;
	memset(&e_rfc_error_info, 0, sizeof(e_rfc_error_info));
}

void r3_set_f_rfc_exception(H_R3RFC_FUNC h, char * exception)
{
	int ino;
	memset(&e_rfc_error_info, 0, sizeof(e_rfc_error_info));
	ino=r3_get_ino(h, "X", exception);
	if (ino>=0 && ino<=h->n_interface)
		strcpy(e_rfc_error_info.message, h->interface[ino].paramtext);
	e_error=1;
	e_exception_type="RFC_EXCEPTION";
	e_exception=exception;
}

void r3_set_rfc_sys_exception(char * exception)
{
	e_error=1;
	e_exception_type="RFC_SYS_EXCEPTION";
	e_exception=exception;
	RfcLastError(&e_rfc_error_info);
}

void r3_set_itab_exception(char * exception)
{
	e_error=1;
	e_exception_type="ITAB_EXCEPTION";
	e_exception=exception;
	memset(&e_rfc_error_info, 0, sizeof(e_rfc_error_info));
}

void r3_set_rfcapi_exception(char * exception)
{
	e_error=1;
	e_exception_type="RFCAPI_EXCEPTION";
	e_exception=exception;
	memset(&e_rfc_error_info, 0, sizeof(e_rfc_error_info));
}

char * r3_get_exception_type()
{
	if (e_error)
		return e_exception_type;
	else
		return "NO_ERROR";	
}

char * r3_get_exception()
{
	if (e_error)
		return e_exception;
	else
		return "NO_ERROR";	
}

int r3_get_error()
{
	return e_error;
}

void r3_set_error_message(char * msg)
{
	if (strlen(msg)<=sizeof(e_rfc_error_info.message))
		strcpy(e_rfc_error_info.message, msg);
	else
	{
		strncpy(e_rfc_error_info.message, msg,
			sizeof(e_rfc_error_info.message)-1);
		e_rfc_error_info.message[
			sizeof(e_rfc_error_info.message)-1]=0;
	}
}

char * r3_get_error_message()
{
	if (e_error)
		return e_rfc_error_info.message;
	else
		return "No error";	
}

/* EOF r3errh.c */
