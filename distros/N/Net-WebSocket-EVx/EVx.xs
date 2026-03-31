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
	#ifndef EWOULDBLOCK
		#define EWOULDBLOCK EAGAIN
	#endif
#endif

#define FRAGMENTED_EOF 0
#define FRAGMENTED_ERROR -1
#define FRAGMENTED_DATA 1

#define REQUIRE_CTX(ws) if (!(ws)->ctx) { croak("WebSocket connection already closed"); }

typedef struct {
	wslay_event_context_ptr ctx;
	HV* perl_callbacks;
	ev_io io;
	SV* queue_wait_cb;
	struct wslay_event_callbacks callbacks;
	char read_stopped;
	char write_stopped;
} websocket_object;

static void wait_io_event(websocket_object* websock_object);

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

static websocket_object* get_wslay_context (HV* hv) {
	MAGIC* mg;
	for (mg = SvMAGIC((SV*) hv); mg; mg = mg->mg_moremagic) {
		if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == NULL) {
			return (websocket_object*) mg->mg_ptr;
		}
	}
	croak("Can't get ptr from object hash!\n");
}

static int genmask_callback(wslay_event_context_ptr ctx, uint8_t* buf, size_t len, void* data) {
	websocket_object* websock_object = (websocket_object*) data;
	SV** cb;
	if ((cb = hv_fetch(websock_object->perl_callbacks , "genmask", 7, 0))) {
		int count;
		SV* sv_data;
		STRLEN source_len;
		char *source_buf;
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		XPUSHs(sv_2mortal(newSViv(len)));
		PUTBACK;
		count = call_sv(*cb, G_SCALAR);
		SPAGAIN;
		if (count != 1) { croak("Wslay - genmask callback returned bad value!\n"); }
		sv_data = POPs;
		source_buf = SvPV(sv_data, source_len);
		if (source_len) { memcpy(buf, source_buf, (source_len < len ? source_len : len)); }
		PUTBACK;
		FREETMPS;
		LEAVE;
		return 0;
	};
	{
		size_t i;
		for(i = 0; i < len; i++){ buf[i] = (char) rand(); }
	}
	return 0;
}

static void on_frame_recv_start_callback (wslay_event_context_ptr ctx, const struct wslay_event_on_frame_recv_start_arg* frame, void* data) {
	SV** cb;
	if (!(cb = hv_fetch(((websocket_object*) data)->perl_callbacks, "on_frame_recv_start", 19, 0)) ) {
		return;
	}
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
	call_sv(*cb, G_VOID);
	FREETMPS;
	LEAVE;
}

static void on_frame_recv_chunk_callback (wslay_event_context_ptr ctx, const struct wslay_event_on_frame_recv_chunk_arg* chunk, void* data) {
	SV** cb;
	if (!(cb = hv_fetch(((websocket_object*) data)->perl_callbacks, "on_frame_recv_chunk", 19, 0))) {
		return;
	}
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	EXTEND(SP, 1);
	PUSHs(sv_2mortal(newSVpvn(chunk->data, chunk->data_length)));
	PUTBACK;
	call_sv(*cb, G_VOID);
	FREETMPS;
	LEAVE;
}

static void on_frame_recv_end_callback(wslay_event_context_ptr ctx, void* data) {
	SV** cb;
	if (!(cb = hv_fetch(((websocket_object*) data)->perl_callbacks, "on_frame_recv_end", 17, 0))) {
		return;
	}
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	call_sv(*cb, G_DISCARD|G_NOARGS);
	FREETMPS;
	LEAVE;
}

static void on_msg_recv_callback(wslay_event_context_ptr ctx, const struct wslay_event_on_msg_recv_arg* msg, void* data) {
	SV** cb;
	SV* msg_data;
	if (msg->opcode == 0x08) { return; }
	if (!(cb = hv_fetch(((websocket_object*) data)->perl_callbacks, "on_msg_recv", 11, 0))) {
		return;
	}
	msg_data = newSVpvn(msg->msg, msg->msg_length);
	if (!(msg->rsv & WSLAY_RSV1_BIT) && msg->opcode == 1) { SvUTF8_on(msg_data); }
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
	call_sv(*cb, G_VOID);
	FREETMPS;
	LEAVE;
}

