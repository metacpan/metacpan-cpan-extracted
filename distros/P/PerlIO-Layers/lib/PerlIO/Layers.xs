#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <perliol.h>

#define CONSTANT(name, key, value) hv_store(get_hv("PerlIO::Layers::" #name, TRUE), key, sizeof key - 1, newSVuv(value), 0)

#define INSTANCE_CONSTANT(cons) CONSTANT(FLAG_FOR, #cons, PERLIO_F_##cons)

#define KIND_CONSTANT(cons) CONSTANT(KIND_FOR, #cons, PERLIO_K_##cons)

MODULE = PerlIO::Layers				PACKAGE = PerlIO::Layers

BOOT:
	INSTANCE_CONSTANT(EOF);
	INSTANCE_CONSTANT(CANWRITE);
	INSTANCE_CONSTANT(CANREAD);
	INSTANCE_CONSTANT(ERROR);
	INSTANCE_CONSTANT(TRUNCATE);
	INSTANCE_CONSTANT(APPEND);
	INSTANCE_CONSTANT(CRLF);
	INSTANCE_CONSTANT(UTF8);
	INSTANCE_CONSTANT(UNBUF);
	INSTANCE_CONSTANT(WRBUF);
	INSTANCE_CONSTANT(RDBUF);
	INSTANCE_CONSTANT(LINEBUF);
	INSTANCE_CONSTANT(TEMP);
	INSTANCE_CONSTANT(OPEN);
	INSTANCE_CONSTANT(FASTGETS);
	
	KIND_CONSTANT(BUFFERED);
	KIND_CONSTANT(RAW);
	KIND_CONSTANT(CANCRLF);
	KIND_CONSTANT(FASTGETS);
	KIND_CONSTANT(MULTIARG);
	KIND_CONSTANT(UTF8);

SV*
_get_kinds(handle);
	PerlIO* handle;
	PREINIT:
	HV* ret = newHV();
	CODE:
	while (PerlIOBase(handle)) {
		PerlIOl* current = PerlIOBase(handle);
		hv_store(ret, current->tab->name, strlen(current->tab->name), newSViv(current->tab->kind), 0);
		handle = PerlIONext(handle);
	}
	RETVAL = newRV_noinc((SV*)ret);
	OUTPUT:
		RETVAL

IV
get_buffer_sizes(handle);
	PerlIO* handle;
	PREINIT:
		PerlIO* current;
		int counter = 0;
	PPCODE:
		for (current = handle; *current; current = PerlIONext(current)) {
			PerlIOBuf* buffer;
			if (!(PerlIOBase(current)->tab->kind & PERLIO_K_BUFFERED))
				continue;
			buffer = PerlIOSelf(current, PerlIOBuf);
			if (!buffer->bufsiz && !buffer->buf)
				PerlIO_get_base(current);
			mXPUSHu(buffer->bufsiz);
			counter++;
		}
		if (!counter)
			Perl_croak(aTHX_ "Handle not buffered, aborting");
		PUTBACK;

