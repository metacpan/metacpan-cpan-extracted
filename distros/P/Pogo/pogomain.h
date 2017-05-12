// pogomain.h
// 1999 Sey
#ifndef _POGOMAIN_H_
#define _POGOMAIN_H_
#include "pogocall.h"

// symbol _INXS_ means being compiled in Pogo.xs
// Why is this ugly macro necessary? Becase the symbol 'ref' conflicts
// between 'perl.h' and 'goods.h'.
#ifndef _INXS_
// ------------------------------------------------------------------
// Persistent classes corresponding to interface classes
// ------------------------------------------------------------------
class pVar : public object {
public:
	pVar(class_descriptor &desc);
	
	char*    get_class() const;
	void     set_class(const char*);
	char*    get_pclass() const;
	void     set_pclass(const char*);
	callresult _call(void* func, void* argref);
	
	METACLASS_DECLARATIONS(pVar, object);
protected:
	ref<eString> pclass;		// class name for Pogo::* object itself
	ref<eString> blessclass;
};

class pScalar : public pVar {
public:
	pScalar();
	static  ref<pScalar> create() 
		{ return new pScalar(); }
	
	ref<object> get() const;
	void set(ref<object> val);
	
	METACLASS_DECLARATIONS(pScalar, pVar);
protected:
	ref<object> value;
};

// pString is not used, eString is directly used
#if 0
class pString : public pVar {
public:
	pString(const char *str);
	pString(const nstring* str);
	static ref<pString> create(const char *str) { return new pString(str); }
	static ref<pString> create(const nstring *str) { return new pString(str); }
	
	nstring* get() const;
	void     set(const char* str);
	void     set(const nstring* str);
	
	METACLASS_DECLARATIONS(pString, pVar);
protected:
	ref<eString> string;
};
#endif

class pArray : public pVar {
public:
	pArray(unsigned size);
	static ref<pArray> create(unsigned size) 
		{ return new pArray(size); }
	
	ref<object> get(unsigned idx) const;
	void     set(unsigned idx, ref<object> val);
	unsigned      get_size() const;
	void     set_size(unsigned size);
	void     clear();
	void     push(ref<object> val);
	ref<object> pop();
	void     insert(unsigned idx, ref<object> val);
	ref<object> remove(unsigned idx);

	METACLASS_DECLARATIONS(pArray, pVar);
protected:
	ref<eArray> array;
};

class pHash : public pVar {
public:
	pHash(unsigned size);
	static ref<pHash> create(unsigned size) 
		{ return new pHash(size); }
	
	ref<object> get(const char* key) const;
	void     set(const char* key, ref<object> val);
	int      exists(const char* key) const;
	ref<object> remove(const char* key);
	void     clear();
	char*    first_key() const;
	char*    next_key(const char* key) const;
	
	METACLASS_DECLARATIONS(pHash, pVar);
protected:
	ref<eHash> hash;
};

class pBtree : public pVar {
public:
	pBtree();
	static ref<pBtree> create() { return new pBtree(); }
	
	ref<object> get(const char* key) const;
	void     set(const char* key, ref<object> val);
	int      exists(const char* key) const;
	ref<object> remove(const char* key);
	void     clear();
	char*    first_key() const;
	char*    last_key() const;
	char*    next_key(const char* key) const;
	char*    prev_key(const char* key) const;
	char*    find_key(const char* key) const;
	
	void     initialize() const;
	
	METACLASS_DECLARATIONS(pBtree, pVar);
protected:
	ref<eBtree> btree;
};

class pNtree : public pVar {
public:
	pNtree();
	static ref<pNtree> create() { return new pNtree(); }
	
	ref<object> get(const char* key) const;
	void     set(const char* key, ref<object> val);
	int      exists(const char* key) const;
	ref<object> remove(const char* key);
	void     clear();
	char*    first_key() const;
	char*    last_key() const;
	char*    next_key(const char* key) const;
	char*    prev_key(const char* key) const;
	char*    find_key(const char* key) const;
	
	METACLASS_DECLARATIONS(pNtree, pVar);
protected:
	ref<eNtree> ntree;
};

class pHtree : public pVar {
public:
	pHtree(unsigned size);
	static ref<pHtree> create(unsigned size)
		{ return new pHtree(size); }
	
	ref<object> get(const char* key) const;
	void     set(const char* key, ref<object> val);
	int      exists(const char* key) const;
	ref<object> remove(const char* key);
	void     clear();
	char*    first_key() const;
	char*    next_key(const char* key) const;
	
