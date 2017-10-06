#include "libouroboros.h"
#include "const-c.inc"

MODULE = Ouroboros	PACKAGE = Ouroboros

INCLUDE: fn-pointer-xs.inc
INCLUDE: const-xs.inc

BOOT:
	{
		HV *sizes = get_hv("Ouroboros::SIZE_OF", GV_ADD);
#define SS(ty)  hv_store(sizes, #ty, strlen(#ty), newSVuv(sizeof(ty)), 0)
/* sizeof { */
		SS(bool);
		SS(svtype);
		SS(PADOFFSET);
		SS(Optype);
		SS(ouroboros_stack_t);
		SS(MAGIC);
		SS(MGVTBL);
/* } */
#undef SS
	}
