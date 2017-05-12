/* foo.h for testing */

#ifdef USE_PPPORT
#include "ppport.h"
#endif

bool
foo_is_ok(void);

typedef int (*fake_decl)(int, int);
