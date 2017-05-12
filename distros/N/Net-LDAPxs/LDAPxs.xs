#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* LDAP C SDK Include Files */
#include <lber.h>
#include <ldap.h>

#include "const-c.inc"

/* Prototypes */
LDAP* _connect(char *, int, int, char *);
void ldap_add_mods(HV*, LDAPMod ***);
void ldapmod_struct(AV*, LDAPMod ***);
void free_attrs(LDAPMod **);
AV* get_entries(LDAP *, LDAPMessage *);
SV* rc_exception(int);

LDAP* 
_connect(char *host, int port, int version, char *scheme)
{
	int rc;
	LDAP* ld = NULL;
	char *ldapuri = NULL;

	LDAPURLDesc url;
	memset( &url, 0, sizeof(url));

	url.lud_scheme = scheme;
	url.lud_host = host;
	url.lud_port = port;
	url.lud_scope = LDAP_SCOPE_DEFAULT;
	ldapuri = ldap_url_desc2str( &url );

	rc = ldap_initialize( &ld, ldapuri );
	if (rc != LDAP_SUCCESS) {
		fprintf( stderr,
				"Could not create LDAP session handle for URI=%s (%d): %s\n",
				ldapuri, rc, ldap_err2string(rc) );
		exit( EXIT_FAILURE );
	}
	if (ldap_set_option(ld, LDAP_OPT_PROTOCOL_VERSION, &version) != LDAP_SUCCESS) {
		fprintf( stderr,
				"Could not set LDAP_OPT_PROTOCOL_VERSION %d\n",
				version );
		exit( EXIT_FAILURE );
	}
	return ld;
}

void
free_attrs(LDAPMod **list_of_attrs)
{
	int i = 0;
	while(list_of_attrs[i] != NULL)
		free(list_of_attrs[i++]->mod_values);
	free(list_of_attrs);
}

void
ldapmod_struct(AV* attrs_av, LDAPMod ***list_of_attrs)
{
/* the data structure of attrs_av is like this
$VAR1 = [
          {
            'type' => 'cn',
		    'vals' => [
		                'buy2',
		                'buy3'
		              ],
		    'changetype' => 0
		  },
		  {
		    'type' => 'ca',
		    'vals' => [
		                'test123'
		              ],
            'changetype' => 0
          }
        ];
*/
	int len, j;

	len = av_len(attrs_av) + 1;
	*list_of_attrs = (LDAPMod **)malloc((len+1)*sizeof(LDAPMod *));
	for (j = 0; j < len; j++) {
		HV* attrs_hv;
		AV *val_array;
		LDAPMod mods;
		SV **elem;
		SV **svp;
		int len_vals, i;

		elem = av_fetch(attrs_av, j, 0);
		if (elem != NULL) {
			attrs_hv = (HV*)SvRV(*elem);
			if ((svp = hv_fetch(attrs_hv, "changetype", 10, FALSE)) && SvIOK(*svp)) {
				mods.mod_op = SvIV(*svp);
			}else{
				croak("changetype is wrong");
			}
			if ((svp = hv_fetch(attrs_hv, "type", 4, FALSE)) && SvPOK(*svp)) {
				mods.mod_type = (char *)SvPV_nolen(*svp);
			}else{
				croak("type is wrong");
			}
			if ((svp = hv_fetch(attrs_hv, "vals", 4, FALSE)) && SvROK(*svp)) {
				val_array = (AV*)SvRV(*svp);
			}else{
				croak("vals is wrong");
			}

			len_vals = av_len(val_array) + 1;
			mods.mod_values = (char **)malloc((len_vals+1)*sizeof(char *));
			for (i = 0; i < len_vals; i++) {
				elem = av_fetch(val_array, i, 0);
				if (elem != NULL) {
					mods.mod_values[i] = (char *)SvPV_nolen(*elem);
				}
			}
			mods.mod_values[i] = NULL;
			/* add the constructed LDAPMod to the list of attrs */
			(*list_of_attrs)[j] = (LDAPMod *)malloc(sizeof(LDAPMod));
			*((*list_of_attrs)[j]) = mods;
		}
	}
	/* list of attrs should be a NULL terminated array */
	(*list_of_attrs)[j] = NULL;
}

