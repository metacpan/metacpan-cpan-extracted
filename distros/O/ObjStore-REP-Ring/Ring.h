struct osp_ring_page : os_virtual_behavior {
  struct osp_ring_page *prev, *next;
  osp_keypack1 keys;
  OSPVptr *first;
  I16 fill, old_fill;

  osp_ring_page();
  virtual ~osp_ring_page();

  virtual int get_max()=0;
  virtual int avail()=0;
  virtual OSPVptr *array()=0;
  virtual OSPVptr &at(int xx)=0;

  void cache_keys(osp_pathexam &exam, OSSVPV *pv);
  void uncache_keys();
  void verify_keys(osp_pathexam &exam);
  int qck_cmp(osp_pathexam &exam, int update_ok);

  void reset_first();
  void _move(OSPVptr *start, OSPVptr *end, OSPVptr *to);
  void prepare_insert(int items);
  void fwd_xfer(int at);
  OSSVPV *shift();
  OSSVPV *pop();
  void extend(int to);
  void push(OSSVPV *pv);
  void push(SV **base, int items);
  void unshift(OSSVPV *pv);
  void unshift(SV **base, int items);
  void insert_after(int at, OSSVPV *pv);
  void splice(int offset, int length, SV **base, int count);
};

#define OSP_RING_PAGE1_MAX 64
struct osp_ring_page1 : osp_ring_page {
  static os_typespec *get_os_typespec();
  OSPVptr ar[OSP_RING_PAGE1_MAX];

  virtual int get_max();
  virtual int avail();
  virtual OSPVptr *array();
  virtual OSPVptr &at(int xx);
};

#define RGf_STALE		0x100

#define RG_STALE(pv)		(OSPvFLAGS(pv) & RGf_STALE)
#define RG_STALE_on(pv)		(OSPvFLAGS(pv) |= RGf_STALE)
#define RG_STALE_off(pv)	(OSPvFLAGS(pv) &= ~RGf_STALE)

struct OSPV_ring_index1 : OSPV_Generic {
  static os_typespec *get_os_typespec();
  OSPVptr conf;
  U32 version;	// inc if new/delete
  U32 max;
  U32 fill;  // can be stale -- use read_fill() or fix_stale() first
  osp_ring_page *first, *last;

  OSPV_ring_index1();
  void fix_stats();
  void stale_stats();
  U32 read_fill();  // read-only!
  osp_ring_page *new_page(osp_ring_page *ref, int after);
  osp_ring_page *get_page(U32 loc, I16 *offset);
  void split(osp_ring_page *pp, int at);
  void free_page(osp_ring_page *pp);
  virtual ~OSPV_ring_index1();
  virtual int get_perl_type();
  virtual char *os_class(STRLEN *len);
  virtual char *rep_class(STRLEN *len);
  virtual OSSVPV *new_cursor(os_segment *seg);
  virtual double _percent_filled();
  virtual void _debug1(void *);
  virtual int add(OSSVPV *);
  virtual int remove(OSSVPV *);
  virtual int FETCHSIZE();
  virtual void CLEAR();
  virtual void Extend(U32 to);
  virtual void FETCH(SV *key);
  virtual void STORE(SV *key, SV *value);
  virtual void POP();
  virtual void SHIFT();
  virtual void PUSH(SV **base, int items);
  virtual void UNSHIFT(SV **base, int items);
  virtual void SPLICE(int offset, int length, SV **top, int count);
};

#define RGf_POSITION		0x0100
#define RGf_ATEND		0x0200

#define RG_POSITION(pv)		(OSPvFLAGS(pv) & RGf_POSITION)
#define RG_POSITION_on(pv)	(OSPvFLAGS(pv) |= RGf_POSITION)
#define RG_POSITION_off(pv)	(OSPvFLAGS(pv) &= ~RGf_POSITION)

#define RG_ATEND(pv)		(OSPvFLAGS(pv) & RGf_ATEND)
#define RG_ATEND_on(pv)		(OSPvFLAGS(pv) |= RGf_ATEND)
#define RG_ATEND_off(pv)	(OSPvFLAGS(pv) &= ~RGf_ATEND)

struct OSPV_ring_index1_cs : OSPV_Cursor2 {
  static os_typespec *get_os_typespec();
  OSPVptr myfocus;
  U32 version;
  I32 abpos;
  osp_ring_page *page;
  I16 reloff;

  OSPV_ring_index1_cs(OSPV_ring_index1 *_fo);
  void CHK_VER();
  virtual OSSVPV *focus();
  virtual void moveto(I32);
  virtual void step(I32 delta);
  virtual I32 pos(); //probably not kept up-to-date
  virtual void at();
  virtual void keys();
  virtual void store(SV *);
  virtual int seek(osp_pathexam &);
};
