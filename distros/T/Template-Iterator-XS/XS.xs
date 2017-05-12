#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __cplusplus
}
#endif

static unsigned int STATUS_DONE ;

// ------------------------------------------------------------------------
//  get_next()
// 
//  Called repeatedly to access successive elements in the data set.
//  Should only be called after calling get_first() or a warning will 
//  be raised and (undef, STATUS_DONE) returned.
// #------------------------------------------------------------------------
// 
// sub get_next {
//     my $self = shift;
//     my ($max, $index) = @$self{ qw( MAX INDEX ) };
//     my $data = $self->{ _DATASET };
// 
//     # warn about incorrect usage
//     unless (defined $index) {
//         my ($pack, $file, $line) = caller();
//         warn("iterator get_next() called before get_first() at $file line $line\n");
//         return (undef, Template::Constants::STATUS_DONE);   ## RETURN ##
//     }
// 
//     # if there's still some data to go...
//     if ($index < $max) {
//         # update counters and flags
//         $index++;
//         @$self{ qw( INDEX COUNT FIRST LAST ) }
//         = ( $index, $index + 1, 0, $index == $max ? 1 : 0 );
//         @$self{ qw( PREV NEXT ) } = @$data[ $index - 1, $index + 1 ];
//         return $data->[ $index ];                           ## RETURN ##
//     }
//     else {
//         return (undef, Template::Constants::STATUS_DONE);   ## RETURN ##
//     }
// }


MODULE = Template::Iterator::XS           PACKAGE = Template::Iterator::XS

void
_init(status_done)
    int status_done
    PPCODE:
      STATUS_DONE = status_done;

void
get_next(self)
    SV *self
    PPCODE:
        {
            HV * obj;
            AV * dataset;
            SV ** ref;
            int max, index;
            if ( !SvROK(self)) croak("panic: bad object");
            obj = (HV*)SvRV(self);
            if ( SvTYPE((SV*)obj) != SVt_PVHV) croak("panic: object is not a hash");
            ref = hv_fetch( obj, "MAX", strlen("MAX"), 0); 
            if (ref == NULL) croak("panic: no item %s", "MAX");
            max = SvIV(*ref);
            ref = hv_fetch( obj, "INDEX", strlen("INDEX"), 0); 
            if (ref == NULL) croak("panic: no item %s", "INDEX");

            if (!SvOK(*ref)) {
                warn("iterator get_next() called before get_first()");
                EXTEND(sp,2);
                PUSHs(&PL_sv_undef);
                PUSHs(sv_2mortal(newSViv(STATUS_DONE)));
                PUTBACK;
                return;
            }
            index = SvIV(*ref);

            if ( index >= max ) {
                EXTEND(sp,2);
                PUSHs(&PL_sv_undef);
                PUSHs(sv_2mortal(newSViv(STATUS_DONE)));
                PUTBACK;
                return;
            }

            ref = hv_fetch( obj, "_DATASET", strlen("_DATASET"), 0); 
            if (ref == NULL) croak("panic: no item %s", "_DATASET");
            if ( SvTYPE(SvRV(*ref)) != SVt_PVAV) croak("panic: _DATASET is not an array %d %d", SvTYPE(*ref));
            dataset = (AV*)(SvRV(*ref));

            index++;
            hv_store( obj, "INDEX", strlen("INDEX"), newSViv(index), 0);
            hv_store( obj, "COUNT", strlen("COUNT"), newSViv(index+1), 0);
            hv_store( obj, "FIRST", strlen("FIRST"), newSViv(0), 0);
            hv_store( obj, "LAST",  strlen("LAST"), newSViv((index == max) ? 1 : 0), 0);

            ref = av_fetch( dataset, index - 1, 0);
            hv_store( obj, "PREV", strlen("PREV"), newSVsv(ref ? *ref : &PL_sv_undef), 0);
            ref = av_fetch( dataset, index + 1, 0);
            hv_store( obj, "NEXT", strlen("NEXT"), newSVsv(ref ? *ref : &PL_sv_undef), 0);
            ref = av_fetch( dataset, index, 0);
            XPUSHs(sv_2mortal(newSVsv(ref ? *ref : &PL_sv_undef)));
        }


