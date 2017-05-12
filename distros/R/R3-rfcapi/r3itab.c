/*
	r3itab.c
	Copyright (c) 1999 Johan Schoen. All rights reserved.

	revision history
	
	0.01	1999-03-22	schoen
		first version created

	0.20	1999-10-28	schoen
		last changes before first upload to CPAN

	0.21	1999-11-02	schoen
		fixed mem dealloc bug in r3_del_itab

	0.30	1999-11-09	schoen
		added support for R/3 release pre 40A
		added function r3_clear_itab_fields

	0.31	1999-11-10	schoen
		added special support for NUMC/N/TYPNUM

	0.32 	1999-11-15	schoen
		corrected handling of TYPINT and TYPFLOAT
*/


#include <memory.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <saprfc.h>
#include <sapitab.h>
#include <ctype.h>
#include "r3rfc.h"

typedef RFC_CHAR X030L_TABNAME[30];
typedef RFC_CHAR PRE4_X030L_TABNAME[10];
typedef RFC_INT RFC_FIELDS_INTLENGTH;

typedef struct {
  RFC_CHAR Tabname[30];
  RFC_CHAR Fieldname[30];
  RFC_INT Position;
  RFC_INT Offset;
  RFC_INT Intlength;
  RFC_INT Decimals;
  RFC_CHAR Exid[1]; } RFC_FIELDS;

typedef struct {
  RFC_CHAR Tabname[10];
  RFC_CHAR Fieldname[10];
  RFC_INT Position;
  RFC_INT Offset;
  RFC_INT Intlength;
  RFC_INT Decimals;
  RFC_CHAR Exid[1]; } RFC3FIELDS;

static RFC_TYPEHANDLE h_RFC_FIELDS;
static RFC_TYPEHANDLE h_RFC3FIELDS;

static RFC_TYPE_ELEMENT t_RFC_FIELDS[] = {
  {"TABNAME", TYPC, 30, 0},
  {"FIELDNAME", TYPC, 30, 0},
  {"POSITION", TYPINT, sizeof(RFC_INT), 0},
  {"OFFSET", TYPINT, sizeof(RFC_INT), 0},
  {"INTLENGTH", TYPINT, sizeof(RFC_INT), 0},
  {"DECIMALS", TYPINT, sizeof(RFC_INT), 0},
  {"EXID", TYPC, 1, 0}, };

static RFC_TYPE_ELEMENT t_RFC3FIELDS[] = {
  {"TABNAME", TYPC, 10, 0},
  {"FIELDNAME", TYPC, 10, 0},
  {"POSITION", TYPINT, sizeof(RFC_INT), 0},
  {"OFFSET", TYPINT, sizeof(RFC_INT), 0},
  {"INTLENGTH", TYPINT, sizeof(RFC_INT), 0},
  {"DECIMALS", TYPINT, sizeof(RFC_INT), 0},
  {"EXID", TYPC, 1, 0}, };

#define ENTRIES(tab) (sizeof(tab)/sizeof((tab)[0]))

unsigned r3_exid2type(char c)
{
	unsigned p;
	switch(c)
	{
	case 'C':
		p= TYPC;
		break;
	case 'N':
		p= TYPNUM;
		break;
	case 'D':
		p= TYPDATE;
		break;
	case 'F':
		p= TYPFLOAT;
		break;
	case 'I':
		p= TYPINT;
		break;
	case 'P':
		p= TYPP;
		break;
	case 'T':
		p= TYPTIME;
		break;
	case 'X':
		p= TYPX;
		break;
	default:
		/* if we do not know the data type - treat it as binary */
		p= TYPX;
	}
	return p;
}

