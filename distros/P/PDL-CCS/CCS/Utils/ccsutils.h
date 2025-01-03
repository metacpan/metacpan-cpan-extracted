#include "pdl.h"

/* null-detection adapted from PDL_MAYBE_SIZE macro; see also
 *  - https://github.com/PDLPorters/pdl-linearalgebra/blob/f789c4100d04ba9d1b50f8c18249bdef29338496/Real/real.pd#L63-L75
 *  - https://github.com/moocow-the-bovine/PDL-CCS/issues/16#issuecomment-2566952192
 *  - https://github.com/moocow-the-bovine/PDL-CCS/issues/16#issuecomment-2567084731
 */
#define CCS_PDL_IS_NULL(pdl) \
  ((pdl)->nvals==0 && ((pdl)->state & PDL_MYDIMS_TRANS))
