/*
	r3rfc.h
	johan schoen, johan.schon@capgemini.se

	revision history:

	0.02	1999-03-23	schoen
		minor changes

	0.30	1999-11-05	schoen
		added support for R/3 release < 40A

	0.32	1999-11-15	schoen
		changed prototypes for r3_getint, r3_setint, r3_getfloat
		and r3_setfloat
*/

typedef struct {
	RFC_HANDLE h_rfc;
	int error;
	int pre4; /* should be set if R/3 release is before 40A */
	char * exception_type;
	char * exception;
	RFC_ERROR_INFO rfc_error_info;
} R3RFC_CONN;
typedef R3RFC_CONN * H_R3RFC_CONN;

typedef struct {
	char paramclass[2];
	char parameter[31];
	char tabname[31];
	char fieldname[31];
	char exid[2];
	long position;
	long offset;
	long intlength;
	long decimal;
	char zdefault[22];
	char paramtext[80];
	void * buffer;
} R3RFC_FUNCINT;

typedef struct {
	char tabname[31];
	char fieldname[31];
	char exid[2];
	long position;
	long offset;
	long intlength;
	long decimal;
} R3RFC_ITABDEF;

typedef struct {
	H_R3RFC_CONN	h_conn;
	char  		name[31];
	R3RFC_FUNCINT  	* interface;
	int		n_interface;
	RFC_PARAMETER 	* exporting;
	int		n_exporting;
	RFC_PARAMETER 	* importing;
	int		n_importing;
	RFC_TABLE 	* tables;
	int		n_tables;	
} R3RFC_FUNC;
typedef R3RFC_FUNC * H_R3RFC_FUNC;

typedef struct {
	H_R3RFC_CONN	h_conn;
	char		name[31];
	long		rec_size;
	ITAB_H		h_itab;
	R3RFC_ITABDEF	* fields;
	int		n_fields;	
	RFC_TYPEHANDLE	h_type;
	char		* curr_row;
} R3RFC_ITAB;
typedef R3RFC_ITAB * H_R3RFC_ITAB;


H_R3RFC_CONN r3_new_conn(char * client,
			char * user,
			char * password,
			char * language,
			char * hostname,
			int sysnr,
			char * gwhost,
			char * gwservice,
			int trace);
void r3_del_conn(H_R3RFC_CONN h);
void r3_set_pre4(H_R3RFC_CONN h);

void r3_rfc_clear_error();
void r3_set_rfc_exception(char * exception);
void r3_set_f_rfc_exception(H_R3RFC_FUNC h, char * exception);
void r3_set_rfc_sys_exception(char * exception);
void r3_set_itab_exception(char * exception);
void r3_set_rfcapi_exception(char * exception);
char * r3_get_exception_type();
char * r3_get_exception();
int r3_get_error();
char * r3_get_error_message();
void r3_set_error_message(char * msg);

H_R3RFC_FUNC r3_new_func(H_R3RFC_CONN h_conn, char * functionname);
void r3_del_func(H_R3RFC_FUNC h);
int r3_call_func(H_R3RFC_FUNC h);
void r3_clear_params(H_R3RFC_FUNC h);
int r3_set_export_value(H_R3RFC_FUNC h, char * export, char * value);
int r3_set_exp_val(H_R3RFC_FUNC h, int ino, char * value);
char * r3_get_import_value(H_R3RFC_FUNC h, char * import);
char * r3_get_imp_val(H_R3RFC_FUNC h, int ino);
int r3_set_table(H_R3RFC_FUNC h, char * table, H_R3RFC_ITAB h_table);
int r3_get_ino(H_R3RFC_FUNC h, char * pc, char * fn);
int r3_get_params(H_R3RFC_FUNC h);
char * r3_get_param_name(H_R3RFC_FUNC h, int ino);
char * r3_get_param_class(H_R3RFC_FUNC h, int ino);

H_R3RFC_ITAB r3_new_itab(H_R3RFC_CONN h_conn, char * table_name);
void r3_del_itab(H_R3RFC_ITAB h);
int r3_add_row(H_R3RFC_ITAB h);
int r3_ins_row(H_R3RFC_ITAB h, long row_no);
int r3_del_row(H_R3RFC_ITAB h, long row_no);
int r3_set_row(H_R3RFC_ITAB h, long row_no);
int r3_set_field_value(H_R3RFC_ITAB h, char * field, char * value);
int r3_set_f_val(H_R3RFC_ITAB h, int fino, char * value);
char * r3_get_f_val(H_R3RFC_ITAB h, int fino);
char * r3_get_field_value(H_R3RFC_ITAB h, char * field);
long r3_rows(H_R3RFC_ITAB h);
int r3_trunc_rows(H_R3RFC_ITAB h);
unsigned r3_exid2type(char c);
int r3_get_fino(H_R3RFC_ITAB h, char * fn);
int r3_get_fields(H_R3RFC_ITAB h);
char * r3_get_field_name(H_R3RFC_ITAB h, int fino);
char * r3_get_record(H_R3RFC_ITAB h);
int r3_set_record(H_R3RFC_ITAB h, char * value);

void r3_stbl(char *s);
void r3_ftbl(char *s, int n);
void r3_setchar(char * var, size_t n, char * str);
char * r3_getchar(char * var, size_t n);
void r3_setdate(char * var, char * str);
char * r3_getdate(char * var);
void r3_setfloat(void * var, char * str);
char * r3_getfloat(void * var);
void r3_setint(void * var, char * str);
char * r3_getint(void * var);
void r3_setnum(char * var, size_t n, char * str);
char * r3_getnum(char * var, size_t n);
void r3_settime(char * var, char * str);
char * r3_gettime(char * var);
void r3_setbyte(unsigned char * var, size_t n, char * str);
char * r3_getbyte(unsigned char * var, size_t n);
void r3_setbcd(unsigned char * bcd, size_t n, int decimals, char * str);
char * r3_getbcd(unsigned char * bcd, size_t n, int decimals);

/* EOF r3rfc.h */
