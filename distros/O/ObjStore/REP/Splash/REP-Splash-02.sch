#include <osp-preamble.h>
#include <osperl.h>
#include "Splash.h"
#include <ostore/manschem.hh>

OS_REPORT_DLL_LOAD_AND_UNLOAD(0)
OS_SCHEMA_DLL_ID("perl:ObjStore::REP::Splash")
OS_SCHEMA_INFO_NAME(ObjStore_REP_Splash_dll_schema_info)

//-------------------------------- COLLECTIONS
OS_MARK_SCHEMA_TYPE(hvent2);
OS_MARK_SCHEMA_TYPE(OSPV_avarray);
OS_MARK_SCHEMA_TYPE(OSPV_av2array);
OS_MARK_SCHEMA_TYPE(OSPV_hvarray2);
OS_MARK_SCHEMA_TYPE(OSPV_splashheap);
