#define OBJSTORE_LIB_PDL_VERSION 1
#define USE_OBJSTORE_LIB_PDL(YourName,ver)					\
STMT_START {									\
  SV *apiv = perl_get_sv("ObjStore::Lib::PDL::APIVERSION", 0);			\
  if (!apiv) croak("ObjStore::Lib::PDL not loaded");				\
  if (SvIV(apiv) != OBJSTORE_LIB_PDL_VERSION)					\
    croak("ObjStore::Lib::PDL binary API version mismatch -- recompile %s",	\
	  YourName);								\
} STMT_END

struct Lib__PDL1 : OSSVPV {
  static os_typespec *get_os_typespec();

  I32 *dims;
  void *data;
  I16 datatype;
  I16 ndims;

  Lib__PDL1();
  virtual ~Lib__PDL1();
  virtual int get_perl_type();
  virtual void make_constant();
  virtual char *os_class(STRLEN *len);
  virtual char *rep_class(STRLEN *len);
  virtual dynacast_fn get_dynacast_meth();

  void clear();
  void copy(Lib__PDL1 &tmpl);
  U32 calc_nvals();
  void allocate_cells(U32, int);
  void set_datatype(int ndt);
  void setdims(I32 cnt, I32 *dsz, void *tmpl=0);
};

struct Lib__PDL1_c {
  void *data;
  I16 datatype;
  I16 ndims;
  I32 *dims;
  I32 def_dims[10];
  I32 *dimincs;
  I32 def_dimincs[10];
  I32 *loc;
  I32 def_loc[10];
  U32 pos;

  Lib__PDL1_c(Lib__PDL1 *pdl);
  ~Lib__PDL1_c();

  // xchg?
  void seek(SV **ats);
  void seek(I32 *ats);
  void setdim(int dx, I32 to);

  void set(SV *);
  void set(I32 value);
  void set(double value);

  char &at_b() { return ((char*)data)[pos]; }
  os_int16 &at_s() { return ((os_int16*)data)[pos]; }
  os_unsigned_int16 &at_us() { return ((os_unsigned_int16*)data)[pos]; }
  os_int32 &at_l() { return ((os_int32*)data)[pos]; }
  float &at_f() { return ((float*)data)[pos]; }
  double &at_d() { return ((double*)data)[pos]; }
};
