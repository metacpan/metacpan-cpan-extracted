// pogogcls.cxx
// 1999 Sey
#include "pogogcls.h"

//--------------------------------------------------------------------
// p must be a NULL or malloc'ed or realloc'ed pointer
char* eString::get_text_alloc(char*& p) const {
	if( p == NULL )	p = (char*)malloc(used);
	else			p = (char*)realloc(p,used);
	strncpy(p, array, used);
	return p;
}

char* eString::get_text_alloc(char*& p, unsigned& len) const {
	if( p == NULL )	p = (char*)malloc(used);
	else			p = (char*)realloc(p,used);
	memcpy(p, array, used);
	len = used;
	return p;
}

void eString::replace(const char* str) { 
	eString* s = (eString*)set_size(strlen(str)+1);
	strcpy(s->array, str);
}

void eString::replace(const char* str, unsigned len) {
	eString* s = (eString*)set_size(len + 1);
	memcpy(s->array, str, len);
	s->used = len;
	s->array[len] = 0;
}

ref<eString> eString::create(const char* str) { 
	size_t len = strlen(str)+1;
	eString* s = new (self_class, len) eString(self_class, len); 
	strcpy(s->array, str);
	return s;
}

ref<eString> eString::create(const char* str, size_t size) {
	eString* s = new (self_class, size + 1) eString(self_class, size + 1); 
	memcpy(s->array, str, size);
	s->used = size;
	s->array[size] = 0;
	return s;
}

field_descriptor& eString::describe_components() {
    return NO_FIELDS;
}

REGISTER(eString, String, pessimistic_repeatable_read_scheme);

//--------------------------------------------------------------------
field_descriptor& eArray::describe_components() {
    return NO_FIELDS;
}

REGISTER(eArray, ArrayOfObject, pessimistic_repeatable_read_scheme);

//--------------------------------------------------------------------
void eHash::set(const char* name, ref<object> obj) {
	ref<object> value = get(name);
	if( value == NULL ) {
		put(name,obj);
	} else {
		del(name,value);
		put(name,obj);
	}
}

// p must be a NULL or malloc'ed or realloc'ed pointer
char* eHash::first_key(char*& p) const {
	int len;
	ref<hash_item> ip = NULL;
	for(unsigned i = 0; i < size; i++) {
		ip = table[i];
		if( ip != NULL )
			break;
	}
	if( ip != NULL )	len = strlen(ip->name) + 1;
	else				len = 1;
	if( p == NULL )	p = (char*)malloc(len);
	else			p = (char*)realloc(p,len);
	if( ip != NULL )	strcpy(p,ip->name);
	else				*p = '\0';
	if( ip != NULL )	return p;
	else				return NULL;
}

// p must be a NULL or malloc'ed or realloc'ed pointer
char* eHash::next_key(char*& p, const char* key) const {
	int len,end;
	unsigned slot = string_hash_function(key) % size;
	ref<hash_item> ip = table[slot];
	while( ip != NULL ) { 
		if( ip->compare(key) == 0 )
			break;
		ip = ip->next;
	}
	if( ip != NULL ) {
		ip = ip->next;
		if( ip == NULL )
			for(unsigned i = slot + 1; i < size; i++) {
				if( table[i] != NULL ) {
					ip = table[i];
					break;
				}
			}
	}
	if( ip != NULL )	len = strlen(ip->name) + 1;
	else				len = 1;
	if( p == NULL )	p = (char*)malloc(len);
	else			p = (char*)realloc(p,len);
	if( ip != NULL )	strcpy(p,ip->name);
	else				*p = '\0';
	if( ip != NULL )	return p;
	else				return NULL;
}

field_descriptor& eHash::describe_components() {
    return NO_FIELDS;
}

REGISTER(eHash, hash_table, pessimistic_repeatable_read_scheme);

//--------------------------------------------------------------------
// p must be a NULL or malloc'ed or realloc'ed pointer
char* eBtree::first_key(char*& p) const {
	int len;
	
	ref<set_member> m = first;
	if( m != NULL )	len = m->getKeyLength() + 1;
	else			len = 1;
	if( p == NULL )	p = (char*)malloc(len);
	else			p = (char*)realloc(p,len);
	if( m != NULL )	m->copyKeyTo(p, len);
	else			*p = '\0';
	if( m != NULL )	return p;
	else			return NULL;
}

