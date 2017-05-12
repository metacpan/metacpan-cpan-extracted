/*
	perlio.c - PerlIO in Ruby
*/

#include "ruby_pm.h"
#include "perlio.h"

#ifdef LL2NUM
#undef OFFT2NUM
#define OFFT2NUM LL2NUM
#endif

#ifndef O_BINARY
#define O_BINARY 0
#endif

#define PGV(pio) ((GV*)valueRV(pio))
#define PIOp(pio) GvIOp(PGV(pio))
#define PIO(pio)  CheckClosed(pio)
#define PIFP(pio) IoIFP(CheckReadable(pio))
#define POFP(pio) IoOFP(CheckWritable(pio))
#define PIOFP(pio) pio_fp(aTHX_ pio)

#define PIO_NAME(pio) GvNAME(PGV(pio))

#define pio_taint_check(pio) rb_io_taint_check(pio)

#define EvilFH(pio,msg)       pio_evil_fh(aTHX_ pio, msg)
#define CheckInitialized(pio) do{ IO* io = GvIO(PGV(pio)); if(!io || !IoTYPE(io)) EvilFH(pio, "uninitialized"); } while(0)
#define CheckClosed(pio)      pio_check_closed(aTHX_ pio)
#define CheckReadable(pio)    pio_check_readable(aTHX_ pio)
#define CheckWritable(pio)    pio_check_writable(aTHX_ pio)

#define EOFReached(pio) rb_raise(rb_eEOFError, "`%s': End of file reached", PIO_NAME(pio))

VALUE pio_stdin, pio_stdout, pio_stderr;


#define gv_gen(gv, name, len) ((gv = (GV*)newSV(0)), gv_init(gv, PL_curstash, name, len, FALSE))

VALUE plrb_cPerlIO;

VALUE
plrb_pio_gv2pio_noinc(pTHX_ GV* gv)
{
	SV* rv = newRV_noinc((SV*)gv);

	if(!SvOBJECT(gv)){
		IO* io = GvIO(gv);
		HV* stash = io ? SvSTASH(io) : NULL;

		if(!stash) stash = gv_stashpv("IO::Handle", TRUE);

		sv_bless(rv, stash);
	}

	return any_new2_noinc(plrb_cPerlIO, rv);
}
VALUE
plrb_pio_io2pio(pTHX_ IO* io)
{
	GV* gv;
	const char* fdstr;

	if(PIOp(pio_stdin) == io){
		return pio_stdin;
	}
	else if(PIOp(pio_stdout) == io){
		return pio_stdout;
	}
	else if(PIOp(pio_stderr) == io){
		return pio_stderr;
	}

	if(!io) return Qnil;

	fdstr = form("(%d)", PerlIO_fileno(IoIFP(io)));
	gv_gen(gv, fdstr, strlen(fdstr));

	GvIOp(gv) = (IO*)SvREFCNT_inc((SV*)io);

	return gv2pio_noinc(gv);
}


static VALUE
pio_path(VALUE self)
{
	GV* gv = PGV(self);
	VALUE name = rb_str_new(GvNAME(gv), (long)GvNAMELEN(gv));

	V2V_INFECT(self, name);

	return name;
}

SV*
IO_Handle_inspect(pTHX_ GV* gv)
{
	IO* io = GvIO(gv);
	SV* sv;
	int fd;

	if(!io){
		return &PL_sv_undef;
	}

	fd = PerlIO_fileno(IoIFP(io));

	sv = newSV(32);

	sv_setpv(sv, sv_reftype((SV*)gv, TRUE));
	sv_catpv(sv, "(");

	if(fd != -1){
		sv_catpvf(sv, "fd=%d,", fd);
		if(IoOFP(io) && IoIFP(io) != IoOFP(io)){
			int ofd = PerlIO_fileno(IoOFP(io));
			if(fd != ofd){
				sv_catpvf(sv, "%d,", ofd);
			}
		}
	}


	sv_catpv(sv, "type=");

	switch(IoTYPE(io)){
	case IoTYPE_RDONLY:
		sv_catpv(sv, "RDONLY");
		break;
	case IoTYPE_WRONLY:
		sv_catpv(sv, "WRONLY");
		break;
	case IoTYPE_RDWR:
		sv_catpv(sv, "RDWR");
		break;
	case IoTYPE_APPEND:
		sv_catpv(sv, "APPEND");
		break;
	case IoTYPE_STD:
		sv_catpv(sv, "STD");
		break;
	case IoTYPE_SOCKET:
		sv_catpv(sv, "SOCKET");
		break;
	case IoTYPE_CLOSED:
		sv_catpv(sv, "CLOSED");
		break;
	case IoTYPE_IMPLICIT:
		sv_catpv(sv, "IMPLICIT");
		break;
	case IoTYPE_NUMERIC:
		sv_catpv(sv, "NUMERIC");
		break;
	case '\0':
		sv_catpv(sv, "unopened");
		break;
	default:
		sv_catpvf(sv, "'%c'", IoTYPE(io));
	}

	sv_catpv(sv, ")");

	return sv;
}

