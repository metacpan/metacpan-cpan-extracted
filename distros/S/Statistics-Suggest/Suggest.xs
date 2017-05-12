#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <suggest.h>

#include "const-c.inc"


/****************************/

int* malloc_int(int n)
{
  return ((int*) malloc(sizeof(int) * n));
}

float* malloc_float(int n)
{
  return ((float*) malloc(sizeof(float) * n));
}

/****************************/

float* make_float_array(SV *sv, int num) 
{
  float *data;
  AV *av;
  int i;

  data = (float*) malloc (sizeof(float) * num);

  av = (AV*)SvRV(sv);
  for (i = 0; i < num; i++)  {
    data[i] = (float)SvNV(*av_fetch(av, i , 0));
  }
  return data;        
}

int* make_int_array(SV *sv, int num) 
{
  int *data;
  AV *av;
  int i;

  data = (int*) malloc (sizeof(int) * num);

  av = (AV*)SvRV(sv);
  for (i = 0; i < num; i++)  {
    data[i] = (int)SvNV(*av_fetch(av, i , 0));
  }
  return data;
}

/****************************/

AV* make_av_from_float(float* data, int num) 
{
  AV *av;
  int i;

  av = newAV();
  for (i = 0; i < num; i++) {
    av_push(av, newSVnv((double)data[i]));
  }
  return av;
}

AV* make_av_from_int(int* data, int num) 
{
  AV *av;
  int i;

  av = newAV();
  for (i = 0; i < num; i++) {
    av_push(av, newSVnv((double)data[i]));
  }
  return av;
}

/****************************/

void set_array_from_int(SV* sv, int* data, int num)
{ 
   sv_setsv(sv, newRV_noinc((SV*) make_av_from_int(data, num)));
}

void set_array_from_float(SV* sv, float* data, int num)
{ 
   sv_setsv(sv, newRV_noinc((SV*) make_av_from_float(data, num)));
}

/****************************/

MODULE = Statistics::Suggest		PACKAGE = Statistics::Suggest		

INCLUDE: const-xs.inc

PROTOTYPES: ENABLE

void
SUGGEST_Clean(arg0)
	int *	arg0

float
SUGGEST_EstimateAlpha(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
	int	arg0
	int	arg1
	int	arg2
	int *	arg3
	int *	arg4
	int	arg5
	int	arg6

int *
SUGGEST_Init(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
	int	arg0
	int	arg1
	int	arg2
	int *	arg3
	int *	arg4
	int	arg5
	int	arg6
	float	arg7

int
SUGGEST_TopN(arg0, arg1, arg2, arg3, arg4)
	int *	arg0
	int	arg1
	int *	arg2
	int	arg3
	int *	arg4

int *
_SUGGEST_Init(nusers, nitems, ntrans, userid_sv, itemid_sv, RType, NNbr, Alpha)
    int nusers
    int nitems
    int ntrans
    SV* userid_sv
    SV* itemid_sv
    int RType
    int NNbr
    float Alpha
  CODE:
{
    int *userid;
    int *itemid;

    /* set necessary values from sv* */
    userid = make_int_array(userid_sv, ntrans);
    itemid = make_int_array(itemid_sv, ntrans);
    
    /* call API */
    RETVAL = SUGGEST_Init(nusers, nitems, ntrans, userid, itemid, RType, NNbr, Alpha);

    /* free buffers */
    free(userid);
    free(itemid);
}
  OUTPUT:
    RETVAL

int
_SUGGEST_TopN(rcmdHandle, bsize, itemids_sv, NRcmd, rcmds_sv)
    int * rcmdHandle
    int bsize
    SV* itemids_sv
    int NRcmd
    SV* rcmds_sv
  CODE:
{
    int* itemids;
    int* rcmds;
    int rtn;

    /* prepare internal buffers */
    rcmds = malloc_int(NRcmd);

    /* set necessary values from sv* */
    itemids = make_int_array(itemids_sv, bsize);

    /* call API */
    rtn = SUGGEST_TopN(rcmdHandle, bsize, itemids, NRcmd, rcmds);
    RETVAL = rtn;

    /* set sv* and free buffers */
    if (rtn >= 0) {
        set_array_from_int(rcmds_sv, rcmds, rtn);
    }
    free(rcmds);
}
  OUTPUT:
    RETVAL

void
_SUGGEST_Clean(rcmdHandle)
    int * rcmdHandle
  CODE:
{
    SUGGEST_Clean(rcmdHandle);
}

float
_SUGGEST_EstimateAlpha(nusers, nitems, ntrans, userid_sv, itemid_sv, NNbr, NRcmd)
    int nusers
    int nitems
    int ntrans
    SV* userid_sv
    SV* itemid_sv
    int NNbr
    int NRcmd
  CODE:
{
    int *userid;
    int *itemid;

    /* set necessary values from sv* */
    userid = make_int_array(userid_sv, ntrans);
    itemid = make_int_array(itemid_sv, ntrans);
    
    /* call API */
    RETVAL = SUGGEST_EstimateAlpha(nusers, nitems, ntrans, userid, itemid, NNbr, NRcmd);

    /* free buffers */
    free(userid);
    free(itemid);
}
  OUTPUT:
    RETVAL