// p must be a NULL or malloc'ed or realloc'ed pointer
char* eBtree::last_key(char*& p) const {
	int len;
	
	ref<set_member> m = last;
	if( m != NULL )	len = m->getKeyLength() + 1;
	else			len = 1;
	if( p == NULL )	p = (char*)malloc(len);
	else			p = (char*)realloc(p,len);
	if( m != NULL )	m->copyKeyTo(p, len);
	else			*p = '\0';
	if( m != NULL )	return p;
	else			return NULL;
}

// p must be a NULL or malloc'ed or realloc'ed pointer
char* eBtree::next_key(char*& p, const char* key) const {
	int len;
	
	ref<set_member> m = find(key);
	if( m != NULL )
		m = m->next;
	if( m != NULL )	len = m->getKeyLength() + 1;
	else			len = 1;
	if( p == NULL )	p = (char*)malloc(len);
	else			p = (char*)realloc(p,len);
	if( m != NULL )	m->copyKeyTo(p, len);
	else			*p = '\0';
	if( m != NULL )	return p;
	else			return NULL;
}

// p must be a NULL or malloc'ed or realloc'ed pointer
char* eBtree::prev_key(char*& p, const char* key) const {
	int len;
	
	ref<set_member> m = find(key);
	if( m != NULL )
		m = m->prev;
	if( m != NULL )	len = m->getKeyLength() + 1;
	else			len = 1;
	if( p == NULL )	p = (char*)malloc(len);
	else			p = (char*)realloc(p,len);
	if( m != NULL )	m->copyKeyTo(p, len);
	else			*p = '\0';
	if( m != NULL )	return p;
	else			return NULL;
}

// p must be a NULL or malloc'ed or realloc'ed pointer
char* eBtree::find_key(char*& p, const char* key) const {
	int len;
	
	ref<set_member> m = findGE(key);
	if( m != NULL )	len = m->getKeyLength() + 1;
	else			len = 1;
	if( p == NULL )	p = (char*)malloc(len);
	else			p = (char*)realloc(p,len);
	if( m != NULL )	m->copyKeyTo(p, len);
	else			*p = '\0';
	if( m != NULL )	return p;
	else			return NULL;
}

field_descriptor& eBtree::describe_components() {
    return NO_FIELDS;
}

REGISTER(eBtree, B_tree, pessimistic_repeatable_read_scheme);

//--------------------------------------------------------------------
int     set_member_numkey::compare(const char* key, size_t) const {
	return int(atol(this->key) - atol(key));
}
int     set_member_numkey::compare(const char* key) const {
	return int(atol(this->key) - atol(key));
}
int     set_member_numkey::compareIgnoreCase(const char* key) const {
	return int(atol(this->key) - atol(key));
}
skey_t  set_member_numkey::get_key() const {
	return str2key(key, size - offsetof(set_member_numkey, key)); 
}
skey_t  set_member_numkey::str2key(const char* s, size_t) {
	return skey_t(atol(s));
}

ref<set_member_numkey> set_member_numkey::create(ref<object> obj, 
	const char* key) {
	size_t key_size = strlen(key) + 1;
	return new (self_class, key_size) 
		set_member_numkey(self_class, obj, key, key_size);
}
ref<set_member_numkey> set_member_numkey::create(ref<object> obj, 
	const char* key, size_t key_size) {
	return new (self_class, key_size) 
		set_member_numkey(self_class, obj, key, key_size);
}

field_descriptor& set_member_numkey::describe_components() {
	return NO_FIELDS;
}

REGISTER(set_member_numkey, set_member, pessimistic_repeatable_read_scheme);

//--------------------------------------------------------------------
ref<set_member> eNtree::find(skey_t key) const {
	return B_tree::find(key);
}
ref<set_member> eNtree::find(const char* str, size_t len, skey_t key) const {
	return B_tree::find(str,len,key);
}
ref<set_member> eNtree::find(const char* str) const {
	size_t len = strlen(str); 
	return find(str, len, set_member_numkey::str2key(str, len)); 
}

ref<set_member> eNtree::findGE(skey_t key) const {
	return B_tree::findGE(key);
}
ref<set_member> eNtree::findGE(const char* str, size_t len, skey_t key) const {
	return B_tree::findGE(str,len,key);
}
ref<set_member> eNtree::findGE(const char* str) const {
	size_t len = strlen(str); 
	return findGE(str, len, set_member_numkey::str2key(str, len)); 
}
// p must be a NULL or malloc'ed or realloc'ed pointer
char* eNtree::next_key(char*& p, const char* key) const {
	int len;
	
	ref<set_member> m = find(key);
	if( m != NULL )
		m = m->next;
	if( m != NULL )	len = m->getKeyLength() + 1;
	else			len = 1;
	if( p == NULL )	p = (char*)malloc(len);
	else			p = (char*)realloc(p,len);
	if( m != NULL )	m->copyKeyTo(p, len);
	else			*p = '\0';
	if( m != NULL )	return p;
	else			return NULL;
}