static VALUE
pio_inspect(VALUE self)
{
	dTHX;
	GV* gv = PGV(self);
	VALUE str = rb_str_buf_new(0);
	SV* sv;

	rb_str_buf_cat2(str, "#<");
	rb_str_buf_cat2(str, rb_obj_classname(self));
	rb_str_buf_cat2(str, " ");

	rb_str_buf_append(str, pio_path(self));
	rb_str_buf_cat2(str, " ");

	sv = IO_Handle_inspect(aTHX_ gv);
	rb_str_buf_cat(str, SvPVX(sv), (long)SvCUR(sv));
	SvREFCNT_dec(sv);

	rb_str_cat(str, ">", 1);

	return str;
}

static inline void
pio_evil_fh(pTHX_ VALUE pio, const char* msg)
{
	rb_raise(rb_eIOError, "`%s' %s", PIO_NAME(pio), msg);
}

static IO*
pio_check_closed(pTHX_ VALUE pio)
{
	IO* io;
	CheckInitialized(pio);

	io = GvIOp(PGV(pio));

	if(IoTYPE(io) == IoTYPE_CLOSED){
		EvilFH(pio, "closed");
	}

	return io;
}


static IO*
pio_check_readable(pTHX_ VALUE pio)
{
	IO* io = CheckClosed(pio);

	if(!IoIFP(io) || IoTYPE(io) == IoTYPE_WRONLY){
		EvilFH(pio, "opened only for output");
	}
	return io;
}
static IO*
pio_check_writable(pTHX_ VALUE pio)
{
	IO* io = CheckClosed(pio);

	if(!IoOFP(io) || IoTYPE(io) == IoTYPE_RDONLY){
		EvilFH(pio, "opened only for input");
	}
	return io;
}

static inline PerlIO*
pio_fp(pTHX_ VALUE pio)
{
	IO* io = CheckClosed(pio);
	return IoIFP(io) ? IoIFP(io) : IoOFP(io);
}

static VALUE
pio_to_io(VALUE self)
{
	dTHX;
	int fd = PerlIO_fileno(PIFP(self));

	VALUE vfd = INT2FIX(dup(fd));

	return rb_class_new_instance(1, &vfd, rb_cIO);
}

static VALUE
pio_close(VALUE self)
{
	dTHX;

	return do_close(PGV(self), (bool)FALSE)  ? Qtrue : Qfalse;
}



