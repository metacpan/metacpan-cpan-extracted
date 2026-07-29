#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "wslay/wslay.h"
#include "EVAPI.h"

//windows
#ifdef WIN32
	#ifndef EWOULDBLOCK
		#define EWOULDBLOCK WSAEWOULDBLOCK
	#endif
#else
	#include <fcntl.h>
	#ifndef EWOULDBLOCK
		#define EWOULDBLOCK EAGAIN
	#endif
#endif

#define FRAGMENTED_EOF 0
#define FRAGMENTED_ERROR -1
#define FRAGMENTED_DATA 1

#define REQUIRE_CTX(ws) if (!(ws)->ctx) { croak("WebSocket connection already closed"); }

/* croak_sv is perl 5.13.1+; before that, rethrow via $@ */
#ifdef croak_sv
	#define RETHROW(sv) croak_sv(sv)
#else
	#define RETHROW(sv) STMT_START { sv_setsv(ERRSV, (sv)); croak(NULL); } STMT_END
#endif

typedef struct {
	wslay_event_context_ptr ctx;
	HV* perl_callbacks;
	ev_io io;
	ev_cleanup loop_cleanup;
	struct ev_loop* loop;
	SV* queue_wait_cb;
	SV* pending_error;
	SV** frag_sources;
	size_t frag_count;
	size_t frag_size;
	struct wslay_event_callbacks callbacks;
	uint8_t default_rsv;
	char read_stopped;
	char write_stopped;
} websocket_object;

/* no handlers; its address just identifies our magic among other PERL_MAGIC_ext */
static MGVTBL wslay_magic_vtbl;

static void wait_io_event(websocket_object* websock_object);

/* a watcher cannot ask whether its loop is alive, and EV::default_destroy()
   frees one out from under us; this fires while it is still usable */
static void loop_cleanup_event(struct ev_loop* loop, ev_cleanup* w, int revents) {
	websocket_object* websock_object = (websocket_object*) w->data;
	if (ev_is_active(&(websock_object->io))) { ev_io_stop(loop, &(websock_object->io)); }
	websock_object->loop = NULL;
}

static void stop_io_watcher(websocket_object* websock_object) {
	if (websock_object->loop && ev_is_active(&(websock_object->io))) {
		ev_io_stop(websock_object->loop, &(websock_object->io));
	}
}

static ssize_t recv_callback(wslay_event_context_ptr ctx, uint8_t* buf, size_t len, int flags, void* data) {
	websocket_object* websock_object = (websocket_object*) data;
	ssize_t r;
	while ((r = recv(websock_object->io.fd, buf, len, 0)) == -1 && errno == EINTR);
	if (r == -1) {
		if (errno == EAGAIN || errno == EWOULDBLOCK) {
			wslay_event_set_error(ctx, WSLAY_ERR_WOULDBLOCK);
		} else {
			wslay_event_set_error(ctx, WSLAY_ERR_CALLBACK_FAILURE);
		}
	} else if (r == 0) { /* Unexpected EOF is also treated as an error */
		wslay_event_set_error(ctx, WSLAY_ERR_CALLBACK_FAILURE);
		r = -1;
	}
	return r;
}

static ssize_t send_callback(wslay_event_context_ptr ctx, const uint8_t* buf, size_t len, int flags, void* data) {
	websocket_object* websock_object = (websocket_object*) data;
	ssize_t r;
	int sflags = 0;
	#ifdef MSG_MORE
	if(flags & WSLAY_MSG_MORE) { sflags |= MSG_MORE; }
	#endif // MSG_MORE
	while ((r = send(websock_object->io.fd, buf, len, sflags)) == -1 && errno == EINTR);
	if (r == -1) {
		if(errno == EAGAIN || errno == EWOULDBLOCK) {
			wslay_event_set_error(ctx, WSLAY_ERR_WOULDBLOCK);
		} else {
			wslay_event_set_error(ctx, WSLAY_ERR_CALLBACK_FAILURE);
		}
	}
	return r;
}

static MAGIC* get_wslay_magic (HV* hv) {
	MAGIC* mg;
	for (mg = SvMAGIC((SV*) hv); mg; mg = mg->mg_moremagic) {
		if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &wslay_magic_vtbl) {
			return mg;
		}
	}
	return NULL;
}

