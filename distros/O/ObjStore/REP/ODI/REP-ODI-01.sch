#include <osp-preamble.h>
#include <osperl.h>
#include "ODI.h"
#include <ostore/manschem.hh>

OS_REPORT_DLL_LOAD_AND_UNLOAD(0)
OS_SCHEMA_DLL_ID("perl:ObjStore::REP::ODI")
OS_SCHEMA_INFO_NAME(ObjStore_REP_ODI_dll_schema_info)

//-------------------------------- COLLECTIONS
OS_MARK_DICTIONARY(hkey,OSSV*);
OS_MARK_SCHEMA_TYPE(hkey);
OS_MARK_SCHEMA_TYPE(OSPV_hvdict);