/* ldap_add_mods has the same function of ldapmod_struct, but operated in a different way. This function is deprecated */
void
ldap_add_mods(HV* attrs_hv, LDAPMod ***list_of_attrs)
{
	int count, j;

	I32 klen;
	SV *val;

	count = hv_iterinit(attrs_hv);
	*list_of_attrs = (LDAPMod **)malloc((count+1)*sizeof(LDAPMod *));
	for (j = 0; j< count; j++) {
		LDAPMod mods;
		//val = hv_iternextsv(attrs_hv, (char **) &key, &klen);
		mods.mod_op = 0;
		val = hv_iternextsv(attrs_hv, (char **) &mods.mod_type, &klen);
		if (SvTYPE(SvRV(val)) == SVt_PVAV) {
		    /* In case of multi-value */
			AV *val_array = (AV*)SvRV(val);
			int len;
			SV** elem;
			int i;

			len = av_len(val_array) + 1;
			mods.mod_values = (char **)malloc((len+1)*sizeof(char *));
			for (i = 0; i < len; i++) {
				elem = av_fetch(val_array, i, 0);
				if (elem != NULL) {
					mods.mod_values[i] = (char *)SvPV_nolen(*elem);
				}
			}
			mods.mod_values[i] = NULL;
		}else{
			mods.mod_values = (char **)malloc(2*sizeof(char *));
			mods.mod_values[0] = (char *)SvPV_nolen(val);
			mods.mod_values[1] = NULL;
		}
		(*list_of_attrs)[j] = (LDAPMod *)malloc(sizeof(LDAPMod));
		*((*list_of_attrs)[j]) = mods;
	}
	(*list_of_attrs)[j] = NULL;
}


AV*
get_entries(LDAP *ld, LDAPMessage *res)
{
	AV* entries = newAV();

	int i, j, k;
	char *dn, *a;
	LDAPMessage *e;
	BerElement *ptr;
	struct berval **vals;
	struct berval val;

	for(e = ldap_first_entry(ld, res), i = 0; e != NULL; e = ldap_next_entry(ld, e)) { 
		HV* entry_hash;
		AV* attr_array;
		HV* stash;
		SV* object;

		dn = ldap_get_dn(ld, e);
		/* one entry per hash */
		entry_hash = newHV();
		/* attributes array */
		attr_array = newAV();
		for ( a = ldap_first_attribute(ld, e, &ptr), j = 0; a != NULL; a = ldap_next_attribute(ld, e, ptr) ) {
			HV* attr_hash;
			AV* val_array;

			vals = ldap_get_values_len(ld, e, a);
			/* one attribute of an entry */
			attr_hash = newHV();
			/* values of an attribute */
			val_array = newAV();
			for (k = 0; vals[k] != NULL; k++) {
				val = *vals[k];
				av_store(val_array, k, newSVpv(val.bv_val, 0));
			}
			ldap_value_free_len(vals);

			hv_store(attr_hash, "type", 4, newSVpv(a, 0), 0);
			hv_store(attr_hash, "vals", 4, newRV_noinc((SV*)val_array), 0);
			av_store(attr_array, j++, newRV_noinc((SV*)attr_hash));
			ldap_memfree(a);
		}
		hv_store(entry_hash, "objectName", 10, newSVpv(dn, 0), 0);
		hv_store(entry_hash, "attributes", 10, newRV_noinc((SV*)attr_array), 0);
		/* setup a new object called Net::LDAPxs::Entry for every entry */
		stash = gv_stashpv("Net::LDAPxs::Entry", GV_ADDWARN);
		object = newRV_noinc((SV*)entry_hash);
		sv_bless(object, stash);

		av_store(entries, i++, object);

		ldap_memfree(dn);
		if (ptr != NULL)
			ldap_memfree(ptr);
	}
	return entries;
}


