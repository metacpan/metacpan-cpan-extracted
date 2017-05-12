// pogogcls.h - generic classes for Pogo
// 1999 Sey
#ifndef _POGOGCLS_H_
#define _POGOGCLS_H_

#include <goods.h>
#include <dbscls.h>
#include <time.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>
#include "nstring.h"

//--------------------------------------------------------------------
class eString : public String
	{
protected:
	eString(class_descriptor& desc, size_t init_size) : String(desc, init_size)
		{}
    
public:
	int  compare(const nstring* str) const { 
		return memcmp(array, str->str, str->len); 
	}

	int  comparen(const char* str, unsigned len) const { 
		return strncmp(array, str, len); 
	}
	int  comparen(ref<eString> const& str, unsigned len) const { 
		return -str->comparen(array, len); 
	}

	char* get_text_alloc(char*& p) const;
	char* get_text_alloc(char*& p, unsigned& len) const;
	char* get_text_alloc(nstring* str) const {
		return get_text_alloc(str->str, str->len);
	}

	virtual ref<ArrayOfByte> clone() const { return create(array); }

    void replace(const char* str);
	void replace(const char* str, unsigned len);
	void replace(const nstring* str) { replace(str->str, str->len); }
	
	static ref<eString> create(ref<eString> copy) { return copy->clone(); }
	static ref<eString> create(size_t init_size = 0) { 
		return new (self_class, init_size) eString(self_class, init_size); 
	}
	static ref<eString> create(const char* str);
	static ref<eString> create(const char* str, size_t size);
	static ref<eString> create(const nstring* str) {
		return create(str->str, str->len);
	}
	
	METACLASS_DECLARATIONS(eString, String); 
	};
// end class eString

//--------------------------------------------------------------------
class eArray : public ArrayOfObject {
protected:
	eArray(class_descriptor& desc, size_t init_size) 
		: ArrayOfObject(desc, init_size, init_size) {}

public:
	void setsize(nat4 size) { set_size(size); }
	static ref<eArray> create(size_t init_size = 0) { 
		return new (self_class, init_size) eArray(self_class, init_size); 
	}
	
	METACLASS_DECLARATIONS(eArray, ArrayOfObject); 
};

//--------------------------------------------------------------------
class eHash : public hash_table {
protected:
	eHash(size_t hash_table_size)
		: hash_table(hash_table_size, self_class) {} 

public:
	void set(const char* name, ref<object> obj);
	char* first_key(char*& p) const;
	char* next_key(char*& p, const char* key) const;

	static ref<eHash> create(size_t size) 
		{ return new (self_class, size) eHash(size); }
	METACLASS_DECLARATIONS(eHash, hash_table);
};

//--------------------------------------------------------------------
class eBtree : public B_tree {
protected:
	eBtree(class_descriptor& desc) : B_tree(desc) {}

public:
	void reset() { root = NULL; height = 0; }
	
	char* first_key(char*& p) const;
	char* last_key(char*& p) const;
	char* next_key(char*& p, const char* key) const;
	char* prev_key(char*& p, const char* key) const;
	char* find_key(char*& p, const char* key) const;

	static ref<eBtree> create() { return new eBtree(self_class); }
	METACLASS_DECLARATIONS(eBtree, B_tree);
};

//--------------------------------------------------------------------
class set_member_numkey : public set_member {
	friend class set_owner;
protected:
	set_member_numkey(class_descriptor& aDesc, ref<object> const& obj, 
		const char* key, size_t key_size) 
		: set_member(aDesc,obj,key,key_size)
		{}
public:
	int     compare(const char* key, size_t) const; 
	int     compare(const char* key) const; 
	int     compareIgnoreCase(const char* key) const; 
	skey_t  get_key() const; 
	static skey_t  str2key(const char* s, size_t);
	
	static ref<set_member_numkey> create(ref<object> obj, const char* key);
	static ref<set_member_numkey> create(ref<object> obj, const char* key,
			size_t key_size);
	METACLASS_DECLARATIONS(set_member_numkey, set_member);
};

//--------------------------------------------------------------------
class eNtree : public eBtree {
	friend class B_page;
protected:
	eNtree(class_descriptor& desc) : eBtree(desc) {}

public:
	ref<set_member> find(skey_t key) const;
	ref<set_member> find(const char* str, size_t len, skey_t key) const;
	ref<set_member> find(const char* str) const;

	ref<set_member> findGE(skey_t key) const;
	ref<set_member> findGE(const char* str, size_t len, skey_t key) const;
	ref<set_member> findGE(const char* str) const;

	char*	next_key(char*& p, const char* key) const;
	char*	prev_key(char*& p, const char* key) const;
	char*	find_key(char*& p, const char* key) const;

	void	insert(char const* key, ref<object> obj);
	
	static ref<eNtree> create() { return new eNtree(self_class); } 
	METACLASS_DECLARATIONS(eNtree, eBtree);
};

//--------------------------------------------------------------------
class eHtree : public H_tree {
protected:
	eHtree(size_t hash_size) : H_tree(hash_size, self_class) {}

public:
	void set(const char* name, ref<object> obj);
	char* first_key(char*& p) const;
	char* next_key(char*& p, const char* key) const;

	static ref<eHtree> create(size_t size) 
		{ return new (self_class, size) eHtree(size); }
	METACLASS_DECLARATIONS(eHtree, H_tree);
};

//--------------------------------------------------------------------
extern int binary_output_fd;

class eBinary : public Blob { 
protected: 
	eBinary(const void* buf, size_t buf_size) : 
		Blob((void*)buf, buf_size, self_class) 
		{}
	
	// static int output_fd = 1;

public: 
	// void set_output_fd(int fd)
	//	{ output_fd = fd; }
	
	virtual boolean handle() const;
	
	static ref<eBinary> create(int input_fd, size_t part_size);
	
	static ref<eBinary> create(const void* buf, size_t buf_size);
    
	METACLASS_DECLARATIONS(eBinary, Blob);
};


//--------------------------------------------------------------------
class eTime : public object
	{
protected:
	nat4 _time;
	// time_t	_time;
	
	eTime() : object(self_class) { _time = time(NULL); }
	eTime(ref<eTime> t) : object(self_class) { _time = t->_time; }
	eTime(nat4 t) : object(self_class) { _time = t; }

public:
	time_t get() const { return _time; }
	void set(ref<eTime> t) { _time = t->_time; }
	void set(nat4 t) { _time = t; }
	void setnow() { _time = time(NULL); }
	char* strlocal(char* buf) const;
	char* strgm(char* buf) const;
	int compare(ref<eTime> const& t) const;
	
	static ref<eTime> create() { return new eTime(); }
	static ref<eTime> create(const ref<eTime> t) { return new eTime(t); }
	static ref<eTime> create(nat4 t) { return new eTime(t); }
	
	METACLASS_DECLARATIONS(eTime, object);
	};
// end class eTime

//--------------------------------------------------------------------
class SortedNumArray : public ArrayOfInt { 
protected: 
	SortedNumArray(class_descriptor& desc, size_t init_size) 
		: ArrayOfInt(desc, init_size, init_size) {}
public: 
	int	find(int4 num) const;
	int	find_pos(int4 num, int ins) const;
	void ins(int4 num);
	void del(int4 num);
	void setsize(nat4 size) { set_size(size); }
	static ref<SortedNumArray> create(size_t init_size = 0) { 
		return new (self_class, init_size) 
			SortedNumArray(self_class, init_size); 
	}
	METACLASS_DECLARATIONS(SortedNumArray, ArrayOfInt); 
};
// end class SortedNumArray

#endif
