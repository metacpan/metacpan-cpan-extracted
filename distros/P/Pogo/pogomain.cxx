// pogomain.cxx
// 1999 Sey

#include <stdio.h>
#include <string.h>

#include <goods.h>
#include <dbscls.h>
#include "nstring.h"
#include "pogogcls.h"
#include "pogomain.h"
#include "pogocall.h"

#ifdef POGO_DEBUG
#define D(m)	{m;}
#else
#define D(m)
#endif

// ------------------------------------------------------------------
// Persistent classes corresponding to interface classes
// ------------------------------------------------------------------
pVar::pVar(class_descriptor &desc) : object(desc) {
	pclass = NULL;
	blessclass = NULL;
}
char* pVar::get_class() const {
	if( blessclass == NULL )	return NULL;
	static char* buf = NULL;
	return blessclass->get_text_alloc(buf);
}
void  pVar::set_class(const char* name) {
	if( blessclass == NULL )	blessclass = eString::create(name);
	else modify(blessclass)->replace(name);
}
char* pVar::get_pclass() const {
	if( pclass == NULL )	return NULL;
	static char* buf = NULL;
	return pclass->get_text_alloc(buf);
}
void  pVar::set_pclass(const char* name) {
	if( pclass == NULL )	pclass = eString::create(name);
	else modify(pclass)->replace(name);
}
callresult  pVar::_call(void* func, void* argref) {
	return _pogo_call_sv(func, argref);
}

field_descriptor& pVar::describe_components() {
	return
		FIELD(pclass),
		FIELD(blessclass);
}

REGISTER(pVar, object, pessimistic_repeatable_read_scheme);

// ------------------------------------------------------------------
pScalar::pScalar() : pVar(self_class) {
	value = NULL;
}
ref<object> pScalar::get() const { return value; }
void pScalar::set(ref<object> val) { 
	value = val; 
}

field_descriptor& pScalar::describe_components() {
	return
		FIELD(value);
}

REGISTER(pScalar, pVar, pessimistic_repeatable_read_scheme);

// ------------------------------------------------------------------
// pString is not used
#if 0
pString::pString(const char* str) : pVar(self_class) {
	if( str != NULL ) {
		string = eString::create(str);
	} else {
		string = eString::create("");
	}
}
pString::pString(const nstring* str) : pVar(self_class) {
	if( str != NULL ) {
		string = eString::create(str->str, str->len);
	} else {
		string = eString::create("");
	}
}
nstring* pString::get() const {
	static nstring buf;
	string->get_text_alloc(buf.str, buf.len);
	return &buf;
}
void  pString::set(const char* str) {
	modify(string)->replace(str);
}
void  pString::set(const nstring* str) {
	modify(string)->replace(str->str, str->len);
}

field_descriptor& pString::describe_components() {
	return
		FIELD(string);
}

REGISTER(pString, pVar, pessimistic_repeatable_read_scheme);
#endif
// ------------------------------------------------------------------
pArray::pArray(unsigned size) : pVar(self_class) {
	array = eArray::create(size_t(size));
}
ref<object> pArray::get(unsigned idx) const {
	if( idx >= array->length() )	return NULL;
	return array->getat(nat4(idx));
}
void     pArray::set(unsigned idx, ref<object> val) {
	modify(array)->putat(nat4(idx), val);
}
unsigned      pArray::get_size() const {
	return array->length();
}
void     pArray::set_size(unsigned size) {
	modify(array)->setsize(nat4(size));
}
void     pArray::clear() {
	modify(array)->setsize(0);
}
void     pArray::push(ref<object> val) {
	modify(array)->push(val);
}
ref<object> pArray::pop() {
	if( array->length() > 0 )	return modify(array)->pop();
	else	return NULL;
}
void     pArray::insert(unsigned idx, ref<object> val) {
	if( idx <= array->length() )
		modify(array)->insert(nat4(idx), val);
}
ref<object> pArray::remove(unsigned idx) {
	ref<object> val = NULL;
	if( idx < array->length() ) {
		val = array->getat(nat4(idx));
		modify(array)->remove(nat4(idx));
	}
	return val;
}

