#include <osp-preamble.h>
#include <osperl.h>
#include "FatTree.h"
#include <ostore/manschem.hh>

OS_REPORT_DLL_LOAD_AND_UNLOAD(0)
OS_SCHEMA_DLL_ID("perl:ObjStore::REP::FatTree")
OS_SCHEMA_INFO_NAME(ObjStore_REP_FatTree_dll_schema_info)

OS_MARK_SCHEMA_TYPE(TCE);

OS_MARK_SCHEMA_TYPE(avtn);
OS_MARK_SCHEMA_TYPE(OSPV_fattree_av)
OS_MARK_SCHEMA_TYPE(av2tn);
OS_MARK_SCHEMA_TYPE(OSPV_fattree_av2)

OS_MARK_SCHEMA_TYPE(dex2tn);
OS_MARK_SCHEMA_TYPE(OSPV_fatindex2);
OS_MARK_SCHEMA_TYPE(OSPV_fatindex2_cs);
OS_MARK_SCHEMA_TYPE(dex3tn);
OS_MARK_SCHEMA_TYPE(OSPV_fatindex3);
OS_MARK_SCHEMA_TYPE(OSPV_fatindex3_cs);