static VALUE
pio_open(int argc, VALUE* argv, VALUE klass)
{
	dTHX;
	volatile VALUE vpath;
	volatile VALUE vmode;
	volatile VALUE vperm;

	int as_raw = FALSE;
	int mode = 0;
	int perm = 0666;

	char*  arg1ptr;
	STRLEN arg1len;
	SV* arg2 = NULL;
	int numargs = 0;

	GV* gv;

	VALUE self;

	PERL_UNUSED_ARG(klass);

	rb_scan_args(argc, argv, "12", &vpath, &vmode, &vperm);

	if(!NIL_P(vmode)){
		VALUE m;

		/* open(path, o_flags) */
		m = rb_check_convert_type(vmode, T_FIXNUM, "Fixnum", "to_int");
		if(!NIL_P(m)){
			StringValue(vpath);
			arg1ptr = RSTRING_PTR(vpath);
			arg1len = RSTRLEN(vpath);

			as_raw = TRUE;

			mode = FIX2INT(m);
		}

		/* open(path, modestr) */
		else{
			char* p;
			VALUE v;

			numargs = 1;
			arg2 = VALUE2SV(vpath);
			StringValue(vpath);

			v = vmode;
			StringValue(v);

			vmode = rb_str_new(NULL, RSTRING_LEN(v)+1);
			rb_str_set_len(vmode, 0);
	
			p   = RSTRING_PTR(v);

			while(*p && isSPACE(*p)) p++;

			switch(*p){
			case 'w':
				p++;
				if(*p == '+'){ p++; rb_str_buf_cat(vmode, "+", 1); }
				rb_str_buf_cat(vmode, ">", 1);
				break;
			case 'r':
				p++;
				if(*p == '+'){ p++; rb_str_buf_cat(vmode, "+", 1); }
				rb_str_buf_cat(vmode, "<", 1);
				break;
			case 'a':
				p++;
				if(*p == '+'){ p++; rb_str_buf_cat(vmode, "+", 1); }
				rb_str_buf_cat(vmode, ">>", 2);
				break;
			}

			while(*p && isSPACE(*p)) p++;

			if(*p == 'b'){
				p++;
				mode |= O_BINARY;
			}

			rb_str_buf_cat(vmode, p, RSTRING_LEN(v) - (p - RSTRING_PTR(v)));

			arg1ptr = RSTRING_PTR(vmode);
			arg1len = RSTRLEN(vmode);

		}

	}
	else{
		StringValue(vpath);
		arg1ptr = RSTRING_PTR(vpath);
		arg1len = RSTRLEN(vpath);

		mode = O_RDONLY;
	}

	if(!NIL_P(vperm)){
		perm = NUM2INT(vperm);
	}

	
	gv_gen(gv, RSTRING_PTR(vpath), RSTRLEN(vpath));

	if(!do_openn(gv, arg1ptr, (I32)arg1len, as_raw, mode, perm, Nullfp, &arg2, numargs))
	{
		rb_sys_fail(RSTRING_PTR(vpath));
	}

	self = gv2pio_noinc(gv);

	if(rb_block_given_p()){
		return rb_ensure(rb_yield, self, pio_close, self);
	}

	return self;
}

static VALUE
pio_flock(VALUE self, VALUE operation)
{
	dTHX;
	PerlIO* fp = PIOFP(self);
	int op = NUM2INT(operation);

	PerlIO_flush(fp);
	if(flock(PerlIO_fileno(fp), op) < 0){
		rb_sys_fail(PIO_NAME(self));
	}
	return self;
}

static VALUE
pio_binmode(int argc, VALUE* argv, VALUE self)
{
	dTHX;
	IO* io;
	int mode = 0;
	char* discp;
	volatile VALUE layer;

	rb_scan_args(argc, argv, "01", &layer);

	io = PIO(self);

	if(NIL_P(layer)){
		discp = ":raw";
		mode |= O_BINARY;
	}
	else{
		if(SYMBOL_P(layer)){
			const char* name  = rb_id2name(SYM2ID(layer));
			layer = rb_str_new(NULL, (long)strlen(name)+1);

			rb_str_set_len(layer, 0);

			rb_str_buf_cat2(layer, ":");
			rb_str_buf_cat2(layer, name);
		}else{
			StringValue(layer);
		}

		discp = RSTRING_PTR(layer);
	}

	if(PerlIO_binmode(aTHX_ IoIFP(io), IoTYPE(io), mode, discp)){
		if(IoOFP(io) && IoIFP(io) != IoOFP(io)){
			if(!PerlIO_binmode(aTHX_ IoOFP(io), IoTYPE(io), mode, discp)){
				goto error;
			}
		}

		return self;
	}

	error:
	rb_raise(rb_eArgError, "Can't binmode %s", PIO_NAME(self));

	return Qnil;
}

static VALUE
pio_fileno(VALUE self)
{
	dTHX;
	IO* io;
	PerlIO* fp;
	int fd;

	CheckInitialized(self);

	io = GvIOp(PGV(self));
	fp = IoIFP(io) ? IoIFP(io) : IoOFP(io);

	if(fp){
		fd = PerlIO_fileno(fp);
		return INT2FIX(fd);
	}
	return Qnil;
}
static VALUE
pio_closed(VALUE self)
{
	dTHX;
	IO* io;

	CheckInitialized(self);

	io = GvIOp(PGV(self));

	return( IoTYPE(io) == IoTYPE_CLOSED ? Qtrue : Qfalse );
}

