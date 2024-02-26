#include "cowl.h"

/**
 * Allocate UVec_CowlObjectPtr on heap and assign new value to it.
 *
 * See also: uvec_CowlObjectPtr
 */
UVec(CowlObjectPtr) * COWL_WRAP_my_uvec_new_on_heap_CowlObjectPtr () {
	UVec(CowlObjectPtr) * vec = (UVec(CowlObjectPtr) *)( malloc(sizeof(UVec(CowlObjectPtr))) );
	*vec = uvec(CowlObjectPtr);
	return vec;
}