static int install_structure(H_R3RFC_ITAB h)
{
	RFC_RC RfcRc;
	RFC_TYPE_ELEMENT * p_type;
	int i;
	p_type=malloc(h->n_fields*sizeof(RFC_TYPE_ELEMENT));
	if (!p_type)
	{
		r3_set_rfcapi_exception("MALLOC_FAILED");
		return -1;
	}
	memset(p_type,0,h->n_fields*sizeof(RFC_TYPE_ELEMENT));
	for (i=0; i<h->n_fields; i++)
	{
		p_type[i].name=h->fields[i].fieldname;
		p_type[i].length=h->fields[i].intlength;
		p_type[i].type = r3_exid2type(h->fields[i].exid[0]);
		p_type[i].decimals=h->fields[i].decimal;
	}
	RfcRc = RfcInstallStructure(h->name,
			p_type,
			h->n_fields,
			&h->h_type);
	free(p_type);
	switch (RfcRc)
	{
		case RFC_OK:
			return 0;
		case RFC_MEMORY_INSUFFICIENT:
			r3_set_itab_exception("RFC_MEMORY_INSUFFICIENT");
			return 1;
		default:
			r3_set_itab_exception("UNKNOWN_ERROR");
			return 2;
	}
	r3_set_rfcapi_exception("RFCAPI_ERROR");
	return 666; /* should never be reached */;
} 

H_R3RFC_ITAB r3_pre4_new_itab(H_R3RFC_CONN h_conn,
			char * table_name)
{
	static H_R3RFC_ITAB h;
	static RFC_FIELDS_INTLENGTH iTablength;
	static PRE4_X030L_TABNAME eTabname;
	RFC_PARAMETER Exporting[2];
	RFC_PARAMETER Importing[2];
	RFC_TABLE Tables[2];
	RFC_RC RfcRc;
	char *RfcException = NULL;
	ITAB_H thFields;
	int i;
	RFC3FIELDS * tFields;

	/* install structures */
	if (h_RFC3FIELDS==0) 
	{
		RfcRc = RfcInstallStructure("RFC3FIELDS",
                               t_RFC3FIELDS,
                               ENTRIES(t_RFC3FIELDS),
                               &h_RFC3FIELDS);
    		if (RfcRc != RFC_OK)
		{
			if (RfcRc == RFC_MEMORY_INSUFFICIENT)
				r3_set_itab_exception("RFC_MEMORY_INSUFFICIENT");
			else
				r3_set_itab_exception("UNKNOWN_ERROR");
			return NULL;
		}
	}

	/* define export params */
	memset(eTabname, ' ', sizeof(eTabname));
	strncpy((char *)eTabname, table_name, strlen(table_name));

	Exporting[0].name = "TABNAME";
	Exporting[0].nlen = 7;
	Exporting[0].type = TYPC;
	Exporting[0].leng = sizeof(PRE4_X030L_TABNAME);
	Exporting[0].addr = eTabname;

	Exporting[1].name = NULL;

	/* define internal tables */
	thFields=ItCreate("FIELDS", sizeof(RFC3FIELDS), 0, 0);
	if (thFields==ITAB_NULL)
	{
		r3_set_itab_exception("RFC_MEMORY_INSUFFICIENT");
		return NULL;
	}

	Tables[0].name     = "FIELDS";
	Tables[0].nlen     = 6;
	Tables[0].type     = h_RFC3FIELDS;
	Tables[0].ithandle = thFields;
	Tables[0].leng     = sizeof(RFC3FIELDS);

	Tables[1].name = NULL;

	/* define import params */

	Importing[0].name = "TABLENGTH";
	Importing[0].nlen = 9;
	Importing[0].type = TYPINT;
	Importing[0].leng = sizeof(RFC_FIELDS_INTLENGTH);
	Importing[0].addr = &iTablength;

	Importing[1].name = NULL;

	/* call function module */
	RfcRc = RfcCallReceive(h_conn->h_rfc,
		"RFC_GET_STRUCTURE_DEFINITION",
		Exporting,
		Importing,
		Tables,
		&RfcException);
	if (RfcRc != RFC_OK)
	{
		switch (RfcRc)
		{
		case RFC_FAILURE:
			r3_set_rfc_sys_exception("RFC_FAILURE");
			break;
		case RFC_EXCEPTION:
			r3_set_rfc_exception(RfcException);
			break;
		case RFC_SYS_EXCEPTION:
			r3_set_rfc_sys_exception(RfcException);
			break;
		case RFC_CALL:
			r3_set_rfc_exception("RFC_CALL");
			break;
		default:
			r3_set_rfcapi_exception("UNKNOWN_ERROR");
		}
		ItDelete(thFields);
		return NULL;
	}

	/* allocate memory for the table */
	if (!(h=malloc(sizeof(R3RFC_ITAB))))	
	{
		r3_set_rfcapi_exception("MALLOC_FAILED");
		ItDelete(thFields);
		return NULL;
	}
	memset(h, 0, sizeof(R3RFC_ITAB));
	h->h_conn=h_conn;
	h->h_itab=ITAB_NULL;
	h->rec_size=iTablength;
	strcpy(h->name, table_name);

	/* get table definition */
	h->n_fields=ItFill(thFields);
	h->fields=malloc(h->n_fields*sizeof(R3RFC_ITABDEF));
	if (h->fields==NULL)
	{
		r3_set_rfcapi_exception("MALLOC_FAILED");
		r3_del_itab(h);
		ItDelete(thFields);
		return NULL;
	}
	memset(h->fields, 0, h->n_fields*sizeof(R3RFC_ITABDEF));
	for (i=0; i<h->n_fields; i++)
	{
		tFields=ItGetLine(thFields, i+1);
		if (tFields  == NULL)
		{
			r3_set_itab_exception("RFC_MEMORY_INSUFFICIENT");
			r3_del_itab(h);
			ItDelete(thFields);
			return NULL;
		}
	
		strncpy(h->fields[i].tabname,
			(char *)tFields->Tabname,
			sizeof(tFields->Tabname));
		r3_stbl(h->fields[i].tabname);

		strncpy(h->fields[i].fieldname,
			tFields->Fieldname,
			sizeof(tFields->Fieldname));
		r3_stbl(h->fields[i].fieldname);

		strncpy(h->fields[i].exid,
			tFields->Exid,
			sizeof(tFields->Exid));
		r3_stbl(h->fields[i].exid);

		h->fields[i].position=tFields->Position;
		h->fields[i].offset=tFields->Offset;
		h->fields[i].intlength=tFields->Intlength;
		h->fields[i].decimal=tFields->Decimals;
	}

	/* delete table */
	ItDelete(thFields);

	/* create ITAB */
	h->h_itab=ItCreate(h->name, h->rec_size, 0, 0);
	if (h->h_itab==ITAB_NULL)
	{
		r3_set_itab_exception("RFC_MEMORY_INSUFFICIENT");
		r3_del_itab(h);
		return NULL;
	}

	if (install_structure(h))
	{
		r3_del_itab(h);
		return NULL;
	}
	return h;
}

