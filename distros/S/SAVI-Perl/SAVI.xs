/*
 * SAVI-Perl version 0.30
 *
 * Paul Henson <henson@acm.org>
 *
 * Copyright (c) 2002-2004 Paul Henson -- see COPYRIGHT file for details
 *
 */

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define INITGUID

#include "sav_if/csavi3c.h"

#ifdef __cplusplus
}
#endif


typedef CISavi3 *SAVI__handle;
typedef CIEnumSweepResults *SAVI__results;

typedef struct savi_version {
  U32 version;
  char string[128];
  U32 count;
  CIEnumIDEDetails *ide_list;
} savi_version_obj;

typedef savi_version_obj *SAVI__version;
typedef CIIDEDetails *SAVI__version__ide;

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

MODULE = SAVI			PACKAGE = SAVI::handle

void
DESTROY(savi_h)
  SAVI::handle savi_h
  CODE:
  {
    if (savi_h) {
      savi_h->pVtbl->Terminate(savi_h);
      savi_h->pVtbl->Release(savi_h);
    }
  }

void
new(class)
  char *class
  PPCODE:
  {
    SAVI__handle savi_h;
    CISweepClassFactory2 *factory;
    HRESULT status;
    SV *sv;

    status = DllGetClassObject((REFIID)&SOPHOS_CLASSID_SAVI, (REFIID)&SOPHOS_IID_CLASSFACTORY2, (void **)&factory);
    
    if (SOPHOS_SUCCEEDED(status)) {
      status = factory->pVtbl->CreateInstance(factory, NULL, &SOPHOS_IID_SAVI3, (void **)&savi_h);
      
      if (SOPHOS_SUCCEEDED(status)) {
	status = savi_h->pVtbl->InitialiseWithMoniker(savi_h, SOPHOS_COMSTR("SAVI-Perl"));
	
	if (SOPHOS_SUCCEEDED(status)) {
	    sv = sv_newmortal();
	    sv_setref_pv(sv, "SAVI::handle", savi_h);
	}
	else
	  savi_h->pVtbl->Release(savi_h);

      }
      
      factory->pVtbl->Release(factory);
    }
    
    if (SOPHOS_FAILED(status)) {
      sv = sv_2mortal(newSViv(SOPHOS_CODE(status)));
    }
    
    XPUSHs(sv);
  }


int type_invalid(savi_h)
  SAVI::handle savi_h
  CODE:
  {
    RETVAL = SOPHOS_TYPE_INVALID;
  }
  OUTPUT:
    RETVAL

int type_u08(savi_h)
  SAVI::handle savi_h
  CODE:
  {
    RETVAL = SOPHOS_TYPE_U08;
  }
  OUTPUT:
    RETVAL

int type_u16(savi_h)
  SAVI::handle savi_h
  CODE:
  {
    RETVAL = SOPHOS_TYPE_U16;
  }
  OUTPUT:
    RETVAL

int type_u32(savi_h)
  SAVI::handle savi_h
  CODE:
  {
    RETVAL = SOPHOS_TYPE_U32;
  }
  OUTPUT:
    RETVAL

int type_s08(savi_h)
  SAVI::handle savi_h
  CODE:
  {
    RETVAL = SOPHOS_TYPE_S08;
  }
  OUTPUT:
    RETVAL

int type_s16(savi_h)
  SAVI::handle savi_h
  CODE:
  {
    RETVAL = SOPHOS_TYPE_S16;
  }
  OUTPUT:
    RETVAL

int type_s32(savi_h)
  SAVI::handle savi_h
  CODE:
  {
    RETVAL = SOPHOS_TYPE_S32;
  }
  OUTPUT:
    RETVAL

int type_boolean(savi_h)
  SAVI::handle savi_h
  CODE:
  {
    RETVAL = SOPHOS_TYPE_BOOLEAN;
  }
  OUTPUT:
    RETVAL

int type_bytestream(savi_h)
  SAVI::handle savi_h
  CODE:
  {
    RETVAL = SOPHOS_TYPE_BYTESTREAM;
  }
  OUTPUT:
    RETVAL

int type_option_group(savi_h)
  SAVI::handle savi_h
  CODE:
  {
    RETVAL = SOPHOS_TYPE_OPTION_GROUP;
  }
  OUTPUT:
    RETVAL