static VALUE
pio_seek(int argc, VALUE* argv, VALUE self)
{
	dTHX;
	VALUE pos, whence;
	int ret;

	rb_scan_args(argc, argv, "11", &pos, &whence);

	ret = PerlIO_seek(PIOFP(self), NUM2OFFT(pos), NIL_P(whence) ? SEEK_SET : FIX2INT(whence));

	if(ret < 0){
		rb_sys_fail(PIO_NAME(self));
	}

	return INT2NUM(ret);
}

#define pio_tell pio_get_pos

static VALUE
pio_get_pos(VALUE self)
{
	dTHX;
	PerlIO* fp = PIOFP(self);
	Off_t pos;

	pos = PerlIO_tell(fp);

	return OFFT2NUM(pos);
}

static VALUE
pio_set_pos(VALUE self, VALUE pos)
{
	dTHX;
	PerlIO* fp = PIOFP(self);
	Off_t ret;

	ret = PerlIO_seek(fp, NUM2OFFT(pos), SEEK_SET);
	PerlIO_clearerr(fp);

	return OFFT2NUM(ret);
}

static VALUE
pio_rewind(VALUE self)
{
	dTHX;
	PerlIO_rewind(PIOFP(self));
	IoLINES(PIO(self)) = 0;

	return self;
}

static VALUE
pio_get_lineno(VALUE self)
{
	dTHX;
	IO* io = PIO(self);

	return INT2NUM((long)IoLINES(io));
}
static VALUE
pio_set_lineno(VALUE self, VALUE lineno)
{
	dTHX;
	IO* io = PIO(self);

	IoLINES(io) = NUM2INT(lineno);

	return lineno;
}

/* read */

static VALUE
pio_eof(VALUE self)
{
	dTHX;
	IO* io = PIO(self);

	if(IoTYPE(io) == IoTYPE_WRONLY){
		EvilFH(self, "opened only for output");
	}

	return PerlIO_eof(IoIFP(io)) ? Qtrue : Qfalse;
}


static inline long
ifp_remain_size(pTHX_ PerlIO* ifp)
{
	Off_t size = BUFSIZ;
	Stat_t st;

	if(fstat(PerlIO_fileno(ifp), &st) == 0 && S_ISREG(st.st_mode)){
		Off_t pos = PerlIO_tell(ifp);
		if(pos != (Off_t) -1 && st.st_size > pos){
			size = st.st_size - pos;

			if(size > LONG_MAX){
				rb_raise(rb_eIOError, "File too big for single read");
			}
		}
	}
	return (long)size;
}



static inline VALUE
io_gets(pTHX_ SV* sv, IO* io)
{
	if(sv_gets(sv, IoIFP(io), FALSE)){
		IoLINES(io)++;
		return rb_tainted_str_new(SvPVX(sv), (long)SvCUR(sv));
	}

	if(PerlIO_error(IoIFP(io))) rb_sys_fail(NULL);

	return Qnil;
}

static VALUE
pio_gets(int argc, VALUE* argv, VALUE self){
	dTHX;
	IO* io;

	rb_scan_args(argc, argv, "0");

	io = CheckReadable(self);

	return io_gets(aTHX_ DEFSV, io);
}
static VALUE
pio_getc(VALUE self){
	dTHX;
	PerlIO* ifp = PIFP(self);

	int c = PerlIO_getc(ifp);

	if(PerlIO_error(ifp)) rb_sys_fail(PIO_NAME(self));

	return c == EOF ? Qnil : INT2FIX(c);
}

static VALUE
pio_ungetc(VALUE self, VALUE ch){
	dTHX;
	PerlIO* ifp = PIFP(self);
	int c = PerlIO_ungetc(ifp, NUM2CHR(ch));

	if(PerlIO_error(ifp)) rb_sys_fail(PIO_NAME(self));

	return INT2FIX(c);
}

