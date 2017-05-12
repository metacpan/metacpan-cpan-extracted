#ifndef PAM_PERL_HELPER
#define PAM_PERL_HELPER

#include <security/pam_modules.h>

int invoke(const char *phase, pam_handle_t *pamh, int flags, int argc, const char **argv);
void start_perl_callback(pam_handle_t *pamh);
void end_perl_callback(pam_handle_t *pamh);

#endif