SV *
rc_exception(int rc)
{
	HV* stash;
	SV* object;
	HV* exception;

	exception = newHV();
	hv_store(exception, "code", 4, newSViv(rc), 0);
	hv_store(exception, "mesg", 4, newSVpv(ldap_err2string(rc),0),0);

	stash = gv_stashpv("Net::LDAPxs::Exception", GV_ADDWARN);
	object = newRV_inc((SV*)exception);
	sv_bless(object, stash);

	return object;
}


MODULE = Net::LDAPxs		PACKAGE = Net::LDAPxs		

REQUIRE:    1.929

INCLUDE: const-xs.inc


LDAP *
_new(class, args_ref)
		SV *args_ref
	PREINIT:
		HV *args;
		char *host;
		int port;
		int version;
		char *scheme;
		SV** svp;
	CODE:
		if (SvROK(args_ref) &&
			SvTYPE(SvRV(args_ref)) == SVt_PVHV)
		{
			args = (HV*)SvRV(args_ref);
		}else{
			croak("Usage: Net::LDAPxs->new(HOST, port => PORT)");
		}
		if ((svp = hv_fetch(args, "host", 4, FALSE)) && SvPOK(*svp)) {
			host = (char *)SvPV_nolen(*svp);
		}else{
			croak("_new(host): not a string");
		}
		if ((svp = hv_fetch(args, "port", 4, FALSE)) && SvIOK(*svp)) {
			port = SvIV(*svp);
		}else{
			croak("_new(port): not a number");
		}
		if ((svp = hv_fetch(args, "version", 7, FALSE))  && SvIOK(*svp)) {
			version = SvIV(*svp);
		}else{
			croak("_new(version): not a number");
		}
		if ((svp = hv_fetch(args, "scheme", 6, FALSE)) && SvPOK(*svp)) {
			scheme = (char *)SvPV_nolen(*svp);
		}else{
			croak("_new(scheme): not a string");
		}

		RETVAL = _connect(host, port, version, scheme);
	OUTPUT:
		RETVAL

SV *
_bind(ld, opt)
		LDAP *ld
		HV *opt
	PREINIT:
		SV** svp;
		int rc;
		char *binddn, *bindpasswd;
		int async;
		int msgid;
		struct berval   passwd = { 0, NULL };

		char *matched = NULL, *errmsg = NULL; 
		char **referrals;
		LDAPControl **resultctrls = NULL;
		LDAPMessage *result;
		struct berval       *servercredp;
	CODE:
		if ((svp = hv_fetch(opt, "binddn", 6, FALSE)) && SvPOK(*svp)) {
			binddn = (char *)SvPV_nolen(*svp);
		}else{
			croak("_bind(binddn): not a string");
		}
		if (hv_exists(opt, "bindpw", 6)) {
			if ((svp = hv_fetch(opt, "bindpw", 6, FALSE)) && SvPOK(*svp)) {
				bindpasswd = (char *)SvPV_nolen(*svp);
				passwd.bv_val = ber_strdup( bindpasswd );
				passwd.bv_len = strlen( passwd.bv_val );
			}else{
				croak("_bind(bindpw): not a string");
			}
		}else{
			bindpasswd = "0";
			passwd.bv_val = ber_strdup( bindpasswd );
			passwd.bv_len = strlen( passwd.bv_val );
		}
		if ((svp = hv_fetch(opt, "async", 5, FALSE)) && SvIOK(*svp)) {
			async = SvIV(*svp);
		}else{
			croak("_bind(async): not a number");
		}

		ldap_set_option( ld, LDAP_OPT_REFERRALS, LDAP_OPT_ON );

		if (async == 0) {
			rc = ldap_sasl_bind_s( ld, binddn, LDAP_SASL_SIMPLE, &passwd, NULL, NULL, &servercredp );
		}else if(async == 1) {
			/* The asynchronous version of this API only supports the LDAP_SASL_SIMPLE mechanism. */
			rc = ldap_sasl_bind( ld, binddn, LDAP_SASL_SIMPLE, &passwd, NULL, NULL, &msgid );
			ldap_result( ld, msgid, LDAP_MSG_ALL, NULL, &result );
			ldap_parse_result( ld, result, &rc, &matched, &errmsg, &referrals, &resultctrls, 0 ); 
		}else{ }
		RETVAL = rc_exception(rc);
	OUTPUT:
		RETVAL

