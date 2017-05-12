#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <atmi.h>
#include <fml32.h>
#include <fml.h>
#include <tx.h>
#include <xa.h>
#include <Usignal.h>
#include <userlog.h>

void InitTuxedoConstants();
long getTuxedoConstant( char *name );

typedef char *          CHAR_PTR;
typedef TPINIT *        TPINIT_PTR;
typedef FBFR32 *        FBFR32_PTR;
typedef CLIENTID *      CLIENTID_PTR;
typedef TPTRANID *      TPTRANID_PTR;
typedef XID *           XID_PTR;
typedef TPQCTL *        TPQCTL_PTR;
typedef TPEVCTL *       TPEVCTL_PTR;
typedef TXINFO *        TXINFO_PTR;
typedef TPSVCINFO *     TPSVCINFO_PTR;

static HV * UnsolicitedHandlerMap = (HV *)NULL;

void _TMDLLENTRY
unsolicited_message_handler( data, len, flags )
    char * data;
    long len;
    long flags;
{
    long context = 0;
    long nullContext = TPNULLCONTEXT;
    int rval;
    dSP ;
    SV ** sv;

    /* get the context */
    rval = tpgetctxt( &context, 0 );

    /* get the callback handler associated with this context */
    sv = hv_fetch( UnsolicitedHandlerMap, 
                   (char *)&context,
                   sizeof(context),
                   FALSE
                   );

    if ( sv == (SV**)NULL )
    {
        /* should search for the TPNULLCONTEXT entry */
        sv = hv_fetch( UnsolicitedHandlerMap, 
                       (char *)&nullContext,
                       sizeof(nullContext),
                       FALSE
                       );

        if ( sv == (SV**)NULL )
            croak( "Could not find unsolicted message handler for context %d "
                   " or the NULL context.\n",
                   context
                   );
    }

    PUSHMARK( SP );
    XPUSHs( newRV_inc( sv_2mortal(newSViv((IV)data)) ) );
    XPUSHs( sv_2mortal(newSViv(len)) );
    XPUSHs( sv_2mortal(newSViv(flags) ) );
    PUTBACK ;

    /* call the Perl sub */
    perl_call_sv( *sv, G_DISCARD );
}


static HV * signum        = (HV *)NULL;

static void
signum_init()
{
    int signumIV;
    char *sig_num;
    char *sig_name;
    char *numDelim;
    char *nameDelim;
    STRLEN n_a;
    SV **svPtr;
    SV * value;
    I32 len;

    HV * Config = get_hv( "Config", FALSE );

    if ( Config == NULL )
        croak( "Could not access the %%Config variable to get signal names and numbers.\n" );

    svPtr = hv_fetch( Config, (char *)"sig_num", strlen("sig_num"), FALSE );
    if ( svPtr == (SV**)NULL )
        croak( "Could not get the value of $Config{sig_num}.\n" );
    sig_num = SvPV( *svPtr, n_a );

    svPtr = hv_fetch( Config, (char *)"sig_name", strlen("sig_name"), FALSE );
    if ( svPtr == (SV**)NULL )
        croak( "Could not get the value of $Config{sig_name}.\n" );
    sig_name = SvPV( *svPtr, n_a );

    signum = newHV();
    for ( ; ; )
    {
        numDelim  = strchr( sig_num + 1, ' ' );
        nameDelim = strchr( sig_name + 1, ' ' );

        if ( numDelim != NULL ) *numDelim = '\0';
        if ( nameDelim != NULL ) *nameDelim = '\0';

        sscanf( sig_num, "%d", &signumIV );

        hv_store( signum, 
                  (char*)sig_name, 
                  strlen(sig_name), 
                  newSViv(signumIV),
                  0
                  );

        if ( numDelim == NULL || nameDelim == NULL ) break;

        sig_num  = numDelim + 1;
        sig_name = nameDelim + 1;
    }

/*
    hv_iterinit( signum );
    value =  hv_iternextsv( signum, &sig_name, &len );
    while ( value != NULL )
    {
        signumIV = SvIV( value );
        printf( "signum{%s} = %d\n", sig_name, signumIV );
        value =  hv_iternextsv( signum, &sig_name, &len );
    }
*/
}

static HV * SignalHandlerMap = (HV *)NULL;

static void
signal_handler( sig_num )
    int sig_num;
{
    dSP ;
    SV ** sv;

    /* get the callback handler associated with this context */
    sv = hv_fetch( SignalHandlerMap, 
                   (char *)&sig_num,
                   sizeof(sig_num),
                   FALSE
                   );

    if ( sv == (SV**)NULL )
        croak( "Could not find signal handler for signal %d.\n",
               sig_num
               );

    PUSHMARK( SP );
    XPUSHs( sv_2mortal(newSViv(sig_num)) );
    PUTBACK ;

    /* call the Perl sub */
    perl_call_sv( *sv, G_DISCARD );
}

int buffer_setref( SV * sv, char *buffer )
{
    char type[16];

    int rc = tptypes( buffer, type, NULL );
    if ( rc != -1 )
    {
        if ( !strcmp(type, "TPINIT") )
            sv_setref_pv(sv, "TPINIT_PTR", (void*)buffer);
        else if ( !strcmp(type, "FML32") )
            sv_setref_pv(sv, "FBFR32_PTR", (void*)buffer);
        else
            sv_setref_pv(sv, Nullch, (void*)buffer);
    }
    return rc;
}