field_descriptor& pArray::describe_components() {
	return
		FIELD(array);
}

REGISTER(pArray, pVar, pessimistic_repeatable_read_scheme);

// ------------------------------------------------------------------
pHash::pHash(unsigned size) : pVar(self_class) {
	hash = eHash::create(size);
}
ref<object> pHash::get(const char* key) const {
	return hash->get(key);
}
void     pHash::set(const char* key, ref<object> val) {
	modify(hash)->set(key, val);
}
int      pHash::exists(const char* key) const {
	return hash->get(key) != NULL ? 1 : 0;
}
ref<object> pHash::remove(const char* key) {
	ref<object> val = hash->get(key);
	if( val != NULL )	modify(hash)->del(key, val);
	return val;
}
void     pHash::clear() {
	modify(hash)->reset();
}
char*    pHash::first_key() const {
	static char* buf = NULL;
	return hash->first_key(buf);
}
char*    pHash::next_key(const char* key) const {
	static char* buf = NULL;
	return hash->next_key(buf, key);
}

field_descriptor& pHash::describe_components() {
	return
		FIELD(hash);
}

REGISTER(pHash, pVar, pessimistic_repeatable_read_scheme);

// ------------------------------------------------------------------
pBtree::pBtree() : pVar(self_class) {
	btree = eBtree::create();
}
ref<object> pBtree::get(const char* key) const {
	ref<set_member> m = btree->find(key);
	if( m == NULL ) return NULL;
	return m->obj;
}
void     pBtree::set(const char* key, ref<object> val) {
	ref<set_member> m = btree->find(key);
	if( m == NULL ) {
		modify(btree)->insert(key, val);
	} else if( m->obj != val ) {
		modify(btree)->remove(m);
		modify(btree)->insert(key, val);
	}
}
int      pBtree::exists(const char* key) const {
	ref<set_member> m = btree->find(key);
	return m != NULL ? 1 : 0;
}
ref<object> pBtree::remove(const char* key) {
	ref<set_member> m = btree->find(key);
	if( m == NULL ) return NULL;
	modify(btree)->remove(m);
	return m->obj;
}
void     pBtree::clear() {
	modify(btree)->reset();
}
char*    pBtree::first_key() const {
	static char* buf = NULL;
	return btree->first_key(buf);
}
char*    pBtree::last_key() const {
	static char* buf = NULL;
	return btree->last_key(buf);
}
char*    pBtree::next_key(const char* key) const {
	static char* buf = NULL;
	return btree->next_key(buf, key);
}
char*    pBtree::prev_key(const char* key) const {
	static char* buf = NULL;
	return btree->prev_key(buf, key);
}
char*    pBtree::find_key(const char* key) const {
	static char* buf = NULL;
	return btree->find_key(buf, key);
}

// initialization for the database root object
void pBtree::initialize() const {
	D(printf("pBtree::initialize()\n"))
	if( is_abstract_root() ) {
		ref<pBtree> root = this;
		modify(root)->become(new pBtree());
		modify(root)->set_pclass("Pogo::Btree");
		D(printf("root becomes pBtree\n"))
	}
}

field_descriptor& pBtree::describe_components() {
	return
		FIELD(btree);
}

REGISTER(pBtree, pVar, pessimistic_repeatable_read_scheme);

