//------------------------------------------------------------ODI

#include "osp_hkey.h"

// ObjectStore collections
#include <ostore/coll/cursor.hh>
#include <ostore/coll/dict_pt.hh>

struct OSPV_hvdict : OSPV_Generic {
  static os_typespec *get_os_typespec();
  os_Dictionary < hkey, OSSV* > hv;
  OSPV_hvdict(os_unsigned_int32);
  virtual ~OSPV_hvdict();
//  virtual OSSVPV *new_cursor(os_segment *seg);
  virtual char *os_class(STRLEN *);
  virtual char *rep_class(STRLEN *);
  virtual int get_perl_type();
  virtual OSSV *hvx(char *key);
  virtual void FETCH(SV *key);
  virtual void STORE(SV *key, SV *value);
  virtual void DELETE(SV *key);
  virtual void CLEAR();
  virtual int EXISTS(SV *key);
  virtual void FIRST(osp_smart_object **);
  virtual void NEXT(osp_smart_object **);
  virtual int FETCHSIZE();
  virtual OSSVPV *traverse1(osp_pathexam &exam);
  virtual OSSV *traverse2(osp_pathexam &exam);
  virtual void make_constant();
};