static websocket_object* get_wslay_context (HV* hv) {
	MAGIC* mg = get_wslay_magic(hv);
	if (!mg || !mg->mg_ptr) {
		croak("Net::WebSocket::EVx - object is not initialized or has already been destroyed");
	}
	return (websocket_object*) mg->mg_ptr;
}

/* hold a callback's exception instead of letting it longjmp out of wslay/libev */
static void catch_perl_error(websocket_object* websock_object) {
	if (!SvTRUE(ERRSV)) { return; }
	if (!websock_object->pending_error) { websock_object->pending_error = newSVsv(ERRSV); }
	sv_setpvn(ERRSV, "", 0);
}

static SV* take_perl_error(websocket_object* websock_object) {
	SV* error = websock_object->pending_error;
	websock_object->pending_error = NULL;
	return error;
}

/* a callback may drop the last reference to its own object (undef $ws), freeing
   the struct we are using; UNGUARD is what then runs DESTROY, so nothing may
   touch the object after it */
#define GUARD(ws)   SvREFCNT_inc((SV*) (ws)->perl_callbacks)
#define UNGUARD(ws) SvREFCNT_dec((SV*) (ws)->perl_callbacks)

static void track_fragmented_source(websocket_object* websock_object, SV* cb) {
	if (websock_object->frag_count == websock_object->frag_size) {
		size_t size = websock_object->frag_size ? websock_object->frag_size * 2 : 4;
		SV** sources = (SV**) realloc(websock_object->frag_sources, size * sizeof(SV*));
		if (!sources) { croak("Net::WebSocket::EVx - out of memory"); }
		websock_object->frag_sources = sources;
		websock_object->frag_size = size;
	}
	SvREFCNT_inc(cb);
	websock_object->frag_sources[websock_object->frag_count++] = cb;
}

static void release_fragmented_source(websocket_object* websock_object, SV* cb) {
	size_t i;
	for (i = 0; i < websock_object->frag_count; i++) {
		if (websock_object->frag_sources[i] == cb) {
			websock_object->frag_sources[i] = websock_object->frag_sources[--websock_object->frag_count];
			SvREFCNT_dec(cb);
			return;
		}
	}
}

static int genmask_callback(wslay_event_context_ptr ctx, uint8_t* buf, size_t len, void* data) {
	websocket_object* websock_object = (websocket_object*) data;
	SV** cb;
	size_t i;
	/* wslay reuses buf between frames, so seed it first: a failing callback must
	   never leave the previous frame's key (or zeroes) in place */
	for (i = 0; i < len; i++) { buf[i] = (uint8_t) (rand() & 0xff); }
	if (websock_object->pending_error) { return 0; }
	if ((cb = hv_fetch(websock_object->perl_callbacks , "genmask", 7, 0))) {
		int count, failed = 0;
		SV* sv_data;
		STRLEN source_len;
		char *source_buf;
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		XPUSHs(sv_2mortal(newSVuv(len)));
		PUTBACK;
		count = call_sv(*cb, G_SCALAR|G_EVAL);
		SPAGAIN;
		if (SvTRUE(ERRSV)) {
			catch_perl_error(websock_object);
			failed = 1;
		} else {
			sv_data = count ? SP[0] : &PL_sv_undef;
			/* an undef return is a length error, not something to warn about */
			if (SvOK(sv_data)) { source_buf = SvPV(sv_data, source_len); }
			else { source_buf = NULL; source_len = 0; }
			if (source_len != len) {
				websock_object->pending_error = newSVpvf(
					"Net::WebSocket::EVx - genmask callback must return exactly %" UVuf " bytes, got %" UVuf,
					(UV) len, (UV) source_len
				);
				failed = 1;
			} else {
				memcpy(buf, source_buf, len);
			}
		}
		SP -= count;
		PUTBACK;
		FREETMPS;
		LEAVE;
		if (failed) {
			wslay_event_set_error(ctx, WSLAY_ERR_CALLBACK_FAILURE);
			return -1;
		}
	}
	return 0;
}

