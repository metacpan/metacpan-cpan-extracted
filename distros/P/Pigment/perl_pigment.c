#include "perl-pigment.h"

STATIC const char *
event_subclass_from_event (PgmEvent *event) {
    switch (event->type) {
        case PGM_NOTHING:
            return NULL;
            break;
        case PGM_MOTION_NOTIFY:
            return "Motion";
            break;
        case PGM_BUTTON_PRESS:
        case PGM_DOUBLE_BUTTON_PRESS:
        case PGM_TRIPLE_BUTTON_PRESS:
        case PGM_BUTTON_PRESSURE:
        case PGM_BUTTON_RELEASE:
            return "Button";
            break;
        case PGM_KEY_PRESS:
        case PGM_KEY_RELEASE:
            return "Key";
            break;
        case PGM_EXPOSE:
            return "Expose";
            break;
        case PGM_CONFIGURE:
            return "Configure";
            break;
        case PGM_DRAG_MOTION:
        case PGM_DRAG_DROP:
        case PGM_DRAG_LEAVE:
            return "Dnd";
            break;
        case PGM_SCROLL:
            return "Scroll";
            break;
        case PGM_STATE:
            return "State";
            break;
        case PGM_DELETE:
            return "Delete";
            break;
        case PGM_WIN32_MESSAGE:
            return "Win32Message";
            break;
    }
}

STATIC GPerlBoxedWrapFunc default_boxed_wrapper;
STATIC GPerlBoxedWrapperClass *wrapper_class = NULL;

STATIC SV *
wrap_event (GType type, const gchar *package, gpointer boxed, gboolean own)
{
    HV *stash = NULL;
    GString *class;
    const char *suffix;
	SV *ret = (*default_boxed_wrapper) (type, package, boxed, own);

    suffix = event_subclass_from_event ((PgmEvent *)boxed);
    if (suffix) {
        class = g_string_new (package);
        g_string_append (class, "::");
        g_string_append (class, suffix);

        stash = gv_stashpvn (class->str, class->len, 1);

        g_string_free (class, TRUE);
    }

    if (stash) {
	    sv_bless (ret, stash);
    }

	return ret;
}

GPerlBoxedWrapperClass *
perl_pigment_get_element_wrapper_class ()
{
	if (!wrapper_class) {
		GPerlBoxedWrapperClass *default_wrapper = gperl_default_boxed_wrapper_class ();

		default_boxed_wrapper = default_wrapper->wrap;

		wrapper_class = g_new (GPerlBoxedWrapperClass, 1);
		wrapper_class->destroy = default_wrapper->destroy;
		wrapper_class->unwrap = default_wrapper->unwrap;
		wrapper_class->wrap = wrap_event;
	}

	return wrapper_class;
}