// p must be a NULL or malloc'ed or realloc'ed pointer
char* eNtree::prev_key(char*& p, const char* key) const {
	int len;
	
	ref<set_member> m = find(key);
	if( m != NULL )
		m = m->prev;
	if( m != NULL )	len = m->getKeyLength() + 1;
	else			len = 1;
	if( p == NULL )	p = (char*)malloc(len);
	else			p = (char*)realloc(p,len);
	if( m != NULL )	m->copyKeyTo(p, len);
	else			*p = '\0';
	if( m != NULL )	return p;
	else			return NULL;
}

// p must be a NULL or malloc'ed or realloc'ed pointer
char* eNtree::find_key(char*& p, const char* key) const {
	int len;
	
	ref<set_member> m = findGE(key);
	if( m != NULL )	len = m->getKeyLength() + 1;
	else			len = 1;
	if( p == NULL )	p = (char*)malloc(len);
	else			p = (char*)realloc(p,len);
	if( m != NULL )	m->copyKeyTo(p, len);
	else			*p = '\0';
	if( m != NULL )	return p;
	else			return NULL;
}
void	eNtree::insert(char const* key, ref<object> obj) {
	B_tree::insert(set_member_numkey::create(obj, key));
}

field_descriptor& eNtree::describe_components() {
	return NO_FIELDS;
}

REGISTER(eNtree, eBtree, pessimistic_repeatable_read_scheme);

//--------------------------------------------------------------------
void eHtree::set(const char* name, ref<object> obj) {
	ref<object> value = get(name);
	if( value == NULL ) {
		put(name,obj);
	} else {
		del(name,value);
		put(name,obj);
	}
}

// p must be a NULL or malloc'ed or realloc'ed pointer
char* eHtree::first_key(char*& p) const {
	int len;
	ref<hash_item> ip = NULL;
	for( unsigned h = 0; h < size; h++ ) {
		int i, j;
		ref<H_page> pg = root;
		for( i = height; --i > 0; ) { 
			if( pg.is_nil() ) break;
			j = (h >> (i*H_page::size_log)) & ((1 << H_page::size_log) - 1);
			pg = pg->p[j];
		}
		if( pg.is_nil() ) continue;
		i = h & ((1 << H_page::size_log) - 1);
		ip = pg->p[i];
		if( ip != NULL ) break;
	}
	
	if( ip != NULL )	len = strlen(ip->name) + 1;
	else				len = 1;
	if( p == NULL )	p = (char*)malloc(len);
	else			p = (char*)realloc(p,len);
	if( ip != NULL )	strcpy(p,ip->name);
	else				*p = '\0';
	if( ip != NULL )	return p;
	else				return NULL;
}

// p must be a NULL or malloc'ed or realloc'ed pointer
char* eHtree::next_key(char*& p, const char* key) const {
	int len;
	ref<hash_item> ip = NULL;
	unsigned h = string_hash_function(key) % size;
	int i, j;
	ref<H_page> pg = root;
	for( i = height; --i > 0; ) { 
		if( pg.is_nil() ) break;
		j = (h >> (i*H_page::size_log)) & ((1 << H_page::size_log) - 1);
		pg = pg->p[j];
	}
	if( !pg.is_nil() ) {
		i = h & ((1 << H_page::size_log) - 1);
		ip = pg->p[i];
		while( ip != NULL ) { 
			if( ip->compare(key) == 0 ) break;
			ip = ip->next;
		}
	}
	if( ip != NULL ) ip = ip->next;
	if( ip == NULL && h + 1 < size ) {
		for( h = h + 1; h < size; h++ ) {
			int i, j;
			ref<H_page> pg = root;
			for( i = height; --i > 0; ) { 
				if( pg.is_nil() ) break;
				j = (h >> (i*H_page::size_log)) & ((1 << H_page::size_log) - 1);
				pg = pg->p[j];
			}
			if( pg.is_nil() ) continue;
			i = h & ((1 << H_page::size_log) - 1);
			ip = pg->p[i];
			if( ip != NULL ) break;
		}
	}

	if( ip != NULL )	len = strlen(ip->name) + 1;
	else				len = 1;
	if( p == NULL )	p = (char*)malloc(len);
	else			p = (char*)realloc(p,len);
	if( ip != NULL )	strcpy(p,ip->name);
	else				*p = '\0';
	if( ip != NULL )	return p;
	else				return NULL;
}