static VALUE
pio_read(int argc, VALUE* argv, VALUE self)
{
	dTHX;
	PerlIO* ifp;
	VALUE length, buffer;
	long len, n;

	rb_scan_args(argc, argv, "02", &length, &buffer);


	ifp = PIFP(self);
	if(PerlIO_eof(ifp)) return Qnil;

	if(!NIL_P(buffer)){
		StringValue(buffer);
		rb_str_modify(buffer);
		OBJ_TAINT(buffer);
	}

	if(NIL_P(length)){
		/* slurp */
		long bytes = 0;
		len = ifp_remain_size(aTHX_ ifp);

		if(NIL_P(buffer)){
			buffer = rb_tainted_str_new(NULL, len);
		}
		else{
			rb_str_resize(buffer, len);
		}
		for(;;){
			rb_str_locktmp(buffer);
			assert( (len - bytes) >= 0 );
			n = PerlIO_read(ifp, RSTRING_PTR(buffer)+bytes, (Size_t)(len - bytes));
			rb_str_unlocktmp(buffer);

			if (n == 0 && bytes == 0) {
				rb_str_resize(buffer, 0);

				if(PerlIO_eof(ifp)) return Qnil;

				rb_sys_fail(PIO_NAME(self));
			}
			bytes += n;
			if (bytes < len) break;
			len += BUFSIZ;
			rb_str_resize(buffer, len);
		}

		rb_str_resize(buffer, bytes);

		return buffer;
	}

	len = NUM2LONG(length);

	if(len < 0){
		rb_raise(rb_eArgError, "Negative length (or length too big)");
	}

	if(NIL_P(buffer)){
		buffer = rb_tainted_str_new(NULL, len);
	}
	else{
		rb_str_resize(buffer, len);
	}

	rb_str_locktmp(buffer);
	n = PerlIO_read(ifp, RSTRING_PTR(buffer), (Size_t)len);
	rb_str_unlocktmp(buffer);

	if(n <= 0){
		rb_str_resize(buffer, 0);

		if(PerlIO_eof(ifp)) return Qnil;

		rb_sys_fail(PIO_NAME(self));
	}

	rb_str_resize(buffer, n);

	return buffer;
}

static VALUE
pio_readline(int argc, VALUE* argv, VALUE self)
{
	dTHX;
	VALUE line = pio_gets(argc, argv, self);

	if(NIL_P(line)){
		EOFReached(self);
	}
	return line;
}
static VALUE
pio_readlines(int argc, VALUE* argv, VALUE self)
{
	dTHX;
	VALUE line;
	VALUE ary = rb_ary_new();

	while(!NIL_P(line = pio_gets(argc, argv, self))){
		rb_ary_push(ary, line);
	}
	return ary;
}


static VALUE
pio_each_line(int argc, VALUE* argv, VALUE self)
{
	dTHX;
	register IO* io;
	register VALUE line;
	SV* sv = DEFSV;
	/* VALUE rs; */

	rb_scan_args(argc, argv, "0");

	io = CheckReadable(self);

	while(!NIL_P(line = io_gets(aTHX_ sv, io))){
		rb_yield(line);
	}
	return self;
}

static VALUE
pio_each_byte(VALUE self)
{
	dTHX;
	PerlIO* ifp = PIFP(self);

	register int c;

	while((c = PerlIO_getc(ifp)) != EOF){
		rb_yield(INT2FIX(c));
	}

	if(PerlIO_error(ifp)) rb_sys_fail(PIO_NAME(self));

	return self;
}

/* write */


static VALUE
pio_write(VALUE self, VALUE obj)
{
	dTHX;
	IO* io;
	STRLEN tmplen;
	const char* tmp;
	long n;

	rb_secure(4);

	io = CheckWritable(self);

	obj = rb_obj_as_string(obj);

	tmplen = RSTRLEN(obj);
	tmp    = RSTRING_PTR(obj);

	n = PerlIO_write(IoOFP(io), tmp, tmplen);

	if(n < 0){
		rb_sys_fail(PIO_NAME(self));
	}

	if(IoFLAGS(io) & IOf_FLUSH) /* autoflush */
		PerlIO_flush(IoOFP(io));

	return LONG2NUM(n);
}

static VALUE
pio_putc(VALUE self, VALUE ch)
{
	dTHX;
	char c = NUM2CHR(ch);

	if(PerlIO_write(POFP(self), &c, 1) != 1){
		rb_sys_fail(PIO_NAME(self));
	}
	return ch;
}

static VALUE
pio_flush(VALUE self)
{
	dTHX;
	PerlIO* ofp = POFP(self);
	PerlIO_flush(ofp);

	if(PerlIO_error(ofp)) rb_sys_fail(PIO_NAME(self));

	return self;
}

#define pio_addstr rb_io_addstr
#define pio_print  rb_io_print
#define pio_printf rb_io_printf
#define pio_puts   rb_io_puts

/* take over rb_stdout/rb_stderr */

