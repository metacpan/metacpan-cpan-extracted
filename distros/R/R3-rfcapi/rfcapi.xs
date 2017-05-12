/*
	rfcapi.xs
	Copyright (c) 1999 Johan Schoen. All rights reserved.
*/

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "saprfc.h"
#include "r3rfc.h"
#ifdef __cplusplus
}
#endif

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = R3::rfcapi		PACKAGE = R3::rfcapi		


double
constant(name,arg)
	char *		name
	int		arg

H_R3RFC_CONN
r3_new_conn(client, user, passwd, lang, host, sys, gwhost, gwserv, trace)
	char * client
	char * user
	char * passwd
	char * lang
	char * host
	int sys
	char * gwhost
	char * gwserv
	int trace

void
r3_del_conn(h_conn)
	H_R3RFC_CONN h_conn

void
r3_set_pre4(h_conn)
	H_R3RFC_CONN h_conn

H_R3RFC_FUNC 
r3_new_func(h_conn, functionname)
	H_R3RFC_CONN h_conn
	char * functionname

void 
r3_del_func(h)
	H_R3RFC_FUNC h

int
r3_call_func(h)
	H_R3RFC_FUNC h

void
r3_clear_params(h)
	H_R3RFC_FUNC h

int
r3_set_export_value(h, export, value)
	H_R3RFC_FUNC h
	char * export
	char * value

int
r3_set_exp_val(h, ino, value)
	H_R3RFC_FUNC h
	int ino
	char * value

char * 
r3_get_import_value(h, import)
	H_R3RFC_FUNC h
	char * import

char * 
r3_get_imp_val(h, ino)
	H_R3RFC_FUNC h
	int ino

int
r3_set_table(h, table, h_table)
	H_R3RFC_FUNC h
	char * table
	H_R3RFC_ITAB h_table

H_R3RFC_ITAB
r3_new_itab(h_conn, table_name)
	H_R3RFC_CONN h_conn
	char * table_name

void 
r3_del_itab(h)
	H_R3RFC_ITAB h

int
r3_add_row(h)
	H_R3RFC_ITAB h

int
r3_ins_row(h, row_no)
	H_R3RFC_ITAB h
	long row_no

int
r3_del_row(h, row_no)
	H_R3RFC_ITAB h
	long row_no

int
r3_set_row(h, row_no)
	H_R3RFC_ITAB h
	long row_no

int
r3_set_field_value(h, field, value)
	H_R3RFC_ITAB h
	char * field  
	char * value

int
r3_set_f_val(h, fino, value)
	H_R3RFC_ITAB h
	int fino
	char * value

char *
r3_get_field_value(h, field)
	H_R3RFC_ITAB h
	char * field

char *
r3_get_f_val(h, fino)
	H_R3RFC_ITAB h
	int fino

long
r3_rows(h)
	H_R3RFC_ITAB h

int
r3_trunc_rows(h)
	H_R3RFC_ITAB h

int
r3_get_ino(h, pc, fn)
	H_R3RFC_FUNC h
	char * pc
	char * fn

int
r3_get_fino(h, fn)
	H_R3RFC_ITAB h
	char * fn

int
r3_get_params(h)
	H_R3RFC_FUNC h

char *
r3_get_param_name(h, ino)
	H_R3RFC_FUNC h
	int ino

char *
r3_get_param_class(h, ino)
	H_R3RFC_FUNC h
	int ino

int
r3_get_fields(h)
	H_R3RFC_ITAB h

char *
r3_get_field_name(h, fino)
	H_R3RFC_ITAB h
	int fino

void
r3_rfc_clear_error()

int
r3_get_error()

char *
r3_get_exception_type()

char *
r3_get_exception()

char *
r3_get_error_message()

char * 
r3_get_record(h)
	H_R3RFC_ITAB h

int
r3_set_record(h, value)
	H_R3RFC_ITAB h
	char * value

int
r3_clear_itab_fields(h)
	H_R3RFC_ITAB h



