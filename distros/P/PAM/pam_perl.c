#include <dlfcn.h>

#include <stdlib.h>

#define PAM_SM_AUTH
#define PAM_SM_ACCOUNT
#define PAM_SM_SESSION
#define PAM_SM_PASSWORD

#include <security/pam_modules.h>

int invoke(const char *phase, pam_handle_t *pamh, int flags, int argc, const char **argv);

int
invoke(const char *phase, pam_handle_t *pamh, int flags, int argc, const char **argv)
{
    int (*perl_invoke)(const char*, pam_handle_t*, int, int, const char**) = NULL;
    void *handle = NULL;

    handle = dlopen(PAM_LIB_DIR "/perl_helper.so", RTLD_LAZY | RTLD_GLOBAL | RTLD_NODELETE);
    if (handle == NULL)
        return PAM_MODULE_UNKNOWN;

    perl_invoke = dlsym(handle, "invoke");
    if (perl_invoke == NULL)
        return PAM_MODULE_UNKNOWN;

    return (*perl_invoke)(phase, pamh, flags, argc, argv);
}

PAM_EXTERN int
pam_sm_authenticate(pam_handle_t *pamh, int flags, int argc, const char **argv)
{
    return invoke("authenticate", pamh, flags, argc, argv);
}

PAM_EXTERN int
pam_sm_setcred(pam_handle_t *pamh, int flags, int argc, const char **argv)
{
    return invoke("setcred", pamh, flags, argc, argv);
}

PAM_EXTERN int
pam_sm_acct_mgmt(pam_handle_t *pamh, int flags, int argc, const char **argv)
{
    return invoke("acct_mgmt", pamh, flags, argc, argv);
}

PAM_EXTERN int
pam_sm_chauthtok(pam_handle_t *pamh, int flags, int argc, const char **argv)
{
    return invoke("chauthtok", pamh, flags, argc, argv);
}

PAM_EXTERN int
pam_sm_open_session(pam_handle_t *pamh, int flags, int argc, const char **argv)
{
    return invoke("open_session", pamh, flags, argc, argv);
}

PAM_EXTERN int
pam_sm_close_session(pam_handle_t *pamh, int flags, int argc, const char **argv)
{
    return invoke("close_session", pamh, flags, argc, argv);
}

#ifdef PAM_STATIC

struct pam_module _pam_perl_modstruct = {
    "pam_perl",
    pam_sm_authenticate,
    pam_sm_setcred,
    pam_sm_acct_mgmt,
    pam_sm_open_session,
    pam_sm_close_session,
    pam_sm_chauthtok
};

#endif