H_R3RFC_ITAB r3_new_itab(H_R3RFC_CONN h_conn,
			char * table_name)
{
	static H_R3RFC_ITAB h;
	static RFC_FIELDS_INTLENGTH iTablength;
	static X030L_TABNAME eTabname;
	RFC_PARAMETER Exporting[2];
	RFC_PARAMETER Importing[2];
	RFC_TABLE Tables[2];
	RFC_RC RfcRc;
	char *RfcException = NULL;
	ITAB_H thFields;
	int i;
	RFC_FIELDS * tFields;

	if (h_conn->pre4)
		return r3_pre4_new_itab(h_conn, table_name);

	/* install structures */
	if (h_RFC_FIELDS==0) 
	{
		RfcRc = RfcInstallStructure("RFC_FIELDS",
                               t_RFC_FIELDS,
                               ENTRIES(t_RFC_FIELDS),
                               &h_RFC_FIELDS);
    		if (RfcRc != RFC_OK)
		{
			if (RfcRc == RFC_MEMORY_INSUFFICIENT)
				r3_set_itab_exception("RFC_MEMORY_INSUFFICIENT");
			else
				r3_set_itab_exception("UNKNOWN_ERROR");
			return NULL;
		}
	}

	/* define export params */
	memset(eTabname, ' ', sizeof(eTabname));
	strncpy((char *)eTabname, table_name, strlen(table_name));

	Exporting[0].name = "TABNAME";
	Exporting[0].nlen = 7;
	Exporting[0].type = TYPC;
	Exporting[0].leng = sizeof(X030L_TABNAME);
	Exporting[0].addr = eTabname;

	Exporting[1].name = NULL;

	/* define internal tables */
	thFields=ItCreate("FIELDS", sizeof(RFC_FIELDS), 0, 0);
	if (thFields==ITAB_NULL)
	{
		r3_set_itab_exception("RFC_MEMORY_INSUFFICIENT");
		return NULL;
	}

	Tables[0].name     = "FIELDS";
	Tables[0].nlen     = 6;
	Tables[0].type     = h_RFC_FIELDS;
	Tables[0].ithandle = thFields;
	Tables[0].leng     = sizeof(RFC_FIELDS);

	Tables[1].name = NULL;

	/* define import params */

	Importing[0].name = "TABLENGTH";
	Importing[0].nlen = 9;
	Importing[0].type = TYPINT;
	Importing[0].leng = sizeof(RFC_FIELDS_INTLENGTH);
	Importing[0].addr = &iTablength;

	Importing[1].name = NULL;

	/* call function module */
	RfcRc = RfcCallReceive(h_conn->h_rfc,
		"RFC_GET_STRUCTURE_DEFINITION",
		Exporting,
		Importing,
		Tables,
		&RfcException);
	if (RfcRc != RFC_OK)
	{
		switch (RfcRc)
		{
		case RFC_FAILURE:
			r3_set_rfc_sys_exception("RFC_FAILURE");
			break;
		case RFC_EXCEPTION:
			r3_set_rfc_exception(RfcException);
			break;
		case RFC_SYS_EXCEPTION:
			r3_set_rfc_sys_exception(RfcException);
			break;
		case RFC_CALL:
			r3_set_rfc_exception("RFC_CALL");
			break;
		default:
			r3_set_rfcapi_exception("UNKNOWN_ERROR");
		}
		ItDelete(thFields);
		return NULL;
	}

	/* allocate memory for the table */
	if (!(h=malloc(sizeof(R3RFC_ITAB))))	
	{
		r3_set_rfcapi_exception("MALLOC_FAILED");
		ItDelete(thFields);
		return NULL;
	}
	memset(h, 0, sizeof(R3RFC_ITAB));
	h->h_conn=h_conn;
	h->h_itab=ITAB_NULL;
	h->rec_size=iTablength;
	strcpy(h->name, table_name);

	/* get table definition */
	h->n_fields=ItFill(thFields);
	h->fields=malloc(h->n_fields*sizeof(R3RFC_ITABDEF));
	if (h->fields==NULL)
	{
		r3_set_rfcapi_exception("MALLOC_FAILED");
		r3_del_itab(h);
		ItDelete(thFields);
		return NULL;
	}
	memset(h->fields, 0, h->n_fields*sizeof(R3RFC_ITABDEF));
	for (i=0; i<h->n_fields; i++)
	{
		tFields=ItGetLine(thFields, i+1);
		if (tFields  == NULL)
		{
			r3_set_itab_exception("RFC_MEMORY_INSUFFICIENT");
			r3_del_itab(h);
			ItDelete(thFields);
			return NULL;
		}
	
		strncpy(h->fields[i].tabname,
			(char *)tFields->Tabname,
			sizeof(tFields->Tabname));
		r3_stbl(h->fields[i].tabname);

		strncpy(h->fields[i].fieldname,
			tFields->Fieldname,
			sizeof(tFields->Fieldname));
		r3_stbl(h->fields[i].fieldname);

		strncpy(h->fields[i].exid,
			tFields->Exid,
			sizeof(tFields->Exid));
		r3_stbl(h->fields[i].exid);

		h->fields[i].position=tFields->Position;
		h->fields[i].offset=tFields->Offset;
		h->fields[i].intlength=tFields->Intlength;
		h->fields[i].decimal=tFields->Decimals;
	}

	/* delete table */
	ItDelete(thFields);

	/* create ITAB */
	h->h_itab=ItCreate(h->name, h->rec_size, 0, 0);
	if (h->h_itab==ITAB_NULL)
	{
		r3_set_itab_exception("RFC_MEMORY_INSUFFICIENT");
		r3_del_itab(h);
		return NULL;
	}

	if (install_structure(h))
	{
		r3_del_itab(h);
		return NULL;
	}
	return h;
}