// ------------------------------------------------------------------
pNtree::pNtree() : pVar(self_class) {
	ntree = eNtree::create();
}
ref<object> pNtree::get(const char* key) const {
	ref<set_member> m = ntree->find(key);
	if( m == NULL ) return NULL;
	return m->obj;
}
void     pNtree::set(const char* key, ref<object> val) {
	ref<set_member> m = ntree->find(key);
	if( m == NULL ) {
		modify(ntree)->insert(key, val);
	} else if( m->obj != val ) {
		modify(ntree)->remove(m);
		modify(ntree)->insert(key, val);
	}
}
int      pNtree::exists(const char* key) const {
	ref<set_member> m = ntree->find(key);
	return m != NULL ? 1 : 0;
}
ref<object> pNtree::remove(const char* key) {
	ref<set_member> m = ntree->find(key);
	if( m == NULL ) return NULL;
	modify(ntree)->remove(m);
	return m->obj;
}
void     pNtree::clear() {
	modify(ntree)->reset();
}
char*    pNtree::first_key() const {
	static char* buf = NULL;
	return ntree->first_key(buf);
}
char*    pNtree::last_key() const {
	static char* buf = NULL;
	return ntree->last_key(buf);
}
char*    pNtree::next_key(const char* key) const {
	static char* buf = NULL;
	return ntree->next_key(buf, key);
}
char*    pNtree::prev_key(const char* key) const {
	static char* buf = NULL;
	return ntree->prev_key(buf, key);
}
char*    pNtree::find_key(const char* key) const {
	static char* buf = NULL;
	return ntree->find_key(buf, key);
}

field_descriptor& pNtree::describe_components() {
	return
		FIELD(ntree);
}

REGISTER(pNtree, pVar, pessimistic_repeatable_read_scheme);

// ------------------------------------------------------------------
pHtree::pHtree(unsigned size) : pVar(self_class) {
	htree = eHtree::create(size);
}
ref<object> pHtree::get(const char* key) const {
	return htree->get(key);
}
void     pHtree::set(const char* key, ref<object> val) {
	modify(htree)->set(key, val);
}
int      pHtree::exists(const char* key) const {
	return htree->get(key) != NULL ? 1 : 0;
}
ref<object> pHtree::remove(const char* key) {
	ref<object> val = htree->get(key);
	if( val != NULL )	modify(htree)->del(key, val);
	return val;
}
void     pHtree::clear() {
	modify(htree)->reset();
}
char*    pHtree::first_key() const {
	static char* buf = NULL;
	return htree->first_key(buf);
}
char*    pHtree::next_key(const char* key) const {
	static char* buf = NULL;
	return htree->next_key(buf, key);
}

field_descriptor& pHtree::describe_components() {
	return
		FIELD(htree);
}

REGISTER(pHtree, pVar, pessimistic_repeatable_read_scheme);

// ------------------------------------------------------------------
pSortedNumArray::pSortedNumArray(unsigned size) : pVar(self_class) {
	snarray = SortedNumArray::create(size_t(size));
}
int     pSortedNumArray::get(unsigned idx) const {
	if( idx >= snarray->length() )	return 0L;
	return snarray->getat(nat4(idx));
}
int      pSortedNumArray::find(int val) const {
	return snarray->find(int4(val));
}
int      pSortedNumArray::findGE(int val) const {
	return snarray->find_pos(int4(val), 0);
}
void     pSortedNumArray::set(int val) {
	modify(snarray)->ins(int4(val));
}
void     pSortedNumArray::ins(int val) {
	modify(snarray)->ins(int4(val));
}
void     pSortedNumArray::del(int val) {
	modify(snarray)->del(int4(val));
}
unsigned      pSortedNumArray::get_size() const {
	return snarray->length();
}
void     pSortedNumArray::set_size(unsigned size) {
	modify(snarray)->setsize(nat4(size));
}
void     pSortedNumArray::clear() {
	modify(snarray)->setsize(0);
}

field_descriptor& pSortedNumArray::describe_components() {
	return
		FIELD(snarray);
}

REGISTER(pSortedNumArray, pVar, pessimistic_repeatable_read_scheme);

