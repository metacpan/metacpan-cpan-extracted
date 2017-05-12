#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdlib.h>
#include <ctype.h>

#define ENCODE_BUF 128
#define SKIPSPACES(p) while( *p==' ' || *p=='\t' || *p=='\r' || *p=='\n' ) p++;
#define SKIPSPACES_P(p) while( (*p)[0]==' ' || (*p)[0]=='\t' || (*p)[0]=='\r' || (*p)[0]=='\n' ) (*p)++;
#define IS_DELIM_CHAR(c) (isspace(c) || (c==',') || (c=='=') || (c=='>'))

int get_next_string(char **p, char *part, int is_key) {
	SKIPSPACES_P(p);
	if( (*p)[0] == '"' ) { // Work with quoted string
		int cnt=0;
		(*p)++;
		while( (*p)[0] != '"' && (*p)[0] != 0 ) {
			if ((*p)[0] == 0)
				return -2; // Unexpected end of string
			if( (*p)[0] == '\\' )
				(*p)++;
			*(part++) = *((*p)++);
			cnt++;
		}
		*part = 0;
		(*p)++; //skip "
		// fprintf(stderr, "get_next_string returning %d: %s (quoted)\n", cnt, &part[-cnt]);
		return cnt;
	}
	else if( !is_key && toupper((*p)[0]) == 'N' && toupper((*p)[1]) == 'U' && toupper((*p)[2]) == 'L' && toupper((*p)[3]) == 'L' ) {
		*part=0;
		(*p)+=4;
		// fprintf(stderr,"get_next_string returning %d: NULL\n", -1);
		return -1;
	}
	else if ((*p)[0] != 0 && !IS_DELIM_CHAR((*p)[0])) { // work with unquoted string
		int cnt=0;
		while( !IS_DELIM_CHAR((*p)[0]) ) {
			if ((*p)[0] == 0)
			    return -2; // Unexpected end of string
			if( (*p)[0] == '\\' )
				(*p)++;
			*(part++) = *((*p)++);
			cnt++;
		}
		*part = 0;
		// fprintf(stderr,"get_next_string returning %d: %s (unquoted)\n", cnt, &part[-cnt]);
		return cnt;
	}
	// fprintf(stderr,"get_next_string returning -2: ERROR\n");
	return -2; //error
}

MODULE = Pg::hstore		PACKAGE = Pg::hstore		

SV *
encode(SV *hashref)
PROTOTYPE: $
INIT:
	char *buf;
	HV *hash;
	int buf_len=ENCODE_BUF;
	int buf_fill=0, itemcnt=0;
	HE *ent;
	I32 keylen, i, utf8_flag_found=0;
	STRLEN vallen;
	char *key, *val;
	SV *valsv, *res;
