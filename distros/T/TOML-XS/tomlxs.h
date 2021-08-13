/* On some systems Perl clobbers free() to be its own special thing.
   That doesn’t work very well with tomlc99’s expectation that we call
   free() on some of its stuff. This works around that by providing a
   means to call free() from an XSUB.
*/

#include "toml.h"

/* Per Tony Cook, writing an external pointer to the PV is safe
   except when DEBUGGING or MYMALLOC. WIN32 also seems to break it. */
#if defined(DEBUGGING) || defined(MYMALLOC) || defined(WIN32)
#  define TOMLXS_SV_CAN_USE_EXTERNAL_STRING 0
#else
#  define TOMLXS_SV_CAN_USE_EXTERNAL_STRING 1
#endif

void tomlxs_free_string(char *ptr);

void tomlxs_free_timestamp(toml_timestamp_t *ptr);

enum toml_xs_type {
    TOML_XS_TYPE_INVALID,
    TOML_XS_TYPE_TABLE,
    TOML_XS_TYPE_ARRAY,
    TOML_XS_TYPE_STRING,
    TOML_XS_TYPE_BOOLEAN,
    TOML_XS_TYPE_INTEGER,
    TOML_XS_TYPE_DOUBLE,
    TOML_XS_TYPE_TIMESTAMP,
};
