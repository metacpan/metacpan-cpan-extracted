#ifndef __osp_hkey__
#define __osp_hkey__

// perl overlaps with _Mapping_ext::op method!
#undef GIMME_V
#undef op

#include <ostore/coll.hh>

// 8 bytes
struct hkey {
  static os_typespec *get_os_typespec();
  char *pv;
  os_unsigned_int32 len;
  hkey();
  hkey(const hkey &);
  hkey(const char *);
  ~hkey();
  int valid();
  void set_undef();
  hkey *operator=(const hkey &);
  hkey *operator=(const char *);
  void s(const char *k1, os_unsigned_int32);
  SV *to_sv();
  static int rank(os_void_const_p s1, os_void_const_p s2);
  static os_unsigned_int32 hash(os_void_const_p s1);
};

#endif
