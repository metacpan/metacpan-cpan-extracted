/* 

$Id: array.c,v 1.11 2010/12/06 09:25:27 dk Exp $ 

Implemenmtation of PHP::TieHash and PHP::TieArray methods

*/

#include "PHP.h"

#ifdef __cplusplus
extern "C" {
#endif

XS(PHP_ArrayHandle_new)
{
	dXSARGS;
	STRLEN na;
	zval * array;
	
	if ( items != 1)
		croak("PHP::ArrayHandle::new: 1 parameter expected");

	SP -= items;

	MAKE_STD_ZVAL( array);
	array_init( array);

	XPUSHs( sv_2mortal( Entity_create( SvPV( ST(0), na), array)));
	PUTBACK;
	ZVAL_DELREF( array);
	return;
}

XS( PHP_TieHash_EXISTS)
{
	dXSARGS;
	char * key;
	STRLEN na, klen;
	zval * array;

#define METHOD "PHP::TieHash::EXISTS"
	if ( items != 2) 
		croak("%s: expect 2 parameters", METHOD);

	if (( array = SV2ZANY( ST(0))) == NULL)
		croak("%s: (%s) is not a PHP array", METHOD, SvPV(ST(0), na));

	key = SvPV( ST(1), klen);
	DEBUG("exists 0x%x->{%s}", array, key);

	SP -= items;
	PUTBACK;

	return XSRETURN_IV( zend_hash_exists( HASH_OF(array), key, klen + 1));
#undef METHOD
}

XS( PHP_TieHash_FETCH)
{
	dXSARGS;
	char * key;
	STRLEN na, klen;
	zval * array, **zobj;
	SV * retsv;

#define METHOD "PHP::TieHash::FETCH"
	if ( items != 2) 
		croak("%s: expect 2 parameters", METHOD);

	if (( array = SV2ZANY( ST(0))) == NULL)
		croak("%s: (%s) is not a PHP array", METHOD, SvPV(ST(0), na));

	key = SvPV( ST(1), klen);
	DEBUG("fetch 0x%x->{%s}", array, key);

	SP -= items;

	if ( zend_hash_find( HASH_OF(array), key, klen + 1, (void**) &zobj) == FAILURE) {
		XPUSHs( &PL_sv_undef);
		PUTBACK;
		return;
	}

	if ( !( retsv = zval2sv( *zobj))) {
		warn("%s: value cannot be converted\n", METHOD);
		retsv = &PL_sv_undef;
	}
	retsv = sv_2mortal( retsv);
	XPUSHs( retsv);

#undef METHOD
	PUTBACK;

	return;
}

XS( PHP_TieHash_STORE)
{
	dXSARGS;
	char * key;
	STRLEN na, klen;
	zval * array, *zobj;
	SV * val;

#define METHOD "PHP::TieHash::STORE"
	if ( items != 3) 
		croak("%s: expect 3 parameters", METHOD);

	if (( array = SV2ZANY( ST(0))) == NULL)
		croak("%s: (%s) is not a PHP array", METHOD, SvPV(ST(0), na));

	key = SvPV( ST(1), klen);
	DEBUG("store 0x%x->{%s}=%s", array, key, SvPV( ST(2), na));

	MAKE_STD_ZVAL( zobj);
	zobj-> type = IS_NULL;
	if ( !sv2zval( val = ST(2), zobj, -1)) {
		zval_ptr_dtor( &zobj);
		croak("%s: scalar (%s) type=%d cannot be converted", 
			METHOD, SvPV( val, na), SvTYPE( val));
	}

	if ( zend_hash_update( 
		HASH_OF(array), key, klen + 1,
		(void *)&zobj, sizeof(zval *), NULL
		) == FAILURE) {
		zval_ptr_dtor( &zobj);
		croak("%s: failed", METHOD);
	}

#undef METHOD
	SP -= items;
	PUTBACK;
	XSRETURN_EMPTY;
}

XS( PHP_TieHash_DELETE)
{
	dXSARGS;
	char * key;
	STRLEN na, klen;
	zval * array;

#define METHOD "PHP::TieHash::DELETE"
	if ( items != 2) 
		croak("%s: expect 2 parameters", METHOD);

	if (( array = SV2ZANY( ST(0))) == NULL)
		croak("%s: (%s) is not a PHP array", METHOD, SvPV(ST(0), na));

	key = SvPV( ST(1), klen);
	DEBUG("delete 0x%x->{%s}", array, key);

	SP -= items;
	PUTBACK;

	zend_hash_del( HASH_OF(array), key, klen + 1);

	XSRETURN_EMPTY;
#undef METHOD
}

XS( PHP_TieHash_CLEAR)
{
	dXSARGS;
	STRLEN na;
	zval * array;

#define METHOD "PHP::TieHash::CLEAR"
	if ( items != 1) 
		croak("%s: expect 1 parameter", METHOD);

	if (( array = SV2ZANY( ST(0))) == NULL)
		croak("%s: (%s) is not a PHP array", METHOD, SvPV(ST(0), na));

	DEBUG("clear 0x%x", array);

	SP -= items;
	PUTBACK;

	zend_hash_clean( HASH_OF(array));

	XSRETURN_EMPTY;
#undef METHOD
}

/* for internal use by FIRSTKEY and NEXTKEY - construct return value and advance zhash ptr  */
static SV *
do_zenum( 
	char * method,
	zval * array,
	HashPosition * hpos
) {
	SV * ret;
	int rettype;
	unsigned int klen;
	unsigned long numkey;
	char * key;

	if ( ( rettype = zend_hash_get_current_key_ex( HASH_OF(array), 
		&key, &klen, &numkey, 0, hpos)) == HASH_KEY_NON_EXISTANT) {
		DEBUG( "%s: enum stop", method);
		return &PL_sv_undef;
	}
	
	if ( rettype == HASH_KEY_IS_STRING) {
		ret = newSVpvn( key, klen - 1); 
		DEBUG( "%s: enum %s", method, key);
	} else {
		ret = newSViv( numkey); 
		DEBUG( "%s: enum index %d", method, numkey);
	}

	return sv_2mortal( ret);
}

XS( PHP_TieHash_FIRSTKEY)
{
	dXSARGS;
	zval * array;
	STRLEN na;
	SV * hash_position, * perl_obj;
	HashPosition hpos_buf, *hpos;

#define METHOD "PHP::TieHash::FIRSTKEY"
	if ( items != 1) 
		croak("%s: expect 1 parameter", METHOD);

	if (( array = SV2ZANY( perl_obj = ST(0))) == NULL)
		croak("%s: (%s) is not a PHP array", METHOD, SvPV( perl_obj, na));

	DEBUG("firstkey 0x%x", array);

	hash_position = newSV( sizeof( HashPosition));
        sv_setpvn( hash_position, ( char *) &hpos_buf, sizeof( hpos_buf));
	hpos = ( HashPosition*) SvPV( hash_position, na);
	(void)hv_store((HV *) SvRV( perl_obj), "__ENUM__", 8, hash_position, 0);

	zend_hash_internal_pointer_reset_ex( HASH_OF(array), hpos); 

	SP -= items;

	XPUSHs( do_zenum( METHOD, array, hpos));
	PUTBACK;

#undef METHOD
	return;
}

XS( PHP_TieHash_NEXTKEY)
{
	dXSARGS;
	zval * array;
	STRLEN na;
	SV ** hash_position, * perl_obj;
	HashPosition *hpos;

#define METHOD "PHP::TieHash::NEXTKEY"
	if ( items != 2) 
		croak("%s: expect 2 parameters", METHOD);

	if (( array = SV2ZANY( perl_obj = ST(0))) == NULL)
		croak("%s: (%s) is not a PHP array", METHOD, SvPV( perl_obj, na));

	DEBUG("nextkey 0x%x", array);

	if ( !( hash_position = hv_fetch(( HV *) SvRV( perl_obj), "__ENUM__", 8, 0)))
		croak("%s: Internal inconsistency", METHOD);
	hpos = ( HashPosition*) SvPV( *hash_position, na);
	
	zend_hash_move_forward_ex( HASH_OF(array), hpos);
	
	SP -= items;
	XPUSHs( do_zenum( METHOD, array, hpos));
	PUTBACK;
		
#undef METHOD
	return;
}

XS( PHP_TieArray_EXISTS)
{
	dXSARGS;
	long key;
	STRLEN na;
	zval * array;

#define METHOD "PHP::TieArray::EXISTS"
	if ( items != 2) 
		croak("%s: expect 2 parameters", METHOD);

	if (( array = SV2ZANY( ST(0))) == NULL)
		croak("%s: (%s) is not a PHP array", METHOD, SvPV(ST(0), na));

	key = SvIV( ST(1));
	DEBUG("exists 0x%x->[%d]", array, key);

	SP -= items;
	PUTBACK;

	return XSRETURN_IV( zend_hash_index_exists( HASH_OF(array), key));
#undef METHOD
}

XS( PHP_TieArray_FETCH)
{
	dXSARGS;
	long key;
	STRLEN na;
	zval * array, **zobj;
	SV * retsv;

#define METHOD "PHP::TieArray::FETCH"
	if ( items != 2) 
		croak("%s: expect 2 parameters", METHOD);

	if (( array = SV2ZANY( ST(0))) == NULL)
		croak("%s: (%s) is not a PHP array", METHOD, SvPV(ST(0), na));

	key = SvIV( ST(1));
	DEBUG("fetch 0x%x->[%d]", array, key);

	SP -= items;

	if ( zend_hash_index_find( HASH_OF(array), key, (void**) &zobj) == FAILURE) {
		XPUSHs( &PL_sv_undef);
		PUTBACK;
		return;
	}

	if ( !( retsv = zval2sv( *zobj))) {
		warn("%s: value cannot be converted\n", METHOD);
		retsv = &PL_sv_undef;
	}
	if ( retsv != &PL_sv_undef) 
		retsv = sv_2mortal( retsv);
	XPUSHs( retsv);

#undef METHOD
	PUTBACK;

	return;
}

XS( PHP_TieArray_STORE)
{
	dXSARGS;
	long key;
	STRLEN na;
	zval * array, *zobj;
	SV * val;

#define METHOD "PHP::TieArray::STORE"
	if ( items != 3) 
		croak("%s: expect 3 parameters", METHOD);

	if (( array = SV2ZANY( ST(0))) == NULL)
		croak("%s: (%s) is not a PHP array", METHOD, SvPV(ST(0), na));

	key = SvIV( ST(1));
	DEBUG("store 0x%x->[%d]=%s", array, key, SvPV( ST(2), na));

	MAKE_STD_ZVAL( zobj);
	zobj-> type = IS_NULL;
	if ( !sv2zval( val = ST(2), zobj, -1)) {
		zval_ptr_dtor( &zobj);
		croak("%s: scalar (%s) type=%d cannot be converted", 
			METHOD, SvPV( val, na), SvTYPE( val));
	}

	if ( zend_hash_index_update( 
		HASH_OF(array), key,
		(void *)&zobj, sizeof(zval *), NULL
		) == FAILURE) {
		zval_ptr_dtor( &zobj);
		croak("%s: failed", METHOD);
	}

#undef METHOD
	SP -= items;
	PUTBACK;
	XSRETURN_EMPTY;
}

XS( PHP_TieArray_DELETE)
{
	dXSARGS;
	long key;
	STRLEN na;
	zval * array;

#define METHOD "PHP::TieArray::DELETE"
	if ( items != 2) 
		croak("%s: expect 2 parameters", METHOD);

	if (( array = SV2ZANY( ST(0))) == NULL)
		croak("%s: (%s) is not a PHP array", METHOD, SvPV(ST(0), na));

	key = SvIV( ST(1));
	DEBUG("delete 0x%x->[%d]", array, key);

	SP -= items;
	PUTBACK;

	zend_hash_index_del( HASH_OF(array), key);

	XSRETURN_EMPTY;
#undef METHOD
}

/* 
   Retrieve index of the last item in the array; return -1 if the array is empty .
*/
static long 
array_last_index( HashTable * array)
{
	unsigned int klen;
	char * key;
	HashPosition hp;
	unsigned long numkey;
	long last = -1;

	zend_hash_internal_pointer_reset_ex( array, &hp); 
	while ( 1) {
		switch( zend_hash_get_current_key_ex( array, 
			&key, &klen, &numkey, 0, &hp)) 
		{
		case HASH_KEY_NON_EXISTANT:
			return last;
		case HASH_KEY_IS_LONG:
			if ( last < (long) numkey) last = numkey;
			break;
		}
		zend_hash_move_forward_ex( array, &hp);
	}
}

XS( PHP_TieArray_FETCHSIZE)
{
	dXSARGS;
	STRLEN na;
	zval * array;

#define METHOD "PHP::TieArray::FETCHSIZE"
	if ( items != 1) 
		croak("%s: expect 1 parameter", METHOD);

	if (( array = SV2ZANY( ST(0))) == NULL)
		croak("%s: (%s) is not a PHP array", METHOD, SvPV(ST(0), na));

	DEBUG("fetchsize 0x%x", array);

	SP -= items;
	PUTBACK;

	XSRETURN_IV( 1 + array_last_index( HASH_OF(array)));
#undef METHOD
}

XS( PHP_TieArray_PUSH)
{
	dXSARGS;
	STRLEN na;
	long i, pos;
	zval * array, * zobj;
	SV * val;

#define METHOD "PHP::TieArray::PUSH"
	if ( items < 1) 
		croak("%s: expect at least 1 parameter", METHOD);

	if (( array = SV2ZANY( ST(0))) == NULL)
		croak("%s: (%s) is not a PHP array", METHOD, SvPV(ST(0), na));

	pos = array_last_index( HASH_OF(array));
	
	DEBUG("push 0x%x %d items after %d", array, items - 1, pos);
	
	for ( i = 1; i < items; i++) {
		DEBUG("push %s", SvPV( ST(i), na));

		MAKE_STD_ZVAL( zobj);
		zobj-> type = IS_NULL;
		if ( !sv2zval( val = ST(i), zobj, -1)) {
			zval_ptr_dtor( &zobj);
			croak("%s: scalar (%s) type=%d cannot be converted", 
				METHOD, SvPV( val, na), SvTYPE( val));
		}

		if ( zend_hash_index_update( 
			HASH_OF(array), pos + i,
			(void *)&zobj, sizeof(zval *), NULL
			) == FAILURE) {
			zval_ptr_dtor( &zobj);
			croak("%s: failed", METHOD);
		}
	}

	SP -= items;
	PUTBACK;

	XSRETURN_IV( pos + items);
	
#undef METHOD
}

XS( PHP_TieArray_POP)
{
	dXSARGS;
	STRLEN na;
	zval * array, **zobj;
	SV * retsv;
	long pos;

#define METHOD "PHP::TieArray::POP"
	if ( items != 1) 
		croak("%s: expect 1 parameters", METHOD);

	if (( array = SV2ZANY( ST(0))) == NULL)
		croak("%s: (%s) is not a PHP array", METHOD, SvPV(ST(0), na));

	pos = array_last_index( HASH_OF(array));

	DEBUG("pop 0x%x at %d", array, pos);

	SP -= items;
	
	if ( pos == -1) { /* empty array */
		XPUSHs( &PL_sv_undef);
		PUTBACK;
		return;
	}

	if ( zend_hash_index_find( HASH_OF(array), pos, (void**) &zobj) == FAILURE) {
		XPUSHs( &PL_sv_undef);
		PUTBACK;
		return;
	}
	
	if ( !( retsv = zval2sv( *zobj))) {
		warn("%s: value cannot be converted\n", METHOD);
		retsv = &PL_sv_undef;
	}

	zend_hash_index_del( HASH_OF(array), pos);

	if ( retsv != &PL_sv_undef) 
		retsv = sv_2mortal( retsv);
	XPUSHs( retsv);

#undef METHOD
	PUTBACK;

	return;
}

void
register_PHP_Array()
{
	newXS( "PHP::ArrayHandle::new", PHP_ArrayHandle_new, "PHP::ArrayHandle");

	newXS( "PHP::TieHash::EXISTS",	PHP_TieHash_EXISTS,	"PHP::TieHash");
	newXS( "PHP::TieHash::FETCH",	PHP_TieHash_FETCH,	"PHP::TieHash");
	newXS( "PHP::TieHash::STORE",	PHP_TieHash_STORE,	"PHP::TieHash");
	newXS( "PHP::TieHash::DELETE",	PHP_TieHash_DELETE,	"PHP::TieHash");
	newXS( "PHP::TieHash::CLEAR",	PHP_TieHash_CLEAR,	"PHP::TieHash");
	newXS( "PHP::TieHash::FIRSTKEY",PHP_TieHash_FIRSTKEY,	"PHP::TieHash");
	newXS( "PHP::TieHash::NEXTKEY",	PHP_TieHash_NEXTKEY,	"PHP::TieHash");

	newXS( "PHP::TieArray::FETCHSIZE",PHP_TieArray_FETCHSIZE,"PHP::TieArray");
	newXS( "PHP::TieArray::EXISTS",	PHP_TieArray_EXISTS,	"PHP::TieArray");
	newXS( "PHP::TieArray::FETCH",	PHP_TieArray_FETCH,	"PHP::TieArray");
	newXS( "PHP::TieArray::STORE",	PHP_TieArray_STORE,	"PHP::TieArray");
	newXS( "PHP::TieArray::DELETE",	PHP_TieArray_DELETE,	"PHP::TieArray");
	newXS( "PHP::TieArray::CLEAR",	PHP_TieHash_CLEAR,	"PHP::TieArray");
	newXS( "PHP::TieArray::PUSH",	PHP_TieArray_PUSH,	"PHP::TieArray");
	newXS( "PHP::TieArray::POP",	PHP_TieArray_POP,	"PHP::TieArray");
}

#ifdef __cplusplus
}
#endif
