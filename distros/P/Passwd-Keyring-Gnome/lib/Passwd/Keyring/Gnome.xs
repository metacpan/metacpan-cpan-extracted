#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "glib.h"
#include "gnome-keyring.h"

const char* SERVER = "Passwd.Gnome.Keyring";

GnomeKeyringPasswordSchema PASSWD_KEYRING_SCHEMA = {
    GNOME_KEYRING_ITEM_GENERIC_SECRET,
    {
       { "group", GNOME_KEYRING_ATTRIBUTE_TYPE_STRING },
       { "realm", GNOME_KEYRING_ATTRIBUTE_TYPE_STRING },
       { "user", GNOME_KEYRING_ATTRIBUTE_TYPE_STRING },
       { NULL, 0 }
    }
};

MODULE=Passwd::Keyring::Gnome    PACKAGE=Passwd::Keyring::Gnome 

SV*
_get_default_keyring_name()
    CODE:
        char *name;
        gnome_keyring_get_default_keyring_sync(&name);
        RETVAL = newSVpv(name, 0);
        g_free(name);
    OUTPUT:
        RETVAL

void
_set_password(const char *user, const char* password, const char *realm, const char *group, const char *label)
    CODE:
        GnomeKeyringResult status = 
            gnome_keyring_store_password_sync(
                &PASSWD_KEYRING_SCHEMA,
                NULL, /* use default keyring */
                label, /* display name */
                password,
                "group", group,
                "realm", realm,
                "user", user,
                NULL);

        if(status == GNOME_KEYRING_RESULT_OK)
        {
            return;
        }
        else
        {
            croak("Failed to set password %s", gnome_keyring_result_to_message(status));
        }


SV*
_get_password(const char *user, const char *realm, const char *group)
    CODE:
        char *passwd;
        GnomeKeyringResult status = 
             gnome_keyring_find_password_sync(
                &PASSWD_KEYRING_SCHEMA,
                &passwd,
                "group", group,
                "realm", realm,
                "user", user,
                NULL);
        if(status == GNOME_KEYRING_RESULT_OK)
        {
           RETVAL = newSVpv(passwd, 0);
           gnome_keyring_free_password(passwd);
        }
        else if (status == GNOME_KEYRING_RESULT_NO_MATCH)
        {
            RETVAL = newSV(0);
        }
        else
        {
            croak("Failed to find a password %s", gnome_keyring_result_to_message(status));
        }
    OUTPUT:
        RETVAL


int
_clear_password(const char *user, const char *realm, const char *group)
    CODE:
        /* Zwraca ilość skasowanych haseł */

        GnomeKeyringResult status = 
             gnome_keyring_delete_password_sync(
                &PASSWD_KEYRING_SCHEMA,
                "group", group,
                "realm", realm,
                "user", user,
                NULL);
        if(status == GNOME_KEYRING_RESULT_OK)
        {
           RETVAL = 1;
        }
        else if (status == GNOME_KEYRING_RESULT_NO_MATCH)
        {
            RETVAL = 0;
        }
        else
        {
            croak("Failed to delete a password %s", gnome_keyring_result_to_message(status));
        }
    OUTPUT:
        RETVAL

