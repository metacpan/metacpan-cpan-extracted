#include <stdlib.h>

#include "toml.h"

#if !TOMLXS_SV_CAN_USE_EXTERNAL_STRING
void tomlxs_free_string(char *ptr) {
    free(ptr);
}
#endif

void tomlxs_free_timestamp(toml_timestamp_t *ptr) {
    free(ptr);
}