static void on_frame_recv_start_callback (wslay_event_context_ptr ctx, const struct wslay_event_on_frame_recv_start_arg* frame, void* data) {
	websocket_object* websock_object = (websocket_object*) data;
	SV** cb;
	if (websock_object->pending_error) { return; }
	if (!(cb = hv_fetch(websock_object->perl_callbacks, "on_frame_recv_start", 19, 0)) ) {
		return;
	}
	{
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSViv(frame->fin)));
		PUSHs(sv_2mortal(newSViv(frame->rsv)));
		PUSHs(sv_2mortal(newSViv(frame->opcode)));
		PUSHs(sv_2mortal(newSVuv(frame->payload_length)));
		PUTBACK;
		call_sv(*cb, G_VOID|G_DISCARD|G_EVAL);
		FREETMPS;
		LEAVE;
	}
	catch_perl_error(websock_object);
}

static void on_frame_recv_chunk_callback (wslay_event_context_ptr ctx, const struct wslay_event_on_frame_recv_chunk_arg* chunk, void* data) {
	websocket_object* websock_object = (websocket_object*) data;
	SV** cb;
	if (websock_object->pending_error) { return; }
	if (!(cb = hv_fetch(websock_object->perl_callbacks, "on_frame_recv_chunk", 19, 0))) {
		return;
	}
	{
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		EXTEND(SP, 1);
		PUSHs(sv_2mortal(newSVpvn((const char*) chunk->data, chunk->data_length)));
		PUTBACK;
		call_sv(*cb, G_VOID|G_DISCARD|G_EVAL);
		FREETMPS;
		LEAVE;
	}
	catch_perl_error(websock_object);
}

static void on_frame_recv_end_callback(wslay_event_context_ptr ctx, void* data) {
	websocket_object* websock_object = (websocket_object*) data;
	SV** cb;
	if (websock_object->pending_error) { return; }
	if (!(cb = hv_fetch(websock_object->perl_callbacks, "on_frame_recv_end", 17, 0))) {
		return;
	}
	{
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		call_sv(*cb, G_DISCARD|G_NOARGS|G_EVAL);
		FREETMPS;
		LEAVE;
	}
	catch_perl_error(websock_object);
}

static void on_msg_recv_callback(wslay_event_context_ptr ctx, const struct wslay_event_on_msg_recv_arg* msg, void* data) {
	websocket_object* websock_object = (websocket_object*) data;
	SV** cb;
	SV* msg_data;
	if (msg->opcode == 0x08) { return; }
	if (websock_object->pending_error) { return; }
	if (!(cb = hv_fetch(websock_object->perl_callbacks, "on_msg_recv", 11, 0))) {
		return;
	}
	msg_data = newSVpvn((const char*) msg->msg, msg->msg_length);
	if (!(msg->rsv & WSLAY_RSV1_BIT) && msg->opcode == 1) { SvUTF8_on(msg_data); }
	{
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSViv(msg->rsv)));
		PUSHs(sv_2mortal(newSViv(msg->opcode)));
		PUSHs(sv_2mortal(msg_data));
		PUSHs(sv_2mortal(newSViv(msg->status_code)));
		PUTBACK;
		call_sv(*cb, G_VOID|G_DISCARD|G_EVAL);
		FREETMPS;
		LEAVE;
	}
	catch_perl_error(websock_object);
}

