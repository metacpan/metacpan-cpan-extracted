#include <osp-preamble.h>
#include <osperl.h>
#include "Ring.h"
#include <ostore/manschem.hh>

OS_REPORT_DLL_LOAD_AND_UNLOAD(0)
OS_SCHEMA_DLL_ID("perl:ObjStore::REP::Ring")
OS_SCHEMA_INFO_NAME(ObjStore_REP_Ring_dll_schema_info)

OS_MARK_SCHEMA_TYPE(osp_ring_page1);
OS_MARK_SCHEMA_TYPE(OSPV_ring_index1);
OS_MARK_SCHEMA_TYPE(OSPV_ring_index1_cs);