void r3_del_itab(H_R3RFC_ITAB h)
{
	if (!h)
		return;
	if (h->h_itab != ITAB_NULL)
		ItDelete(h->h_itab);
	if (h->fields)
		free(h->fields);
	free(h);
}

int r3_add_row(H_R3RFC_ITAB h)
{
	if (!(h->curr_row=ItAppLine(h->h_itab)))
		r3_set_itab_exception("RFC_MEMORY_INSUFFICIENT");
	return h->curr_row==NULL;
}

int r3_ins_row(H_R3RFC_ITAB h, long row_no)
{
	if (!(h->curr_row=ItInsLine(h->h_itab, row_no)))
		r3_set_itab_exception("RFC_MEMORY_INSUFFICIENT");
	return h->curr_row==NULL;
}

int r3_del_row(H_R3RFC_ITAB h, long row_no)
{
	int ret;
	ret=ItDelLine(h->h_itab, row_no);
	if (ret<0)
		r3_set_itab_exception("RFC_MEMORY_INSUFFICIENT");
	if (ret>0)
		r3_set_itab_exception("ROW_DOES_NOT_EXIST");
	return ret;
}

int r3_set_row(H_R3RFC_ITAB h, long row_no)
{
	h->curr_row=ItGupLine(h->h_itab, row_no);
	if (h->curr_row == NULL)
		r3_set_itab_exception("ROW_DOES_NOT_EXIST");
	return h->curr_row==NULL;
}

