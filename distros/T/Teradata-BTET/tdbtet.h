/* Header file for Teradata::BTET */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

typedef unsigned char uchar;

/* Data types */
#define BLOB            400
#define BLOB_DEFERRED   404
#define BLOB_LOCATOR    408
#define BYTEINT_NN      756
#define BYTEINT_N       757
#define BYTE_NN         692
#define BYTE_N          693
 /* CHAR, TIME, and TIMESTAMP are the same */
#define CHAR_NN         452
#define CHAR_N          453
#define CLOB            416
#define CLOB_DEFERRED   420
#define CLOB_LOCATOR    424
#define DATE_NN         752
#define DATE_N          753
#define DECIMAL_NN      484
#define DECIMAL_N       485
#define FLOAT_NN        480
#define FLOAT_N         481
#define GRAPHIC_NN      468
#define GRAPHIC_N       469
#define INTEGER_NN      496
#define INTEGER_N       497
#define LONG_VARBYTE_NN 696
#define LONG_VARBYTE_N  697
#define LONG_VARCHAR_NN 456
#define LONG_VARCHAR_N  457
#define LONG_VARGRAPHIC_NN      472
#define LONG_VARGRAPHIC_N       473
#define SMALLINT_NN     500
#define SMALLINT_N      501
#define VARBYTE_NN      688
#define VARBYTE_N       689
#define VARCHAR_NN      448
#define VARCHAR_N       449
#define VARGRAPHIC_NN   464
#define VARGRAPHIC_N    465

 /* Is this a variable data type? */
#define is_vartype(a) \
 (a == VARBYTE_NN || a == VARBYTE_N || a == VARCHAR_NN || \
  a == VARCHAR_N || a == VARGRAPHIC_NN || a == VARGRAPHIC_N || \
  a == LONG_VARBYTE_NN || a == LONG_VARBYTE_N || \
  a == LONG_VARCHAR_NN || a == LONG_VARCHAR_N || \
  a == LONG_VARGRAPHIC_NN || a == LONG_VARGRAPHIC_N)

 /* Maximum number of fields in each SQLDA */
#define MAX_FIELDS      502
 /* Maximum length of user's select statement */
#define MAX_STMT_LEN    65400
 /* Maximum length of returned data */
#define MAX_RDA_LEN     65000

struct sqlda {
 char   sqldaid[8];
 int    sqldabc;
 short  sqln;
 short  sqld;
 struct sqlvar {
        short  sqltype;
        unsigned short sqllen;
        unsigned char *sqldata;
        short *sqlind;
        struct sqlname {
                short length;
                unsigned char data[30];
        } sqlname;
 } sqlvar[MAX_FIELDS];
};

 /* Simplified descriptor area with fewer data types */
struct datadescr {
 struct {
	short  sqltype;
	unsigned short datalen;
	short  decscale;
 } sqlvar[MAX_FIELDS];
};


 /* Function prototypes */
int error_check ( const char * );
int field_len ( short, unsigned short );
void simplify_sqlda ( struct datadescr *, struct sqlda * );
void _insert_dp ( char *, char *, int );
double _dec_to_double ( uchar *, int, int );
void _dec_to_string ( char *, uchar *, int );
int Zconnect ( char * );
int Zdisconnect ( void );
int Zprepare ( char *, int );
void Zbind_int ( int, int, uchar * );
void Zbind_double ( int, int, uchar * );
void Zbind_string ( int, int, char *, int );
void Zbind_null ( int, int, uchar * );
int Zexecute ( int );
int Zexecute_args ( int );
int Zopen ( int );
int Zopen_args ( int );
int Zfetch ( int );
int Zclose ( int );
int Zbegin_tran ( void );
int Zend_tran ( void );
int Zabort ( void );