void
_unbind(ld)
		LDAP* ld
	PPCODE:
		ldap_unbind_ext(ld, NULL, NULL);

void
_search(ld, opt)
		LDAP *ld
		HV *opt
	PREINIT:
		int rc;
		SV** svp;

		char *base;
		int scope;
		char *filter;
		int sizelimit;
		int async;

		SV** elem;
		AV* avref;
		int len = 0;
		char **attrs = NULL;
		LDAPMessage *result;
		AV* entries;

		HV* ctrl;
		int type = 0;
		char *value;
		int critical = 0;

		char *matched = NULL, *errmsg = NULL; 
		char **referrals;
		LDAPControl *sortctrl = NULL;
		LDAPControl *requestctrls[2];
		LDAPControl **resultctrls = NULL;
		LDAPSortKey **sortkeylist;
		int msgid;

		HV* search_result;
		HV* stash;
		SV* blessed_result;
	PPCODE:
		if ((svp = hv_fetch(opt, "base", 4, FALSE)) && SvPOK(*svp)) {
			base = (char *)SvPV_nolen(*svp);
		}else{
			croak("_search(base): not a string");
		}
		if ((svp = hv_fetch(opt, "scope", 5, FALSE)) && SvIOK(*svp)) {
			scope = SvIV(*svp);
		}else{
			croak("_search(scope): not a number");
		}
		if ((svp = hv_fetch(opt, "filter", 6, FALSE)) && SvPOK(*svp)) {
			filter = (char *)SvPV_nolen(*svp);
		}else{
			croak("_search(filter): not a string");
		}
		if ((svp = hv_fetch(opt, "sizelimit", 9, FALSE)) && SvIOK(*svp)) {
			sizelimit = SvIV(*svp);
		}else{
			croak("_search(sizelimit): not a number");
		}
		if ((svp = hv_fetch(opt, "async", 5, FALSE)) && SvIOK(*svp)) {
			async = SvIV(*svp);
		}else{
			croak("_search(async): not a number");
		}

		if ((svp = hv_fetch(opt, "attrs", 5, FALSE)) && SvROK(*svp)) {
			int i;
			avref = (AV*)SvRV(*svp);
			len = av_len(avref) + 1;
			if (len == 0) {
				attrs = NULL;
			}else{
				attrs = (char **)malloc((len+1)*sizeof(char *));
				for (i = 0; i < len; i++) {
					elem = av_fetch(avref, i, 0);
					if (elem != NULL) {
						attrs[i] = (char *)SvPV_nolen(*elem);
					}
				}
				attrs[i] = NULL;
			}
		}else{
			attrs = NULL;
		}
		if ((svp = hv_fetch(opt, "control", 7, FALSE))) {
			/* there is a control request */
			if (SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV) {
				ctrl = (HV*)SvRV(*svp);
				if ((svp = hv_fetch(ctrl, "type", 4, FALSE)) && SvIOK(*svp)) {
					type = SvIV(*svp);
				}else{
					croak("_search(ctrl-type): not a number");
				}
				if ((svp = hv_fetch(ctrl, "value", 5, FALSE)) && SvPOK(*svp)) {
					value = (char *)SvPV_nolen(*svp);
				}else{
					croak("_search(ctrl-value): not a string");
				}
				if ((svp = hv_fetch(ctrl, "critical", 8, FALSE)) && SvIOK(*svp)) {
					critical = SvIV(*svp);
				}else{
					croak("_search(ctrl-critical): not a number");
				}
			}else{
				croak("_search(ctrl): control object is not a hash");
			}

		/* Server Side Sorting control */
			ldap_create_sort_keylist( &sortkeylist, value );
			rc = ldap_create_sort_control( ld, sortkeylist, critical, &sortctrl ); 
			if (rc != LDAP_SUCCESS) { 
				fprintf( stderr, "ldap_create_sort_control: %s\n", ldap_err2string(rc) ); 
				ldap_unbind_ext(ld, NULL, NULL);
				exit( EXIT_FAILURE );
			} 
			requestctrls[0] = sortctrl; 
			requestctrls[1] = NULL;
		/* end */
		}else{
			/* there is no control request */
			requestctrls[0] = NULL;
			requestctrls[1] = NULL;
		}

        search_result = newHV();
		EXTEND(SP, 1);
		if (async == 0) {
			/* Synchronous bind request */
			rc = ldap_search_ext_s(ld, base, scope, filter, attrs, 0,
				requestctrls, NULL, LDAP_NO_LIMIT, sizelimit, &result);
			if (requestctrls[0] != NULL) {
			/* free the control */
				ldap_free_sort_keylist( sortkeylist );
				ldap_control_free( sortctrl );
			}

    		if (rc != LDAP_SUCCESS) {
    			PUSHs(sv_2mortal(rc_exception(rc)));
    		}else{
        		free(attrs);
        		entries = get_entries(ld, result);
        		ldap_msgfree(result);
        
        		hv_store(search_result, "entries", 7, newRV_noinc((SV*)entries), 0);
        		hv_store(search_result, "mesgid", 6, newSViv(len-1), 0);
        
        		stash = gv_stashpv("Net::LDAPxs::Search", GV_ADD);
        		blessed_result = newRV_inc((SV*)search_result);
        		sv_bless(blessed_result, stash);
        
        		PUSHs(sv_2mortal(blessed_result));
    		}
		}else if (async == 1) {
			/* Asynchronous bind request */
			rc = ldap_search_ext(ld, base, scope, filter, attrs, 0,
				requestctrls, NULL, LDAP_NO_LIMIT, sizelimit, &msgid);
			ldap_result( ld, msgid, LDAP_MSG_ALL, NULL, &result );
			ldap_parse_result( ld, result, &rc, &matched, &errmsg, &referrals, &resultctrls, 0 );
			if (rc != LDAP_SUCCESS) {
				PUSHs(sv_2mortal(rc_exception(rc)));
			}else{
        		entries = get_entries(ld, result);
        		ldap_msgfree(result);
        
        		search_result = newHV();
        		hv_store(search_result, "entries", 7, newRV_noinc((SV*)entries), 0);
        		hv_store(search_result, "mesgid", 6, newSViv(len-1), 0);
        
        		stash = gv_stashpv("Net::LDAPxs::Search", GV_ADD);
        		blessed_result = newRV_inc((SV*)search_result);
        		sv_bless(blessed_result, stash);
        
        		PUSHs(sv_2mortal(blessed_result));
			}
		}else{ }