int r3_get_fino(H_R3RFC_ITAB h, char * fn)
{
	int i;
	for (i=0; i<h->n_fields; i++)
	{
		if (!(strcmp(fn, h->fields[i].fieldname)))
		{
				return i;
		}
	}
	r3_set_rfcapi_exception("NO_SUCH_FIELD");
	r3_set_error_message(fn);
	return -1;
}

int r3_set_field_value(H_R3RFC_ITAB h, char * field, char * value)
{
	int fino;
	fino=r3_get_fino(h, field);
	if (fino<0)
	{
		/* no real need to set exception here */
		r3_set_rfcapi_exception("NO_SUCH_FIELD");
		r3_set_error_message(field);
		return 1;
	}
	return r3_set_f_val(h, fino, value);
}

int r3_clear_itab_fields(H_R3RFC_ITAB h)
{
	int fino;
	char * value;
	value="";
	if (h->curr_row==NULL)
	{
		r3_set_itab_exception("ROW_DOES_NOT_EXIST");
		return 2;
	}
	for (fino=0; fino<h->n_fields; fino++)
	{
		switch(r3_exid2type(h->fields[fino].exid[0]))
		{
			case TYPC:
				r3_setchar(h->curr_row+h->fields[fino].offset,
					h->fields[fino].intlength, value);	
				break;
			case TYPNUM:
				r3_setnum(h->curr_row+h->fields[fino].offset,
					h->fields[fino].intlength, value);	
				break;
			case TYPX:
				r3_setbyte(h->curr_row+h->fields[fino].offset,
					h->fields[fino].intlength, value);	
				break;
			case TYPP:
				r3_setbcd(h->curr_row+h->fields[fino].offset,
					h->fields[fino].intlength,
					h->fields[fino].decimal, value);	
				break;
			case TYPINT:
				r3_setint(h->curr_row +
					h->fields[fino].offset, value);	
				break;
			case TYPFLOAT:
				r3_setfloat(h->curr_row +
					h->fields[fino].offset, value);	
				break;
			case TYPDATE:
				r3_setdate(h->curr_row +
					h->fields[fino].offset, value);	
				break;
			case TYPTIME:
				r3_settime(h->curr_row+h->fields[fino].offset,
					value);	
				break;
			default:
				return 1;
		}
	}
	return 0;
}

