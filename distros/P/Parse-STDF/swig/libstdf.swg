%module libstdf
%include "cdata.i"
%include "funcs.swg"
%include "typemaps.swg"

/*
  Stock declarations from libstdf
 */

%include <libstdf.h>
%include <libstdf_types.h>
%include <libstdf_const.h>

extern stdf_file* stdf_open(char*);
extern int stdf_close(stdf_file*);
extern rec_unknown* stdf_read_record(stdf_file*);
extern char* stdf_get_rec_name(rec_typ, rec_sub);
extern void stdf_free_record(rec_unknown*);
extern stdf_file* stdf_open_ex(char*, unsigned int);
extern stdf_file* stdf_open_ex(char*, unsigned int, unsigned int);
extern rec_unknown* stdf_read_record_raw(stdf_file*);
extern rec_unknown* stdf_parse_raw_record(rec_unknown*);
extern ssize_t stdf_write_record(stdf_file*, void*);
extern char* stdf_get_Vn_name(int);

/* 
  Extended declarations
 */

int stdf_version(stdf_file* f);

rec_mir* rec_to_mir( void* rec);
rec_sdr* rec_to_sdr( void* rec);
rec_pcr* rec_to_pcr( void* rec);
rec_mrr* rec_to_mrr( void* rec);
rec_wir* rec_to_wir( void* rec);
rec_pir* rec_to_pir( void* rec);
rec_prr* rec_to_prr( void* rec);
rec_ptr* rec_to_ptr( void* rec);
rec_dtr* rec_to_dtr( void* rec);
rec_atr* rec_to_atr( void* rec);
rec_far* rec_to_far( void* rec); 
rec_hbr* rec_to_hbr( void* rec);
rec_sbr* rec_to_sbr( void* rec); 
rec_pmr* rec_to_pmr( void* rec); 
rec_pgr* rec_to_pgr( void* rec); 
rec_plr* rec_to_plr( void* rec); 
rec_rdr* rec_to_rdr( void* rec); 
rec_wrr* rec_to_wrr( void* rec); 
rec_wcr* rec_to_wcr( void* rec); 
rec_tsr* rec_to_tsr( void* rec); 
rec_mpr* rec_to_mpr( void* rec); 
rec_ftr* rec_to_ftr( void* rec); 
rec_bps* rec_to_bps( void* rec); 
rec_eps* rec_to_eps( void* rec); 
rec_gdr* rec_to_gdr( void* rec); 
rec_unknown* rec_to_unknown ( void* rec );

void* read_record ( stdf_file* f );
void free_record ( void* rec );
char* get_rec_name ( void* rec );

int make_rec ( rec_typ t, rec_sub s ); 
void init_header ( rec_header* h , rec_typ t ); 

SV* xU1_to_RV( void* data, int len ); 
SV* xN1_to_RV( void* data, int len ); 
SV* xU2_to_RV( void* data, int len );
SV* xR4_to_RV( void* data, int len ); 
SV* xCn_to_RV( void* data, int len );
SV* xVn_to_RV( void* data, int len );