/*
 * Should eventually remove this completely from this module
 *
void
handlePerlSignals()
    PREINIT:
    char * key;
    IV signumIV;
    I32 len;
    SV * value;
    HV * SIG;
    STRLEN n_a;
    SV ** sv;
    CODE:
    SIG = get_hv( "SIG", FALSE );
    if ( SIG != NULL )
    {
        hv_iterinit( SIG );
        value = hv_iternextsv( SIG, &key, &len );
        while ( value != NULL )
        {
            if ( SvOK(value) )
            {
                sv = hv_fetch( signum, 
                               (char *)key,
                               strlen(key),
                               FALSE
                               );

                if ( sv != NULL )
                {
                    signumIV = SvIV( *sv );
                    printf( "Setting Perl signal handler for SIG%s [%d]\n", key, signumIV );
                    Usignal( signumIV, Perl_sighandler );
                }
            }

            value = hv_iternextsv( SIG, &key, &len );
        }
    }
*/


MODULE = TUXEDO    PACKAGE = TUXEDO        

BOOT:
    InitTuxedoConstants();
    signum_init();



long
constant( name, arg )
    char * name
    int arg
    CODE:
        RETVAL = getTuxedoConstant( name );
    OUTPUT:
        RETVAL

long
TPINITNEED( datalen )
    long datalen
    CODE:
        RETVAL = TPINITNEED( datalen );
    OUTPUT:
        RETVAL

int
tpabort( flags )
    long flags

void
tpalloc(type,subtype,size)
    char *type
    char *subtype
    long size
    PREINIT:
        char *ptr;
    CODE:
        ptr = tpalloc( type, subtype, size );
        ST(0) = sv_newmortal();
        if ( ptr )
        {
            if ( !strcmp(type, "TPINIT") )
                sv_setref_pv(ST(0), "TPINIT_PTR", (void*)ptr);
            else if ( !strcmp(type, "FML32") )
                sv_setref_pv(ST(0), "FBFR32_PTR", (void*)ptr);
            else
                sv_setref_pv(ST(0), Nullch, (void*)ptr);
        }
        else
        {
            ST(0) = &PL_sv_undef;
        }

int
tpbegin( timeout, flags )
    unsigned long timeout
    long flags

int
tpbroadcast( lmid, usrname, cltname, data, len, flags )
    SV * lmid
    SV * usrname
    SV * cltname
    SV * data
    long len
    long flags
    PREINIT:
    char * lmid_    = NULL;
    char * usrname_ = NULL;
    char * cltname_ = NULL;
    CHAR_PTR data_  = NULL;
    STRLEN  n_a;
    CODE:
        if ( lmid != &PL_sv_undef )
        {
            if ( !SvPOK(lmid) )
	        croak("lmid is not a string");
            lmid_ = SvPV( lmid, n_a );
        }

        if ( usrname != &PL_sv_undef )
        {
            if ( !SvPOK(usrname) )
	        croak("usrname is not a string");
            usrname_ = SvPV( usrname, n_a );
        }

        if ( cltname != &PL_sv_undef )
        {
            if ( !SvPOK(cltname) )
	        croak("cltname is not a string");
            cltname_ = SvPV( cltname, n_a );
        }

        if ( data != &PL_sv_undef )
        {
            if (!SvROK(data)) 
                croak("data is not a reference");
            data_ = (CHAR_PTR)SvIV((SV*)SvRV(data));
        }

        RETVAL = tpbroadcast( lmid_, usrname_, cltname_, data_, len, flags );

    OUTPUT:
        RETVAL

int
tpcancel( cd )
    int cd

int
tpchkauth()

int
tpchkunsol()

int
tpclose()

int
tpcommit( flags )
    long flags

int
tpconnect( svc, data, len, flags )
    char * svc
    SV * data
    long len
    long flags
    PREINIT:
        CHAR_PTR data_  = NULL;
    CODE:
        if ( data != &PL_sv_undef )
        {
            if (!SvROK(data)) 
                croak("data is not a reference");
            data_ = (CHAR_PTR)SvIV((SV*)SvRV(data));
        }

        RETVAL = tpconnect( svc, data_, len, flags );
    OUTPUT:
        RETVAL

int
tpconvert( strrep, binrep, flags )
    SV * strrep
    SV * binrep
    long flags
    PREINIT:
        char * strrep_ = NULL;
        char * binrep_ = NULL;
        char tostring[TPCONVMAXSTR + 1];
        STRLEN    n_a;
    CODE:
        if ( flags & TPTOSTRING )
        {
            /* binrep is the source, strrep is the dest */
            if (!SvROK(binrep)) 
                croak("binrep is not a reference");
            binrep_ = (CHAR_PTR)SvIV((SV*)SvRV(binrep));
            RETVAL = tpconvert( tostring, binrep_, flags );
            sv_setpv( strrep, tostring );
        }
        else
        {
            /* strrep is the source, binrep is the dest */
            if ( !SvPOK(strrep) )
	        croak("strrep is not a string");
            strrep_ = SvPV( strrep, n_a );

            if ( flags & TPCONVCLTID )
            {
                if ( SvROK(binrep) && sv_isa(binrep, "CLIENTID_PTR") )
                {
                    binrep_ = (CHAR_PTR)SvIV((SV*)SvRV(binrep));
                    RETVAL = tpconvert( strrep_, binrep_, flags );
                }
                else
                {
                    /* binrep_ = calloc( 1, sizeof(CLIENTID) ); */
                    binrep_ = malloc( sizeof(CLIENTID) );
                    memset( binrep_, 0, sizeof(CLIENTID) );
                    RETVAL = tpconvert( strrep_, binrep_, flags );
                    sv_setref_pv( binrep, "CLIENTID_PTR", binrep_ );
                }
            }

            else if ( flags & TPCONVTRANID )
            {
                if ( SvROK(binrep) && sv_isa(binrep, "TPTRANID_PTR") )
                {
                    binrep_ = (CHAR_PTR)SvIV((SV*)SvRV(binrep));
                    RETVAL = tpconvert( strrep_, binrep_, flags );
                }
                else
                {
                    /* binrep_ = calloc( 1, sizeof(TPTRANID) ); */
                    binrep_ = malloc( sizeof(CLIENTID) );
                    memset( binrep_, 0, sizeof(CLIENTID) );
                    RETVAL = tpconvert( strrep_, binrep_, flags );
                    sv_setref_pv( binrep, "TPTRANID_PTR", binrep_ );
                }
            }

            else if ( flags & TPCONVXID )
            {
                if ( SvROK(binrep) && sv_isa(binrep, "XID_PTR") )
                {
                    binrep_ = (CHAR_PTR)SvIV((SV*)SvRV(binrep));
                    RETVAL = tpconvert( strrep_, binrep_, flags );
                }
                else
                {
                    /* binrep_ = calloc( 1, sizeof(XID) ); */
                    binrep_ = malloc( sizeof(CLIENTID) );
                    memset( binrep_, 0, sizeof(CLIENTID) );
                    RETVAL = tpconvert( strrep_, binrep_, flags );
                    sv_setref_pv( binrep, "XID_PTR", binrep_ );
                }
            }
        }
    OUTPUT:
        RETVAL
    