int
count(ld, res)
	INPUT:
		LDAP *ld
		LDAPMessage *res
	CODE:
		RETVAL = ldap_count_entries(ld, res);
	OUTPUT:
		RETVAL


SV *
_add(ld, dn, attrs_ref)
		LDAP *ld
		char *dn
		SV* attrs_ref
	PREINIT:
		HV *attrs_hv;
		int rc;
	CODE:
		if (SvROK(attrs_ref) &&
			SvTYPE(SvRV(attrs_ref)) == SVt_PVHV)
		{
			LDAPMod **list_of_attrs; 
			attrs_hv = (HV*)SvRV(attrs_ref);

			ldap_add_mods(attrs_hv, &list_of_attrs);
			rc = ldap_add_ext_s(ld, dn, list_of_attrs, NULL, NULL);
			free_attrs(list_of_attrs);
			RETVAL = rc_exception(rc);
		}else{
			Perl_croak(aTHX_ "The value for option 'attrs' should be a hash ref");
		}
	OUTPUT:
		RETVAL


SV *
_modify(ld, dn, attrs_ref)
		LDAP *ld
		char *dn
		SV* attrs_ref
	PREINIT:
		AV *attrs_av;
		int rc;
	CODE:
		if (SvROK(attrs_ref) &&
			SvTYPE(SvRV(attrs_ref)) == SVt_PVAV)
		{
			LDAPMod **list_of_attrs; 
			attrs_av = (AV*)SvRV(attrs_ref);

			ldapmod_struct(attrs_av, &list_of_attrs);
			rc = ldap_modify_ext_s(ld, dn, list_of_attrs, NULL, NULL);
			free_attrs(list_of_attrs);
			RETVAL = rc_exception(rc);
		}else{
			Perl_croak(aTHX_ "The value for option should be a hash ref");
		}
	OUTPUT:
		RETVAL


