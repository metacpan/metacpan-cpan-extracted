/* common functions for Perl/Qt4 */


#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "common.h"
#include <QtCore/qbytearray.h>


/* Used by the INPUT typemap for char**.
 * Will convert a Perl AV* (containing strings) to a C char**.
 */
char **
XS_unpack_charPtrPtr( SV *rv )
{
	AV *av;
	SV **ssv;
	char **s;
	int avlen;
	int x;
	STRLEN na;

	if( SvROK( rv ) && (SvTYPE(SvRV(rv)) == SVt_PVAV) )
		av = (AV*)SvRV(rv);
	else {
		warn("XS_unpack_charPtrPtr: rv was not an AV ref");
		return( (char**)NULL );
	}

	/* is it empty? */
	avlen = av_len(av);
	if( avlen < 0 ){
		/* warn("XS_unpack_charPtrPtr: array was empty"); */
		return( (char**)NULL );
	}

	/* av_len+2 == number of strings, plus 1 for an end-of-array sentinel.
	 */
	s = (char **)safemalloc( sizeof(char*) * (avlen + 2) );
	if( s == NULL ){
		warn("XS_unpack_charPtrPtr: unable to malloc char**");
		return( (char**)NULL );
	}
	for( x = 0; x <= avlen; ++x ){
		ssv = av_fetch( av, x, 0 );
		if( ssv != NULL ){
			if( SvPOK( *ssv ) ){
				s[x] = (char *)safemalloc( SvCUR(*ssv) + 1 );
				if( s[x] == NULL )
					warn("XS_unpack_charPtrPtr: unable to malloc char*");
				else
					strcpy( s[x], SvPV( *ssv, na ) );
			}
			else
				warn("XS_unpack_charPtrPtr: array elem %d was not a string.", x );
		}
		else
			s[x] = (char*)NULL;
	}
	s[x] = (char*)NULL; /* sentinel */
	return( s );
}



/* Used by the OUTPUT typemap for char**.
 * Will convert a C char** to a Perl AV*.
 */
void
XS_pack_charPtrPtr(SV *st, char **s )
{
	AV *av = newAV();
	SV *sv;
	char **c;

	for( c = s; *c != NULL; ++c ){
		sv = newSVpv( *c, 0 );
		av_push( av, sv );
	}
	sv = newSVrv( st, NULL );	/* upgrade stack SV to an RV */
	SvREFCNT_dec( sv );	/* discard */
	SvRV( st ) = (SV*)av;	/* make stack RV point at our AV */
}



SV *
class2pobj(IV iv, const char *class_name, int no_ptr)
{
        HV *hv = newHV();
        SV *retval = newSV(0);
        sv_setiv(retval, iv);
        hv_store(hv, "_ptr", 4, retval, 0);
        hv_store(hv, "_del", 4, newSViv(no_ptr), 0);
        return sv_bless(newRV_noinc((SV*)hv), gv_stashpv(class_name, 0));
}


IV
pobj2class(SV *sv, const char *class_name, const char *func, const char *var)
{
    char pclass_name[512];
    char fn_warn[512];
    char ptr_warn[512];
    snprintf(pclass_name, 512, "Qt::%s", class_name);
    snprintf(fn_warn, 512, "%s() -- %s is not blessed Qt::%s", func, var, class_name);
    snprintf(ptr_warn, 512, "%s() -- %s->{_ptr} is NULL", func, var);
    
    if( sv_derived_from(sv, pclass_name) && (SvTYPE(SvRV(sv)) == SVt_PVHV) ) {
	HV *hv = (HV*)SvRV( sv );
	SV **ssv = hv_fetch(hv, "_ptr", 4, 0);
	if ( ssv != NULL )
	    return SvIV(*ssv);
	warn( ptr_warn );
	return (IV)NULL;
    }
    warn( fn_warn );
    return (IV)NULL;
}


