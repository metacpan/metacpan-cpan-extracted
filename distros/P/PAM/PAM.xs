#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdlib.h>
#include <string.h>

#include <syslog.h>

#include <security/pam_modules.h>
#include <security/pam_appl.h>
#include "const-c.inc"

#include "xs_object_magic.h"

#include "compat.h"
#include "perl_helper.h"

static void cleanup_data(pam_handle_t*, void*, int);

static void cleanup_data(pam_handle_t *pamh, void *data, int error_status) {
    free(data);
}

MODULE = PAM    PACKAGE = PAM::Constants

INCLUDE: const-xs.inc

MODULE = PAM    PACKAGE = PAM::Handle    PREFIX = pam_

PROTOTYPES: DISABLE

SV*
get_user(pam_handle, ...)
    pam_handle_t *pam_handle
    PREINIT:
        const char *user;
        const char *prompt = NULL;
        int rv;
    CODE:
        if (items > 1)
            prompt = (char *)SvPV_nolen(ST(1));
        if (pam_handle == NULL)
            croak("pam_handle not defined\n");
        rv = pam_get_user(pam_handle, &user, prompt);
        RETVAL = newSVpv(user, 0);
    OUTPUT:
        RETVAL

SV*
get_item(SV *self, item_type)
    int item_type
    PREINIT:
        pam_handle_t *pam_handle;
        const void *item;
        int rv;
    INIT:
        pam_handle = xs_object_magic_get_struct_rv(aTHX_ self);
    CODE:
        switch (item_type)
        {
            case PAM_SERVICE :
            case PAM_USER :
            case PAM_USER_PROMPT :
            case PAM_TTY :
            case PAM_RUSER :
            case PAM_RHOST :
            case PAM_AUTHTOK :
            case PAM_OLDAUTHTOK :
#ifdef __LINUX_PAM__
            case PAM_XDISPLAY : // Linux specific
#endif
                rv = pam_get_item(pam_handle, item_type, &item);
                if (rv == PAM_SUCCESS)
                    RETVAL = newSVpv((char*)item, 0);
                else
                    RETVAL = &PL_sv_undef;
            break;

            case PAM_CONV :
                rv = pam_get_item(pam_handle, item_type, &item);
                if (rv == PAM_SUCCESS) {
                    SV *pamc = xs_object_magic_create(aTHX_ (void*)item, gv_stashpv("PAM::Conversation", GV_ADD));

                    SV *pamh_ref = newRV_inc(SvRV(self));
                    if (hv_stores((HV*)SvRV(pamc), "handle", pamh_ref) == NULL)
                        SvREFCNT_dec(pamh_ref);

                    RETVAL = pamc;
                } else {
                    RETVAL = &PL_sv_undef;
                }
            break;
#ifdef __LINUX_PAM__
            case PAM_FAIL_DELAY :   // Linux specific
            case PAM_XAUTHDATA :    // Linux specific
            case PAM_AUTHTOK_TYPE : // Linux specific
#endif
            default :
                RETVAL = &PL_sv_undef;
            break;
        }
    OUTPUT:
        RETVAL

void
set_item(pam_handle, item_type, item_sv)
    pam_handle_t *pam_handle
    int item_type
    SV *item_sv
    PREINIT:
        const void *item;
        int rv;
    CODE:
        switch (item_type)
        {
            case PAM_SERVICE :
            case PAM_USER :
            case PAM_USER_PROMPT :
            case PAM_TTY :
            case PAM_RUSER :
            case PAM_RHOST :
            case PAM_AUTHTOK :
            case PAM_OLDAUTHTOK :
#ifdef __LINUX_PAM__
            case PAM_XDISPLAY : // Linux specific
#endif
                item = SvPV_nolen(item_sv);
                rv = pam_set_item(pam_handle, item_type, item);
            break;

            case PAM_CONV :
#ifdef __LINUX_PAM__
            case PAM_FAIL_DELAY :   // Linux specific
            case PAM_XAUTHDATA :    // Linux specific
            case PAM_AUTHTOK_TYPE : // Linux specific
#endif
            default :
            break;
        }

SV*
get_data(pam_handle, name)
    pam_handle_t *pam_handle
    const char *name
    PREINIT:
        const void *data;
        int rv;
    CODE:
        rv = pam_get_data(pam_handle, name, &data);
        if (rv == PAM_SUCCESS)
            RETVAL = newSVpv((char*)data, 0);
        else
            RETVAL = &PL_sv_undef;
    OUTPUT:
        RETVAL