int type_string(savi_h)
  SAVI::handle savi_h
  CODE:
  {
    RETVAL = SOPHOS_TYPE_STRING;
  }
  OUTPUT:
    RETVAL

void
load_data(savi_h)
  SAVI::handle savi_h
  PPCODE:
  {
    HRESULT status;

    status = savi_h->pVtbl->LoadVirusData(savi_h);

    if (SOPHOS_FAILED(status))
      XPUSHs(sv_2mortal(newSViv(SOPHOS_CODE(status))));
  }

void
version(savi_h)
  SAVI::handle savi_h
  PPCODE:
  {
    SV *sv = &PL_sv_undef;
    SAVI__version savi_version;
    HRESULT status;
    
    if (savi_version = (SAVI__version)malloc(sizeof(savi_version_obj))) {
      status = savi_h->pVtbl->GetVirusEngineVersion(savi_h, &(savi_version->version), savi_version->string, 128,
						  NULL, &(savi_version->count), NULL,
						  (REFIID)&SOPHOS_IID_ENUM_IDEDETAILS,
						  (void **)&(savi_version->ide_list));
      if (SOPHOS_SUCCEEDED(status)) {
	sv = sv_newmortal();
	sv_setref_pv(sv, "SAVI::version", savi_version);
      }
      else
	sv = sv_2mortal(newSViv(SOPHOS_CODE(status)));
    }

    XPUSHs(sv);
  }

void
set(savi_h, param, value, type)
  SAVI::handle savi_h
  char *param
  char *value
  int type
  PPCODE:
  {
    HRESULT status;
    
    status = savi_h->pVtbl->SetConfigValue(savi_h, param, type, value);

    if (SOPHOS_FAILED(status))
      XPUSHs(sv_2mortal(newSViv(SOPHOS_CODE(status))));
  
  }

void
get(savi_h, param, type)
  SAVI::handle savi_h
  char *param
  int type
  PPCODE:
  {
    HRESULT status;
    char value[1024];
    
    status = savi_h->pVtbl->GetConfigValue(savi_h, param, type, 1024, value, NULL);

    if (SOPHOS_SUCCEEDED(status))
      XPUSHs(sv_2mortal(newSVpv(value, strlen(value))));
    else
      XPUSHs(&PL_sv_undef);
    
      XPUSHs(sv_2mortal(newSViv(SOPHOS_CODE(status))));
  
  }

void
options(savi_h)
  SAVI::handle savi_h
  PPCODE:
  {
    CIEnumEngineConfig *options;
    CIEngineConfig *option;
    HRESULT status;
    
    status = savi_h->pVtbl->GetConfigEnumerator(savi_h, (REFIID)&SOPHOS_IID_ENUM_ENGINECONFIG, (void **)&options);

    if (SOPHOS_SUCCEEDED(status)) {
      status = options->pVtbl->Reset(options);

      if (SOPHOS_SUCCEEDED(status)) {
	while (options->pVtbl->Next(options, 1, (void **)&option, NULL) == SOPHOS_S_OK) {
	  char name[1024];
	  status = option->pVtbl->GetName(option, 1024, name, NULL);

	  if (SOPHOS_SUCCEEDED(status)) {
	    U32 type;
	    status = option->pVtbl->GetType(option, &type);

	    if (SOPHOS_SUCCEEDED(status)) {
	      XPUSHs(sv_2mortal(newSVpv(name, strlen(name))));
	      XPUSHs(sv_2mortal(newSViv(type)));
	    }
	  }

	  option->pVtbl->Release(option);
	}
      }

      options->pVtbl->Release(options);
    }
  }

void
scan(savi_h, path)
  SAVI::handle savi_h
  char *path
  PPCODE:
  {
    SAVI__results results;
    HRESULT status;
    SV *sv;
    
    status = savi_h->pVtbl->SweepFile(savi_h, path, (REFIID)&SOPHOS_IID_ENUM_SWEEPRESULTS, (void **)&results);

    if (status == SOPHOS_S_OK) {
      results->pVtbl->Release(results);
      sv = sv_newmortal();
      sv_setref_iv(sv, "SAVI::results", 0);
    }
    else if (status == SOPHOS_SAVI_ERROR_VIRUSPRESENT) {
      sv = sv_newmortal();
      sv_setref_pv(sv, "SAVI::results", results);
    }
    else
      sv = sv_2mortal(newSViv(SOPHOS_CODE(status)));
      
    XPUSHs(sv);
  }

