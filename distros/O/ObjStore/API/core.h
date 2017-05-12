struct OSPV_Ref2_hard : OSPV_Ref2 {
  static os_typespec *get_os_typespec();
  os_reference myfocus;
  OSPV_Ref2_hard(OSSVPV *);
  OSPV_Ref2_hard(char *, os_database *);
  virtual os_database *get_database();
  virtual int deleted();
  virtual OSSVPV *focus();
  virtual char *dump();
};

struct OSPV_Ref2_protect : OSPV_Ref2 {
  static os_typespec *get_os_typespec();
  os_reference_protected myfocus;
  OSPV_Ref2_protect(OSSVPV *);
  OSPV_Ref2_protect(char *, os_database *);
  virtual os_database *get_database();
  virtual int deleted();
  virtual OSSVPV *focus();
  virtual char *dump();
};

////////////////////////////////////////////////////////////////////////
// DEPRECIATED (but still included for schema compatibility)

struct OSPV_Ref : OSSVPV {
  static os_typespec *get_os_typespec();
  OSPV_Ref(OSSVPV *);
  OSPV_Ref(char *, os_database *);
  virtual ~OSPV_Ref();
  virtual char *os_class(STRLEN *len);
  os_reference_protected myfocus;
  os_database *get_database();
  char *dump();
  int deleted();
  OSSVPV *focus();
};

struct OSPV_Cursor : OSPV_Ref {
  static os_typespec *get_os_typespec();
  OSPV_Cursor(OSSVPV *);
  virtual char *os_class(STRLEN *len);
  virtual void seek_pole(int);
  virtual void at();
  virtual void next();
};