// ------------------------------------------------------------------
// Perl interface classes (non persistent)
// ------------------------------------------------------------------
char* Pvar::perl_class() const { return this->_perl_class(); }
/* These 'ref<pVar>()' castings are not elegant. If 'this->strip()' returns
   ref<eString>, it will crash! It means that Pstring object cannot call 
   get_class() and set_class(). This dangerous situation may not ocurr because
   Pstring object is only used as internal temporary interface.
*/
char* Pvar::get_class() const { 
	ref<pVar> var = this->strip();
	return var->get_class(); 
}
void  Pvar::set_class(const char* name) { 
	ref<pVar> var = this->strip();
	modify(var)->set_class(name); 
}
char* Pvar::get_pclass() const { 
	ref<pVar> var = this->strip();
	return var->get_pclass(); 
}
void  Pvar::set_pclass(const char* name) { 
	ref<pVar> var = this->strip();
	modify(var)->set_pclass(name); 
}
callresult   Pvar::_call(void* func, void* argref) {
	ref<pVar> var = this->strip();
	return modify(var)->_call(func, argref); 
}
int   Pvar::_equal(const Pvar* var) {
	return var != NULL ? (this->strip() == var->strip() ? 1 : 0) : 0;
}
int   Pvar::wait_modification(unsigned sec) {
	event	modified;
	int result;
	modified.reset();
	this->strip()->signal_on_modification(modified);
	if( sec ) {
		result = modified.wait_with_timeout((time_t)sec);
	} else {
		modified.wait();
		result = 1;
	}
	return result;
}
unsigned Pvar::object_id() {
	return this->strip()->get_handle()->opid;
}

void  Pvar::begin_transaction() { modify(this->strip())->begin_transaction(); }
void  Pvar::abort_transaction() { modify(this->strip())->abort_transaction(); }
void  Pvar::end_transaction() { modify(this->strip())->end_transaction(); }

Pvar* Pvar::root() {
	database* db = (database *)this->strip()->get_database();
	if( db == NULL ) 
		return NULL;
	ref<pBtree> rootbtree;
	db->get_root(rootbtree);
	return wrap(rootbtree);
}

// ------------------------------------------------------------------
Pstring::Pstring(const nstring* str, Pogo* pogo = NULL) {
	if( str == NULL ) string = NULL;
	else { 
		string = eString::create(str); 
		if( pogo != NULL ) string->attach_to_storage(pogo->db, 0);
	}
	D(printf("Pstring created\n"))
}
Pstring::Pstring(const nstring* str, Pvar* pvar) {
	if( str == NULL ) string = NULL;
	else { 
		string = eString::create(str); 
		if( pvar != NULL ) {
			ref<object> pvarobj = pvar->strip();
			if( pvarobj->get_database() ) {
				string->cluster_with(pvarobj);
			}
		}
	}
	D(printf("Pstring created\n"))
}
Pstring::~Pstring() {
	D(printf("Pstring destroyed\n"))
}
nstring* Pstring::get() const { 
	static nstring buf;
	if( string == NULL ) { buf.str = NULL; buf.len = 0; }
	else string->get_text_alloc(&buf);
	return &buf;
}
void     Pstring::set(const nstring* str) { 
	if( str == NULL ) string = NULL;
	else if( string == NULL ) string = eString::create(str);
	else modify(string)->replace(str); 
}

char* Pstring::_perl_class() const { return perl_class(); }
char* Pstring::perl_class() const { return "_string"; }
// Pstring is an internal temporary class, so to be destroyed at strip()
ref<object> Pstring::strip() const { 
	ref<eString> estr = string;
	delete this;
	return estr; 
}
Pstring::Pstring(ref<eString> estr) { string = estr; }

// ------------------------------------------------------------------
Pscalar::Pscalar(Pogo* pogo = NULL) {
	scalar = pScalar::create();
	if( pogo != NULL ) scalar->attach_to_storage(pogo->db, 0);
	D(printf("Pscalar created\n"))
}
Pscalar::Pscalar(Pvar* pvar) {
	scalar = pScalar::create();
	if( pvar != NULL ) {
		ref<object> pvarobj = pvar->strip();
		if( pvarobj->get_database() ) {
			scalar->cluster_with(pvarobj);
		}
	}
	D(printf("Pscalar created\n"))
}
Pscalar::~Pscalar() {
	D(printf("Pscalar destroyed\n"))
}
Pvar*    Pscalar::get() const { 
	ref<object> val = scalar->get();
	if( val == NULL ) return NULL;
	return wrap(val);
}
void     Pscalar::set(const Pvar* val) {
	modify(scalar)->set(val->strip());
}
void     Pscalar::set(const nstring* str) {
	modify(scalar)->set(eString::create(str));
}