static ssize_t fragmented_msg_callback(wslay_event_context_ptr ctx, uint8_t* buf, size_t len, const union wslay_event_msg_source* source, int* eof, void* userdata) {
	websocket_object* websock_object = (websocket_object*) userdata;
	SV* cb = (SV*) source->data;
	ssize_t bytes_written = 0;
	int count, failed = 0;
	SV* data = &PL_sv_undef;
	int status = FRAGMENTED_DATA;
	STRLEN source_len;
	char* source_buf;
	if (websock_object->pending_error) {
		release_fragmented_source(websock_object, cb);
		wslay_event_set_error(ctx, WSLAY_ERR_CALLBACK_FAILURE);
		return -1;
	}
	{
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		XPUSHs(sv_2mortal(newSVuv(len)));
		PUTBACK;
		count = call_sv(cb, G_ARRAY|G_EVAL);
		SPAGAIN;
		if (SvTRUE(ERRSV)) {
			catch_perl_error(websock_object);
			failed = 1;
		} else if (count == 1) {
			data = SP[0];
		} else if (count == 2) {
			status = SvIV(SP[0]);
			data = SP[-1];
		} else {
			websock_object->pending_error = newSVpv(
				"Net::WebSocket::EVx - fragmented msg cb MUST return one or two elements!", 0
			);
			failed = 1;
		}
		if (!failed && SvOK(data)) {
			source_buf = SvPV(data, source_len);
			if (source_len) {
				bytes_written = (ssize_t) (source_len < len ? source_len : len);
				memcpy(buf, source_buf, bytes_written);
			}
		}
		SP -= count;
		PUTBACK;
		FREETMPS;
		LEAVE;
	}
	if (failed) {
		release_fragmented_source(websock_object, cb);
		wslay_event_set_error(ctx, WSLAY_ERR_CALLBACK_FAILURE);
		return -1;
	}
	if (status == FRAGMENTED_EOF) {
		*eof = 1;
		release_fragmented_source(websock_object, cb);
	} else if (status == FRAGMENTED_ERROR) {
		bytes_written = -1;
		wslay_event_set_error(websock_object->ctx, WSLAY_ERR_CALLBACK_FAILURE);
		release_fragmented_source(websock_object, cb);
	}
	// else - FRAGMENTED_DATA
	return bytes_written;
}

//////////////////////
static void close_connection(websocket_object* websock_object) {
	int status;
	SV** cb;
	if (!websock_object->ctx) { return; }
	status = wslay_event_get_status_code_received(websock_object->ctx);
	wslay_event_context_free(websock_object->ctx);
	websock_object->ctx = NULL;
	stop_io_watcher(websock_object);
	if (websock_object->io.fd >= 0) {
		close(websock_object->io.fd); /* our own dup(), never the caller's descriptor */
		websock_object->io.fd = -1;
	}
	/* no perl during global destruction: callbacks and what they close over may be gone */
	if (PL_dirty) { return; }
	if ((cb = hv_fetch(websock_object->perl_callbacks, "on_close", 8, 0))) {
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		EXTEND(SP, 1);
		PUSHs(sv_2mortal(newSViv(status)));
		PUTBACK;
		call_sv(*cb, G_VOID|G_DISCARD|G_EVAL);
		FREETMPS;
		LEAVE;
		catch_perl_error(websock_object);
	};
}

static void wslay_io_event (struct ev_loop* loop, struct ev_io* w, int revents) {
	websocket_object* websock_object = (websocket_object*) w->data;
	SV* error;
	GUARD(websock_object); /* wslay parses into the struct across every callback */
	if (revents & EV_READ) {
		if (wslay_event_recv(websock_object->ctx)) {
			close_connection(websock_object);
			goto done;
		}
	}
	if (!websock_object->ctx) { goto done; }
	if (revents & EV_WRITE) {
		if (wslay_event_send(websock_object->ctx)) {
			close_connection(websock_object);
			goto done;
		}
	}
	wait_io_event(websock_object);
	done:
	error = take_perl_error(websock_object);
	UNGUARD(websock_object);
	if (error) { RETHROW(sv_2mortal(error)); }
};