CODE:
	//Check param
	if( !SvOK(hashref) || !SvROK(hashref) || SvTYPE(SvRV(hashref))!=SVt_PVHV ) {
		XSRETURN_UNDEF;
	}
	hash = (HV*) SvRV(hashref);

	buf = (char*)malloc(buf_len);
	if( buf == NULL ) {
		vwarn("malloc fail", NULL);
		XSRETURN_UNDEF;
	}
	buf[0]=0; //Fix for case we have empty hash so newSVpv with 0 len wont fail

	//Iterate hash
	hv_iterinit(hash);
	while( (ent = hv_iternext(hash)) != NULL ) {
		// Get key
		key = hv_iterkey(ent, &keylen);
		if( key==NULL || keylen<1 ) {
			continue;
		}

		// Get value
		valsv = hv_iterval(hash, ent);
		if( valsv==NULL ) {
			continue;
		}
		utf8_flag_found |= SvUTF8(valsv);
		if( SvOK(valsv) ) {
			val=SvPV(valsv, vallen);
		}else{
			val=NULL;
			vallen=0;
		}

		// Check we have buf mem
		if( (buf_fill+(vallen+keylen)*2+10) > buf_len ) {
			//Add 10 cus it can be 4x'"', 1x' => ', 1x', '
			//We mul to 2 cus each character can be escaped with '\'
			buf_len += (vallen+keylen)*2+10+ENCODE_BUF;
			char *newbuf = (char*)realloc(buf, buf_len);
			if( newbuf == NULL ) {
				vwarn("realloc fail", NULL);
				free(buf);
				XSRETURN_UNDEF;
			}
			buf = newbuf;
			//printf("realloc\n");
		}

		//Concat to string
		//printf("key %s(%d) val %s(%d)\n", key, keylen, val, vallen);
		if( itemcnt ) {
			buf[buf_fill++]=',';
			buf[buf_fill++]=' ';
		}
		buf[buf_fill++]='"';
		for(i=0; i<keylen; i++) {
			if( key[i]=='\\' || key[i]=='"' ) {
				buf[buf_fill++]='\\';
			}
			buf[buf_fill++]=key[i];
		}
		strcpy(&buf[buf_fill], "\" => ");
		buf_fill+=5;

		if( val==NULL ) {
			strcpy(&buf[buf_fill], "NULL");
			buf_fill+=4;
		}else{
			buf[buf_fill++]='"';
			for(i=0; i<vallen; i++) {
				if( val[i]=='\\' || val[i]=='"' ) {
					buf[buf_fill++]='\\';
				}
				buf[buf_fill++]=val[i];
			}
			buf[buf_fill++]='"';
		}

		itemcnt++;
	}//while(ent)

	res = newSVpv(buf, buf_fill);
	if( utf8_flag_found ) {
		SvUTF8_on(res);
	}
	RETVAL = res;
	free(buf);
OUTPUT:
	RETVAL


SV *
decode(sv_str)
	SV *sv_str;
PROTOTYPE: $
INIT:
	char *p;
	char *str;
	U32 str_is_utf8;
	HV *hash;
	char *key, *value;
	int r_key, r_val;
	SV *svkey, *svval;
CODE:
	str_is_utf8 = SvUTF8(sv_str); // Is utf flag on

	str = SvPV_nolen(sv_str);
	//printf("str_is_utf8=%d\n", str_is_utf8);
	p=str;
	//printf("got string: %s\n", p);

	hash = newHV();
	RETVAL = newRV_noinc( (SV*) hash );

	// Get bufs for key/value pairs
	key = (char*) malloc( strlen(str) );
	if( key == NULL ) {
		XSRETURN_UNDEF;
	}
	value = (char*) malloc( strlen(str) );
	if( value == NULL ) {
		free(key);
		XSRETURN_UNDEF;
	}

	// Iterate whole string
	while( *p != 0 ) {
		r_key = get_next_string(&p, key, 1);
		if( r_key < 0 ) //lets think keys cannot be NULL
			break; //Error

		// check there is a "=>" sign
		SKIPSPACES(p);
		if( (p[0] != '=') || (p[1] != '>') )
			break;
		p+=2;

		r_val = get_next_string(&p, value, 0);
		if( r_val == -2 )
			break; //Error

		//Skip possible comma
		SKIPSPACES(p);
		if( *p == ',' ) p++;

		// Store key/value we got
		//printf("key=%s(%d) val=%s(%d)\n", key, r_key, value, r_val);
		svkey = r_key<0 ? newSV(0) : newSVpvn(key, r_key);
		svval = r_val<0 ? newSV(0) : newSVpvn(value, r_val);
		//printf("str_is_utf8=%d\n", str_is_utf8);
		if( str_is_utf8 ) {
			if( SvOK(svkey) && !SvUTF8(svkey) ) {
				SvUTF8_on(svkey);
			}
			if( SvOK(svval) && !SvUTF8(svval) ) {
				SvUTF8_on(svval);
			}
		}
		if( hv_store_ent(hash, svkey, svval, 0) == NULL )
			SvREFCNT_dec(svval);
		SvREFCNT_dec(svkey);
	}
	// Free bufs
	free(key);
	free(value);
OUTPUT:
	RETVAL