static ssize_t fragmented_msg_callback(wslay_event_context_ptr ctx, uint8_t* buf, size_t len, const union wslay_event_msg_source* source, int* eof, void* userdata) {
	websocket_object* websock_object = (websocket_object*) userdata;
	ssize_t bytes_written = 0;
	int count;
	SV* data;
	int status;
	STRLEN source_len;
	char* source_buf;
	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSViv(len)));
	PUTBACK;
	count = call_sv((SV*) source->data, G_ARRAY);
	SPAGAIN;
	if (count == 1) {
		status = FRAGMENTED_DATA;
		data = POPs;
	} else if (count == 2) {
		status = POPi;
		data = POPs;
	} else {
		croak("Wslay - fragmented msg cb MUST return one or two elements! \n");
	}
	source_buf = SvPV(data, source_len);
	if (source_len) {
		bytes_written = (source_len < len ? source_len : len );
		memcpy(buf, source_buf, bytes_written);
	}
	PUTBACK;
	FREETMPS;
	LEAVE;
	if (status == FRAGMENTED_EOF) {
		*eof = 1;
		SvREFCNT_dec((SV*) source->data);
	} else if (status == FRAGMENTED_ERROR) {
		bytes_written = -1;
		wslay_event_set_error(websock_object->ctx, WSLAY_ERR_CALLBACK_FAILURE);
		SvREFCNT_dec((SV*) source->data);
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
	ev_io_stop(EV_DEFAULT, &(websock_object->io));
	if (websock_object->io.fd >= 0) {
		close(websock_object->io.fd);
		websock_object->io.fd = -1;
	}
	if ((cb = hv_fetch(websock_object->perl_callbacks, "on_close", 8, 0))) {
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		EXTEND(SP, 1);
		PUSHs(sv_2mortal(newSViv(status)));
		PUTBACK;
		call_sv(*cb, G_VOID);
		FREETMPS;
		LEAVE;
	};
}

static void wslay_io_event (struct ev_loop* loop, struct ev_io* w, int revents) {
	websocket_object* websock_object = (websocket_object*) w->data;
	if (revents & EV_READ) {
		if (wslay_event_recv(websock_object->ctx)) {
			close_connection(websock_object);
			return;
		}
	}
	if (!websock_object->ctx) { return; }
	if (revents & EV_WRITE) {
		if (wslay_event_send(websock_object->ctx)) {
			close_connection(websock_object);
			return;
		}
	}
	wait_io_event(websock_object);
};

static void wait_io_event(websocket_object* websock_object) {
	int events = 0;
	char wanted_io = 0;
	ev_io_stop(EV_DEFAULT, &(websock_object->io));
	if (websock_object->read_stopped && websock_object->write_stopped) { return; }
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
		SvREFCNT_inc((SV*)websock_object->perl_callbacks);
		{
			dSP;
			ENTER;
			SAVETMPS;
			PUSHMARK(SP);
			call_sv(wait_cb, G_DISCARD|G_NOARGS);
			FREETMPS;
			LEAVE;
		}
		SvREFCNT_dec(wait_cb);
		/* recheck want write - safe because HV refcount prevents DESTROY */
		if (websock_object->ctx && wslay_event_want_write(websock_object->ctx)) {
			if (!websock_object->write_stopped) { events |= EV_WRITE; }
			wanted_io = 1;
		}
		{
			int ctx_alive = (websock_object->ctx != NULL);
			SvREFCNT_dec((SV*)websock_object->perl_callbacks);
			if (!ctx_alive) { return; }
		}
	}

	if (events) {
		ev_io_set(&(websock_object->io), websock_object->io.fd, events);
		ev_io_start(EV_DEFAULT, &(websock_object->io));
	} else if (!wanted_io && websock_object->ctx) {
		close_connection(websock_object);
	}

};


MODULE = Net::WebSocket::EVx	PACKAGE = Net::WebSocket::EVx


BOOT:
{
	I_EV_API("Net::WebSocket::EVx");
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
		websocket_object* websock_object = calloc(1, sizeof(websocket_object));
		ev_io_init(&(websock_object->io), wslay_io_event, sock, EV_READ);
		websock_object->io.data = (SV*) websock_object;
		websock_object->perl_callbacks = object;
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
			free(websock_object);
			croak("Can't initialize! WSLAY_ERR_NOMEM \n");
		}
		sv_magicext((SV*) object, 0, PERL_MAGIC_ext, NULL, (const char *) websock_object, 0);
		wslay_event_config_set_allowed_rsv_bits(websock_object->ctx, WSLAY_RSV1_BIT);
		wait_io_event(websock_object);

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
		wait_io_event(websock_object);

void stop_read(object)
	HV* object
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		websock_object->read_stopped = 1;
		wait_io_event(websock_object);

void stop_write(object)
	HV* object
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		websock_object->write_stopped = 1;
		wait_io_event(websock_object);

void start(object)
	HV* object
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		websock_object->read_stopped = 0;
		websock_object->write_stopped = 0;
		wait_io_event(websock_object);