int
tpdequeue( qspace, qname, ctl, data, len, flags )
    char * qspace
    char * qname
    TPQCTL_PTR ctl
    SV * data
    long len
    long flags
    PREINIT:
    char *obuf;
    CODE:
	if (SvROK(data)) {
	    IV tmp = SvIV((SV*)SvRV(data));
	    obuf = (CHAR_PTR) tmp;
	}
	else
	    croak("data is not a reference");

        RETVAL = tpdequeue( qspace, qname, ctl, &obuf, &len, flags );
	sv_setiv(SvRV(data), (IV)obuf);
    OUTPUT:
        RETVAL
        len

int
tpdiscon( cd )
    int cd

int
tpenqueue( qspace, qname, ctl, data, len, flags )
    char * qspace
    char * qname
    TPQCTL_PTR ctl
    CHAR_PTR data
    long len
    long flags
    CODE:
        RETVAL = tpenqueue( qspace, qname, ctl, data, len, flags );
    OUTPUT:
        RETVAL

int
tperrno()
    CODE:
        RETVAL = tperrno;
    OUTPUT:
        RETVAL

int
tperrordetail( flags )
    long flags

int
tpexport( ibuf, ilen, ostr, olen, flags )
    CHAR_PTR ibuf
    long ilen
    SV * ostr
    long olen
    long flags
    PREINIT:
    char * ostr_ = NULL;
    CODE:
        olen = 1024;
        ostr_ = malloc( olen );
        if ( ostr_ == NULL )
            croak( "tpexort: malloc( %ld ) failed.\n", olen );

        RETVAL = tpexport( ibuf, ilen, ostr_, &olen, flags );

        if ( RETVAL == -1 && tperrno == TPELIMIT )
        {
            ostr_ = realloc( ostr_, olen );
            if ( ostr_ == NULL )
            {
                croak( "tpexort: realloc( 0x%p, %ld ) failed.\n",
                        ostr_, 
                        olen
                        );
            }

            RETVAL = tpexport( ibuf, ilen, ostr_, &olen, flags );
        }

        if ( RETVAL != -1 )
            sv_setpvn( ostr, ostr_, olen );

        free( ostr_ );
    OUTPUT:
        RETVAL
        olen

void
tpfree( ptr )
    SV * ptr
    PREINIT:
    char *buf;
    CODE:
	if (SvROK(ptr)) {
	    IV tmp = SvIV((SV*)SvRV(ptr));
	    buf = (CHAR_PTR) tmp;
	}
	else
	    croak("idata is not a reference");

        tpfree( buf );

        /* set the reference to NULL so that we
         *  know not to free the buffer again.
         */
	sv_setiv(SvRV(ptr), NULL);

int
tpgetctxt( context, flags )
    long context
    long flags
    CODE:
        RETVAL = tpgetctxt( &context, flags );
    OUTPUT:
        RETVAL
        context

int
tpgetlev()

int
tpgetrply( cd, odata, olen, flags )
    int cd
    SV * odata
    long olen
    long flags
    PREINIT:
    char *obuf;
    CODE:
	if (SvROK(odata)) {
	    IV tmp = SvIV((SV*)SvRV(odata));
	    obuf = (CHAR_PTR) tmp;
	}
	else
	    croak("odata is not a reference");

        RETVAL = tpgetrply( &cd, &obuf, &olen, flags );
	sv_setiv(SvRV(odata), (IV)obuf);
    OUTPUT:
        RETVAL
        cd
        olen

int
tpgprio()

int
tpimport( istr, ilen, odata, olen, flags )
    char *      istr
    long        ilen
    SV *        odata
    long        olen
    long        flags
    PREINIT:
    char *obuf;
    CODE:
	if (SvROK(odata)) {
	    IV tmp = SvIV((SV*)SvRV(odata));
	    obuf = (CHAR_PTR) tmp;
	}
	else
	    croak("odata is not a reference");

        olen = 0;
        RETVAL = tpimport( istr, ilen, &obuf, &olen, flags );
        sv_setiv( SvRV(odata), (IV)obuf );
    OUTPUT:
        RETVAL
        olen

int
tpinit( tpinitdata )
    TPINIT_PTR tpinitdata

int
tpnotify( clientid, data, len, flags )
    CLIENTID_PTR clientid
    CHAR_PTR     data
    long         len
    long         flags

int
tpopen()

int
tppost( eventname, data, len, flags )
    char * eventname
    SV *   data
    long   len
    long   flags
    PREINIT:
    CHAR_PTR data_  = NULL;
    CODE:
        if ( data != &PL_sv_undef )
        {
            if (!SvROK(data)) 
                croak("data is not a reference");
            data_ = (CHAR_PTR)SvIV((SV*)SvRV(data));
        }

        RETVAL = tppost( eventname, data_, len, flags );
    OUTPUT:
        RETVAL