static VALUE
write_to_pio_stdout(VALUE rbio, VALUE str)
{
	PERL_UNUSED_ARG(rbio);

	return pio_write(pio_stdout, str);
}
static VALUE
write_to_pio_stderr(VALUE rbio, VALUE str)
{
	PERL_UNUSED_ARG(rbio);
	return pio_write(pio_stderr, str);
}

void Init_perlio(pTHX)
{
	plrb_cPerlIO = rb_define_class_under(plrb_mPerl, "IO", plrb_cAny);

	rb_include_module(plrb_cPerlIO, rb_mEnumerable);

	rb_define_module_function(plrb_mPerl, "open", pio_open, -1);

	rb_define_method(plrb_cPerlIO, "inspect", pio_inspect,  0);
	rb_define_method(plrb_cPerlIO, "path",    pio_path,     0);
	rb_define_method(plrb_cPerlIO, "to_io",   pio_to_io,    0);

	rb_define_method(plrb_cPerlIO, "close",   pio_close,    0);

	rb_define_method(plrb_cPerlIO, "flock",   pio_flock,    1);
	rb_define_method(plrb_cPerlIO, "binmode", pio_binmode, -1);
	rb_define_method(plrb_cPerlIO, "fileno",  pio_fileno,   0);
	rb_define_method(plrb_cPerlIO, "closed?", pio_closed,   0);

	rb_define_method(plrb_cPerlIO, "seek",    pio_seek,    -1);
	rb_define_method(plrb_cPerlIO, "tell",    pio_tell,     0);
	rb_define_method(plrb_cPerlIO, "pos",     pio_get_pos,  0);
	rb_define_method(plrb_cPerlIO, "pos=",    pio_set_pos,  1);
	rb_define_method(plrb_cPerlIO, "rewind",  pio_rewind,   0);

	rb_define_method(plrb_cPerlIO, "lineno",  pio_get_lineno, 0);
	rb_define_method(plrb_cPerlIO, "lineno=", pio_set_lineno, 1);

	/* read */

	rb_define_method(plrb_cPerlIO, "eof?",      pio_eof, 0);
	rb_define_method(plrb_cPerlIO, "eof",       pio_eof, 0);

	rb_define_method(plrb_cPerlIO, "gets",      pio_gets,  -1);
	rb_define_method(plrb_cPerlIO, "getc",      pio_getc,   0);
	rb_define_method(plrb_cPerlIO, "ungetc",    pio_ungetc, 1);

	rb_define_method(plrb_cPerlIO, "read",      pio_read,      -1);
	rb_define_method(plrb_cPerlIO, "readline",  pio_readline,  -1);
	rb_define_method(plrb_cPerlIO, "readlines", pio_readlines, -1);

	rb_define_method(plrb_cPerlIO, "each",      pio_each_line, -1);
	rb_define_method(plrb_cPerlIO, "each_line", pio_each_line, -1);
	rb_define_method(plrb_cPerlIO, "each_byte", pio_each_byte,  0);

	/* write */

	rb_define_method(plrb_cPerlIO, "write",    pio_write,    1);

	rb_define_method(plrb_cPerlIO, "flush",  pio_flush, 0);

	rb_define_method(plrb_cPerlIO, "<<",     pio_addstr,  1);
	rb_define_method(plrb_cPerlIO, "print",  pio_print,  -1);
	rb_define_method(plrb_cPerlIO, "printf", pio_printf, -1);
	rb_define_method(plrb_cPerlIO, "putc",   pio_putc,    1);
	rb_define_method(plrb_cPerlIO, "puts",   pio_puts,   -1);


	pio_stdout = gv2pio(PL_defoutgv);
	pio_stderr = gv2pio(PL_stderrgv);
	pio_stdin  = gv2pio(PL_stdingv);

	rb_define_const(plrb_mPerl, "STDIN",  pio_stdin);
	rb_define_const(plrb_mPerl, "STDOUT", pio_stdout);
	rb_define_const(plrb_mPerl, "STDERR", pio_stderr);

#ifdef PERLIO_REPLACE_RUBYIO

	rb_stdout = pio_stdout;
	rb_stderr = pio_stdin;
	rb_stdin  = pio_stderr;
#else

	rb_define_singleton_method(rb_stdout, "write", write_to_pio_stdout, 1);
	rb_define_singleton_method(rb_stderr, "write", write_to_pio_stderr, 1);

#endif

}
