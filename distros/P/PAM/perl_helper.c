#include <EXTERN.h>
#include <perl.h>

#include <security/pam_modules.h>
#include <syslog.h>

#include <xs_object_magic.h>

#include <assert.h>

#include "compat.h"
#include "perl_helper.h"

#define ORIGINAL_INTERPRETER_KEY "perl_original_interpreter"
#define MY_INTERPRETER_KEY "perl_my_interpreter"

EXTERN_C void xs_init(pTHX);

void cleanup_my_perl(pam_handle_t *pamh, void *data, int error_status);

int
invoke(const char *phase, pam_handle_t *pamh, int flags, int argc, const char **argv)
{
    int rv = PAM_SYSTEM_ERR;
    int i;
    PerlInterpreter *original_interpreter, *my_perl;

    pam_syslog(pamh, LOG_DEBUG, "Starting up");

    if (pam_get_data(pamh, ORIGINAL_INTERPRETER_KEY, (void*)&original_interpreter) == PAM_SUCCESS) {
        pam_syslog(pamh, LOG_DEBUG, "Unexpected, original interpreter is already defined");
        return PAM_SYSTEM_ERR;
    }

    original_interpreter = PERL_GET_INTERP;

    if (pam_get_data(pamh, MY_INTERPRETER_KEY, (void*)&my_perl) != PAM_SUCCESS) {
        pam_syslog(pamh, LOG_DEBUG, "I don't have an interpreter allocated yet");
        my_perl = NULL;
    }

    if (my_perl == NULL) {
        int my_argc = 3;
        char *my_argv[] = { "", "-T", "-e1", NULL }; // POSIX says it must be NULL terminated, even though we have argc

        pam_syslog(pamh, LOG_DEBUG, "Creating a new perl interpreter");

        if (original_interpreter == NULL) {
            pam_syslog(pamh, LOG_DEBUG, "We're the first perl interpreter, initialize perl libs");
            PERL_SYS_INIT(&my_argc, (char***)&my_argv);
        }

        my_perl = perl_alloc();
        PERL_SET_CONTEXT(my_perl);
        perl_construct(my_perl);
        perl_parse(my_perl, xs_init, my_argc, my_argv, (char **)NULL);
    }
    else {
        pam_syslog(pamh, LOG_DEBUG, "Already have a perl interpreter, change context to it");
        PERL_SET_CONTEXT(my_perl);
    }

    if (argc < 1 || argv[0] == NULL) {
        pam_syslog(pamh, LOG_DEBUG, "We were called with no arguments, don't know what to load");
        return PAM_MODULE_UNKNOWN;
    }

    SV *module_name = newSVpv(argv[0], 0);

    load_module(0, newSVsv(module_name), NULL, NULL);

    SV *other_module_name = newSVpv("XS::Object::Magic", 0);
    load_module(0, newSVsv(other_module_name), NULL, NULL);
    SV *pamh_sv = xs_object_magic_create(aTHX_ pamh, gv_stashpv("PAM::Handle", GV_ADD));

    pam_set_data(pamh, MY_INTERPRETER_KEY, my_perl, &cleanup_my_perl);
    if (original_interpreter != NULL) {
        pam_syslog(pamh, LOG_DEBUG, "We have an original interpreter, set up some state to store it");
        pam_set_data(pamh, ORIGINAL_INTERPRETER_KEY, original_interpreter, NULL);
    }

    pam_syslog(pamh, LOG_DEBUG, "Get ready to invoke the module");

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 3 + argc);
    XPUSHs(sv_2mortal(module_name));
    XPUSHs(sv_2mortal(pamh_sv));
    XPUSHs(sv_2mortal(newSViv(flags)));
    for (i = 0; i < argc; i++)
        XPUSHs(sv_2mortal(newSVpv(argv[i], 0)));
    PUTBACK;
    call_method(phase, G_SCALAR);
    SPAGAIN;
    rv = POPi;
    PUTBACK;
    FREETMPS;
    LEAVE;

    if (original_interpreter != NULL) {
        pam_syslog(pamh, LOG_DEBUG, "Return to the original interpreter context");
        PERL_SET_CONTEXT(original_interpreter);
        pam_set_data(pamh, ORIGINAL_INTERPRETER_KEY, NULL, NULL);
    }

/*  Can't use this cause we might not be the last perl interpreter. Really only perl(1) can call this.
    else {
        PERL_SYS_TERM();
    }
*/

    return rv;
}

void
cleanup_my_perl(pam_handle_t *pamh, void *data, int error_status)
{
    pam_syslog(pamh, LOG_DEBUG, "Cleaning up perl interpreter");
    PerlInterpreter *my_perl = (PerlInterpreter*)data;
    perl_destruct(my_perl);
    perl_free(my_perl);
    my_perl = NULL;
}

void
start_perl_callback(pam_handle_t *pamh)
{
    PerlInterpreter *original_interpreter;
    if (pam_get_data(pamh, ORIGINAL_INTERPRETER_KEY, (void*)&original_interpreter) != PAM_SUCCESS)
        original_interpreter = NULL;
    if (original_interpreter != NULL) {
        PERL_SET_CONTEXT(original_interpreter);
    }
}

void
end_perl_callback(pam_handle_t *pamh)
{
    PerlInterpreter *my_perl;
    if (pam_get_data(pamh, MY_INTERPRETER_KEY, (void*)&my_perl) != PAM_SUCCESS)
        my_perl = NULL;
    assert(my_perl);
    PERL_SET_CONTEXT(my_perl);
}