void
tprealloc( ptr, size )
    SV * ptr
    long     size
    PREINIT:
    CHAR_PTR ptr_;
    CHAR_PTR rval;
    CODE:
        if (!SvROK(ptr)) 
            croak("ptr is not a reference");
        ptr_ = (CHAR_PTR)SvIV((SV*)SvRV(ptr));

        rval = tprealloc( ptr_, size );
        sv_setiv( SvRV(ptr), (IV)rval );

        if ( rval )
        {
            ST(0) = newRV_inc( SvRV(ptr) );
        }
        else
        {
            ST(0) = &PL_sv_undef;
        }

int
tprecv( cd, data, len, flags, revent )
    int cd
    SV * data
    long len
    long flags
    long revent
    PREINIT:
    char * data_ = NULL;
    CODE:
	if (SvROK(data)) {
	    IV tmp = SvIV((SV*)SvRV(data));
	    data_ = (CHAR_PTR) tmp;
	}
	else
	    croak("data is not a reference");

        RETVAL = tprecv( cd, &data_, &len, flags, &revent );
        sv_setiv( SvRV(data), (IV)data_ );
    OUTPUT: 
        RETVAL
        revent

int
tpresume( tranid, flags )
    TPTRANID_PTR tranid
    long flags

int
tpscmt( flags )
    long flags

int
tpsend( cd, data, len, flags, revent )
    int cd
    SV * data
    long len
    long flags
    long revent
    PREINIT:
    char * data_ = NULL;
    CODE:
        if ( data != &PL_sv_undef )
        {
            if (!SvROK(data)) 
                croak("data is not a reference");
            data_ = (CHAR_PTR)SvIV((SV*)SvRV(data));
        }

        RETVAL = tpsend( cd, data_, len, flags, &revent );
    OUTPUT:
        RETVAL
        revent

int
tpsetctxt( context, flags )
    long context
    long flags

void
tpsetunsol( callback )
    SV * callback
    PREINIT:
    long context = 0;
    int rval = 0;
    CODE:
    if ( UnsolicitedHandlerMap == (HV*)NULL )
        UnsolicitedHandlerMap = newHV();

    rval = tpgetctxt( &context, 0 );
    hv_store( UnsolicitedHandlerMap, 
              (char*)&context, 
              sizeof(context), 
              newSVsv(callback),
              0
              );
    tpsetunsol( unsolicited_message_handler );

int
tpsprio( prio, flags )
    int prio
    long flags

char *
tpstrerror( error )
    int error

char *
tpstrerrordetail( err, flags )
    int err
    long flags

long
tpsubscribe( eventexpr, filter, ctl, flags )
    char * eventexpr
    char * filter
    SV * ctl
    long flags
    PREINIT:
    TPEVCTL_PTR ctl_ = NULL;
    CODE:
        if ( ctl != &PL_sv_undef )
        {
            if (!SvROK(ctl) || !sv_isa(ctl, "TPEVCTL_PTR") )
                croak("ctl is not a TPEVCTL_PTR reference");
            ctl_ = (TPEVCTL_PTR)SvIV((SV*)SvRV(ctl));
        }
        RETVAL = tpsubscribe( eventexpr, filter, ctl_, flags );
    OUTPUT:
        RETVAL

int
tpsuspend( tranid, flags )
    TPTRANID_PTR tranid
    long flags

int
tpterm()

long
tptypes( ptr, type, subtype )
    CHAR_PTR ptr
    SV * type
    SV * subtype
    PREINIT:
        char type_[8];
        char subtype_[16];
    CODE:
        RETVAL = tptypes( ptr, type_, subtype_ );
        if ( type != &PL_sv_undef )
            sv_setpv( type, type_ );
        if ( subtype != &PL_sv_undef )
            sv_setpv( subtype, subtype_ );
    OUTPUT:
        RETVAL
        type
        subtype

int
tpunsubscribe( subscription, flags )
    long subscription
    long flags

int
tpcall( svc, idata, ilen, odata, len, flags )
    char * svc
    SV * idata
    long ilen
    SV * odata
    long len
    long flags
    PREINIT:
    char *inbuf;
    char *obuf;
    CODE:

	if (SvROK(idata)) {
	    IV tmp = SvIV((SV*)SvRV(idata));
	    inbuf = (CHAR_PTR) tmp;
	}
	else
	    croak("idata is not a reference");

	if (SvROK(odata)) {
	    IV tmp = SvIV((SV*)SvRV(odata));
	    obuf = (CHAR_PTR) tmp;
	}
	else
	    croak("odata is not a reference");

        RETVAL = tpcall( svc, inbuf, ilen, &obuf, &len, flags );

        /* we don't want the destructor called when
         * we update the odata reference, so we can't call
         * sv_setref_pv, because this will decrement the reference
         * counter of the odata reference, and potentially call the
         * destructor.  Instead I explicitely set the value of the
         * pointer held by the odata reference.
         */
	sv_setiv(SvRV(odata), (IV)obuf);

    OUTPUT:
        RETVAL
        len

int
tpacall( svc, idata, ilen, flags )
    char * svc
    CHAR_PTR idata
    long ilen
    long flags
    PREINIT:
    char *inbuf;
    CODE:
        RETVAL = tpacall( svc, idata, ilen, flags );
    OUTPUT:
        RETVAL

char *
tuxgetenv( name )
    char * name
    
int
tuxputenv( string )
    char * string

int
tx_begin()

int
tx_close()

int
tx_commit()

int
tx_info( info )
    TXINFO_PTR info

int
tx_open()

int
tx_rollback()

int
tx_set_commit_return( when_return )
    long when_return

int
tx_set_transaction_control( control )
    long control

int
tx_set_transaction_timeout( timeout )
    long timeout

void
Usignal( signum, callback )
    int signum
    SV * callback
    CODE:
    if ( SignalHandlerMap == (HV*)NULL )
        SignalHandlerMap = newHV();

    hv_store( SignalHandlerMap, 
              (char*)&signum, 
              sizeof(signum), 
              newSVsv(callback),
              0
              );
    Usignal( signum, signal_handler );