	METACLASS_DECLARATIONS(pHtree, pVar);
protected:
	ref<eHtree> htree;
};

class pSortedNumArray : public pVar {
public:
	pSortedNumArray(unsigned size);
	static ref<pSortedNumArray> create(unsigned size)
		{ return new pSortedNumArray(size); }
	
	int      get(unsigned idx) const;
	int      find(int val) const;
	int      findGE(int val) const;
	void     set(int val);
	void     ins(int val);
	void     del(int val);
	unsigned  get_size() const;
	void     set_size(unsigned size);
	void     clear();
	
	METACLASS_DECLARATIONS(pSortedNumArray, pVar);
protected:
	ref<SortedNumArray> snarray;
};

#endif

// ------------------------------------------------------------------
// Perl interface classes (non persistent)
// ------------------------------------------------------------------
class Pvar;
class Pscalar;
class Pstring;
class Parray;
class Phash;
class Phtree;
class Pbtree;
class Pntree;
class Psnarray;

// database class
class Pogo {
	friend class Pvar;
	friend class Pscalar;
	friend class Pstring;
	friend class Parray;
	friend class Phash;
	friend class Phtree;
	friend class Pbtree;
	friend class Pntree;
	friend class Psnarray;
public:
	Pogo(const char* cfgfile = NULL);
	~Pogo();
	int      open(const char* cfgfile);
	void     close();
	int      opened() const;
	Pvar*    root();
	void     begin_transaction();
	void     abort_transaction();
	void     end_transaction();
	char*    perl_class() const;
	static void initialize();
#ifdef GLOBALDB
	static Pogo* POGOOBJ();
#endif
#ifndef _INXS_
protected:
	static int task_initialized;
	int        fopened;
	database*  db;
	ref<pBtree> rootbtree;
#endif
};

// virtual base class for variable classes
class Pvar {
public:
	virtual ~Pvar() {}
	char*    get_class() const;
	void     set_class(const char*);
	char*    get_pclass() const;
	void     set_pclass(const char*);
	void     begin_transaction();
	void     abort_transaction();
	void     end_transaction();
	callresult _call(void* func, void* argref);
	int      _equal(const Pvar* var);
	int      wait_modification(unsigned sec);
	unsigned object_id();
	Pvar*    root();
	// You probably think why both perl_class() and _perl_class() exist.
	// The reason is that virtual functions are not available in XS code.
	char*   perl_class() const;
#ifndef _INXS_
	virtual char*    _perl_class() const = 0;
	virtual ref<object> strip() const = 0;
#endif
};

// string class
// this class does not correspond to pString
// this class does not correspond to Pogo::String perl class
class Pstring : public Pvar {
public:
	Pstring(const nstring* str, Pogo* pogo = NULL);
	Pstring(const nstring* str, Pvar* pvar);
	~Pstring();
	nstring* get() const;
	void     set(const nstring* str);
	char*    perl_class() const;
#ifndef _INXS_
	char*    _perl_class() const;
	ref<object> strip() const;
	Pstring(ref<eString> pstr);
protected:
	ref<eString> string;
#endif
};

// scalar class
class Pscalar : public Pvar {
public:
	Pscalar(Pogo* pogo = NULL);
	Pscalar(Pvar* pvar);
	~Pscalar();
	Pvar*    get() const;
	void     set(const Pvar* val);
	void     set(const nstring* str);
	char*    perl_class() const;
#ifndef _INXS_
	char*    _perl_class() const;
	ref<object> strip() const;
	Pscalar(ref<pScalar> pscalar);
protected:
	ref<pScalar> scalar;
#endif
};

// array class
class Parray : public Pvar {
public:
	Parray(unsigned size, Pogo* pogo = NULL);
	Parray(unsigned size, Pvar* pvar);
	~Parray();
	Pvar*    get(unsigned idx) const;
	void     set(unsigned idx, const Pvar* val);
	void     set(unsigned idx, const nstring* str);
	unsigned get_size() const;
	void     set_size(unsigned size);
	void     clear();
	void     push(const Pvar* val);
	void     push(const nstring* str);
	Pvar*    pop();
	void     insert(unsigned idx, const Pvar* val);
	void     insert(unsigned idx, const nstring* str);
	Pvar*    remove(unsigned idx);
	char*    perl_class() const;
#ifndef _INXS_
	char*    _perl_class() const;
	ref<object> strip() const;
	Parray(ref<pArray> parr);
protected:
	ref<pArray> array;
#endif
};

