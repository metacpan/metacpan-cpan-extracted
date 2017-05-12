#include "osp-preamble.h"
#include "osperl.h"
#include "core.h"
#include <ostore/manschem.hh>

OS_REPORT_DLL_LOAD_AND_UNLOAD(0)
OS_SCHEMA_DLL_ID("perl:ObjStore")
OS_SCHEMA_INFO_NAME(ObjStore_dll_schema_info)

// OSSV is painful to evolve; Everything else is ez!
OS_MARK_SCHEMA_TYPE(OSSV);
OS_MARK_SCHEMA_TYPE(OSPVptr);
OS_MARK_SCHEMA_TYPE(OSPVweakptr);

// scalars
OS_MARK_SCHEMA_TYPE(OSPV_iv);
OS_MARK_SCHEMA_TYPE(OSPV_nv);

// useful stuff
OS_MARK_SCHEMA_TYPE(hvent2);    // too late to add 'osp_' prefix :-(
OS_MARK_SCHEMA_TYPE(osp_keypack1);

OS_MARK_SCHEMA_TYPE(osp_str3);
OS_MARK_SCHEMA_TYPE(osp_str7);
OS_MARK_SCHEMA_TYPE(osp_str11);
OS_MARK_SCHEMA_TYPE(osp_str15);
OS_MARK_SCHEMA_TYPE(osp_str19);
OS_MARK_SCHEMA_TYPE(osp_str23);
OS_MARK_SCHEMA_TYPE(osp_str27);
OS_MARK_SCHEMA_TYPE(osp_str31);
OS_MARK_SCHEMA_TYPE(osp_str35);

OS_MARK_SCHEMA_TYPE(osp_bitset1);
OS_MARK_SCHEMA_TYPE(osp_bitset2);
OS_MARK_SCHEMA_TYPE(osp_bitset3);
OS_MARK_SCHEMA_TYPE(osp_bitset4);

//-------------------------------- REFERENCES
OS_MARK_SCHEMA_TYPE(OSPV_Ref2_protect);
OS_MARK_SCHEMA_TYPE(OSPV_Ref2_hard);
