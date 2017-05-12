// Splash collections
#include "splash.h"

//Splash REDUX

struct OSPV_splashheap : OSPV_Generic {
  static os_typespec *get_os_typespec();
  SPList < OSPVptr > av;
  OSPVptr conf_slot;
  OSPV_splashheap(int);
  virtual ~OSPV_splashheap();
  virtual char *os_class(STRLEN *);
  virtual char *rep_class(STRLEN *);
  virtual int get_perl_type();
  virtual int FETCHSIZE();
  virtual void CLEAR();
  virtual int add(OSSVPV*);
  virtual void SHIFT();
  virtual void FETCH(SV *xx);
};

struct OSPV_avarray : OSPV_Generic {
  static os_typespec *get_os_typespec();
  SPList < OSSV > av;
  OSPV_avarray(int);
  virtual ~OSPV_avarray();
//  virtual OSSVPV *new_cursor(os_segment *seg);
  virtual char *os_class(STRLEN *);
  virtual char *rep_class(STRLEN *);
  virtual int get_perl_type();
  virtual OSSV *avx(int xx);
  virtual void FETCH(SV *xx);
  virtual void STORE(SV *xx, SV *value);
  virtual void POP();
  virtual void SHIFT();
  virtual void PUSH(int ax, int items);
  virtual void UNSHIFT(int ax, int items);
  virtual void SPLICE(int offset, int length, SV **base, int count);
  virtual void CLEAR();
  virtual int FETCHSIZE();
  OSSV *fancy_traverse(char *keyish);
  virtual OSSVPV *traverse1(osp_pathexam &exam);
  virtual OSSV *traverse2(osp_pathexam &exam);
  virtual void make_constant();
  virtual double _percent_filled();
};

struct OSPV_av2array : OSPV_Generic {
  static os_typespec *get_os_typespec();
  SPList < OSPVptr > av;
  OSPV_av2array(int);
  virtual ~OSPV_av2array();
  virtual char *os_class(STRLEN *);
  virtual char *rep_class(STRLEN *);
  virtual int get_perl_type();
  virtual void FETCH(SV *xx);
  virtual void STORE(SV *xx, SV *value);
  virtual void POP();
  virtual void SHIFT();
  virtual void PUSH(int ax, int items);
  virtual void UNSHIFT(int ax, int items);
  virtual void SPLICE(int offset, int length, SV **base, int count);
  virtual void CLEAR();
  virtual int FETCHSIZE();
};

struct OSPV_hvarray2 : OSPV_Generic {
  static os_typespec *get_os_typespec();
  SPList < hvent2 > hv;
  OSPV_hvarray2(int);
  virtual ~OSPV_hvarray2();
//  virtual OSSVPV *new_cursor(os_segment *seg);
  virtual char *os_class(STRLEN *);
  virtual char *rep_class(STRLEN *);
  virtual int get_perl_type();
  int index_of(char *key);
  int first(int start);
  virtual OSSV *hvx(char *key);
  virtual void FETCH(SV *key);
  virtual void STORE(SV *key, SV *value);
  virtual void DELETE(SV *key);
  virtual void CLEAR();
  virtual int EXISTS(SV *key);
  virtual void FIRST(osp_smart_object **);
  virtual void NEXT(osp_smart_object **);
  virtual double _percent_filled();
  virtual int FETCHSIZE();
  virtual OSSVPV *traverse1(osp_pathexam &exam);
  virtual OSSV *traverse2(osp_pathexam &exam);
  virtual void make_constant();
};