static void wait_io_event(websocket_object* websock_object) {
	int events = 0;
	char wanted_io = 0;
	stop_io_watcher(websock_object);
	if (!websock_object->loop) { return; } /* loop destroyed under us: no more IO */
	if (websock_object->read_stopped && websock_object->write_stopped) { return; }
	if (!websock_object->ctx) { return; }
	if (wslay_event_want_read(websock_object->ctx)) {
		if (!websock_object->read_stopped) { events |= EV_READ; }
		wanted_io = 1;
	}
	if (wslay_event_want_write(websock_object->ctx)) {
		if (!websock_object->write_stopped) { events |= EV_WRITE; }
		wanted_io = 1;
	} else if (
		websock_object->queue_wait_cb &&
		!wslay_event_get_queued_msg_count(websock_object->ctx)
	) {
		SV* wait_cb = websock_object->queue_wait_cb;
		websock_object->queue_wait_cb = NULL;
		{
			dSP;
			ENTER;
			SAVETMPS;
			PUSHMARK(SP);
			call_sv(wait_cb, G_DISCARD|G_NOARGS|G_EVAL);
			FREETMPS;
			LEAVE;
		}
		SvREFCNT_dec(wait_cb);
		catch_perl_error(websock_object);
		/* the callback may have closed the connection under us */
		if (!websock_object->ctx) { return; }
		if (wslay_event_want_write(websock_object->ctx)) {
			if (!websock_object->write_stopped) { events |= EV_WRITE; }
			wanted_io = 1;
		}
	}

	if (events) {
		ev_io_set(&(websock_object->io), websock_object->io.fd, events);
		ev_io_start(websock_object->loop, &(websock_object->io));
	} else if (!wanted_io && websock_object->ctx) {
		close_connection(websock_object);
	}

};

/* wait_io_event for the XSUBs: guarded, and rethrows what a callback died with */
static void wait_io_event_guarded(websocket_object* websock_object) {
	SV* error;
	GUARD(websock_object);
	wait_io_event(websock_object);
	error = take_perl_error(websock_object);
	UNGUARD(websock_object);
	if (error) { RETHROW(sv_2mortal(error)); }
}


MODULE = Net::WebSocket::EVx	PACKAGE = Net::WebSocket::EVx


BOOT:
{
	I_EV_API("Net::WebSocket::EVx");
	/* unseeded rand() emits the same mask sequence in every process */
	srand((unsigned int) Perl_seed(aTHX));
#ifdef WIN32
	_setmaxstdio(2048);
#endif
}

PROTOTYPES: DISABLE

void _wslay_event_context_init(object, sock, is_server)
	HV* object
	int sock
	int is_server
	CODE:
		websocket_object* websock_object;
		int fd;
		if (sock < 0) { croak("Net::WebSocket::EVx - invalid file descriptor: %d", sock); }
		/* own a private copy: closing the caller's would have perl close it
		   again when their handle is reaped, killing whatever reused the number */
		fd = dup(sock);
		if (fd < 0) { croak("Net::WebSocket::EVx - dup(%d) failed: %s", sock, strerror(errno)); }
		#ifndef WIN32
		{	/* keep the caller's close-on-exec setting, which dup() drops */
			int fd_flags = fcntl(sock, F_GETFD);
			if (fd_flags >= 0) { (void) fcntl(fd, F_SETFD, fd_flags); }
		}
		#endif
		websock_object = calloc(1, sizeof(websocket_object));
		if (!websock_object) { close(fd); croak("Net::WebSocket::EVx - out of memory"); }
		ev_io_init(&(websock_object->io), wslay_io_event, fd, EV_READ);
		websock_object->io.data = (void*) websock_object;
		ev_cleanup_init(&(websock_object->loop_cleanup), loop_cleanup_event);
		websock_object->loop_cleanup.data = (void*) websock_object;
		websock_object->loop = EV_DEFAULT;
		websock_object->perl_callbacks = object;
		websock_object->default_rsv = WSLAY_RSV1_BIT;
		websock_object->callbacks.recv_callback = recv_callback;
		websock_object->callbacks.send_callback = send_callback;
		websock_object->callbacks.genmask_callback = genmask_callback;
		websock_object->callbacks.on_frame_recv_start_callback = on_frame_recv_start_callback;
		websock_object->callbacks.on_frame_recv_chunk_callback = on_frame_recv_chunk_callback;
		websock_object->callbacks.on_frame_recv_end_callback = on_frame_recv_end_callback;
		websock_object->callbacks.on_msg_recv_callback = on_msg_recv_callback;
		if (is_server
			? wslay_event_context_server_init(&(websock_object->ctx), &(websock_object->callbacks), websock_object)
			: wslay_event_context_client_init(&(websock_object->ctx), &(websock_object->callbacks), websock_object)
		) {
			close(fd);
			free(websock_object);
			croak("Can't initialize! WSLAY_ERR_NOMEM \n");
		}
		sv_magicext((SV*) object, NULL, PERL_MAGIC_ext, &wslay_magic_vtbl, (const char *) websock_object, 0);
		ev_cleanup_start(websock_object->loop, &(websock_object->loop_cleanup));
		wslay_event_config_set_allowed_rsv_bits(websock_object->ctx, WSLAY_RSV1_BIT);
		wait_io_event_guarded(websock_object);