int
userlog( message )
    char * message

int
Ferror32()
    CODE:
        RETVAL = Ferror32;
    OUTPUT:
        RETVAL

char *
Fstrerror32( err )
    int err
    
int
Fappend32( fbfr, fieldid, value, len )
    FBFR32_PTR  fbfr
    FLDID32     fieldid
    SV *        value
    FLDLEN32    len
    PREINIT:
    IV          iv_val;
    double      nv_val;
    char *      pv_val;
    STRLEN      pv_len;
    char *      value_ptr;
    CODE:
        if ( SvROK( value ) )
        {
	    IV tmp = SvIV((SV*)SvRV(ST(0)));
	    value_ptr = (char *) tmp;
        }
        else if ( SvIOK(value) )
        {
            iv_val = SvIV( value );
            value_ptr = (char *)&iv_val;
        }
        else if ( SvNOK(value) )
        {
            nv_val = SvNV( value );
            value_ptr = (char *)&nv_val;
        }
        else if ( SvPOK(value) )
        {
            pv_val = SvPV( value, pv_len );
            value_ptr = pv_val;
        }

        RETVAL = Fappend32( fbfr, fieldid, value_ptr, len );
    OUTPUT:
        RETVAL

int
Fadd32( fbfr, fieldid, value, len )
    FBFR32_PTR  fbfr
    FLDID32     fieldid
    SV *        value
    FLDLEN32    len
    PREINIT:
    IV          iv_val;
    double      nv_val;
    char *      pv_val;
    STRLEN      pv_len;
    char *      value_ptr;
    CODE:
        if ( SvROK( value ) )
        {
	    IV tmp = SvIV((SV*)SvRV(value));
	    value_ptr = (char *) tmp;
        }
        else if ( SvIOK(value) )
        {
            iv_val = SvIV( value );
            value_ptr = (char *)&iv_val;
        }
        else if ( SvNOK(value) )
        {
            nv_val = SvNV( value );
            value_ptr = (char *)&nv_val;
        }
        else if ( SvPOK(value) )
        {
            pv_val = SvPV( value, pv_len );
            value_ptr = pv_val;
        }

        RETVAL = Fadd32( fbfr, fieldid, value_ptr, len );
    OUTPUT:
        RETVAL

int
Fget32( fbfr, fieldid, oc, loc, maxlen )
    FBFR32_PTR  fbfr
    FLDID32     fieldid
    FLDOCC32    oc
    SV *        loc
    SV *    maxlen
    PREINIT:
    char *      val;
    char        cval;
    long        lval;
    short       sval;
    float       fval;
    double      dval;
    FLDLEN32    len = 0;
    CODE:
        /* get the length of the field */
        val = Ffind32( fbfr, fieldid, oc, &len );
        if ( val != NULL )
        {
            switch ( Fldtype32(fieldid) )
            {
                case FLD_SHORT:
                    Fget32( fbfr, fieldid, oc, (char *)&sval, &len );
                    sv_setiv( loc, sval );
                    break;

                case FLD_LONG:
                    Fget32( fbfr, fieldid, oc, (char *)&lval, &len );
                    sv_setiv( loc, lval );
                    break;

                case FLD_CHAR:
                    Fget32( fbfr, fieldid, oc, (char *)&cval, &len );
                    sv_setiv( loc, cval );
                    break;

                case FLD_FLOAT:
                    Fget32( fbfr, fieldid, oc, (char *)&fval, &len );
                    sv_setnv( loc, fval) ;
                    break;

                case FLD_DOUBLE:
                    Fget32( fbfr, fieldid, oc, (char *)&dval, &len );
                    sv_setnv( loc, dval );
                    break;

                case FLD_STRING:
                case FLD_CARRAY:
                    sv_setpvn( loc, val, len );
                    break;

                case FLD_PTR:
                    sv_setref_pv( loc, Nullch, (void*)val );
                    break;

                case FLD_FML32:
                    val = tpalloc( "FML32", 0, len );
                    if ( val == NULL )
                    {
                        RETVAL = -1;
                        break;
                    }
                    sv_setref_pv(loc , "FBFR32_PTR", (void*)val );
                    RETVAL = Fget32( fbfr, fieldid, oc, val, &len );
                    break;

                case FLD_VIEW32:
                    break;
            }

            if ( maxlen != &PL_sv_undef )
            {
                sv_setuv(maxlen, (UV)len);
                SvSETMAGIC(maxlen);
            }
        }
        else
        {
            RETVAL = -1;
        }
    OUTPUT:
        RETVAL
        loc

int
Findex32( fbfr, intvl )
    FBFR32_PTR fbfr
    FLDOCC32   intvl

int
Fprint32( fbfr )
    FBFR32_PTR fbfr

FLDID32
Fmkfldid32( type, num )
    int type
    FLDID32 num



MODULE = TUXEDO        PACKAGE = CHAR_PTR        

void
DESTROY( char_ptr )
    CHAR_PTR  char_ptr
    CODE:
        /* printf( "CHAR_PTR::DESTROY()\n" ); */
        if ( char_ptr != NULL )
        {
	    /* printf( "calling tpfree( 0x%p )\n", char_ptr ); */
            tpfree( char_ptr );
            /* printf( "finished calling tpfree\n" ); */
        }


MODULE = TUXEDO        PACKAGE = TPINIT_PTR        

char *
usrname( obj, ... )
    TPINIT_PTR obj
    PREINIT:
    char *usrname;
    STRLEN n_a;
    CODE:
        if ( items > 1 )
        {
            usrname = (char *)SvPV( ST(1), n_a );
            strcpy( obj->usrname, usrname );
        }
        RETVAL = obj->usrname;
    OUTPUT:
        RETVAL