void start_read(object)
	HV* object
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		websock_object->read_stopped = 0;
		wait_io_event(websock_object);

void start_write(object)
	HV* object
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		websock_object->write_stopped = 0;
		wait_io_event(websock_object);

void _set_waiter(object, waiter)
	HV* object
	SV* waiter
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		if (websock_object->queue_wait_cb) { SvREFCNT_dec(websock_object->queue_wait_cb); }
		websock_object->queue_wait_cb = waiter;
		SvREFCNT_inc(waiter);
		wait_io_event(websock_object);

int queue_msg (object, data, opcode=1)
	HV* object
	SV* data
	int opcode
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		STRLEN len;
		struct wslay_event_msg msg;
		msg.msg = SvPV(data, len);
		msg.msg_length = len;
		msg.opcode = opcode;
		int result = wslay_event_queue_msg(websock_object->ctx, &msg);
		if (result == WSLAY_ERR_INVALID_ARGUMENT) { croak("Wslay queue_msg - WSLAY_ERR_INVALID_ARGUMENT"); }
		if (result == WSLAY_ERR_NOMEM) { croak("Wslay queue_msg - WSLAY_ERR_NOMEM"); }
		wait_io_event(websock_object);
		RETVAL = result;
	OUTPUT:
		RETVAL

int queue_msg_ex (object, data, opcode=1, rsv=WSLAY_RSV1_BIT)
	HV* object
	SV* data
	int opcode
	int rsv
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		STRLEN len;
		struct wslay_event_msg msg;
		msg.msg = SvPV(data, len);
		msg.msg_length = len;
		msg.opcode = opcode;
		int result = wslay_event_queue_msg_ex(websock_object->ctx, &msg, rsv);
		if (result == WSLAY_ERR_INVALID_ARGUMENT) { croak("Wslay queue_msg_ex - WSLAY_ERR_INVALID_ARGUMENT"); }
		if (result == WSLAY_ERR_NOMEM) { croak("Wslay queue_msg_ex - WSLAY_ERR_NOMEM"); }
		wait_io_event(websock_object);
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
		msg.source.data = SvREFCNT_inc(cb);
		msg.read_callback = fragmented_msg_callback;
		int result = wslay_event_queue_fragmented_msg(websock_object->ctx, &msg);
		if (result == WSLAY_ERR_INVALID_ARGUMENT) { SvREFCNT_dec(cb); croak("Wslay queue_fragmented - WSLAY_ERR_INVALID_ARGUMENT"); }
		if (result == WSLAY_ERR_NOMEM) { SvREFCNT_dec(cb); croak("Wslay queue_fragmented - WSLAY_ERR_NOMEM"); }
		if (result) { SvREFCNT_dec(cb); }
		wait_io_event(websock_object);
		RETVAL = result;
	OUTPUT:
		RETVAL

int queue_fragmented_ex (object, cb, opcode=2, rsv=WSLAY_RSV1_BIT)
	HV* object
	SV* cb
	int opcode
	int rsv
	CODE:
		websocket_object* websock_object = get_wslay_context(object);
		REQUIRE_CTX(websock_object);
		struct wslay_event_fragmented_msg msg;
		msg.opcode = opcode;
		msg.source.data = SvREFCNT_inc(cb);
		msg.read_callback = fragmented_msg_callback;
		int result = wslay_event_queue_fragmented_msg_ex(websock_object->ctx, &msg, rsv);
		if (result == WSLAY_ERR_INVALID_ARGUMENT) { SvREFCNT_dec(cb); croak("Wslay queue_fragmented_ex - WSLAY_ERR_INVALID_ARGUMENT"); }
		if (result == WSLAY_ERR_NOMEM) { SvREFCNT_dec(cb); croak("Wslay queue_fragmented_ex - WSLAY_ERR_NOMEM"); }
		if (result) { SvREFCNT_dec(cb); }
		wait_io_event(websock_object);
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
		int result = wslay_event_queue_close(websock_object->ctx, status_code, reason, reason_length);
		if (result == WSLAY_ERR_INVALID_ARGUMENT) {croak("Wslay close - WSLAY_ERR_INVALID_ARGUMENT"); }
		if (result == WSLAY_ERR_NOMEM) { croak("Wslay close - WSLAY_ERR_NOMEM"); }
		wslay_event_shutdown_read(websock_object->ctx);
		wait_io_event(websock_object);
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
		websocket_object* websock_object = get_wslay_context(object);
		if (websock_object->queue_wait_cb) { SvREFCNT_dec(websock_object->queue_wait_cb); }
		if (websock_object->ctx) { close_connection(websock_object); }
		free(websock_object);