char*    Pscalar::_perl_class() const { return perl_class(); }
char*    Pscalar::perl_class() const { return get_pclass(); }
ref<object> Pscalar::strip() const { return scalar; }
Pscalar::Pscalar(ref<pScalar> pscalar) { scalar = pscalar; }

// ------------------------------------------------------------------
Parray::Parray(unsigned size, Pogo* pogo = NULL) { 
	array = pArray::create(size); 
	if( pogo != NULL ) array->attach_to_storage(pogo->db, 0);
	D(printf("Parray created\n"))
}
Parray::Parray(unsigned size, Pvar* pvar) { 
	array = pArray::create(size); 
	if( pvar != NULL ) {
		ref<object> pvarobj = pvar->strip();
		if( pvarobj->get_database() ) {
			array->cluster_with(pvarobj);
		}
	}
	D(printf("Parray created\n"))
}
Parray::~Parray() {
	D(printf("Parray destroyed\n"))
}
Pvar*    Parray::get(unsigned idx) const { 
	ref<object> val = array->get(idx);
	if( val == NULL ) return NULL;
	return wrap(val);
}
void     Parray::set(unsigned idx, const Pvar* val) { 
	modify(array)->set(idx, val->strip()); 
}
void     Parray::set(unsigned idx, const nstring* str) { 
	modify(array)->set(idx, eString::create(str)); 
}
unsigned Parray::get_size() const { return array->get_size(); }
void     Parray::set_size(unsigned size) { modify(array)->set_size(size); }
void     Parray::clear() { modify(array)->clear(); }
void     Parray::push(const Pvar* val) { modify(array)->push(val->strip()); }
void     Parray::push(const nstring* str) { modify(array)->push(eString::create(str)); }
Pvar*    Parray::pop() {
	ref<object> val = modify(array)->pop();
	if( val == NULL ) return NULL;
	return wrap(val);
}
void     Parray::insert(unsigned idx, const Pvar* val) { 
	modify(array)->insert(idx, val->strip()); 
}
void     Parray::insert(unsigned idx, const nstring* str) { 
	modify(array)->insert(idx, eString::create(str)); 
}
Pvar*    Parray::remove(unsigned idx) {
	ref<object> val = modify(array)->remove(idx);
	if( val == NULL ) return NULL;
	return wrap(val);
}

char* Parray::_perl_class() const { return perl_class(); }
char* Parray::perl_class() const { return get_pclass(); }
ref<object> Parray::strip() const { return array; }
Parray::Parray(ref<pArray> parr) { array = parr; }

// ------------------------------------------------------------------
Phash::Phash(unsigned size, Pogo* pogo = NULL) { 
	hash = pHash::create(size); 
	if( pogo != NULL ) hash->attach_to_storage(pogo->db, 0);
	D(printf("Phash created\n"))
}
Phash::Phash(unsigned size, Pvar* pvar) { 
	hash = pHash::create(size); 
	if( pvar != NULL ) {
		ref<object> pvarobj = pvar->strip();
		if( pvarobj->get_database() ) {
			hash->cluster_with(pvarobj);
		}
	}
	D(printf("Phash created\n"))
}
Phash::~Phash() {
	D(printf("Phash destroyed\n"))
}
Pvar*    Phash::get(const char* key) const {
	ref<object> val = hash->get(key);
	if( val == NULL ) return NULL;
	return wrap(val);
}
void     Phash::set(const char* key, const Pvar* val) { 
	modify(hash)->set(key, val->strip()); 
}
void     Phash::set(const char* key, const nstring* str) { 
	modify(hash)->set(key, eString::create(str)); 
}
int      Phash::exists(const char* key) const { return hash->exists(key); }
Pvar*    Phash::remove(const char* key) {
	ref<object> val = modify(hash)->remove(key);
	if( val == NULL ) return NULL;
	return wrap(val);
}
void     Phash::clear() { modify(hash)->clear(); }
char*    Phash::first_key() const { return hash->first_key(); }
char*    Phash::next_key(const char* key) const { return hash->next_key(key); }