SV *
_moddn(ld, dn, attrs_ref)
		LDAP *ld
		char *dn
		SV* attrs_ref
	PREINIT:
		SV** svp;
		HV *attrs_hv;

		int rc;

		char *newrdn=NULL;
		char *newSuperior=NULL;
		int deleteoldrdn=0;
	CODE:
		if (SvROK(attrs_ref) &&
			SvTYPE(SvRV(attrs_ref)) == SVt_PVHV)
		{
			attrs_hv = (HV*)SvRV(attrs_ref);

			if ((svp = hv_fetch(attrs_hv, "newrdn", 6, FALSE)) && SvPOK(*svp)) {
				newrdn = (char *)SvPV_nolen(*svp);
			}else{
				croak("_moddn(newrdn): not a string");
			}
			if ((svp = hv_fetch(attrs_hv, "newsuperior", 11, FALSE)) && SvPOK(*svp)) {
				newSuperior = (char *)SvPV_nolen(*svp);
			}else{
				/* if no "newsuperior" present, use default value. */
			}
			if ((svp = hv_fetch(attrs_hv, "deleteoldrdn", 12, FALSE)) && SvIV(*svp)) {
				deleteoldrdn = SvIV(*svp);
			}else{
				croak("_moddn(deleteoldrdn): not a string");
			}
			rc = ldap_rename_s(ld, dn, newrdn, newSuperior, deleteoldrdn,NULL, NULL);
			RETVAL = rc_exception(rc);
		}else{
			Perl_croak(aTHX_ "The value for option should be a hash ref");
		}
	OUTPUT:
		RETVAL


SV *
_compare(ld, dn, attr, value)
		LDAP *ld
		char *dn
		char *attr
		char *value
	PREINIT:
		struct berval bvalue = { 0, NULL };
		int rc;
	CODE:
		bvalue.bv_val = strdup( value );
		bvalue.bv_len = strlen( bvalue.bv_val );

		rc = ldap_compare_ext_s(ld, dn, attr, &bvalue, NULL, NULL); 
		free(bvalue.bv_val);
		if (rc == LDAP_COMPARE_TRUE) {
			RETVAL = rc_exception(0);
		}else{
			RETVAL = rc_exception(rc);
		}
	OUTPUT:
		RETVAL

SV *
_delete(ld, dn)
		LDAP *ld
		char *dn
	PREINIT:
		int rc;
	CODE:
		rc = ldap_delete_ext_s(ld, dn, NULL, NULL);
		RETVAL = rc_exception(rc);
	OUTPUT:
		RETVAL




MODULE = Net::LDAPxs		PACKAGE = Net::LDAPxs::Control::Sort		

REQUIRE:    1.929

INCLUDE: const-xs.inc


SV *
new(class, args_ref)
		SV *args_ref
	PREINIT:
		HV *args;
		char *value;
		int critical;

		SV** svp;
	CODE:
		if (SvROK(args_ref) &&
			SvTYPE(SvRV(args_ref)) == SVt_PVHV)
		{
			args = (HV*)SvRV(args_ref);
		}else{
			Perl_croak(aTHX_ "Usage: Net::LDAPxs->new(HOST, port => PORT)");
		}
		if ((svp = hv_fetch(args, "value", 5, FALSE)))
			value = (char *)SvPV_nolen(*svp);
		if ((svp = hv_fetch(args, "critical", 8, FALSE)))
			critical = SvIV(*svp);

		RETVAL = rc_exception(0);
	OUTPUT:
		RETVAL