int r3_set_f_val(H_R3RFC_ITAB h, int fino, char * value)
{
	if (fino<0 || fino>=h->n_fields)
	{
		r3_set_rfcapi_exception("NO_SUCH_FIELD");
		return 1;
	}
	if (h->curr_row==NULL)
	{
		r3_set_itab_exception("ROW_DOES_NOT_EXIST");
		return 2;
	}
	switch(r3_exid2type(h->fields[fino].exid[0]))
	{
		case TYPC:
			r3_setchar(h->curr_row+h->fields[fino].offset,
				h->fields[fino].intlength,
				value);	
			break;
		case TYPNUM:
			r3_setnum(h->curr_row+h->fields[fino].offset,
				h->fields[fino].intlength,
				value);	
			break;
		case TYPX:
			r3_setbyte(h->curr_row+h->fields[fino].offset,
				h->fields[fino].intlength,
				value);	
			break;
		case TYPP:
			r3_setbcd(h->curr_row+h->fields[fino].offset,
				h->fields[fino].intlength,
				h->fields[fino].decimal,	
				value);	
			break;
		case TYPINT:
			r3_setint(h->curr_row+h->fields[fino].offset,
				value);	
			break;
		case TYPFLOAT:
			r3_setfloat(h->curr_row +
				h->fields[fino].offset, value);	
			break;
		case TYPDATE:
			r3_setdate(h->curr_row+h->fields[fino].offset,
				value);	
			break;
		case TYPTIME:
			r3_settime(h->curr_row+h->fields[fino].offset,
				value);	
			break;
		default:
			return 1;
	}
	return 0;
}

char * r3_get_field_value(H_R3RFC_ITAB h, char * field)
{
	int fino;
	fino=r3_get_fino(h, field);
	return r3_get_f_val(h, fino);
}

char * r3_get_f_val(H_R3RFC_ITAB h, int fino)
{
	if (fino<0 || fino>=h->n_fields)
	{
		r3_set_rfcapi_exception("NO_SUCH_FIELD");
		return NULL;
	}
	switch(r3_exid2type(h->fields[fino].exid[0]))
	{
		case TYPC:
			return r3_getchar(h->curr_row+h->fields[fino].offset,
				h->fields[fino].intlength);	
		case TYPNUM:
			return r3_getnum(h->curr_row+h->fields[fino].offset,
				h->fields[fino].intlength);	
		case TYPX:
			return r3_getbyte(h->curr_row+h->fields[fino].offset,
				h->fields[fino].intlength);
		case TYPP:
			return r3_getbcd(h->curr_row+h->fields[fino].offset,
				h->fields[fino].intlength,
				h->fields[fino].decimal);	
		case TYPINT:
			return r3_getint(h->curr_row+h->fields[fino].offset);	
		case TYPFLOAT:
			return r3_getfloat(h->curr_row+h->fields[fino].offset);
		case TYPDATE:
			return r3_getdate(h->curr_row+h->fields[fino].offset);
		case TYPTIME:
			return r3_gettime(h->curr_row+h->fields[fino].offset);
		default:
			r3_set_rfcapi_exception("UNKNOWN_FIELD_TYPE");
			return NULL;
	}
	r3_set_rfcapi_exception("ERROR");
	return NULL; /* should never by reached */
}

char * r3_get_record(H_R3RFC_ITAB h)
{
	if (!h->curr_row)
	{
		r3_set_itab_exception("ROW_DOES_NOT_EXIST");
		return NULL;
	}
	return r3_getbyte(h->curr_row, h->rec_size);
}

int r3_set_record(H_R3RFC_ITAB h, char * value)
{
	if (!h->curr_row)
	{
		r3_set_itab_exception("ROW_DOES_NOT_EXIST");
		return 1;
	}
	r3_setbyte(h->curr_row, h->rec_size, value);
	return 0;
}

long r3_rows(H_R3RFC_ITAB h)
{
	return ItFill(h->h_itab);
}

int r3_trunc_rows(H_R3RFC_ITAB h)
{
	return ItFree(h->h_itab);
}

int r3_get_fields(H_R3RFC_ITAB h)
{
	return h->n_fields;
}

char * r3_get_field_name(H_R3RFC_ITAB h, int fino)
{
	if (fino<0 || fino>=h->n_fields)
	{
		r3_set_rfcapi_exception("NO_SUCH_FIELD");
		return NULL;
	}
	else
		return h->fields[fino].fieldname;
}
/* EOF r3itab.c */
