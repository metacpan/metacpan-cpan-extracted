#include <stdio.h>
#include <stdlib.h>
#include <math.h>


int lpm_init(void);
int lpm_add_raw(int handle, SV * svprefix, int prefix_len, SV *value);
SV * lpm_lookup_raw(int handle, SV *svaddr);
void lpm_finish(int handle);
void lpm_destroy(int handle);
SV * lpm_info(int handle);
SV * lpm_dump(int handle);


