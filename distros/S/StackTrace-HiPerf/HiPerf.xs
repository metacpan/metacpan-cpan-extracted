#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

MODULE = StackTrace::HiPerf PACKAGE = StackTrace::HiPerf

PROTOTYPES: DISABLE

SV* trace( int start_depth = 0 )
    CODE:
     SV * trace = newSVpv( "", 0 );
     int caller_depth = -1;
     I32 i;
     for ( i = cxstack_ix; i >= 0; --i ) {
         switch( CxTYPE( &cxstack[ i ] ) & CXTYPEMASK ) {
             case CXt_SUB:
             case CXt_EVAL:
                if ( ++caller_depth >= start_depth ) {
                    sv_catpvf(
                        trace,
                        "%li|%s||",
                        ( I32 ) CopLINE( cxstack[ i ].blk_oldcop ),
                        OutCopFILE( cxstack[ i ].blk_oldcop )
                    );
                }
         }
     }
     RETVAL = trace;
OUTPUT: RETVAL