int 
create_meta_data (char *sss, AV *signal_av, AV *slot_av, char **stringdata, uint **data)
{
    STRLEN ln;
    int fn = qstrlen(sss)+1;
    int cnt_s = 0;
    int avlen;
    SV **ssv;

	cnt_s = av_len(signal_av) + av_len(slot_av) + 2;
	*data = new uint[11 + 5 * cnt_s];
	if ( !data )
	    Perl_croak(aTHX_ "Can not allocate memory for data");
	(*data)[0] = 1;
	(*data)[1] = 0;
	(*data)[2] = 0;
	(*data)[3] = 0;
	(*data)[4] = cnt_s;
	if ( cnt_s )
	    (*data)[5] = 10;
	else
	    (*data)[5] = 0;
	(*data)[6] = 0;
	(*data)[7] = 0;
	(*data)[8] = 0;
	(*data)[9] = 0;
	cnt_s = 10;
	if ( cnt_s > 0 ) {
	    int qq = fn;
	    sss[fn] = 0;
	    fn++;
	    avlen = av_len(signal_av);
	    for( int a = 0; a <= avlen; ++a ){
		ssv = av_fetch( signal_av, a, 0 );
		if ( ssv != NULL && SvPOK( *ssv ) ) {
		    (*data)[cnt_s++] = fn;
		    (*data)[cnt_s++] = qq;
		    (*data)[cnt_s++] = qq;
		    (*data)[cnt_s++] = qq;
		    (*data)[cnt_s++] = 0x05;
		    char * sl = (char *)SvPV( *ssv, ln );
		    for ( int i = 0 ; i <= ln ; i++ )
			sss[i+fn] = sl[i];
		    fn += ln;
		    fn++;
		    
		}
	    }
	    avlen = av_len(slot_av);
	    for( int a = 0; a <= avlen; ++a ){
		ssv = av_fetch( slot_av, a, 0 );
		if( ssv != NULL  && SvPOK( *ssv ) ) {
		    (*data)[cnt_s++] = fn;
		    (*data)[cnt_s++] = qq;
		    (*data)[cnt_s++] = qq;
		    (*data)[cnt_s++] = qq;
		    (*data)[cnt_s++] = 0x0a;
		    char * sl = (char *)SvPV( *ssv, ln );
		    for ( int i = 0 ; i <= ln ; i++ )
			sss[i+fn] = sl[i];
		    fn += ln;
		    fn++;
		}
	    }
	}
	fn--;
	(*data)[cnt_s] = 0;

	
	*stringdata = new char[fn+1];
	if ( !(*stringdata) )
	    Perl_croak(aTHX_ "Can not allocate memory for stringdata");
	for ( int i = 0 ; i <= fn ; i++ )
	    (*stringdata)[i] = sss[i];
/*
	printf("perl xs :\n");
	
	for ( int i = 0 ; i <= fn ; i++ )
	    if ( (*stringdata)[i] == 0 )
		printf("\\0");
	    else
		putchar((*stringdata)[i]);
	printf("\n");
	for ( int i = 0 ; i <= cnt_s ; i++ )
	    printf("data : %d %d\n", i, (*data)[i]);
*/
    return fn;
}


void common_slots(int _id, void **_a, const char *stringdata, const uint *data, void *class_ptr, char *clFn)
{
    int i = 0, cnt = 0, k = 0;
    char sl[1024], sl2[128];
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    // XPUSHs(sv_2mortal(newSViv(perl_cl_ref)));
    XPUSHs(sv_2mortal(newSViv(PTR2IV(class_ptr))));

    for ( int j = data[10 + _id * 5] ; stringdata[j] != 0 ; i++, j++  ) {
        sl[i] = stringdata[j];
        if ( cnt ) {
            if ( sl[i-1] == '(' && sl[i] == ')' )
                cnt = 0;
            else {
                if ( sl[i] == ')' || sl[i] == ',' ) {
                    sl2[k] = 0;
                    if (  !strcmp("short", sl2) )
                        XPUSHs(sv_2mortal(newSViv(  (*reinterpret_cast< short(*)>(_a[cnt]))  )));
                    else if ( !strcmp("int", sl2) )
                        XPUSHs(sv_2mortal(newSViv(  (*reinterpret_cast< int(*)>(_a[cnt]))  )));
                    else if ( !strcmp("long", sl2) )
                        XPUSHs(sv_2mortal(newSViv(  (*reinterpret_cast< long(*)>(_a[cnt]))  )));
                    else if ( !strcmp("bool", sl2) )
                        XPUSHs(sv_2mortal(newSVuv(  (*reinterpret_cast< bool(*)>(_a[cnt]))  )));
                    else if ( !strcmp("uint", sl2) )
                        XPUSHs(sv_2mortal(newSVuv(  (*reinterpret_cast< uint(*)>(_a[cnt]))  )));
                    else if ( !strcmp("ulong", sl2) )
                        XPUSHs(sv_2mortal(newSVuv(  (*reinterpret_cast< ulong(*)>(_a[cnt]))  )));
                    else if ( !strcmp("qreal", sl2) )
                        XPUSHs(sv_2mortal(newSVnv(  (*reinterpret_cast< qreal(*)>(_a[cnt]))  )));
                    else if ( !strcmp("double", sl2) )
                        XPUSHs(sv_2mortal(newSVnv(  (*reinterpret_cast< double(*)>(_a[cnt]))  )));
                    else if ( !strcmp("char*", sl2) )
                        XPUSHs(sv_2mortal(newSVpv(  (*reinterpret_cast< char*(*)>(_a[cnt])), 0  )));
                    cnt++;
                    k = 0;
                }
                else {
                    sl2[k] = sl[i];
                    k++;
                }
            } // ! ( && )
        }
        if ( sl[i] == '(' ) {
            strncpy(sl2, sl, i);
            sl2[i] = 0;
            XPUSHs(sv_2mortal(newSVpv(sl2, 0)));
            cnt = 1;
        }
    }
    sl[i] = 0;

    PUTBACK;
    call_pv(clFn, G_DISCARD);
    FREETMPS;
    LEAVE;
};