char *
cltname( obj, ... )
    TPINIT_PTR obj
    PREINIT:
    char *cltname;
    STRLEN n_a;
    CODE:
        if ( items > 1 )
        {
            cltname = (char *)SvPV( ST(1), n_a );
            strcpy( obj->cltname, cltname );
        }
        RETVAL = obj->cltname;
    OUTPUT:
        RETVAL

char *
passwd( obj, ... )
    TPINIT_PTR obj
    PREINIT:
    char *passwd;
    STRLEN n_a;
    CODE:
        if ( items > 1 )
        {
            passwd = (char *)SvPV( ST(1), n_a );
            strcpy( obj->passwd, passwd );
        }
        RETVAL = obj->passwd;
    OUTPUT:
        RETVAL

char *
grpname( obj, ... )
    TPINIT_PTR obj
    PREINIT:
    char *grpname;
    STRLEN n_a;
    CODE:
        if ( items > 1 )
        {
            grpname = (char *)SvPV( ST(1), n_a );
            strcpy( obj->grpname, grpname );
        }
        RETVAL = obj->grpname;
    OUTPUT:
        RETVAL

long
flags( obj, ... )
    TPINIT_PTR obj
    PREINIT:
    long flags;
    CODE:
        if ( items > 1 )
        {
            flags = (long)SvIV( ST(1) );
            obj->flags = flags;
        }
        RETVAL = obj->flags;
    OUTPUT:
        RETVAL

long
datalen( obj, ... )
    TPINIT_PTR obj
    PREINIT:
    long datalen;
    CODE:
        if ( items > 1 )
        {
            datalen = (long)SvIV( ST(1) );
            obj->datalen = datalen;
        }
        RETVAL = obj->datalen;
    OUTPUT:
        RETVAL

char *
data( obj, ... )
    TPINIT_PTR obj
    PREINIT:
    char *data;
    STRLEN n_a;
    CODE:
        if ( items > 1 )
        {
            data = (char *)SvPV( ST(1), n_a );
            strcpy( (char *)&(obj->data), data );
        }
        RETVAL = (char *)&(obj->data);
    OUTPUT:
        RETVAL


MODULE = TUXEDO        PACKAGE = FBFR32_PTR        


MODULE = TUXEDO        PACKAGE = CLIENTID_PTR

void
new()
    PREINIT:
        char *ptr;
    CODE:
        /* ptr = calloc( 1, sizeof(CLIENTID) ); */
        ptr = malloc( sizeof(CLIENTID) );
        memset( ptr, 0, sizeof(CLIENTID) );
	/* printf( "calloc returned 0x%p\n", ptr ); */
        ST(0) = sv_newmortal();
        if ( ptr != NULL )
            sv_setref_pv(ST(0), "CLIENTID_PTR", ptr);
        else
            ST(0) = &PL_sv_undef;

void
DESTROY( clientid_ptr )
    CLIENTID_PTR  clientid_ptr
    CODE:
        /* printf( "CLIENTID_PTR::DESTROY()\n" ); */
        if ( clientid_ptr != NULL )
        {
	    /* printf( "free( 0x%p )\n", clientid_ptr ); */
            free( (char *)clientid_ptr );
            /* printf( "finished calling free.\n" ); */
        }

void
clientdata( obj, ... )
    CLIENTID_PTR obj
    PREINIT:
        long arraysize;
        AV * clientdata;
        int i;
    PPCODE:
        arraysize = sizeof(obj->clientdata)/sizeof(long);
        if ( items > 1 )
        {
            if ( items > 5 )
                croak( "More than 4 elements provided for clientdata.\n" );

            for ( i = 1; i < items; i++ )
                obj->clientdata[i-1] = SvIV((SV*)ST(i));
        }

        EXTEND(SP, arraysize);
        for ( i = 0; i < arraysize; i++ )
            PUSHs( sv_2mortal(newSViv( obj->clientdata[i])) );


MODULE = TUXEDO        PACKAGE = TPTRANID_PTR
void
new()
    PREINIT:
        char *ptr;
    CODE:
        /* ptr = calloc( 1, sizeof(TPTRANID) ); */
        ptr = malloc( sizeof(TPTRANID) );
        memset( ptr, 0, sizeof(TPTRANID) );
        ST(0) = sv_newmortal();
        if ( ptr != NULL )
            sv_setref_pv(ST(0), "TPTRANID_PTR", ptr);
        else
            ST(0) = &PL_sv_undef;

void
DESTROY( tptranid_ptr )
    TPTRANID_PTR  tptranid_ptr
    CODE:
        /* printf( "TPTRANID_PTR::DESTROY()\n" ); */
        if ( tptranid_ptr != NULL )
        {
            /* printf( "free( 0x%p )\n", tptranid_ptr ); */
            free( (char *)tptranid_ptr );
            /* printf( "finished calling free.\n" ); */
        }

void
info( obj, ... )
    TPTRANID_PTR obj
    PREINIT:
        long arraysize;
        int i;
    PPCODE:
        arraysize = sizeof(obj->info)/sizeof(long);
        if ( items > 1 )
        {
            if ( items > (arraysize + 1) )
                croak( "More than %d elements provided for clientdata.\n",
                        arraysize
                        );

            for ( i = 1; i < items; i++ )
                obj->info[i-1] = SvIV((SV*)ST(i));
        }

        EXTEND(SP, arraysize);
        for ( i = 0; i < arraysize; i++ )
            PUSHs( sv_2mortal(newSViv( obj->info[i])) );


MODULE = TUXEDO        PACKAGE = XID_PTR
void
new()
    PREINIT:
        char *ptr;
    CODE:
        /* ptr = calloc( 1, sizeof(XID) ); */
        ptr = malloc( sizeof(XID) );
        memset( ptr, 0, sizeof(XID) );
        ST(0) = sv_newmortal();
        if ( ptr != NULL )
            sv_setref_pv(ST(0), "XID_PTR", ptr);
        else
            ST(0) = &PL_sv_undef;