char* Phash::_perl_class() const { return perl_class(); }
char* Phash::perl_class() const { return get_pclass(); }
ref<object> Phash::strip() const { return hash; }
Phash::Phash(ref<pHash> phash) { hash = phash; }

// ------------------------------------------------------------------
Phtree::Phtree(unsigned size, Pogo* pogo = NULL) { 
	htree = pHtree::create(size); 
	if( pogo != NULL ) htree->attach_to_storage(pogo->db, 0);
	D(printf("Phtree created\n"))
}
Phtree::Phtree(unsigned size, Pvar* pvar) { 
	htree = pHtree::create(size); 
	if( pvar != NULL ) {
		ref<object> pvarobj = pvar->strip();
		if( pvarobj->get_database() ) {
			htree->cluster_with(pvarobj);
		}
	}
	D(printf("Phtree created\n"))
}
Phtree::~Phtree() {
	D(printf("Phtree destroyed\n"))
}
Pvar*    Phtree::get(const char* key) const {
	ref<object> val = htree->get(key);
	if( val == NULL ) return NULL;
	return wrap(val);
}
void     Phtree::set(const char* key, const Pvar* val) { 
	modify(htree)->set(key, val->strip()); 
}
void     Phtree::set(const char* key, const nstring* str) { 
	modify(htree)->set(key, eString::create(str)); 
}
int      Phtree::exists(const char* key) const { return htree->exists(key); }
Pvar*    Phtree::remove(const char* key) {
	ref<object> val = modify(htree)->remove(key);
	if( val == NULL ) return NULL;
	return wrap(val);
}
void     Phtree::clear() { modify(htree)->clear(); }
char*    Phtree::first_key() const { return htree->first_key(); }
char*    Phtree::next_key(const char* key) const { return htree->next_key(key); }

char* Phtree::_perl_class() const { return perl_class(); }
char* Phtree::perl_class() const { return get_pclass(); }
ref<object> Phtree::strip() const { return htree; }
Phtree::Phtree(ref<pHtree> phtree) { htree = phtree; }

// ------------------------------------------------------------------
Pbtree::Pbtree(Pogo* pogo = NULL) { 
	btree = pBtree::create(); 
	if( pogo != NULL ) btree->attach_to_storage(pogo->db, 0);
	D(printf("Pbtree created\n"))
}
Pbtree::Pbtree(Pvar* pvar) { 
	btree = pBtree::create(); 
	if( pvar != NULL ) {
		ref<object> pvarobj = pvar->strip();
		if( pvarobj->get_database() ) {
			btree->cluster_with(pvarobj);
		}
	}
	D(printf("Pbtree created\n"))
}
Pbtree::~Pbtree() {
	D(printf("Pbtree destroyed\n"))
}
Pvar*    Pbtree::get(const char* key) const {
	ref<object> val = btree->get(key);
	if( val == NULL ) return NULL;
	return wrap(val);
}
void     Pbtree::set(const char* key, const Pvar* val) { 
	modify(btree)->set(key, val->strip()); 
}
void     Pbtree::set(const char* key, const nstring* str) { 
	modify(btree)->set(key, eString::create(str)); 
}
int      Pbtree::exists(const char* key) const { return btree->exists(key); }
Pvar*    Pbtree::remove(const char* key) {
	ref<object> val = modify(btree)->remove(key);
	if( val == NULL ) return NULL;
	return wrap(val);
}
void     Pbtree::clear() { modify(btree)->clear(); }
char*    Pbtree::first_key() const { return btree->first_key(); }
char*    Pbtree::last_key() const { return btree->last_key(); }
char*    Pbtree::next_key(const char* key) const { return btree->next_key(key); }
char*    Pbtree::prev_key(const char* key) const { return btree->prev_key(key); }
char*    Pbtree::find_key(const char* key) const { return btree->find_key(key); }