void _wslay_event_config_set_no_buffering (object, buffering)
	HV* object
	int buffering
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		wslay_event_config_set_no_buffering(websock_object->ctx, buffering);

void _wslay_event_config_set_max_recv_msg_length(object, len)
	HV* object
	UV len
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		wslay_event_config_set_max_recv_msg_length(websock_object->ctx, len);

void _wslay_event_config_set_allowed_rsv_bits(object, rsv)
	HV* object
	int rsv
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		wslay_event_config_set_allowed_rsv_bits(websock_object->ctx, (uint8_t) rsv);

void _set_default_rsv(object, rsv)
	HV* object
	int rsv
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		websock_object->default_rsv = (uint8_t) rsv;

void shutdown_read(object)
	HV* object
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		wslay_event_shutdown_read(websock_object->ctx);

void shutdown_write(object)
	HV* object
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		wslay_event_shutdown_write(websock_object->ctx);

void stop(object)
	HV* object
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		websock_object->read_stopped = 1;
		websock_object->write_stopped = 1;
		wait_io_event_guarded(websock_object);

void stop_read(object)
	HV* object
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		websock_object->read_stopped = 1;
		wait_io_event_guarded(websock_object);

void stop_write(object)
	HV* object
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		websock_object->write_stopped = 1;
		wait_io_event_guarded(websock_object);

void start(object)
	HV* object
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		websock_object->read_stopped = 0;
		websock_object->write_stopped = 0;
		wait_io_event_guarded(websock_object);

void start_read(object)
	HV* object
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		websock_object->read_stopped = 0;
		wait_io_event_guarded(websock_object);

void start_write(object)
	HV* object
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		websock_object->write_stopped = 0;
		wait_io_event_guarded(websock_object);

void _set_waiter(object, waiter)
	HV* object
	SV* waiter
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		if (websock_object->queue_wait_cb) { SvREFCNT_dec(websock_object->queue_wait_cb); }
		websock_object->queue_wait_cb = waiter;
		SvREFCNT_inc(waiter);
		wait_io_event_guarded(websock_object);

int queue_msg (object, data, opcode=1)
	HV* object
	SV* data
	int opcode
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		STRLEN len;
		struct wslay_event_msg msg;
		msg.msg = (const uint8_t*) SvPV(data, len);
		msg.msg_length = len;
		msg.opcode = opcode;
		int result = wslay_event_queue_msg(websock_object->ctx, &msg);
		if (result == WSLAY_ERR_INVALID_ARGUMENT) { croak("Wslay queue_msg - WSLAY_ERR_INVALID_ARGUMENT"); }
		if (result == WSLAY_ERR_NOMEM) { croak("Wslay queue_msg - WSLAY_ERR_NOMEM"); }
		wait_io_event_guarded(websock_object);
		RETVAL = result;
	OUTPUT:
		RETVAL

int queue_msg_ex (object, data, opcode=1, rsv=-1)
	HV* object
	SV* data
	int opcode
	int rsv
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		STRLEN len;
		struct wslay_event_msg msg;
		if (rsv < 0) { rsv = websock_object->default_rsv; }
		msg.msg = (const uint8_t*) SvPV(data, len);
		msg.msg_length = len;
		msg.opcode = opcode;
		int result = wslay_event_queue_msg_ex(websock_object->ctx, &msg, (uint8_t) rsv);
		if (result == WSLAY_ERR_INVALID_ARGUMENT) { croak("Wslay queue_msg_ex - WSLAY_ERR_INVALID_ARGUMENT"); }
		if (result == WSLAY_ERR_NOMEM) { croak("Wslay queue_msg_ex - WSLAY_ERR_NOMEM"); }
		wait_io_event_guarded(websock_object);
		RETVAL = result;
	OUTPUT:
		RETVAL

