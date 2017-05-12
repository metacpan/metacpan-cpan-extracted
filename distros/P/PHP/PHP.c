/*
$Id: PHP.c,v 1.20 2011/07/26 07:55:10 dk Exp $
*/
#include "PHP.h"

#ifdef __cplusplus
extern "C" {
#endif

int opt_debug = 0;

static int initialized = 0;
static HV *z_objects = NULL; 	/* SV => zval ; the hash accounts for zrefcount */ 
static SV *ksv = NULL;		/* local SV for key storage */
static SV *stdout_hook = NULL;/* if non-null, is a callback for stdout */
static SV *stderr_hook = NULL;/* if non-null, is a callback for stderr */
static SV *header_hook = NULL;/* if non-null, is a callback for header */
static char * eval_ptr = NULL;
static char *post_content = NULL;
static int post_content_index = -1;
static int post_content_length = -1;

/*
these macros allow re-entrant accumulation of php errors
to be reported, if any, by croak() 
*/
#define PHP_EVAL_BUFSIZE 2048
#define dPHP_EVAL   char eval_buf[PHP_EVAL_BUFSIZE], *old_eval_ptr
#define PHP_EVAL_ENTER \
	old_eval_ptr = eval_ptr;\
	eval_ptr = eval_buf;\
	eval_buf[0] = 0
#define PHP_EVAL_LEAVE eval_ptr = old_eval_ptr
#define PHP_EVAL_CROAK(default_message)	

void init_rfc1867();
void deinit_rfc1867();

void 
debug( char * format, ...)
{
	va_list args;

	if ( !opt_debug) return;
	va_start( args, format);
	vfprintf( stderr, format, args);
	fprintf( stderr, "\n");
	va_end( args);
}

/* use perl hashes to store non-sv values */

/* store and/or delete */
static void
hv_store_zval( HV * h, const SV* key, zval * val)
{
	HE *he;

	if ( val) {
		ZVAL_ADDREF( val);
		DEBUG("addref=%d 0x%x", PHP_REFCOUNT(val), val);
	}

	if ( !ksv) ksv = newSV( sizeof( SV*)); 
	sv_setpvn( ksv, ( char *) &key, sizeof( SV*));           
	he = hv_fetch_ent( h, ksv, 0, 0);
	
	if ( he) {
		zval * z = ( zval *) HeVAL( he);
		if ( z) {
			DEBUG("delref=%d %s0x%x", 
				PHP_REFCOUNT(z) - 1,
				PHP_REFCOUNT(z) > 1 ? "" : "kill ",
				z);
			zval_ptr_dtor( &z);
		}
		HeVAL( he) = &PL_sv_undef;
		(void)hv_delete_ent( h, ksv, G_DISCARD, 0);
	}

	if ( val) {
		he = hv_store_ent( h, ksv, &PL_sv_undef, 0);
		HeVAL( he) = ( SV *) val;
	}
}

/* fetch */
static zval *
hv_fetch_zval( HV * h, const SV * key)
{
	SV ** v = hv_fetch( h, (char*)&key, sizeof(SV*), 0);
	return v ? (zval*)(*v) : NULL;
}

/* kill the whole hash */
static void
hv_destroy_zval( HV * h)
{
	HE * he;
	zval * value;

	hv_iterinit( h);
	for (;;)
	{
		if (( he = hv_iternext( h)) == NULL) 
			break;

		value = ( zval*) HeVAL( he);
		if ( value) {
			DEBUG("force delete 0x%x delref=%d", value, PHP_REFCOUNT(value) - 1);
			zval_ptr_dtor( &value);
		}
		HeVAL( he) = &PL_sv_undef;
	}
	sv_free((SV *) h);
}

/* create a blessed instance of PHP::Entity */
SV *
Entity_create( char * class, zval * data)
{
	SV * obj, * mate;
	dSP;
	
	ENTER;
	SAVETMPS;
	PUSHMARK( sp);
	XPUSHs( sv_2mortal( newSVpv( class, 0)));
	PUTBACK;
	perl_call_method( "CREATE", G_SCALAR);
	SPAGAIN;
	mate = SvRV( POPs);
	if ( !mate)
		croak("PHP::Entity::create: something really bad happened");
	obj = newRV_inc( mate);
	hv_store_zval( z_objects, mate, data);
	PUTBACK;
	FREETMPS;
	LEAVE;
	
	DEBUG("new SV*(0x%x) => %s(0x%x)", mate, class, data);

	return obj;
}

/* instantiate php object from a given class */
XS(PHP_Object__new)
{
	dXSARGS;
	STRLEN i, len;
	zval * object;
#if PHP_MAJOR_VERSION > 4
#define ZCLASSPTR *zclass
#else
#define ZCLASSPTR zclass
#endif
	zend_class_entry * ZCLASSPTR; 
	char *class, *save_class, uclass[2048], *uc;

	if ( items != 2)
		croak("PHP::Object::new: 2 parameters expected");
	
	save_class = class = SvPV( ST( 1), len);

	DEBUG("new '%s'", save_class);

	if ( len > 2047) len = 2047;
	for ( i = 0, uc = uclass; i < len + 1; i++)
		*(uc++) = tolower( *(class++));

	if ( zend_hash_find(CG(class_table), uclass, len + 1, (void **) &zclass) == FAILURE)
		croak("PHP::Object::new: undefined class name '%s'", save_class);


	SP -= items;

	MAKE_STD_ZVAL( object);

	object_init_ex( object, ZCLASSPTR);

	XPUSHs( sv_2mortal( Entity_create( SvPV( ST(0), len), object)));
	PUTBACK;
#undef ZCLASSPTR
	ZVAL_DELREF( object);

	return;
}

XS(PHP_stringify)
{
	dXSARGS;
	SV * sv;
	char str[32];

	if ( items != 1)
		croak("PHP::stringify: 1 parameter expected");

	sv = ST(0);
	if ( !SvROK( sv))
		croak("PHP::stringify: not a reference passed");
	sprintf( str, "PHP(0x%x)", (unsigned int) SvRV( sv));

	XPUSHs( sv_2mortal( newSVpv( str, strlen( str))));
	PUTBACK;

	return;
}


/* map SV into zval */
zval * 
get_php_entity( SV * perl_object, int check_type)
{
	HV *obj;
	zval * z;
	
	if ( !SvROK( perl_object)) 
		return NULL;
	obj = (HV*) SvRV( perl_object);
	DEBUG("object? SV*(0x%x)", obj);
	
	z = hv_fetch_zval( z_objects, (SV*) obj); 

	if ( z && check_type >= 0 && z-> type != check_type)
		return NULL;
	return z;
}

/* copy SV content into ZVAL */
int
sv2zval( SV * sv, zval * zarg, int suggested_type )
{
	STRLEN len;

	if ( !SvOK( sv)) {
		DEBUG("%s: NULL", "sv2zval");
		zarg-> type = IS_NULL;
	} else if ( !SvROK( sv)) {
		int type;
		
		if ( suggested_type < 0) {
			if ( SvIOK( sv)) {
				type = SVt_IV;
				DEBUG("%s: sensed IV", "sv2zval");
			} else if ( SvNOK( sv)) {
				type = SVt_NV;
				DEBUG("%s: sensed NV", "sv2zval");
			} else if ( SvPOK( sv)) {
				type = SVt_PV;
				DEBUG("%s: sensed PV", "sv2zval");
			} else if ( SvIOKp( sv)) {
				type = SVt_IV;
				DEBUG("%s: forcibly sensed IV", "sv2zval");
			} else if ( SvNOKp( sv)) {
				type = SVt_NV;
				DEBUG("%s: forcibly sensed NV", "sv2zval");
			} else if ( SvPOKp( sv)) {
				type = SVt_PV;
				DEBUG("%s: forcibly sensed PV", "sv2zval");
			} else {
				type = -1;
				DEBUG("%s: sensed nothing", "sv2zval");
			}
		} else {
			type = suggested_type; 
		}
			
		switch ( type) {
		case SVt_IV:
			DEBUG("%s: LONG %d", "sv2zval", SvIV(sv));
			ZVAL_LONG(zarg, SvIV( sv));
			break;
		case SVt_NV:
			DEBUG("%s: DOUBLE %g", "sv2zval", SvNV(sv));
			ZVAL_DOUBLE(zarg, SvNV( sv));
			break;
		case SVt_PV: {
			char * c = SvPV( sv, len);
			DEBUG("%s: STRING %s", "sv2zval", c);
			ZVAL_STRINGL( zarg, c, len, 1);
			break;
		}
		default:
			DEBUG("%s: cannot convert scalar %d/%s", "sv2zval", SvTYPE( sv), SvPV( sv, len));
			return 0;
		}
	} else {
		switch ( SvTYPE( SvRV( sv))) {
		case SVt_PVHV: {
			zval * obj;
			if (( obj = SV2ZANY( sv)) == NULL) {
				warn("%s: not a PHP entity %d/%s", 
					"sv2zval", SvTYPE( sv), SvPV( sv, len));
				return 0;
			}
			DEBUG("%s: %s 0x%x ref=%d", "sv2zval", 
				(obj->type == IS_OBJECT) ? "OBJECT" : "ARRAY",
				obj, 
				PHP_REFCOUNT(obj));
			*zarg = *obj;
			zval_copy_ctor( zarg);
			break;
		}	
		default:
			DEBUG("%s: cannot convert reference %d/%s", "sv2zval", SvTYPE( sv), SvPV( sv, len));
			return 0;
		}
	}

	return 1;
}

/* copy ZVAL content into a fresh SV */
SV *
zval2sv( zval * zobj)
{
	switch ( zobj-> type) {
	case IS_NULL:
		DEBUG("%s: NULL", "zval2sv");
		return &PL_sv_undef;
	case IS_BOOL:
		DEBUG("%s: BOOL %s", "zval2sv", Z_LVAL( *zobj) ? "TRUE" : "FALSE");
		return Z_LVAL( *zobj) ? &PL_sv_yes : &PL_sv_no;
	case IS_LONG:
		DEBUG("%s: LONG %d", "zval2sv", Z_LVAL( *zobj));
		return newSViv( Z_LVAL( *zobj));
	case IS_DOUBLE:
		DEBUG("%s: DOUBLE %d", "zval2sv", Z_DVAL( *zobj));
		return newSVnv( Z_DVAL( *zobj));
	case IS_STRING:
		DEBUG("%s: STRING %d", "zval2sv", Z_STRVAL( *zobj));
		return newSVpv( Z_STRVAL( *zobj), Z_STRLEN( *zobj));
	case IS_ARRAY:  {
		SV * array_handle, * obj;
		dSP;
	
		DEBUG("%s: ARRAY 0x%x ref=%d", "zval2sv", zobj, PHP_REFCOUNT(zobj));

		array_handle = Entity_create( "PHP::ArrayHandle", zobj);
		
		ENTER;
		SAVETMPS;
		PUSHMARK( sp);
		XPUSHs( sv_2mortal( newSVpv( "PHP::Array", 0)));
		XPUSHs( sv_2mortal( array_handle ));
		PUTBACK;
		perl_call_method( "new", G_SCALAR);
		SPAGAIN;
		obj = newSVsv( POPs);
		PUTBACK;
		FREETMPS;
		LEAVE;

		return obj;
		}
	case IS_OBJECT:		
		DEBUG("%s: OBJECT 0x%x ref=%d", "zval2sv", zobj, PHP_REFCOUNT(zobj));
		return Entity_create( "PHP::Object", zobj);
	default:
		DEBUG("%s: ENTITY 0x%x type=%i\n", "zval2sv", zobj, zobj->type);
		return Entity_create( "PHP::Entity", zobj);
	}
}

/* free zval corresponding to a SV */ 
XS(PHP_Entity_DESTROY)
{
	dXSARGS;
	zval * obj;

	if ( !initialized) /* if called after PHP::done */
		XSRETURN_EMPTY;
	
	if ( items != 1)
		croak("PHP::Entity::destroy: 1 parameter expected");

	if (( obj = SV2ZANY( ST(0))) == NULL)
		croak("PHP::Entity::destroy: not a PHP entity");

	DEBUG("delete object 0x%x", obj);
	hv_store_zval( z_objects, SvRV( ST(0)), NULL);
	
	PUTBACK;
	XSRETURN_EMPTY;
}

/* 
link and unlink manage a hash of aliases, used when different SVs can
represent single zval. This is useful for tied hashes and arrays.
*/
XS( PHP_Entity_link)
{
	dXSARGS;
	zval * obj;

	if ( items != 2)
		croak("PHP::Entity::link: 2 parameters expected");

	if (( obj = SV2ZANY( ST(0))) == NULL)
		croak("PHP::Entity::link: not a PHP entity");

	DEBUG("link SV*(0x%x) => 0x%x", SvRV( ST( 1)), obj);
	hv_store_zval( z_objects, SvRV( ST(1)), obj);
	
	PUTBACK;
	XSRETURN_EMPTY;
}

XS( PHP_Entity_unlink)
{
	dXSARGS;

	if ( items != 1)
		croak("PHP::Entity::unlink: 1 parameter expected");

	DEBUG("unlink SV*(0x%x)", SvRV( ST( 0)));
	hv_store_zval( z_objects, SvRV( ST( 0)), NULL);
	
	PUTBACK;
	XSRETURN_EMPTY;
}

#define ZARG_STATIC_BUFSIZE 32
/* call a php function or method, croak if it fails */
XS(PHP_exec)
{
	dXSARGS;
	dPHP_EVAL;
	STRLEN len;
	int i, zargc, zobject, as_method;
	int ret = FAILURE;
	zval *retval;
	SV * retsv;
	
	/* zvals with actial scalar values */
	static zval *zargv_static[ZARG_STATIC_BUFSIZE];
	zval **zargv, **zarg;
	/* array of pointers to these zvals */
	static zval **pargv_static[ZARG_STATIC_BUFSIZE];
	zval ***pargv;

	
	(void)items;

	if ( items < 2)
		croak("%s: expect at least 2 parameters", "PHP::exec");

	zobject = -1;
	as_method = SvIV( ST(0));

#define METHOD ( as_method ? "PHP::method" : "PHP::exec")
	
	DEBUG("%s(%s)(%d args)", 
		METHOD,
		SvPV( ST(1), len), 
		items-1);

	/* alloc arguments */
	zargc = items - 1;
	if ( zargc <= ZARG_STATIC_BUFSIZE) {
		zargv = zargv_static;
		pargv = pargv_static;
	} else {
		if ( !( zargv = malloc( 
			sizeof( zval*) * zargc
			+ 
			sizeof( zval**) * zargc
			))) 
			croak("%s: not enough memory (%d bytes)", 
				METHOD, sizeof( void*) * zargc * 2);
		pargv = (zval***)(zargv + zargc);
	}
	for ( i = 0; i < zargc; i++) {
		pargv[i] = zargv + i;
		MAKE_STD_ZVAL( zargv[i]);
		zargv[i]-> type = IS_NULL;
	}

	/* common cleanup code */
#define CLEANUP \
	for ( i = 0; i < zargc; i++) zval_ptr_dtor( zargv + i);\
	if ( zargv != zargv_static) free( zargv);

	/* parse and store arguments */
	for ( i = 0, zarg = zargv; i < zargc; i++, zarg++) {
		if ( !sv2zval( ST(i+1), *zarg, 
			i ? -1 : SVt_PV)) {  /* name can be something else it seems */
			CLEANUP;
			croak("%s: parameter #%d is of unsupported type and cannot be passed", METHOD, i+1); 
		}

		if ( zobject < 0 && (*zarg)->type == IS_OBJECT)
			zobject = i;
	}

	if ( as_method && zobject != 1) {
		CLEANUP;
		croak("%s: first parameter must be an object", METHOD);
	}

	/* issue php call */
	PHP_EVAL_ENTER;
	TSRMLS_FETCH();
	zend_try {
		ret = call_user_function_ex(
			( as_method ? NULL : CG(function_table)), /* namespace */
			( as_method ? zargv + 1 : NULL),	  /* object */	
			zargv[0],			          /* function name */	
			&retval, 				  /* return zvalue */
			zargc - 1 - as_method,			  /* param count */ 
			pargv + 1 + as_method, 			  /* param vector */
			0, NULL TSRMLS_CC);
	} zend_end_try();
	PHP_EVAL_LEAVE;

#if PHP_MAJOR_VERSION > 4
	if ( EG(exception)) {
		zval_ptr_dtor(&EG(exception));
		EG(exception) = NULL;
		ret = FAILURE; /* assert that exception doesn't go unnoticed */
	}
#endif

	if ( ret == FAILURE) {
		CLEANUP;
		if ( eval_buf[0])
			croak("%s", eval_buf);
		else
			croak("%s: function %s call failed", METHOD, SvPV(ST(1), len));
	} else if ( eval_buf[0])
		warn("%s", eval_buf);

	/* read and parse results */
	SPAGAIN;
	SP -= items;

	if ( !( retsv = zval2sv( retval))) {
		warn("%s: function return value cannot be converted\n", METHOD);
		retsv = &PL_sv_undef;
	}
	retsv = sv_2mortal( retsv);
	XPUSHs( retsv);
	CLEANUP;
	zval_ptr_dtor( &retval);
	sv_setsv( GvSV( PL_errgv), &PL_sv_undef);
#undef CLEANUP
#undef METHOD

	PUTBACK;
	return;
}

/* eval php code, croak on failure */
XS(PHP_eval)
{
	dXSARGS;
	int ret = FAILURE;
	dPHP_EVAL;

	STRLEN na;
	(void)items;

	DEBUG("PHP::eval(%d args)", items);
	if ( items < 0 || items > 2)
		croak("PHP::eval: expect 1 parameter");
	
	PHP_EVAL_ENTER;
	zend_try {
		ret = zend_eval_string( SvPV( ST(0), na), NULL, "Embedded code" TSRMLS_CC);
	} zend_end_try();
	PHP_EVAL_LEAVE;

#if PHP_MAJOR_VERSION > 4
	if ( EG(exception)) {
		zval_ptr_dtor(&EG(exception));
		EG(exception) = NULL;
		ret = FAILURE; /* assert that exception doesn't go unnoticed */
	}
#endif

	if ( ret == FAILURE) {
		croak( "%s", eval_buf[0] ? eval_buf : "PHP::eval failed");
	} else if ( eval_buf[0])
		warn("%s", eval_buf);
	
	PUTBACK;
	XSRETURN_EMPTY;
}

/* eval php code with return, croak on failure */
XS(PHP_eval_return)
{
	dXSARGS;
	int ret = FAILURE;
	zval * zret;
	SV * retsv;
	dPHP_EVAL;

	STRLEN na;
	(void)items;

	DEBUG("PHP::eval_return(%d args)", items);
	if ( items < 0 || items > 2)
		croak("PHP::eval_return: expect 1 parameter");

	MAKE_STD_ZVAL(zret);
	zret-> type = IS_NULL;
	
	PHP_EVAL_ENTER;
	zend_try {
		ret = zend_eval_string( SvPV( ST(0), na), zret, "Embedded code" TSRMLS_CC);
	} zend_end_try();
	PHP_EVAL_LEAVE;

#if PHP_MAJOR_VERSION > 4
	if ( EG(exception)) {
		zval_ptr_dtor(&EG(exception));
		EG(exception) = NULL;
		ret = FAILURE; /* assert that exception doesn't go unnoticed */
	}
#endif

	if ( ret == FAILURE) {
		zval_ptr_dtor(&zret);
		croak( "%s", eval_buf[0] ? eval_buf : "PHP::eval_return failed");
	} else if ( eval_buf[0])
		warn("%s", eval_buf);
	
	SPAGAIN;
	SP -= items;

	if ( !( retsv = zval2sv( zret))) {
		warn("PHP::eval_return: eval return value cannot be converted\n");
		retsv = &PL_sv_undef;
	}
	retsv = sv_2mortal( retsv);
	XPUSHs( retsv);
	zval_ptr_dtor( &zret);
	PUTBACK;
}

/* get and set various options */
XS(PHP_options)
{
	dXSARGS;
	STRLEN na;
	char * c;

	(void)items;

	if ( items > 2) 
		croak("PHP::options: must be 0, 1, or 2 parameters");

	switch ( items) {
	case 0:
		SPAGAIN;
		SP -= items;
		EXTEND( sp, 1);
		PUSHs( sv_2mortal( newSVpv( "debug", 5)));
		PUSHs( sv_2mortal( newSVpv( "stdout", 6)));
		PUSHs( sv_2mortal( newSVpv( "stderr", 6)));
		PUSHs( sv_2mortal( newSVpv( "header", 6)));
		PUSHs( sv_2mortal( newSVpv( "version", 7)));
		return;
	case 1:
	case 2:
		c = SvPV( ST(0), na);
		if ( strcmp( c, "debug") == 0) {
			if ( items == 1) {
				SPAGAIN;
				SP -= items;
				XPUSHs( sv_2mortal( newSViv( opt_debug)));
				PUTBACK;
				return;
			} else {
				opt_debug = SvIV( ST( 1));
			}
		} else if ( 
			strcmp( c, "header") == 0 ||
			strcmp( c, "stdout") == 0 ||
			strcmp( c, "stderr") == 0
			) {
			SV ** ptr = ( strcmp( c, "stdout") == 0) ? 
				&stdout_hook : (strcmp( c, "stderr" ) == 0
				? &stderr_hook : &header_hook);
			if ( items == 1) {
				SPAGAIN;
				SP -= items;
				if ( *ptr)
					XPUSHs( sv_2mortal( newSVsv( *ptr)));
				else
					XPUSHs( &PL_sv_undef);
				PUTBACK;
				return;
			} else {
				SV * hook = ST( 1);
				if ( SvTYPE( hook) == SVt_NULL) {
					if ( *ptr) 
						sv_free( *ptr);
					*ptr = NULL;
					PUTBACK;
					return;
				}
			   	if ( !SvROK( hook) || ( SvTYPE( SvRV( hook)) != SVt_PVCV)) {
					warn("PHP::options::stdout: Not a CODE reference passed");
					PUTBACK;
					return; 
				}
				if ( *ptr) 
					sv_free( *ptr);
				*ptr = newSVsv( hook);
				PUTBACK;
			}
		} else if ( strcmp( c, "version") == 0) {
			if ( items == 1) {
				SPAGAIN;
				SP -= items;
				XPUSHs( sv_2mortal( newSVpv( PHP_VERSION, 0 )));
				PUTBACK;
				return;
			} else {
				croak("PHP::options: `%s' is a read-only option", c);
			}
		} else {
			croak("PHP::options: unknown option `%s'", c);
		}
	}
	
	XSRETURN_EMPTY;
}

/* process php warnings; save the last warning for the eventual croak */
static void
mod_log_message( char * message)
{
	if ( eval_ptr) {
		if ( *eval_ptr && !stderr_hook)
			warn("%s", eval_ptr);
		strlcpy( eval_ptr, message, PHP_EVAL_BUFSIZE);
	}

	if ( stderr_hook) {
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK( sp);
		XPUSHs( sv_2mortal( newSVpv( message, 0)));
		PUTBACK;
		perl_call_sv( stderr_hook, G_DISCARD);
		SPAGAIN;
		FREETMPS;
		LEAVE;
	} else if ( !eval_ptr) { 
		/* eventual warnings in code outside eval and exec */
		warn("%s", message);
	}
}

/* get php stdout */
static int 
mod_ub_write(const char *str, uint str_length TSRMLS_DC)
{
	if ( stdout_hook) {
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK( sp);
		XPUSHs( sv_2mortal( newSVpvn( str, str_length)));
		PUTBACK;
		perl_call_sv( stdout_hook, G_DISCARD);
		SPAGAIN;
		FREETMPS;
		LEAVE;
		return str_length;
	} else {
		return PerlIO_write( PerlIO_stdout(), str, str_length);
	}
}

/* php-embed call fflush() here - well, we don't */
static int 
mod_deactivate(TSRMLS_D)
{
	return SUCCESS;
}

static int
mod_header_handler(sapi_header_struct *sapi_header, sapi_header_op_enum op,
		   sapi_headers_struct *sapi_headers TSRMLS_DC)
{
	if (sapi_header && sapi_header->header_len && header_hook) {
		debug("*** header enum is %d ***", op);
	  	int replace = !(int) op;
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(sp);
		XPUSHs(sv_2mortal(newSVpvn(sapi_header->header,
				sapi_header->header_len)));
		XPUSHs(sv_2mortal(newSViv(replace)));
		PUTBACK;
		perl_call_sv( header_hook, G_DISCARD );
		SPAGAIN;
		FREETMPS;
		LEAVE;
		return SUCCESS;
	}
	return FAILURE;
}

XS(PHP_set_php_input)
{
	dXSARGS;
	(void) items;
	if (items != 1) {
		croak("PHP_set_php_input: expect exactly 1 input!");
	}
	post_content = SvPV(ST(0), post_content_length);
	post_content_index = 0;
}

static int
mod_read_post(char *buffer, uint count_bytes TSRMLS_DC)
{
	int old_index = post_content_index;
	if (NULL == post_content) {
		return 0;
	}
	while (post_content_index < post_content_length &&
	       post_content_index - old_index < count_bytes) {
		buffer[post_content_index - old_index] = post_content[post_content_index];
		post_content_index++;
	}
	if (post_content_index >= post_content_length) {
		post_content = NULL; /* memory leak here? */
		post_content_length = 0;
	}
	return post_content_index - old_index;
}

/* stop PHP embedded module */
XS(PHP_done)
{
	dXSARGS;
	(void)items;
	initialized = 0;
	hv_destroy_zval( z_objects);
	sv_free( ksv);
	z_objects = NULL;
	ksv = NULL;
	if ( stdout_hook) {
		sv_free( stdout_hook);
		stdout_hook = NULL;
	}
	if ( stderr_hook) {
		sv_free( stderr_hook);
		stderr_hook = NULL;
	}

#if PHP_MAJOR_VERSION == 5 && PHP_MINOR_VERSION < 4
	php_end_ob_buffers(1 TSRMLS_CC);
#else
	php_output_end_all(TSRMLS_C);
#endif
	deinit_rfc1867();
	php_embed_shutdown(TSRMLS_C);
	DEBUG("PHP::done");
	XSRETURN_EMPTY;
}

XS(PHP_assign_global)
{
	dXSARGS;
	char *varname;
	zval *zv;
	(void)items;

	if (items != 2)
		croak("PHP_assign_global: expect exactly 2 inputs");

	ALLOC_ZVAL(zv);
	if (!sv2zval(ST(1), zv, -1)) {
		FREE_ZVAL(zv);
		croak("PHP::assign_global: parameter 1 is of unsupported type and cannot be passed"); 
	}

	varname = SvPV_nolen(ST(0));
	ZEND_SET_GLOBAL_VAR(varname, zv);
}


/*
 * rfc1867 functions -- on file upload, PHP writes the uploaded file
 * to a temporary location and adds the temporary filename to an
 * internal hashtable -- see rfc1867_post_handler() in main/rfc1867.c .
 * PHP's  is_uploaded_file()  function checks this internal hash
 * to make sure that the named file was uploaded properly. 
 *
 * The next few functions provide a mechanism to spoof entries to
 * PHP's hashtable. This will be necessary to support uploaded
 * files in Perl (say, CGI or Catalyst) but making it appear to
 * the PHP interpreter that they were uploaded properly in PHP.
 */ 

XS(PHP_spoof_rfc1867)
{
	dXSARGS;
	char *temp_filename;
	(void)items;

	if (items != 1)
		croak("PHP_spoof_rfc1867: expect exactly 1 input");
	temp_filename = SvPV_nolen(ST(0));
	zend_hash_add(SG(rfc1867_uploaded_files), temp_filename, strlen(temp_filename) + 1, 
		      &temp_filename, sizeof(char *), NULL);
}

void init_rfc1867()
{
	HashTable *uploaded_files = NULL;

	ALLOC_HASHTABLE(uploaded_files);
	// free_estring  can cause seg fault during php_embed_shutdown.
	// hopefully this is not a significant memory leak
//	zend_hash_init(uploaded_files, 5, NULL, (dtor_func_t) free_estring, 0);
	zend_hash_init(uploaded_files, 5, NULL, NULL, 0);
	SG(rfc1867_uploaded_files) = uploaded_files;
}

void deinit_rfc1867()
{
	if (SG(rfc1867_uploaded_files)) {
		//zend_hash_destroy(SG(rfc1867_uploaded_files));  // memory leak?
		FREE_HASHTABLE(SG(rfc1867_uploaded_files));
		SG(rfc1867_uploaded_files) = NULL;
	}
}

/* initialization section */
XS( boot_PHP)
{
	dXSARGS;
	sig_t sig;
	(void)items;
	
	XS_VERSION_BOOTCHECK;

	/* php_embed_init calls signal( SIGPIPE, SIGIGN) for some weird reason -
	   make a work-around */
	sig = signal( SIGPIPE, SIG_IGN);
	php_embed_init(0, NULL PTSRMLS_CC);
	signal( SIGPIPE, sig);
	/* just for the completeness sake, it also does weird
	  setmode(_fileno(stdin/stdout/stderr), O_BINARY)
	  on win32, but I don't really care about this */

	/* overload embed default values and output routines */
	PG(display_errors) = 0;
	PG(log_errors) = 1;
	sapi_module. log_message	= mod_log_message;
	sapi_module. ub_write		= mod_ub_write;
	sapi_module. deactivate		= mod_deactivate;
	sapi_module. header_handler     = mod_header_handler;
	sapi_module. read_post          = mod_read_post;

	php_output_startup();
	php_output_activate(TSRMLS_C);

	/* init our stuff */
	z_objects = newHV();
	
	newXS( "PHP::done", PHP_done, "PHP");
	newXS( "PHP::options", PHP_options, "PHP");
	
	newXS( "PHP::exec", PHP_exec, "PHP");
	newXS( "PHP::eval", PHP_eval, "PHP");
	newXS( "PHP::eval_return", PHP_eval_return, "PHP");
	
	newXS( "PHP::stringify", PHP_stringify, "PHP");
	
	newXS( "PHP::_reset", boot_PHP, "PHP" );
	newXS( "PHP::_assign_global", PHP_assign_global, "PHP");
	newXS( "PHP::set_php_input", PHP_set_php_input, "PHP");
	newXS( "PHP::_spoof_rfc1867", PHP_spoof_rfc1867, "PHP");
	
	newXS( "PHP::Entity::DESTROY", PHP_Entity_DESTROY, "PHP::Entity");
	newXS( "PHP::Entity::link", PHP_Entity_link, "PHP::Entity");
	newXS( "PHP::Entity::unlink", PHP_Entity_unlink, "PHP::Entity");
	
	newXS( "PHP::Object::_new", PHP_Object__new, "PHP::Object");

	register_PHP_Array();
	init_rfc1867();

	initialized = 1;
	
	ST(0) = newSViv(1);
	
	XSRETURN(1);
}


#ifdef __cplusplus
}
#endif