char* Pbtree::_perl_class() const { return perl_class(); }
char* Pbtree::perl_class() const { return get_pclass(); }
ref<object> Pbtree::strip() const { return btree; }
Pbtree::Pbtree(ref<pBtree> pbtree) { btree = pbtree; }

// ------------------------------------------------------------------
Pntree::Pntree(Pogo* pogo = NULL) { 
	ntree = pNtree::create(); 
	if( pogo != NULL ) ntree->attach_to_storage(pogo->db, 0);
	D(printf("Pntree created\n"))
}
Pntree::Pntree(Pvar* pvar) { 
	ntree = pNtree::create(); 
	if( pvar != NULL ) {
		ref<object> pvarobj = pvar->strip();
		if( pvarobj->get_database() ) {
			ntree->cluster_with(pvarobj);
		}
	}
	D(printf("Pntree created\n"))
}
Pntree::~Pntree() {
	D(printf("Pntree destroyed\n"))
}
Pvar*    Pntree::get(const char* key) const {
	ref<object> val = ntree->get(key);
	if( val == NULL ) return NULL;
	return wrap(val);
}
void     Pntree::set(const char* key, const Pvar* val) { 
	modify(ntree)->set(key, val->strip()); 
}
void     Pntree::set(const char* key, const nstring* str) { 
	modify(ntree)->set(key, eString::create(str)); 
}
int      Pntree::exists(const char* key) const { return ntree->exists(key); }
Pvar*    Pntree::remove(const char* key) {
	ref<object> val = modify(ntree)->remove(key);
	if( val == NULL ) return NULL;
	return wrap(val);
}
void     Pntree::clear() { modify(ntree)->clear(); }
char*    Pntree::first_key() const { return ntree->first_key(); }
char*    Pntree::last_key() const { return ntree->last_key(); }
char*    Pntree::next_key(const char* key) const { return ntree->next_key(key); }
char*    Pntree::prev_key(const char* key) const { return ntree->prev_key(key); }
char*    Pntree::find_key(const char* key) const { return ntree->find_key(key); }
char* Pntree::_perl_class() const { return perl_class(); }
char* Pntree::perl_class() const { return get_pclass(); }
ref<object> Pntree::strip() const { return ntree; }
Pntree::Pntree(ref<pNtree> pntree) { ntree = pntree; }

// ------------------------------------------------------------------
Psnarray::Psnarray(unsigned size, Pogo* pogo = NULL) { 
	snarray = pSortedNumArray::create(size); 
	if( pogo != NULL ) snarray->attach_to_storage(pogo->db, 0);
	D(printf("Psnarray created\n"))
}
Psnarray::Psnarray(unsigned size, Pvar* pvar) { 
	snarray = pSortedNumArray::create(size); 
	if( pvar != NULL ) {
		ref<object> pvarobj = pvar->strip();
		if( pvarobj->get_database() ) {
			snarray->cluster_with(pvarobj);
		}
	}
	D(printf("Psnarray created\n"))
}
Psnarray::~Psnarray() {
	D(printf("Psnarray destroyed\n"))
}
int     Psnarray::get(unsigned idx) const { return snarray->get(idx); }
int      Psnarray::find(int val) const { return snarray->find(val); }
int      Psnarray::findGE(int val) const { return snarray->findGE(val); }
void     Psnarray::set(int val) { modify(snarray)->set(val); }
void     Psnarray::ins(int val) { modify(snarray)->ins(val); }
void     Psnarray::del(int val) { modify(snarray)->del(val); }
unsigned Psnarray::get_size() const { return snarray->get_size(); }
void     Psnarray::set_size(unsigned size) { modify(snarray)->set_size(size); }
void     Psnarray::clear() { modify(snarray)->clear(); }

char* Psnarray::_perl_class() const { return perl_class(); }
char* Psnarray::perl_class() const { return get_pclass(); }
ref<object> Psnarray::strip() const { return snarray; }
Psnarray::Psnarray(ref<pSortedNumArray> psnarr) { snarray = psnarr; }


