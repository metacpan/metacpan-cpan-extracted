/* Header file for Teradata::SQL */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <coptypes.h>       /* Teradata include files */
#include <coperr.h>
#include <dbcarea.h>
#include <parcel.h>
#include <dbchqep.h>

/* coptypes really should have this typedef, but it doesn't.
   WGR, 2008-03-19. */
typedef signed char  ByteInt;

/* Data types */
#define BIGINT_NN       600
#define BIGINT_N        601
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
#define NUMBER_NN       604
#define NUMBER_N        605
#define SMALLINT_NN     500
#define SMALLINT_N      501
#define VARBYTE_NN      688
#define VARBYTE_N       689
#define VARCHAR_NN      448
#define VARCHAR_N       449
#define VARGRAPHIC_NN   464
#define VARGRAPHIC_N    465

 /* Maximum number of fields per request */
#define MAX_FIELDS      520
 /* Maximum length of returned data */
#define MAX_RDA_LEN     65400

 /* Simplified descriptor area with fewer data types */
struct datadescr {
 int  nfields;
 struct {
	short  sqltype;
	unsigned short datalen;
	short  dlb;  /* Data length in bytes (for decimal, mostly) */
	short  decscale;
        char   colident[32];
 } sqlvar[MAX_FIELDS];
};

 /* The following is a modified definition of the DataInfo parcel.
    The definition supplied by Teradata only allows 300 fields. */

struct  ModCliDataInfoType
{
   PclWord              FieldCount;
   struct ModCliDInfoType {
	PclWord         SQLType;
	PclWord         SQLLen;
   } InfoVar[MAX_FIELDS];
};

/* Session and Request objects (structures) */
struct sSession {
  char  ccs[32];  /* Client character set */
  struct DBCAREA dbc;
};

struct sRequest {
  Int32  req_num;
  struct DBCAREA * dbcp;
  struct datadescr ddesc;
};

typedef struct sSession  Session, *pSession;
typedef struct sRequest  Request, *pRequest;

 /* The following is the entire structure needed for the IRQ extension
    (passing values to parameterized SQL). We use two parcels:
    DataInfo and IndicData.
    Header: IRX8. Level: 1 for 32-bit, 0 for 64-bit.
    Element Type: 0 (pointers). */
struct irq_ext {
 struct D8CAIRX   irqx_header;
 struct D8XIELEM  irqx_DataInfo_elem;
 struct D8XIEP    irqx_DataInfo_body;
 struct D8XIELEM  irqx_IndicData_elem;
 struct D8XIEP    irqx_IndicData_body;
};

 /* The following is the entire structure needed for segmented
    requests. We need just one parcel: SP Options.
    Header: IRX8. Level: 1. Element Type: 1 (inline). */

struct seg_ext {
 struct D8CAIRX   seg_header;
 struct D8XIELEM  seg_SPOptions_elem;
 struct D8XIEP    seg_SPOptions_body;
};


 /* Function prototypes */
int check_cli_error ( const char *, struct DBCAREA * );
void _simplify_prepinfo ( struct datadescr *, char * );
void _insert_dp ( char *, char *, int );
double _dec_to_double ( Byte *, int, int );
void _dec_to_string ( char *, Byte *, int );
double _num_to_double ( Byte * );
void _num_to_string ( char *, Byte * );
void set_options ( struct DBCAREA * );
int _fetch_parcel ( const char *, struct DBCAREA *, pRequest );
int _fetch_all_parcels ( const char *, struct DBCAREA *, pRequest );
int Zconnect ( pSession, char *, char *, char *, char * );
int Zdisconnect ( pSession );
int Zexecute ( pSession, char * );
int Zopen ( pRequest, char * );
int Zopenseg ( pRequest, char *, char * );
int Zexecutep ( pSession, char * );
int Zexecutep_args ( pSession, char *, struct ModCliDataInfoType *,
  Byte *, int );
int Zopenp ( pRequest, char * );
int Zopenp_args ( pRequest, char *, struct ModCliDataInfoType *,
  Byte *, int );
char * Zfetch ( pRequest );
int Zclose ( pRequest );
int Zabort ( pSession );
int Zserver_info ( DBCHQEP * );
