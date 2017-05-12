#include "perl-pigment.h"

MODULE = Pigment::Event  PACKAGE = Pigment::Event

PgmEventType
type (PgmEvent *event)
	CODE:
		RETVAL = event->any.type;
	OUTPUT:
		RETVAL

guint8
source (PgmEvent *event)
	CODE:
		RETVAL = event->any.source;
	OUTPUT:
		RETVAL

MODULE = Pigment::Event  PACKAGE = Pigment::Event::Motion

guint32
time (PgmEvent *event)
	CODE:
		RETVAL = event->motion.time;
	OUTPUT:
		RETVAL

gfloat
x (PgmEvent *event)
	ALIAS:
		y = 1
	CODE:
		switch (ix) {
			case 0:
				RETVAL = event->motion.x;
				break;
			case 1:
				RETVAL = event->motion.y;
				break;
		}
	OUTPUT:
		RETVAL

guint32
pressure (PgmEvent *event)
	CODE:
		RETVAL = event->motion.pressure;
	OUTPUT:
		RETVAL

BOOT:
	gperl_prepend_isa ("Pigment::Event::Motion", "Pigment::Event");

MODULE = Pigment::Event  PACKAGE = Pigment::Event::Button

guint32
time (PgmEvent *event)
	CODE:
		RETVAL = event->button.time;
	OUTPUT:
		RETVAL

gfloat
x (PgmEvent *event)
	ALIAS:
		y = 1
	CODE:
		switch (ix) {
			case 0:
				RETVAL = event->button.x;
				break;
			case 1:
				RETVAL = event->button.y;
				break;
		}
	OUTPUT:
		RETVAL

PgmButtonType
button (PgmEvent *event)
	CODE:
		RETVAL = event->button.button;
	OUTPUT:
		RETVAL

guint32
pressure (PgmEvent *event)
	CODE:
		RETVAL = event->button.pressure;
	OUTPUT:
		RETVAL

BOOT:
	gperl_prepend_isa ("Pigment::Event::Button", "Pigment::Event");

MODULE = Pigment::Event  PACKAGE = Pigment::Event::Scroll

guint32
time (PgmEvent *event)
	CODE:
		RETVAL = event->scroll.time;
	OUTPUT:
		RETVAL

gfloat
x (PgmEvent *event)
	ALIAS:
		y = 1
	CODE:
		switch (ix) {
			case 0:
				RETVAL = event->scroll.x;
				break;
			case 1:
				RETVAL = event->scroll.y;
				break;
		}
	OUTPUT:
		RETVAL

PgmScrollDirection
direction (PgmEvent *event)
	CODE:
		RETVAL = event->scroll.direction;
	OUTPUT:
		RETVAL

BOOT:
	gperl_prepend_isa ("Pigment::Event::Scroll", "Pigment::Event");

MODULE = Pigment::Event  PACKAGE = Pigment::Event::Key

guint32
time (PgmEvent *event)
	CODE:
		RETVAL = event->key.time;
	OUTPUT:
		RETVAL

guint
modifier (PgmEvent *event)
	CODE:
		RETVAL = event->key.modifier;
	OUTPUT:
		RETVAL

guint
keyval (PgmEvent *event)
	CODE:
		RETVAL = event->key.keyval;
	OUTPUT:
		RETVAL

gchar *
char (PgmEvent *event)
	PREINIT:
		STRLEN len;
		gchar buffer[7];
	CODE:
		len = g_unichar_to_utf8 (pgm_keyval_to_unicode (event->key.keyval), buffer);
		buffer[len] = '\0';
		RETVAL = buffer;
	OUTPUT:
		RETVAL

guint16
hardware_keycode (PgmEvent *event)
	CODE:
		RETVAL = event->key.hardware_keycode;
	OUTPUT:
		RETVAL

BOOT:
	gperl_prepend_isa ("Pigment::Event::Key", "Pigment::Event");

MODULE = Pigment::Event  PACKAGE = Pigment::Event::Expose

BOOT:
	gperl_prepend_isa ("Pigment::Event::Expose", "Pigment::Event");

MODULE = Pigment::Event  PACKAGE = Pigment::Event::Configure

gint
x (PgmEvent *event)
	ALIAS:
		y = 1
		width = 2
		height = 3
	CODE:
		switch (ix) {
			case 0:
				RETVAL = event->configure.x;
				break;
			case 1:
				RETVAL = event->configure.y;
				break;
			case 2:
				RETVAL = event->configure.width;
				break;
			case 3:
				RETVAL = event->configure.height;
				break;
		}
	OUTPUT:
		RETVAL

BOOT:
	gperl_prepend_isa ("Pigment::Event::Configure", "Pigment::Event");

MODULE = Pigment::Event  PACKAGE = Pigment::Event::Dnd

guint32
time (PgmEvent *event)
	CODE:
		RETVAL = event->dnd.time;
	OUTPUT:
		RETVAL

gfloat
x (PgmEvent *event)
	ALIAS:
		y = 1
	CODE:
		switch (ix) {
			case 0:
				RETVAL = event->dnd.x;
				break;
			case 1:
				RETVAL = event->dnd.y;
				break;
		}
	OUTPUT:
		RETVAL

void
uri (PgmEvent *event)
	PREINIT:
		gchar **i;
	PPCODE:
		for (i = event->dnd.uri; *i; i++) {
			XPUSHs (newSVGChar (*i));
		}

BOOT:
	gperl_prepend_isa ("Pigment::Event::Dnd", "Pigment::Event");

MODULE = Pigment::Event  PACKAGE = Pigment::Event::State

PgmViewportState
changed_mask (PgmEvent *event)
	ALIAS:
		state_mask = 1
	CODE:
		switch (ix) {
			case 0:
				RETVAL = event->state.changed_mask;
				break;
			case 1:
				RETVAL = event->state.state_mask;
				break;
		}
	OUTPUT:
		RETVAL

BOOT:
	gperl_prepend_isa ("Pigment::Event::State", "Pigment::Event");

MODULE = Pigment::Event  PACKAGE = Pigment::Event::Delete

BOOT:
	gperl_prepend_isa ("Pigment::Event::Delete", "Pigment::Event");

MODULE = Pigment::Event  PACKAGE = Pigment::Event::Win32Message

guint32
time (PgmEvent *event)
	CODE:
		RETVAL = event->win32_message.time;
	OUTPUT:
		RETVAL

guint
message (PgmEvent *event)
	ALIAS:
		wparam = 1
	CODE:
		switch (ix) {
			case 0:
				RETVAL = event->win32_message.message;
				break;
			case 1:
				RETVAL = event->win32_message.wparam;
				break;
		}
	OUTPUT:
		RETVAL

glong
lparam (PgmEvent *event)
	CODE:
		RETVAL = event->win32_message.lparam;
	OUTPUT:
		RETVAL

BOOT:
	gperl_prepend_isa ("Pigment::Event::Win32Message", "Pigment::Event");
