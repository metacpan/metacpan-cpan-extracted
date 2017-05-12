extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
}

#include <osperl.h>
#include "ospdl.h"
#include <ostore/manschem.hh>

OS_REPORT_DLL_LOAD_AND_UNLOAD(0)
OS_SCHEMA_DLL_ID("perl:ObjStore::Lib::PDL")
OS_SCHEMA_INFO_NAME(Lib__PDL_dll_schema_info)

OS_MARK_SCHEMA_TYPE(Lib__PDL1)