field_descriptor& eHtree::describe_components() {
    return NO_FIELDS;
}

REGISTER(eHtree, H_tree, pessimistic_repeatable_read_scheme);

//--------------------------------------------------------------------
int binary_output_fd = 1;

boolean eBinary::handle() const {
	int output_fd = ::binary_output_fd;
	if( output_fd == 0 )
		output_fd = 1;
	return (size_t)write(output_fd , data, get_size()) == get_size();
}

// This method fails!!! Do NOT use!!!
ref<eBinary> eBinary::create(int input_fd, size_t part_size)
	{
	size_t size;
	eBinary* b = NULL;
	char* buf = (char*)malloc(part_size);
	if( (size = read(input_fd, buf, part_size)) > 0 )
		{
		b = new (self_class, size) eBinary(buf, size);
		while( (size = read(input_fd, buf, part_size)) > 0 ) 
			{
			eBinary* nb = new (self_class, size) eBinary(buf, size);
			b->append(nb);
			}
		}
	free(buf);
	return b;
}

ref<eBinary> eBinary::create(const void* buf, size_t buf_size) { 
	return new (self_class, buf_size) eBinary(buf, buf_size); 
}

field_descriptor& eBinary::describe_components() {
	return NO_FIELDS;
}

REGISTER(eBinary, Blob, pessimistic_repeatable_read_scheme);

// 日時クラス----------------------------------------------------------
char* eTime::strlocal(char* buf) const
	{ 
	struct tm *tmp = localtime((time_t*)(&_time)); 
	sprintf(buf,"%4d/%2d/%2d %2d:%2d:%2d",
		tmp->tm_year + 1900,tmp->tm_mon + 1,tmp->tm_mday,
		tmp->tm_hour,tmp->tm_min,tmp->tm_sec);
	return buf;
	}
// end eTime::strlocal

char* eTime::strgm(char* buf) const
	{ 
	struct tm *tmp = gmtime((time_t*)(&_time)); 
	sprintf(buf,"%4d/%2d/%2d %2d:%2d:%2d",
		tmp->tm_year + 1900,tmp->tm_mon + 1,tmp->tm_mday,
		tmp->tm_hour,tmp->tm_min,tmp->tm_sec);
	return buf;
	}
// end eTime::strgm

int eTime::compare(ref<eTime> const& t) const 
	{ 
	if( _time > t->_time ) return 1; 
	else if( _time == t->_time ) return 0;
	else return -1;
	}
// end eTime::compare

field_descriptor& eTime::describe_components()
	{
	return FIELD(_time);
	}
// end eTime::describe_components

REGISTER(eTime, object, pessimistic_repeatable_read_scheme);

//--------------------------------------------------------------------
int	SortedNumArray::find(int4 num) const { 
	int begin, end, mid;
	if( used == 0 )
		return -1;
	begin = 0;
	end = used - 1;
	while(1) {
		mid = begin + (end - begin) / 2;
		if( array[mid] == num ) {
			return mid;
		} else if( array[mid] > num ) {
			if( array[begin] > num )	return -1;
			if( mid > begin )	end = mid - 1;
			else	return -1;
		} else {
			if( array[end] < num )	return -1;
			if( mid < end )	begin = mid + 1;
			else	return -1;
		}
	}
}
int	SortedNumArray::find_pos(int4 num, int ins = 0) const { 
	int begin, end, mid;
	if( used == 0 ) {
		return 0;
	} else {
		begin = 0;
		end = used - 1;
		while(1) {
			mid = begin + (end - begin) / 2;
			if( array[mid] == num )
				return ins ? -1 : mid;
			else if( array[mid] > num ) {
				if( array[begin] > num )	return begin;
				if( mid > begin )	end = mid - 1;
				else	return begin;
			} else {
				if( array[end] < num )	return end + 1;
				if( mid < end )	begin = mid + 1;
				else	return end + 1;
			}
		}
	}
}
void SortedNumArray::ins(int4 num) {
	int inspos = find_pos(num, 1);
	if( inspos >= 0 )
		insert(inspos, num);
}
void SortedNumArray::del(int4 num) {
	int pos = find(num);
	if( pos >= 0 )
		remove(pos);
}

field_descriptor& SortedNumArray::describe_components() {
	return NO_FIELDS;
}

REGISTER(SortedNumArray, ArrayOfInt, pessimistic_repeatable_read_scheme);
