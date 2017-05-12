#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "pdl.h"
#include "pdlcore.h"

static Core* PDL;
static SV* CoreSV;

static void default_magic (pdl *p, size_t pa) {
	/* Handle the reference counting by hand, thus allowing Perl to handle
	 * the SV cleanup; zero the piddle's pointer so it doesn't touch the
	 * SV late in the piddle's cleanup stage. */
	SvREFCNT_dec((SV*)(p->datasv));
	p->datasv = 0;
	p->data = 0;
}

MODULE = PDL::Parallel::threads           PACKAGE = PDL::Parallel::threads

# Integers (which can be cast to and from pointers) are easily shared using
# threads::shared in a shared hash. This method provides a way to obtain
# the pointer to the datasv for the incoming piddle, and it increments the
# SV's refcount.
size_t
_get_and_mark_datasv_pointer (piddle)
	pdl * piddle
	CODE:
		if (piddle->trans) {
			croak("the piddle is a slice.\n"); /* Slice, data flow, etc */
		}
		else if (0 == (piddle->state & PDL_ALLOCATED)) {
			croak("the piddle does not have any allocated memory (but is "
				"not a slice?).\n"); /* Not sure how this happens */
		}
		else if (piddle->datasv == 0) {
			croak("the piddle has no datasv, which means it's probably "
				"a special piddle.\n"); /* PLplot, mapped with flexraw */
		}
		else if (piddle->data != (void*)SvPV_nolen((SV*)(piddle->datasv))) {
			croak("the piddle's data does not come from the datasv.\n");
			/* Not sure how this happens. */
		}
		else {
			/* Increment the datasv's refcount */
			SvREFCNT_inc((SV*)(piddle->datasv));
			
			/* Tell this piddle to no longer manage its memory */
			piddle->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;
			PDL->add_deletedata_magic(piddle, default_magic, 0);
			
			/* return the pointer */
			RETVAL = (size_t)(piddle->datasv);
		}
	OUTPUT:
		RETVAL


# Given a pointer value that was retrieved with _get_and_mark_datasv_pointer,
# this method creates a new piddle and sets the piddle's datasv to the
# provided location. Combined with proper dim/datatype munging after this
# method is called, as well as the proper flag setting, makes the piddle a
# very thin clone of the original piddle.
pdl *
_new_piddle_around (datasv_pointer, datatype)
	size_t datasv_pointer
	int datatype
	CODE:
		/* Create a new piddle container */
		pdl * piddle = PDL->pdlnew();
		
		/* set the datasv to what was supplied */
		piddle->datasv = (void*) datasv_pointer;
		piddle->data = (void*) SvPV_nolen((SV*)(datasv_pointer));
		
		/* Set the datatype to that supplied */
		piddle->datatype = datatype;

		
		/* Tell the piddle that it doesn't really own the data... */
		PDL->add_deletedata_magic(piddle, default_magic, 0);
		
		/* Increment the SV's reference count so the data persistents
		 * as long as this piddle is around. We'll take care of setting
		 * the piddle state later. */
		SvREFCNT_inc((SV*)(piddle->datasv));
		
		RETVAL = piddle;
	OUTPUT:
		RETVAL


void
_update_piddle_data_state_flags (piddle)
	pdl * piddle
	CODE:
		/* Tell the piddle that it doesn't really own the data... */
		piddle->state |= PDL_DONTTOUCHDATA | PDL_ALLOCATED;

# Needed in the data removal section
void
_dec_datasv_refcount (datasv_pointer)
	size_t datasv_pointer
	CODE:
		SvREFCNT_dec((SV*)(datasv_pointer));

# Super-internal function, used for testing
int
__get_pdl_datasv_ref_count (piddle)
	pdl * piddle
	CODE:
		if (piddle->datasv == 0) {
			RETVAL = -1;
		}
		else {
			RETVAL = SvREFCNT((SV*)(piddle->datasv));
		}
	OUTPUT:
		RETVAL

BOOT:
	perl_require_pv("PDL::Core");
	CoreSV = perl_get_sv("PDL::SHARE",FALSE);
	if (CoreSV==NULL)
		croak("Can't load PDL::Core module");
	PDL = INT2PTR(Core*, SvIV( CoreSV ));
	if (PDL->Version != PDL_CORE_VERSION)
		croak("[PDL->Version: %d PDL_CORE_VERSION: %d XS_VERSION: %s] PDL::Parallel::threads needs to be recompiled against the newly installed PDL", PDL->Version, PDL_CORE_VERSION, XS_VERSION);

