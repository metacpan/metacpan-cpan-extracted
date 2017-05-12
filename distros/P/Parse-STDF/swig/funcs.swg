/* 
   %inline code block is passed verbatim to the generated SWIG wrapper code. 
   Typically within this block we define "helper" functions.
 */

%inline %{

#include <libstdf.h>

int stdf_version(stdf_file* f)
{
  dtc_U4 stdf_ver;
  stdf_get_setting(f, STDF_SETTING_VERSION, &stdf_ver );
  return ( (int) stdf_ver);
}

/*
  Fast record conversion functions
 */

rec_mir* rec_to_mir( void* rec) { return ( (rec_mir*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_sdr* rec_to_sdr( void* rec) { return ( (rec_sdr*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_pcr* rec_to_pcr( void* rec) { return ( (rec_pcr*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_mrr* rec_to_mrr( void* rec) { return ( (rec_mrr*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_wir* rec_to_wir( void* rec) { return ( (rec_wir*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_pir* rec_to_pir( void* rec) { return ( (rec_pir*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_prr* rec_to_prr( void* rec) { return ( (rec_prr*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_ptr* rec_to_ptr( void* rec) { return ( (rec_ptr*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_dtr* rec_to_dtr( void* rec) { return ( (rec_dtr*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_atr* rec_to_atr( void* rec) { return ( (rec_atr*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_far* rec_to_far( void* rec) { return ( (rec_far*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_hbr* rec_to_hbr( void* rec) { return ( (rec_hbr*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_sbr* rec_to_sbr( void* rec) { return ( (rec_sbr*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_pmr* rec_to_pmr( void* rec) { return ( (rec_pmr*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_pgr* rec_to_pgr( void* rec) { return ( (rec_pgr*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_plr* rec_to_plr( void* rec) { return ( (rec_plr*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_rdr* rec_to_rdr( void* rec) { return ( (rec_rdr*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_wrr* rec_to_wrr( void* rec) { return ( (rec_wrr*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_wcr* rec_to_wcr( void* rec) { return ( (rec_wcr*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_tsr* rec_to_tsr( void* rec) { return ( (rec_tsr*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_mpr* rec_to_mpr( void* rec) { return ( (rec_mpr*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_ftr* rec_to_ftr( void* rec) { return ( (rec_ftr*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_bps* rec_to_bps( void* rec) { return ( (rec_bps*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_eps* rec_to_eps( void* rec) { return ( (rec_eps*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_gdr* rec_to_gdr( void* rec) { return ( (rec_gdr*) stdf_parse_raw_record( (rec_unknown*) rec) ); }
rec_unknown* rec_to_unknown ( void* rec ) { return  ( stdf_parse_raw_record( (rec_unknown*) rec) ); }

void* read_record ( stdf_file* f ) { return ( (void*) stdf_read_record_raw(f)  ); }
void free_record ( void* rec ) { stdf_free_record ( (rec_unknown*) rec ); }
char* get_rec_name ( void* rec ) { return ( stdf_get_rec_name (((rec_unknown*)rec)->header.REC_TYP, ((rec_unknown*)rec)->header.REC_SUB) ); }


int make_rec ( rec_typ t, rec_sub s ) { return ( (t << 8) + s ); }
void init_header ( rec_header* h , rec_typ t ) { h->REC_TYP = (rec_typ) (t>>8); h->REC_SUB = (rec_sub) (t&0xff); }


SV* xU1_to_RV( void* data, int len ) 
{
  SV **svs = (SV **) malloc(len*sizeof(SV*));
  for (int i=0; i < len; i++ ) {
    svs[i] = sv_newmortal();
    sv_setuv((SV*) svs[i], *((dtc_U1*) data+i) );
  }
  AV *av = av_make(len,svs);
  SV* result = newRV_noinc((SV*) av ); 
  sv_2mortal(result);
  return(result);
}

SV* xN1_to_RV( void* data, int len ) 
{
  SV **svs = (SV **) malloc(len*sizeof(SV*));
  int p=0;
  unsigned char lo, hi;
  for (int i=0; i < len; i++ ) {
    svs[i] = sv_newmortal();
    if ( (i % 2) == 0) 
    {
      lo = *((unsigned char*) data+p);
      hi = *((unsigned char*) data+p);
      hi >>= 4;
      lo <<= 4;
      lo >>= 4;
      p++;
    }
    ( i % 2) ?  sv_setuv((SV*) svs[i], lo ) : sv_setuv((SV*) svs[i], hi) ;
  }
  AV *av = av_make(len,svs);
  SV* result = newRV_noinc((SV*) av ); 
  sv_2mortal(result);
  return(result);
}

SV* xU2_to_RV( void* data, int len ) 
{
  SV **svs = (SV **) malloc(len*sizeof(SV*));
  for (int i=0; i < len; i++ ) {
    svs[i] = sv_newmortal();
    sv_setuv((SV*) svs[i], *((dtc_U2*) data+i) );
  }
  AV *av = av_make(len,svs);
  SV* result = newRV_noinc((SV*) av ); 
  sv_2mortal(result);
  return(result);
}

SV* xR4_to_RV( void* data, int len ) 
{
  SV **svs = (SV **) malloc(len*sizeof(SV*));
  for (int i=0; i < len; i++ ) {
    svs[i] = sv_newmortal();
    sv_setnv((SV*) svs[i], *((dtc_R4*) data+i) );
  }
  AV *av = av_make(len,svs);
  SV* result = newRV_noinc((SV*) av ); 
  sv_2mortal(result);
  return(result);
}

SV* xCn_to_RV( void* data, int len ) 
{
  SV **svs = (SV **) malloc(len*sizeof(SV*));
  for (int i=0; i < len; i++ ) {
    svs[i] = sv_newmortal();
    char* s = *((char**)data+i);
    STRLEN l = (unsigned char) *s;
    ( l > 0 ) ? sv_setpvn( (SV*) svs[i], s+1, l ) : sv_setpv( (SV*) svs[i], "" );
  }
  AV *av = av_make(len,svs);
  SV* result = newRV_noinc((SV*) av ); 
  sv_2mortal(result);
  return(result);
}

SV* xVn_to_RV( void* data, int len ) 
{
  SV **svs = (SV **) malloc(len*sizeof(SV*));
  dtc_Vn v = (dtc_Vn) data;
  for (int i=0; i < len; i++ ) {
    switch ( v[i].type )
	{ 
	  case GDR_B0:
	  {
        svs[i] = sv_newmortal();
        sv_setpv( (SV*) svs[i], "(pad)" ); // special pad field 
		break;
	  }
	  case GDR_N1:
	  {
	    unsigned char lo, hi;
        svs[i] = sv_newmortal();
        lo = *((unsigned char*) v[i].data);
        lo <<= 4;
        lo >>= 4;
        sv_setuv((SV*) svs[i], lo );
	  }
	  case GDR_U1:
	  {
        svs[i] = sv_newmortal();
        sv_setuv((SV*) svs[i], *((dtc_U1*) v[i].data) );
		break;
	  }
	  case GDR_U2:
	  {
        svs[i] = sv_newmortal();
        sv_setuv((SV*) svs[i], *((dtc_U2*) v[i].data) );
		break;
	  }
	  case GDR_U4:
	  {
        svs[i] = sv_newmortal();
        sv_setuv((SV*) svs[i], *((dtc_U4*) v[i].data) );
		break;
	  }
	  case GDR_I1:
	  {
        svs[i] = sv_newmortal();
        sv_setiv((SV*) svs[i], *((dtc_I1*) v[i].data) );
		break;
	  }
	  case GDR_I2:
	  {
        svs[i] = sv_newmortal();
        sv_setiv((SV*) svs[i], *((dtc_I2*) v[i].data) );
		break;
	  }
	  case GDR_I4:
	  {
        svs[i] = sv_newmortal();
        sv_setiv((SV*) svs[i], *((dtc_I4*) v[i].data) );
		break;
	  }
	  case GDR_R4:
	  {
        svs[i] = sv_newmortal();
        sv_setnv((SV*) svs[i], *((dtc_R4*) v[i].data) );
		break;
	  }
	  case GDR_R8:
	  {
        svs[i] = sv_newmortal();
        sv_setnv((SV*) svs[i], *((dtc_R8*) v[i].data) );
		break;
	  }
	  case GDR_Cn:
	  {
        svs[i] = sv_newmortal();
        char* s = *((char**)v[i].data);
        STRLEN l = (unsigned char) *s;
        ( l > 0 ) ? sv_setpvn( (SV*) svs[i], s+1, l ) : sv_setpv( (SV*) svs[i], "" );
		break;
      }
	  default:
	  {
        svs[i] = sv_newmortal();
        sv_setpv( (SV*) svs[i], "[??]" ); 
		break;
	  }
	} 
  }
  AV *av = av_make(len,svs);
  SV* result = newRV_noinc((SV*) av ); 
  sv_2mortal(result);
  return(result);
}

%}