// wrap() (convert ref<object> to Pvar*)
Pvar* wrap(ref<object> val) {
	if( val == NULL ) return NULL;
	if( val->cls.ctid == eString::self_class.ctid ) {
		return new Pstring(ref<eString>(val));
	} else if( val->cls.ctid == pScalar::self_class.ctid ) {
		return new Pscalar(ref<pScalar>(val));
	} else if( val->cls.ctid == pArray::self_class.ctid ) {
		return new Parray(ref<pArray>(val));
	} else if( val->cls.ctid == pHash::self_class.ctid ) {
		return new Phash(ref<pHash>(val));
	} else if( val->cls.ctid == pHtree::self_class.ctid ) {
		return new Phtree(ref<pHtree>(val));
	} else if( val->cls.ctid == pBtree::self_class.ctid ) {
		return new Pbtree(ref<pBtree>(val));
	} else if( val->cls.ctid == pNtree::self_class.ctid ) {
		return new Pntree(ref<pNtree>(val));
	} else if( val->cls.ctid == pSortedNumArray::self_class.ctid ) {
		return new Psnarray(ref<pSortedNumArray>(val));
	}
	return NULL;
}
Pstring* wrap(ref<eString> val) {
	if( val == NULL ) return NULL;
	return new Pstring(val);
}
Pscalar* wrap(ref<pScalar> val) {
	if( val == NULL ) return NULL;
	return new Pscalar(val);
}
Parray* wrap(ref<pArray> val) {
	if( val == NULL ) return NULL;
	return new Parray(val);
}
Phash* wrap(ref<pHash> val) {
	if( val == NULL ) return NULL;
	return new Phash(val);
}
Phtree* wrap(ref<pHtree> val) {
	if( val == NULL ) return NULL;
	return new Phtree(val);
}
Pbtree* wrap(ref<pBtree> val) {
	if( val == NULL ) return NULL;
	return new Pbtree(val);
}
Pntree* wrap(ref<pNtree> val) {
	if( val == NULL ) return NULL;
	return new Pntree(val);
}
Psnarray* wrap(ref<pSortedNumArray> val) {
	if( val == NULL ) return NULL;
	return new Psnarray(val);
}

// Pogo
Pogo::Pogo(const char* cfgfile = NULL) {
	initialize();
	db = new database();
	fopened = 0;
	rootbtree = NULL;
	D(printf("Pogo created\n"))
	if( cfgfile ) open(cfgfile);
}
Pogo::~Pogo() {
	close();
	delete db;
	D(printf("Pogo destroyed\n"))
}
int     Pogo::open(const char* cfgfile) {
	close();
	boolean ret = db->open(cfgfile);
	if( ret ) {
		D(printf("Pogo opened(%s)\n", cfgfile))
		fopened = 1;
		db->get_root(rootbtree);
		rootbtree->initialize();
		return 1;
	}
	D(printf("Pogo fails to open(%s)\n", cfgfile))
	return 0;
}
void     Pogo::close() {
	if( fopened ) {
		rootbtree = NULL;
		db->close();
		fopened = 0;
	}
}
int      Pogo::opened() const { return fopened; }

Pvar*    Pogo::root() {
	return wrap(rootbtree);
}
void     Pogo::begin_transaction() {
	if( rootbtree != NULL )	modify(rootbtree)->begin_transaction();
}
void     Pogo::abort_transaction() {
	if( rootbtree != NULL )	modify(rootbtree)->abort_transaction();
}
void     Pogo::end_transaction() {
	if( rootbtree != NULL )	modify(rootbtree)->end_transaction();
}
char*    Pogo::perl_class() const { return "Pogo"; }

void Pogo::initialize() {
	if( !task_initialized ) {
		task::initialize(task::huge_stack);
		task_initialized = 1;
		D(printf("task initialized\n"))
	}
}

int Pogo::task_initialized = 0;

#ifdef GLOBALDB
Pogo POGOOBJ;
Pogo* Pogo::POGOOBJ() {
	return &::POGOOBJ;
}
#endif