void
scan_fh(savi_h, fh)
  SAVI::handle savi_h
  FILE *fh
  PPCODE:
  {
    SAVI__results results;
    HRESULT status;
    SV *sv;
    
    status = savi_h->pVtbl->SweepHandle(savi_h, "handle", fileno(fh), (REFIID)&SOPHOS_IID_ENUM_SWEEPRESULTS, (void **)&results);

    if (status == SOPHOS_S_OK) {
      results->pVtbl->Release(results);
      sv = sv_newmortal();
      sv_setref_iv(sv, "SAVI::results", 0);
    }
    else if (status == SOPHOS_SAVI_ERROR_VIRUSPRESENT) {
      sv = sv_newmortal();
      sv_setref_pv(sv, "SAVI::results", results);
    }
    else
      sv = sv_2mortal(newSViv(SOPHOS_CODE(status)));
      
    XPUSHs(sv);
  }

MODULE = SAVI			PACKAGE = SAVI::version

void
DESTROY(version)
  SAVI::version version
  CODE:
  {
    if (version) {
      version->ide_list->pVtbl->Release(version->ide_list);
      free(version);
    }
  }

int
major(version)
  SAVI::version version
  CODE:
  {
    RETVAL = version->version >> 16;
  }
  OUTPUT:
    RETVAL

int
minor(version)
  SAVI::version version
  CODE:
  {
    RETVAL = version->version & 0x0000ffff;
  }
  OUTPUT:
    RETVAL

char *
string(version)
  SAVI::version version
  CODE:
  {
    RETVAL = version->string;
  }
  OUTPUT:
    RETVAL

int
count(version)
  SAVI::version version
  CODE:
  {
    RETVAL = version->count;
  }
  OUTPUT:
    RETVAL

void
ide_list(version)
  SAVI::version version
  PPCODE:
  {
    SAVI__version__ide ide;
    SV *sv;
    
    version->ide_list->pVtbl->Reset(version->ide_list);
    
    while (version->ide_list->pVtbl->Next(version->ide_list, 1, (void **)&ide, NULL) == SOPHOS_S_OK) {
      sv = sv_newmortal();
      sv_setref_pv(sv, "SAVI::version::ide", ide);
      XPUSHs(sv);
    }
  }

MODULE = SAVI			PACKAGE = SAVI::version::ide

void
DESTROY(ide)
  SAVI::version::ide ide
  CODE:
  {
    if (ide)
      ide->pVtbl->Release(ide);
  }

void
name(ide)
  SAVI::version::ide ide
  PPCODE:
  {
    char ide_name[128];
  
    if (ide->pVtbl->GetName(ide, 128, ide_name, NULL) == SOPHOS_S_OK)
      XPUSHs(sv_2mortal(newSVpv(ide_name, strlen(ide_name))));
  }

void
date(ide)
  SAVI::version::ide ide
  PPCODE:
  {
    SYSTEMTIME release_date;
    char buf[128];

    if (ide->pVtbl->GetDate(ide, &release_date) == SOPHOS_S_OK) {
      snprintf(buf, 128, "%d/%d/%d", release_date.wMonth, release_date.wDay, release_date.wYear);
      buf[127] = '\0';
      XPUSHs(sv_2mortal(newSVpv(buf, strlen(buf))));
    }
  }

MODULE = SAVI			PACKAGE = SAVI::results

void
DESTROY(results)
  SAVI::results results
  CODE:
  {
    if (results)
      results->pVtbl->Release(results);
  }

int
infected(results)
  SAVI::results results
  CODE:
  {
    RETVAL = (results != 0);
  }
  OUTPUT:
    RETVAL

void
viruses(results)
  SAVI::results results
  PPCODE:
  {
    CISweepResults *virus_info;

    if (results) {
      results->pVtbl->Reset(results);
    
      while (results->pVtbl->Next(results, 1, (void **)&virus_info, NULL) == SOPHOS_S_OK) {
	char virus_name[128];
	
	if (virus_info->pVtbl->GetVirusName(virus_info, 128, virus_name, NULL) == SOPHOS_S_OK) {
	  XPUSHs(sv_2mortal(newSVpv(virus_name, strlen(virus_name))));
	}
	
	virus_info->pVtbl->Release(virus_info);
      }
    }
  }