// hash class
class Phash : public Pvar {
public:
	Phash(unsigned size, Pogo* pogo = NULL);
	Phash(unsigned size, Pvar* pvar);
	~Phash();
	Pvar*    get(const char* key) const;
	void     set(const char* key, const Pvar* val);
	void     set(const char* key, const nstring* str);
	int      exists(const char* key) const;
	Pvar*    remove(const char* key);
	void     clear();
	char*    first_key() const;
	char*    next_key(const char* key) const;
	char*    perl_class() const;
#ifndef _INXS_
	char*    _perl_class() const;
	ref<object> strip() const;
	Phash(ref<pHash> phash);
protected:
	ref<pHash> hash;
#endif
};

// hash-tree class (hash slots are placed in B-tree)
class Phtree : public Pvar {
public:
	Phtree(unsigned size, Pogo* pogo = NULL);
	Phtree(unsigned size, Pvar* pvar);
	~Phtree();
	Pvar*    get(const char* key) const;
	void     set(const char* key, const Pvar* val);
	void     set(const char* key, const nstring* str);
	int      exists(const char* key) const;
	Pvar*    remove(const char* key);
	void     clear();
	char*    first_key() const;
	char*    next_key(const char* key) const;
	char*    perl_class() const;
#ifndef _INXS_
	char*    _perl_class() const;
	ref<object> strip() const;
	Phtree(ref<pHtree> phtree);
protected:
	ref<pHtree> htree;
#endif
};

// B-tree class
class Pbtree : public Pvar {
public:
	Pbtree(Pogo* pogo = NULL);
	Pbtree(Pvar* pvar);
	~Pbtree();
	Pvar*    get(const char* key) const;
	void     set(const char* key, const Pvar* val);
	void     set(const char* key, const nstring* str);
	int      exists(const char* key) const;
	Pvar*    remove(const char* key);
	void     clear();
	char*    first_key() const;
	char*    last_key() const;
	char*    next_key(const char* key) const;
	char*    prev_key(const char* key) const;
	char*    find_key(const char* key) const;
	char*    perl_class() const;
#ifndef _INXS_
	char*    _perl_class() const;
	ref<object> strip() const;
	Pbtree(ref<pBtree> pbtree);
protected:
	ref<pBtree> btree;
#endif
};

// N-tree class
class Pntree : public Pvar {
public:
	Pntree(Pogo* pogo = NULL);
	Pntree(Pvar* pvar);
	~Pntree();
	Pvar*    get(const char* key) const;
	void     set(const char* key, const Pvar* val);
	void     set(const char* key, const nstring* str);
	int      exists(const char* key) const;
	Pvar*    remove(const char* key);
	void     clear();
	char*    first_key() const;
	char*    last_key() const;
	char*    next_key(const char* key) const;
	char*    prev_key(const char* key) const;
	char*    find_key(const char* key) const;
	char*    perl_class() const;
#ifndef _INXS_
	char*    _perl_class() const;
	ref<object> strip() const;
	Pntree(ref<pNtree> pntree);
protected:
	ref<pNtree> ntree;
#endif
};

// sorted number array class
class Psnarray : public Pvar {
public:
	Psnarray(unsigned size, Pogo* pogo = NULL);
	Psnarray(unsigned size, Pvar* pvar);
	~Psnarray();
	int     get(unsigned idx) const;
	int      find(int val) const;
	int      findGE(int val) const;
	void     set(int val);
	void     ins(int val);
	void     del(int val);
	unsigned get_size() const;
	void     set_size(unsigned size);
	void     clear();
	char*    perl_class() const;
#ifndef _INXS_
	char*    _perl_class() const;
	ref<object> strip() const;
	Psnarray(ref<pSortedNumArray> psnarr);
protected:
	ref<pSortedNumArray> snarray;
#endif
};

#ifndef _INXS_
// utility functions
Pvar* wrap(ref<object> val);
Pstring* wrap(ref<eString> val);
Pscalar* wrap(ref<pScalar> val);
Parray* wrap(ref<pArray> val);
Phash* wrap(ref<pHash> val);
Phtree* wrap(ref<pHtree> val);
Pbtree* wrap(ref<pBtree> val);
Pntree* wrap(ref<pNtree> val);
#endif

#endif

