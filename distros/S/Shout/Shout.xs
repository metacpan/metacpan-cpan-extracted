#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <shout/shout.h>

#include "const-c.inc"

MODULE = Shout		PACKAGE = Shout

INCLUDE: const-xs.inc

void
shout_init()

void
shout_shutdown()

shout_t *
raw_new(CLASS)
	char *CLASS
	CODE:
	RETVAL=(shout_t *)shout_new();   /* typecast so perl won't try to cvt */
	if (RETVAL == NULL) {
		warn("unable to allocate shout_t");
		XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

void
DESTROY(self)
	shout_t *self
	CODE:
	shout_free(self);

void
shout_set_host(self, str)
	shout_t *self
	const char *str

void
shout_set_port(self, num)
	shout_t *self
	int num

void
shout_set_mount(self, str)
	shout_t *self
	char *str

void
shout_set_nonblocking(self, num)
	shout_t *self
	int num

void
shout_set_password(self, str)
	shout_t *self
	char *str

void
shout_set_user(self, str)
	shout_t *self
	char *str

void
shout_set_dumpfile(self, str)
	shout_t *self
	char *str

void
shout_set_name(self, str)
	shout_t *self
	char *str

void
shout_set_url(self, str)
	shout_t *self
	char *str

void
shout_set_genre(self, str)
	shout_t *self
	char *str

void
shout_set_description(self, str)
	shout_t *self
	char *str

void
shout_set_public(self, num)
	shout_t *self
	int num

const char *
shout_get_host(self)
	shout_t *self

unsigned short
shout_get_port(self)
	shout_t *self

const char *
shout_get_mount(self)
	shout_t *self

int
shout_get_nonblocking(self)
	shout_t* self

const char *
shout_get_password(self)
	shout_t *self

const char *
shout_get_user(self)
	shout_t *self

const char *
shout_get_dumpfile(self)
	shout_t *self

const char *
shout_get_name(self)
	shout_t *self

const char *
shout_get_url(self)
	shout_t *self

const char *
shout_get_genre(self)
	shout_t *self

const char *
shout_get_description(self)
	shout_t *self

int
shout_get_public(self)
	shout_t *self

const char *
shout_get_error(self)
	shout_t *self

int
shout_get_errno(self)
	shout_t *self

int
shout_get_format(self)
	shout_t *self

void
shout_set_format(self,format)
	shout_t *self
	int format

int
shout_get_protocol(self)
	shout_t *self

void
shout_set_protocol(self,protocol)
	shout_t *self
	int protocol

void *
shout_new()

void
shout_free(self)
	shout_t *self

int
shout_open(self)
	shout_t *self

int
shout_get_connected(self)
	shout_t *self

int
shout_close(self)
	shout_t *self

int
shout_send(self, buff, len)
       shout_t *self
       unsigned char *buff
       unsigned long len

void
shout_sync(self)
       shout_t *self

int
shout_delay(self)
       shout_t *self

int
shout_queuelen(self)
	shout_t* self

int
shout_set_audio_info(self, name, value)
       shout_t *self
       const char *name
       const char *value

const char *
shout_get_audio_info(self, name)
       shout_t *self
       const char *name

shout_metadata_t *
shout_metadata_new()

void 
shout_metadata_free(md)
	shout_metadata_t *md

int 
shout_metadata_add(md,name,value)
	shout_metadata_t *md
	 char *name
	 char *value

int 
shout_set_metadata(self,md)
	shout_t *self
	shout_metadata_t *md