void
DESTROY( obj )
    XID_PTR  obj
    CODE:
        if ( obj != NULL )
        {
            /* printf( "%s:%d free( 0x%p )\n", __FILE__, __LINE__, obj ); */
            free( (char *)obj );
            /* printf( "finished calling free.\n" ); */
        }

long 
formatID( obj, ... )
    XID_PTR obj
    CODE:
        if ( items > 1 )
            obj->formatID = (long)SvIV((SV*)ST(1));

        RETVAL = obj->formatID;
    OUTPUT:
        RETVAL

long 
gtrid_length( obj, ... )
    XID_PTR obj
    CODE:
        if ( items > 1 )
            obj->gtrid_length = (long)SvIV((SV*)ST(1));

        RETVAL = obj->gtrid_length;
    OUTPUT:
        RETVAL

long 
bqual_length( obj, ... )
    XID_PTR obj
    CODE:
        if ( items > 1 )
            obj->bqual_length = (long)SvIV((SV*)ST(1));

        RETVAL = obj->bqual_length;
    OUTPUT:
        RETVAL

char *
data( obj, ... )
    XID_PTR obj
    PREINIT:
    STRLEN n_a;
    CODE:
        if ( items > 1 )
            strcpy( obj->data, SvPV((SV*)ST(1), n_a) );

        RETVAL = obj->data;
    OUTPUT:
        RETVAL

MODULE = TUXEDO        PACKAGE = TPQCTL_PTR

void
new()
    PREINIT:
        char *ptr;
    CODE:
        /* ptr = calloc( 1, sizeof(TPQCTL) ); */
        ptr = malloc( sizeof(TPQCTL) );
        memset( ptr, 0, sizeof(TPQCTL) );
        ST(0) = sv_newmortal();
        if ( ptr != NULL )
            sv_setref_pv(ST(0), "TPQCTL_PTR", ptr);
        else
            ST(0) = &PL_sv_undef;

void
DESTROY( obj )
    TPQCTL_PTR  obj
    CODE:
        if ( obj != NULL )
        {
            /* printf( "%s:%d free( 0x%p )\n", __FILE__, __LINE__, obj ); */
            free( (char *)obj );
        }

long 
flags( obj, ... )
    TPQCTL_PTR obj
    CODE:
        if ( items > 1 )
            obj->flags = (long)SvIV((SV*)ST(1));
        RETVAL = obj->flags;
    OUTPUT:
        RETVAL

long 
deq_time( obj, ... )
    TPQCTL_PTR obj
    CODE:
        if ( items > 1 )
            obj->deq_time = (long)SvIV((SV*)ST(1));
        RETVAL = obj->deq_time;
    OUTPUT:
        RETVAL


long 
priority( obj, ... )
    TPQCTL_PTR obj
    CODE:
        if ( items > 1 )
            obj->priority = (long)SvIV((SV*)ST(1));
        RETVAL = obj->priority;
    OUTPUT:
        RETVAL


long 
diagnostic( obj, ... )
    TPQCTL_PTR obj
    CODE:
        if ( items > 1 )
            obj->diagnostic = (long)SvIV((SV*)ST(1));
        RETVAL = obj->diagnostic;
    OUTPUT:
        RETVAL


char *
msgid( obj, ... )
    TPQCTL_PTR obj
    PREINIT:
    STRLEN n_a;
    CODE:
        if ( items > 1 )
            strcpy( obj->msgid, (char *)SvPV((SV*)ST(1), n_a) );
        RETVAL = obj->msgid;
    OUTPUT:
        RETVAL


char *
corrid( obj, ... )
    TPQCTL_PTR obj
    PREINIT:
    STRLEN n_a;
    CODE:
        if ( items > 1 )
            strcpy( obj->corrid, (char *)SvPV((SV*)ST(1), n_a) );
        RETVAL = obj->corrid;
    OUTPUT:
        RETVAL


char *
replyqueue( obj, ... )
    TPQCTL_PTR obj
    PREINIT:
    STRLEN n_a;
    CODE:
        if ( items > 1 )
            strcpy( obj->replyqueue, (char *)SvPV((SV*)ST(1), n_a) );
        RETVAL = obj->replyqueue;
    OUTPUT:
        RETVAL


char *
failurequeue( obj, ... )
    TPQCTL_PTR obj
    PREINIT:
    STRLEN n_a;
    CODE:
        if ( items > 1 )
            strcpy( obj->failurequeue, (char *)SvPV((SV*)ST(1), n_a) );
        RETVAL = obj->failurequeue;
    OUTPUT:
        RETVAL


void 
cltid( obj, ... )
    TPQCTL_PTR obj
    PREINIT:
    SV * sv;
    CODE:
        ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "CLIENTID_PTR", (void*)&obj->cltid);
        SvREFCNT_inc( SvRV(ST(0)) );


long 
urcode( obj, ... )
    TPQCTL_PTR obj
    CODE:
        if ( items > 1 )
            obj->urcode = (long)SvIV((SV*)ST(1));
        RETVAL = obj->urcode;
    OUTPUT:
        RETVAL


long 
appkey( obj, ... )
    TPQCTL_PTR obj
    CODE:
        if ( items > 1 )
            obj->appkey = (long)SvIV((SV*)ST(1));
        RETVAL = obj->appkey;
    OUTPUT:
        RETVAL


long 
delivery_qos( obj, ... )
    TPQCTL_PTR obj
    CODE:
        if ( items > 1 )
            obj->delivery_qos = (long)SvIV((SV*)ST(1));
        RETVAL = obj->delivery_qos;
    OUTPUT:
        RETVAL


