#include "perl-pigment.h"

MODULE = Pigment  PACKAGE = Pigment  PREFIX = pgm_

void
pgm_init (class)
	PREINIT:
		GPerlArgv *perl_argv;
	INIT:
		perl_argv = gperl_argv_new ();
	C_ARGS:
		&perl_argv->argc, &perl_argv->argv
	POSTCALL:
		gperl_argv_update (perl_argv);
	CLEANUP:
		gperl_argv_free (perl_argv);

gboolean
pgm_init_check (class)
	PREINIT:
		GPerlArgv *perl_argv;
	INIT:
		perl_argv = gperl_argv_new ();
	C_ARGS:
		&perl_argv->argc, &perl_argv->argv
	POSTCALL:
		gperl_argv_update (perl_argv);
	CLEANUP:
		gperl_argv_free (perl_argv);

void
pgm_deinit (class)
	C_ARGS:

void
pgm_version (class, OUTLIST guint major, OUTLIST guint minor, OUTLIST guint micro, OUTLIST guint nano)
	C_ARGS:
		&major, &minor, &micro, &nano

gchar *
pgm_version_string (class)
	C_ARGS:

gboolean
pgm_events_pending (class)
	C_ARGS:

void
pgm_main (class)
	C_ARGS:

void
pgm_main_quit (class)
	C_ARGS:

void
pgm_main_iteration (class)
	C_ARGS:

void
pgm_main_iteration_do (class, blocking)
		gboolean blocking
	C_ARGS:
		blocking

BOOT:
#include "boot.xsh"
#include "register.xsh"