int queue_fragmented (object, cb, opcode=2)
	HV* object
	SV* cb
	int opcode
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		struct wslay_event_fragmented_msg msg;
		msg.opcode = opcode;
		msg.source.data = cb;
		msg.read_callback = fragmented_msg_callback;
		track_fragmented_source(websock_object, cb);
		int result = wslay_event_queue_fragmented_msg(websock_object->ctx, &msg);
		if (result) { release_fragmented_source(websock_object, cb); }
		if (result == WSLAY_ERR_INVALID_ARGUMENT) { croak("Wslay queue_fragmented - WSLAY_ERR_INVALID_ARGUMENT"); }
		if (result == WSLAY_ERR_NOMEM) { croak("Wslay queue_fragmented - WSLAY_ERR_NOMEM"); }
		wait_io_event_guarded(websock_object);
		RETVAL = result;
	OUTPUT:
		RETVAL

int queue_fragmented_ex (object, cb, opcode=2, rsv=-1)
	HV* object
	SV* cb
	int opcode
	int rsv
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		struct wslay_event_fragmented_msg msg;
		if (rsv < 0) { rsv = websock_object->default_rsv; }
		msg.opcode = opcode;
		msg.source.data = cb;
		msg.read_callback = fragmented_msg_callback;
		track_fragmented_source(websock_object, cb);
		int result = wslay_event_queue_fragmented_msg_ex(websock_object->ctx, &msg, (uint8_t) rsv);
		if (result) { release_fragmented_source(websock_object, cb); }
		if (result == WSLAY_ERR_INVALID_ARGUMENT) { croak("Wslay queue_fragmented_ex - WSLAY_ERR_INVALID_ARGUMENT"); }
		if (result == WSLAY_ERR_NOMEM) { croak("Wslay queue_fragmented_ex - WSLAY_ERR_NOMEM"); }
		wait_io_event_guarded(websock_object);
		RETVAL = result;
	OUTPUT:
		RETVAL

int close (object, status_code = 0, data = NULL)
	HV* object
	int status_code
	SV* data
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		STRLEN reason_length = 0;
		char *reason = NULL;
		if (data) { reason = SvPV(data, reason_length); }
		int result = wslay_event_queue_close(websock_object->ctx, status_code, (const uint8_t*) reason, reason_length);
		if (result == WSLAY_ERR_INVALID_ARGUMENT) {croak("Wslay close - WSLAY_ERR_INVALID_ARGUMENT"); }
		if (result == WSLAY_ERR_NOMEM) { croak("Wslay close - WSLAY_ERR_NOMEM"); }
		wslay_event_shutdown_read(websock_object->ctx);
		wait_io_event_guarded(websock_object);
		RETVAL = result;
	OUTPUT:
		RETVAL

UV queued_count (object)
	HV* object
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		RETVAL = wslay_event_get_queued_msg_count(websock_object->ctx);
	OUTPUT:
		RETVAL

void DESTROY (object)
	HV* object
	CODE:
		MAGIC* mg = get_wslay_magic(object);
		websocket_object* websock_object;
		size_t i;
		if (!mg || !mg->mg_ptr) { XSRETURN_EMPTY; } /* already destroyed */
		websock_object = (websocket_object*) mg->mg_ptr;
		/* detach first: an explicit DESTROY followed by GC must not free twice */
		mg->mg_ptr = NULL;
		if (websock_object->queue_wait_cb) { SvREFCNT_dec(websock_object->queue_wait_cb); }
		close_connection(websock_object);
		if (websock_object->loop && ev_is_active(&(websock_object->loop_cleanup))) {
			ev_cleanup_stop(websock_object->loop, &(websock_object->loop_cleanup));
		}
		/* still-queued messages never reached EOF, so nothing released these */
		for (i = 0; i < websock_object->frag_count; i++) { SvREFCNT_dec(websock_object->frag_sources[i]); }
		free(websock_object->frag_sources);
		if (websock_object->pending_error) {
			if (!PL_dirty) { warn("%s", SvPV_nolen(websock_object->pending_error)); }
			SvREFCNT_dec(websock_object->pending_error);
		}
		free(websock_object);