long 
reply_qos( obj, ... )
    TPQCTL_PTR obj
    CODE:
        if ( items > 1 )
            obj->reply_qos = (long)SvIV((SV*)ST(1));
        RETVAL = obj->reply_qos;
    OUTPUT:
        RETVAL


long 
exp_time( obj, ... )
    TPQCTL_PTR obj
    CODE:
        if ( items > 1 )
            obj->exp_time = (long)SvIV((SV*)ST(1));
        RETVAL = obj->exp_time;
    OUTPUT:
        RETVAL

MODULE = TUXEDO        PACKAGE = TPEVCTL_PTR

void
new()
    PREINIT:
        char *ptr;
    CODE:
        /* ptr = calloc( 1, sizeof(TPEVCTL) ); */
        ptr = malloc( sizeof(TPEVCTL) );
        memset( ptr, 0, sizeof(TPEVCTL) );
        ST(0) = sv_newmortal();
        if ( ptr != NULL )
            sv_setref_pv(ST(0), "TPEVCTL_PTR", ptr);
        else
            ST(0) = &PL_sv_undef;

void
DESTROY( obj )
    TPEVCTL_PTR  obj
    CODE:
        if ( obj != NULL )
        {
            /* printf( "%s:%d free( 0x%p )\n", __FILE__, __LINE__, obj ); */
            free( (char *)obj );
        }

long 
flags( obj, ... )
    TPEVCTL_PTR obj
    CODE:
        if ( items > 1 )
            obj->flags = (long)SvIV((SV*)ST(1));
        RETVAL = obj->flags;
    OUTPUT:
        RETVAL

char *
name1( obj, ... )
    TPEVCTL_PTR obj
    PREINIT:
    STRLEN n_a;
    CODE:
        if ( items > 1 )
            strcpy( obj->name1, (char *)SvPV((SV*)ST(1), n_a) );
        RETVAL = obj->name1;
    OUTPUT:
        RETVAL

char *
name2( obj, ... )
    TPEVCTL_PTR obj
    PREINIT:
    STRLEN n_a;
    CODE:
        if ( items > 1 )
            strcpy( obj->name2, (char *)SvPV((SV*)ST(1), n_a) );
        RETVAL = obj->name2;
    OUTPUT:
        RETVAL

void 
qctl( obj, ... )
    TPEVCTL_PTR obj
    PREINIT:
    SV * sv;
    CODE:
        ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "TPQCTL_PTR", (void*)&obj->qctl);
        SvREFCNT_inc( SvRV(ST(0)) );

MODULE = TUXEDO        PACKAGE = TXINFO_PTR

void
new()
    PREINIT:
        char *ptr;
    CODE:
        /* ptr = calloc( 1, sizeof(TXINFO) ); */
        ptr = malloc( sizeof(TXINFO) );
        memset( ptr, 0, sizeof(TXINFO) );
        ST(0) = sv_newmortal();
        if ( ptr != NULL )
            sv_setref_pv(ST(0), "TXINFO_PTR", ptr);
        else
            ST(0) = &PL_sv_undef;

void
DESTROY( obj )
    TXINFO_PTR  obj
    CODE:
        if ( obj != NULL )
        {
            /* printf( "%s:%d free( 0x%p )\n", __FILE__, __LINE__, obj ); */
            free( (char *)obj );
        }

void 
xid( obj, ... )
    TXINFO_PTR obj
    PREINIT:
    SV * sv;
    CODE:
        ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "XID_PTR", (void*)&obj->xid);
        SvREFCNT_inc( SvRV(ST(0)) );

long 
when_return( obj, ... )
    TXINFO_PTR obj
    CODE:
        if ( items > 1 )
            obj->when_return = (long)SvIV((SV*)ST(1));
        RETVAL = obj->when_return;
    OUTPUT:
        RETVAL

long 
transaction_control( obj, ... )
    TXINFO_PTR obj
    CODE:
        if ( items > 1 )
            obj->transaction_control = (long)SvIV((SV*)ST(1));
        RETVAL = obj->transaction_control;
    OUTPUT:
        RETVAL

long 
transaction_timeout( obj, ... )
    TXINFO_PTR obj
    CODE:
        if ( items > 1 )
            obj->transaction_timeout = (long)SvIV((SV*)ST(1));
        RETVAL = obj->transaction_timeout;
    OUTPUT:
        RETVAL

long 
transaction_state( obj, ... )
    TXINFO_PTR obj
    CODE:
        if ( items > 1 )
            obj->transaction_state = (long)SvIV((SV*)ST(1));
        RETVAL = obj->transaction_state;
    OUTPUT:
        RETVAL

MODULE = TUXEDO        PACKAGE = TPSVCINFO_PTR

void 
data( obj )
    TPSVCINFO_PTR obj
    PREINIT:
    SV * sv;
    CODE:
        ST(0) = sv_newmortal();
        buffer_setref( ST(0), obj->data );

char *
name( obj )
    TPSVCINFO_PTR obj
    CODE:
        RETVAL = obj->name;
    OUTPUT:
        RETVAL

long
flags( obj )
    TPSVCINFO_PTR obj
    CODE:
        RETVAL = obj->flags;
    OUTPUT:
        RETVAL

long
len( obj )
    TPSVCINFO_PTR obj
    CODE:
        RETVAL = obj->len;
    OUTPUT:
        RETVAL

int
cd( obj )
    TPSVCINFO_PTR obj
    CODE:
        RETVAL = obj->cd;
    OUTPUT:
        RETVAL

long
appkey( obj )
    TPSVCINFO_PTR obj
    CODE:
        RETVAL = obj->appkey;
    OUTPUT:
        RETVAL

void 
cltid( obj )
    TPSVCINFO_PTR obj
    PREINIT:
    SV * sv;
    CODE:
        ST(0) = sv_newmortal();
	sv_setref_pv(ST(0), "CLIENTID_PTR", (void*)&obj->cltid);
        SvREFCNT_inc( SvRV(ST(0)) );