void
set_data(pam_handle, name, data_sv)
    pam_handle_t *pam_handle
    const char *name
    SV *data_sv
    PREINIT:
        const void *data;
        void *datacpy;
        int rv;
        STRLEN len = 0;
    CODE:
        if (SvOK(data_sv)) {
            data = SvPV(data_sv, len);
            datacpy = malloc(len);
            if (datacpy == NULL)
                croak("Unable to allocate memory\n");
            memcpy(datacpy, data, len);
            rv = pam_set_data(pam_handle, name, datacpy, &cleanup_data);
        } else {
            // undef should set null
            rv = pam_set_data(pam_handle, name, NULL, NULL);
        }

void
getenvlist(pam_handle)
    pam_handle_t *pam_handle
    PREINIT:
        char **env;
        char **env_orig;
    PPCODE:
        env = pam_getenvlist(pam_handle);
        env_orig = env;
        while (env != NULL) {
            XPUSHs(sv_2mortal(newSVpv(*env, 0)));
            env++;
        }
        free(env_orig);

SV*
getenv(pam_handle, name)
    pam_handle_t *pam_handle
    const char *name
    PREINIT:
        const char *value;
    CODE:
        value = pam_getenv(pam_handle, name);
        RETVAL = newSVpv(value, 0);
    OUTPUT:
        RETVAL

void
putenv(pam_handle, name_value_sv)
    pam_handle_t *pam_handle
    SV *name_value_sv
    const void *name_value = NO_INIT
    int rv           = NO_INIT
    CODE:
        name_value = SvPV_nolen(name_value_sv);
        rv = pam_putenv(pam_handle, name_value);

SV*
strerror(pam_handle, errnum)
    pam_handle_t *pam_handle
    int           errnum
    PREINIT:
        const char *errstr;
    CODE:
        errstr = pam_strerror(pam_handle, errnum);
        RETVAL = newSVpv(errstr, 0);
    OUTPUT:
        RETVAL

MODULE = PAM    PACKAGE = PAM::Conversation

int
run(SV *self, ...)
    PREINIT:
        struct pam_conv *pamc;
        struct pam_message **msg = NULL;
        struct pam_response *resp = NULL;
        int rv, i;
        SV **pamh_ref;
    INIT:
        pamc = xs_object_magic_get_struct_rv(aTHX_ self);
    CODE:
        pamh_ref = hv_fetchs((HV*)SvRV(self), "handle", 0);
        SvREFCNT_inc(*pamh_ref);
        items--; // self takes up one

        if (pamh_ref != NULL) {
            pam_handle_t *pamh = xs_object_magic_get_struct_rv(aTHX_ *pamh_ref);

            msg = malloc(sizeof(struct pam_message*) * items);
            msg[0] = malloc(sizeof(struct pam_message) * items);

            pam_syslog(pamh, LOG_DEBUG, "Allocated memory for %d items", items);

            for (i = 1; i < items; i++) {
                msg[i] = msg[0] + (sizeof(struct pam_message) * i);
            }

            pam_syslog(pamh, LOG_DEBUG, "Done doubly linking list");

            for (i = 0; i < items; i++) {
                pam_syslog(pamh, LOG_DEBUG, "Handling arg item %d", i);

                SV *item_rv = ST(i+1);
                if((SvTYPE(SvRV(item_rv)) != SVt_PVAV)) {
                    croak("PAM::Conversation::run arguments should be all arrayrefs with two elements, %d is not an arrayref.", i);
                }

                AV *item = (AV*)SvRV(item_rv);
                if(av_len(item) != 1) { // av_len returns highest index, not true length, so 1 == 2 items
                    croak("PAM::Conversation::run arguments should be all arrayrefs with two elements, %d is not two elements long.", i);
                }

                {
                    SV **temp = av_fetch(item, 0, 0);
                    if (temp == NULL)
                        croak("PAM::Conversation::run argument %d element zero was NULL.", i);
                    if (*temp == NULL)
                        croak("PAM::Conversation::run argument %d element zero was pointer to NULL.", i);
                    msg[i]->msg_style = SvIV(*temp);
                }
                {
                    SV **temp = av_fetch(item, 1, 0);
                    if (temp == NULL)
                        croak("PAM::Conversation::run argument %d element one was NULL.", i);
                    if (*temp == NULL)
                        croak("PAM::Conversation::run argument %d element one was pointer to NULL.", i);
                    msg[i]->msg       = SvPV_nolen(*temp);
                }

                pam_syslog(pamh, LOG_DEBUG, "Message configued is code %d string %s", msg[i]->msg_style, msg[i]->msg);
            }

            // This takes me back to the other perl interpreter
            start_perl_callback(pamh);

            rv = (*(pamc->conv))(items, (const struct pam_message**)msg, &resp, pamc->appdata_ptr);

            free(msg[0]);

            // And now back into my perl interpreter
            end_perl_callback(pamh);
        }

        SvREFCNT_dec(*pamh_ref);
    OUTPUT:
        RETVAL
