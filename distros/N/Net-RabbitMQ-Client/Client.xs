//
//
//  Created by Alexander Borisov on 30.07.15.
//  Copyright (c) 2015 Alexander Borisov. All rights reserved.
//

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <amqp_tcp_socket.h>
#include <amqp.h>
#include <amqp_framing.h>
#include <amqp_ssl_socket.h>

typedef struct
{
	int version;
}
xs_rabbitmq_t;

typedef int xs_status;
typedef xs_rabbitmq_t * Net__RabbitMQ__Client;

MODULE = Net::RabbitMQ::Client  PACKAGE = Net::RabbitMQ::Client

PROTOTYPES: DISABLE

#***********************************************************************************
#*
#* SSL =sort 1
#*
#***********************************************************************************
#=sort 1

amqp_socket_t*
ssl_socket_new(rmq, conn)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	
	CODE:
		RETVAL = amqp_ssl_socket_new(conn);
	OUTPUT:
		RETVAL

xs_status
ssl_socket_set_cacert(rmq, socket, cacert)
	Net::RabbitMQ::Client rmq;
	amqp_socket_t *socket;
	const char *cacert;
	
	CODE:
		RETVAL = amqp_ssl_socket_set_cacert(socket, cacert);
	OUTPUT:
		RETVAL

xs_status
ssl_socket_set_key(rmq, socket, cert, key)
	Net::RabbitMQ::Client rmq;
	amqp_socket_t *socket;
	const char *cert;
	const char *key;
	
	CODE:
		RETVAL = amqp_ssl_socket_set_key(socket, cert, key);
	OUTPUT:
		RETVAL

xs_status
ssl_socket_set_key_buffer(rmq, socket, cert, key, n)
	Net::RabbitMQ::Client rmq;
	amqp_socket_t *socket;
	const char *cert;
	const char *key;
	size_t n;
	
	CODE:
		RETVAL = amqp_ssl_socket_set_key_buffer(socket, cert, key, n);
	OUTPUT:
		RETVAL

void
ssl_socket_set_verify(rmq, socket, verify)
	Net::RabbitMQ::Client rmq;
	amqp_socket_t *socket;
	amqp_boolean_t verify;
	
	CODE:
		amqp_ssl_socket_set_verify(socket, verify);

void
set_initialize_ssl_library(rmq, do_initialize)
	Net::RabbitMQ::Client rmq;
	amqp_boolean_t do_initialize;
	
	CODE:
		amqp_set_initialize_ssl_library(do_initialize);

#***********************************************************************************
#*
#* Connection and Authorization =sort 0
#*
#***********************************************************************************
#=sort 1

Net::RabbitMQ::Client
create(class_name = 0)
	char *class_name;
	
	CODE:
		xs_rabbitmq_t *rmq = malloc(sizeof(xs_rabbitmq_t));
		
		rmq->version = 0;
		
		RETVAL = rmq;
	OUTPUT:
		RETVAL

#=sort 2

amqp_connection_state_t
new_connection(rmq)
	Net::RabbitMQ::Client rmq;
	
	CODE:
		RETVAL = amqp_new_connection();
	OUTPUT:
		RETVAL

#=sort 3

amqp_socket_t*
tcp_socket_new(rmq, conn)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	
	CODE:
		RETVAL = amqp_tcp_socket_new(conn);
	OUTPUT:
		RETVAL

#=sort 4

xs_status
socket_open(rmq, socket, host, port)
	Net::RabbitMQ::Client rmq;
	amqp_socket_t * socket;
	const char *host;
	int port;
	
	CODE:
		RETVAL = amqp_socket_open(socket, host, port);
	OUTPUT:
		RETVAL

#=sort 5

xs_status
socket_open_noblock(rmq, socket, host, port, struct_timeout)
	Net::RabbitMQ::Client rmq;
	amqp_socket_t * socket;
	const char *host;
	int port;
	SV *struct_timeout;
	
	CODE:
		struct timeval *t_timeout = NULL;
		
		if(SvOK(struct_timeout))
		{
			t_timeout = INT2PTR(struct timeval *, SvIV(struct_timeout));
		}
		
		RETVAL = amqp_socket_open_noblock(socket, host, port, t_timeout);
	OUTPUT:
		RETVAL

#=sort 6

xs_status
login(rmq, conn, vhost, channel_max, frame_max, heartbeat, sasl_method, ...)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	const char *vhost;
	int channel_max;
	int frame_max;
	int heartbeat;
	amqp_sasl_method_enum sasl_method;
	
	CODE:
		if(sasl_method == AMQP_SASL_METHOD_PLAIN)
		{
			const char *login = SvPV_nolen( ST(7) );
			const char *pass  = SvPV_nolen( ST(8) );
			
			amqp_rpc_reply_t rt = amqp_login(conn, vhost, channel_max, frame_max, heartbeat, sasl_method, login, pass);
			
			RETVAL = rt.reply_type;
		}
		else {
			RETVAL = -1;
		}
		
	OUTPUT:
		RETVAL

#=sort 7

xs_status
channel_open(rmq, conn, channel)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	amqp_channel_t channel;
	
	CODE:
		amqp_channel_open(conn, channel);
		
		amqp_rpc_reply_t rt = amqp_get_rpc_reply(conn);
		RETVAL = rt.reply_type;
		
	OUTPUT:
		RETVAL

#=sort 8

SV*
socket_get_sockfd(rmq, socket)
	Net::RabbitMQ::Client rmq;
	amqp_socket_t * socket;
	
	CODE:
		RETVAL = newSViv(amqp_socket_get_sockfd(socket));
	OUTPUT:
		RETVAL

#=sort 9

amqp_socket_t *
get_socket(rmq, conn)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	
	CODE:
		RETVAL = amqp_get_socket(conn);
	OUTPUT:
		RETVAL

#=sort 10

xs_status
channel_close(rmq, conn, channel, code)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	amqp_channel_t channel;
	int code;
	
	CODE:
		amqp_rpc_reply_t rt = amqp_channel_close(conn, channel, code);
		RETVAL = rt.reply_type;
		
	OUTPUT:
		RETVAL

#=sort 11

xs_status
connection_close(rmq, conn, code)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	int code;
	
	CODE:
		amqp_rpc_reply_t rt = amqp_connection_close(conn, code);
		RETVAL = rt.reply_type;
		
	OUTPUT:
		RETVAL

#=sort 12

xs_status
destroy_connection(rmq, conn)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	
	CODE:
		RETVAL = amqp_destroy_connection(conn);
		
	OUTPUT:
		RETVAL

#***********************************************************************************
#*
#* Consume =sort 3
#*
#***********************************************************************************
#=sort 1

xs_status
consume_message(rmq, conn, envelope, struct_timeout, flags)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	amqp_envelope_t *envelope;
	SV *struct_timeout;
	int flags;
	
	CODE:
		struct timeval *t_timeout = NULL;
		
		if(SvOK(struct_timeout))
		{
			t_timeout = INT2PTR(struct timeval *, SvIV(struct_timeout));
		}
		
		amqp_rpc_reply_t rt = amqp_consume_message(conn, envelope, t_timeout, flags);
		RETVAL = rt.reply_type;
		
	OUTPUT:
		RETVAL


#***********************************************************************************
#*
#* Other =sort 9
#*
#***********************************************************************************

SV*
error_string(rmq, error)
	Net::RabbitMQ::Client rmq;
	int error;
	
	CODE:
		RETVAL = newSVpv(amqp_error_string2(error), 0);
	OUTPUT:
		RETVAL

amqp_boolean_t
data_in_buffer(rmq, conn)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	
	CODE:
		RETVAL = amqp_data_in_buffer(conn);
	OUTPUT:
		RETVAL

void
maybe_release_buffers(rmq, conn)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	
	CODE:
		amqp_maybe_release_buffers(conn);


#***********************************************************************************
#*
#* Envelope =sort 6
#*
#***********************************************************************************

SV*
envelope_get_message_body(rmq, envelope)
	Net::RabbitMQ::Client rmq;
	amqp_envelope_t *envelope;
	
	CODE:
		if(envelope->message.body.len) {
			RETVAL = newSVpv((char *)envelope->message.body.bytes, envelope->message.body.len);
		}
		else {
			RETVAL = &PL_sv_undef;
		}
		
	OUTPUT:
		RETVAL

SV*
envelope_get_delivery_tag(rmq, envelope)
	Net::RabbitMQ::Client rmq;
	amqp_envelope_t *envelope;
	
	CODE:
		RETVAL = newSViv(envelope->delivery_tag);
		
	OUTPUT:
		RETVAL

SV*
envelope_get_consumer_tag(rmq, envelope)
	Net::RabbitMQ::Client rmq;
	amqp_envelope_t *envelope;
	
	CODE:
		if(envelope->consumer_tag.len) {
			RETVAL = newSVpv((char *)envelope->consumer_tag.bytes, envelope->consumer_tag.len);
		}
		else {
			RETVAL = &PL_sv_undef;
		}
		
	OUTPUT:
		RETVAL

SV*
envelope_get_routing_key(rmq, envelope)
	Net::RabbitMQ::Client rmq;
	amqp_envelope_t *envelope;
	
	CODE:
		if(envelope->routing_key.len) {
			RETVAL = newSVpv((char *)envelope->routing_key.bytes, envelope->routing_key.len);
		}
		else {
			RETVAL = &PL_sv_undef;
		}
		
	OUTPUT:
		RETVAL

SV*
envelope_get_exchange(rmq, envelope)
	Net::RabbitMQ::Client rmq;
	amqp_envelope_t *envelope;
	
	CODE:
		if(envelope->exchange.len) {
			RETVAL = newSVpv((char *)envelope->exchange.bytes, envelope->exchange.len);
		}
		else {
			RETVAL = &PL_sv_undef;
		}
		
	OUTPUT:
		RETVAL

SV*
envelope_get_redelivered(rmq, envelope)
	Net::RabbitMQ::Client rmq;
	amqp_envelope_t *envelope;
	
	CODE:
		RETVAL = newSViv(envelope->redelivered);
		
	OUTPUT:
		RETVAL

SV*
envelope_get_channel(rmq, envelope)
	Net::RabbitMQ::Client rmq;
	amqp_envelope_t *envelope;
	
	CODE:
		RETVAL = newSViv(envelope->channel);
		
	OUTPUT:
		RETVAL

void
destroy_envelope(rmq, envelope)
	Net::RabbitMQ::Client rmq;
	amqp_envelope_t *envelope;
	
	CODE:
		amqp_destroy_envelope(envelope);

#***********************************************************************************
#*
#* Basic Publish/Consume =sort 2
#*
#***********************************************************************************
#=sort 1

xs_status
basic_publish(rmq, conn, channel, exchange, routing_key, mandatory, immediate, properties, body)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	amqp_channel_t channel;
	SV *exchange;
	const char *routing_key;
	int mandatory;
	int immediate;
	amqp_basic_properties_t *properties;
	const char *body;
	
	CODE:
		amqp_bytes_t c_exchange;
		
		if(SvOK(exchange))
		{
			c_exchange = amqp_cstring_bytes(SvPV_nolen(exchange));
		}
		else {
			c_exchange = amqp_empty_bytes;
		}
		
		RETVAL = amqp_basic_publish(conn, channel, c_exchange,
			amqp_cstring_bytes(routing_key), mandatory, immediate, properties,
			amqp_cstring_bytes(body)
		);
		
	OUTPUT:
		RETVAL

#=sort 2

xs_status
basic_consume(rmq, conn, channel, queue, consumer_tag, no_local, no_ack, exclusive, ...)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	amqp_channel_t channel;
	const char *queue;
	SV *consumer_tag;
	int no_local;
	int no_ack;
	int exclusive;
	
	CODE:
		const char *c_consumer_tag = NULL;
		if(SvOK(consumer_tag))
		{
			c_consumer_tag = (const char *)SvPV_nolen(consumer_tag);
		}
		
		amqp_basic_consume(conn, channel, amqp_cstring_bytes(queue),
			(c_consumer_tag ? amqp_cstring_bytes(c_consumer_tag) : amqp_empty_bytes),
			no_local, no_ack, exclusive, amqp_empty_table
		);
		
		amqp_rpc_reply_t rt = amqp_get_rpc_reply(conn);
		RETVAL = rt.reply_type;
		
	OUTPUT:
		RETVAL

#=sort 3

xs_status
basic_get(rmq, conn, channel, queue, no_ack)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	amqp_channel_t channel;
	const char *queue;
	amqp_boolean_t no_ack;
	
	CODE:
		amqp_rpc_reply_t rt = amqp_basic_get(conn, channel, amqp_cstring_bytes(queue), no_ack);
		RETVAL = rt.reply_type;
		
	OUTPUT:
		RETVAL

#=sort 4

xs_status
basic_ack(rmq, conn, channel, delivery_tag, multiple)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	amqp_channel_t channel;
	SV *delivery_tag;
	amqp_boolean_t multiple;
	
	CODE:
		RETVAL = amqp_basic_ack(conn, channel, SvIV(delivery_tag), multiple);
		
	OUTPUT:
		RETVAL

#=sort 5

xs_status
basic_nack(rmq, conn, channel, delivery_tag, multiple, requeue)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	amqp_channel_t channel;
	SV *delivery_tag;
	amqp_boolean_t multiple;
	amqp_boolean_t requeue;
	
	CODE:
		RETVAL = amqp_basic_nack(conn, channel, SvIV(delivery_tag), multiple, requeue);
		
	OUTPUT:
		RETVAL

#=sort 6

xs_status
basic_reject(rmq, conn, channel, delivery_tag, requeue)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	amqp_channel_t channel;
	SV *delivery_tag;
	amqp_boolean_t requeue;
	
	CODE:
		RETVAL = amqp_basic_reject(conn, channel, SvIV(delivery_tag), requeue);
		
	OUTPUT:
		RETVAL


#***********************************************************************************
#*
#* Queue =sort 4
#*
#***********************************************************************************
#=sort 1

xs_status
queue_declare(rmq, conn, channel, queue, passive, durable, exclusive, auto_delete, ...)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	amqp_channel_t channel;
	const char *queue;
	int passive;
	int durable;
	int exclusive;
	int auto_delete;
	
	CODE:
		amqp_queue_declare(conn, channel, amqp_cstring_bytes(queue),
			passive, durable, exclusive, auto_delete, amqp_empty_table
		);
		
		amqp_rpc_reply_t rt = amqp_get_rpc_reply(conn);
		RETVAL = rt.reply_type;
		
	OUTPUT:
		RETVAL

#=sort 2

xs_status
queue_bind(rmq, conn, channel, queue, exchange, routing_key, ...)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	amqp_channel_t channel;
	const char *queue;
	SV *exchange;
	const char *routing_key;
	
	CODE:
		amqp_bytes_t c_exchange;
		
		if(SvOK(exchange))
		{
			c_exchange = amqp_cstring_bytes(SvPV_nolen(exchange));
		}
		else {
			c_exchange = amqp_empty_bytes;
		}
		
		amqp_queue_bind(conn, channel, amqp_cstring_bytes(queue),
			c_exchange, amqp_cstring_bytes(routing_key), amqp_empty_table
		);
		
		amqp_rpc_reply_t rt = amqp_get_rpc_reply(conn);
		RETVAL = rt.reply_type;
		
	OUTPUT:
		RETVAL

#=sort 3

xs_status
queue_unbind(rmq, conn, channel, queue, exchange, routing_key, ...)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	amqp_channel_t channel;
	const char *queue;
	const char *exchange;
	const char *routing_key;
	
	CODE:
		amqp_queue_unbind(conn, channel, amqp_cstring_bytes(queue),
			amqp_cstring_bytes(exchange), amqp_cstring_bytes(routing_key), amqp_empty_table
		);
		
		amqp_rpc_reply_t rt = amqp_get_rpc_reply(conn);
		RETVAL = rt.reply_type;
		
	OUTPUT:
		RETVAL


#***********************************************************************************
#*
#* Types =sort 7
#*
#***********************************************************************************
#=sort 1

amqp_envelope_t*
type_create_envelope(rmq)
	Net::RabbitMQ::Client rmq;
	
	CODE:
		RETVAL = (amqp_envelope_t *)malloc(sizeof(amqp_envelope_t));
		
	OUTPUT:
		RETVAL

#=sort 2

void
type_destroy_envelope(rmq, envelope)
	Net::RabbitMQ::Client rmq;
	amqp_envelope_t *envelope;
	
	CODE:
		if(envelope)
			free(envelope);

#=sort 3

struct timeval*
type_create_timeout(rmq, timeout_sec)
	Net::RabbitMQ::Client rmq;
	long timeout_sec;
	
	CODE:
		struct timeval *timeout = (struct timeval *)malloc(sizeof(struct timeval));
		
		timeout->tv_sec = timeout_sec;
		
		RETVAL = timeout;
		
	OUTPUT:
		RETVAL

#=sort 4

void
type_destroy_timeout(rmq, struct_timeout)
	Net::RabbitMQ::Client rmq;
	struct timeval *struct_timeout;
	
	CODE:
		if(struct_timeout)
			free(struct_timeout);

#=sort 5

amqp_basic_properties_t*
type_create_basic_properties(rmq)
	Net::RabbitMQ::Client rmq;
	
	CODE:
		RETVAL = (amqp_basic_properties_t *)malloc(sizeof(amqp_basic_properties_t));
		
	OUTPUT:
		RETVAL

#=sort 6

xs_status
type_destroy_basic_properties(rmq, props)
	Net::RabbitMQ::Client rmq;
	amqp_basic_properties_t *props;
	
	CODE:
		if(props)
			free(props);
		
	OUTPUT:
		RETVAL

#***********************************************************************************
#*
#* For a Basic Properties =sort 8
#*
#***********************************************************************************

void
set_prop__flags(rmq, props, flags)
	Net::RabbitMQ::Client rmq;
	amqp_basic_properties_t *props;
	SV* flags;
	
	CODE:
		props->_flags = SvIV(flags);

void
set_prop_delivery_mode(rmq, props, delivery_mode)
	Net::RabbitMQ::Client rmq;
	amqp_basic_properties_t *props;
	SV* delivery_mode;
	
	CODE:
		props->delivery_mode = SvIV(delivery_mode);

void
set_prop_timestamp(rmq, props, timestamp)
	Net::RabbitMQ::Client rmq;
	amqp_basic_properties_t *props;
	SV* timestamp;
	
	CODE:
		props->timestamp = SvIV(timestamp);


void
set_prop_priority(rmq, props, priority)
	Net::RabbitMQ::Client rmq;
	amqp_basic_properties_t *props;
	SV* priority;
	
	CODE:
		props->priority = SvIV(priority);

void
set_prop_content_type(rmq, props, value)
	Net::RabbitMQ::Client rmq;
	amqp_basic_properties_t *props;
	const char *value;
	
	CODE:
		props->content_type = amqp_cstring_bytes(value);

void
set_prop_content_encoding(rmq, props, value)
	Net::RabbitMQ::Client rmq;
	amqp_basic_properties_t *props;
	const char *value;
	
	CODE:
		props->content_encoding = amqp_cstring_bytes(value);

void
set_prop_correlation_id(rmq, props, value)
	Net::RabbitMQ::Client rmq;
	amqp_basic_properties_t *props;
	const char *value;
	
	CODE:
		props->correlation_id = amqp_cstring_bytes(value);

void
set_prop_reply_to(rmq, props, value)
	Net::RabbitMQ::Client rmq;
	amqp_basic_properties_t *props;
	const char *value;
	
	CODE:
		props->reply_to = amqp_cstring_bytes(value);

void
set_prop_expiration(rmq, props, value)
	Net::RabbitMQ::Client rmq;
	amqp_basic_properties_t *props;
	const char *value;
	
	CODE:
		props->expiration = amqp_cstring_bytes(value);

void
set_prop_message_id(rmq, props, value)
	Net::RabbitMQ::Client rmq;
	amqp_basic_properties_t *props;
	const char *value;
	
	CODE:
		props->message_id = amqp_cstring_bytes(value);

void
set_prop_type(rmq, props, value)
	Net::RabbitMQ::Client rmq;
	amqp_basic_properties_t *props;
	const char *value;
	
	CODE:
		props->type = amqp_cstring_bytes(value);

void
set_prop_user_id(rmq, props, value)
	Net::RabbitMQ::Client rmq;
	amqp_basic_properties_t *props;
	const char *value;
	
	CODE:
		props->user_id = amqp_cstring_bytes(value);

void
set_prop_app_id(rmq, props, value)
	Net::RabbitMQ::Client rmq;
	amqp_basic_properties_t *props;
	const char *value;
	
	CODE:
		props->app_id = amqp_cstring_bytes(value);

void
set_prop_cluster_id(rmq, props, value)
	Net::RabbitMQ::Client rmq;
	amqp_basic_properties_t *props;
	const char *value;
	
	CODE:
		props->cluster_id = amqp_cstring_bytes(value);


#***********************************************************************************
#*
#* Exchange =sort 5
#*
#***********************************************************************************
#=sort 1

xs_status
exchange_declare(rmq, conn, channel, exchange, type, passive, durable, auto_delete, internal, ...)
	Net::RabbitMQ::Client rmq;
	amqp_connection_state_t conn;
	amqp_channel_t channel;
	const char *exchange;
	const char *type;
	int passive;
	int durable;
	int auto_delete;
	int internal;
	
	CODE:
		amqp_exchange_declare(conn, channel, amqp_cstring_bytes(exchange), amqp_cstring_bytes(type),
			passive, durable, auto_delete, internal, amqp_empty_table
		);
		
		amqp_rpc_reply_t rt = amqp_get_rpc_reply(conn);
		RETVAL = rt.reply_type;
		
	OUTPUT:
		RETVAL

#***********************************************************************************
#*
#* 
#*
#***********************************************************************************

void
DESTROY(rmq)
	Net::RabbitMQ::Client rmq;
	
	CODE:
		if(rmq)
			free(rmq);

SV*
AMQP_STATUS_OK()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_OK );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_NO_MEMORY()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_NO_MEMORY );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_BAD_AMQP_DATA()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_BAD_AMQP_DATA );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_UNKNOWN_CLASS()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_UNKNOWN_CLASS );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_UNKNOWN_METHOD()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_UNKNOWN_METHOD );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_HOSTNAME_RESOLUTION_FAILED()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_HOSTNAME_RESOLUTION_FAILED );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_INCOMPATIBLE_AMQP_VERSION()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_INCOMPATIBLE_AMQP_VERSION );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_CONNECTION_CLOSED()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_CONNECTION_CLOSED );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_BAD_URL()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_BAD_URL );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_SOCKET_ERROR()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_SOCKET_ERROR );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_INVALID_PARAMETER()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_INVALID_PARAMETER );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_TABLE_TOO_BIG()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_TABLE_TOO_BIG );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_WRONG_METHOD()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_WRONG_METHOD );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_TIMEOUT()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_TIMEOUT );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_TIMER_FAILURE()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_TIMER_FAILURE );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_HEARTBEAT_TIMEOUT()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_HEARTBEAT_TIMEOUT );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_UNEXPECTED_STATE()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_UNEXPECTED_STATE );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_SOCKET_CLOSED()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_SOCKET_CLOSED );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_SOCKET_INUSE()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_SOCKET_INUSE );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_BROKER_UNSUPPORTED_SASL_METHOD()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_BROKER_UNSUPPORTED_SASL_METHOD );
	OUTPUT:
		RETVAL

SV*
_AMQP_STATUS_NEXT_VALUE()
	CODE:
		RETVAL = newSViv( _AMQP_STATUS_NEXT_VALUE );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_TCP_ERROR()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_TCP_ERROR );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_TCP_SOCKETLIB_INIT_ERROR()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_TCP_SOCKETLIB_INIT_ERROR );
	OUTPUT:
		RETVAL

SV*
_AMQP_STATUS_TCP_NEXT_VALUE()
	CODE:
		RETVAL = newSViv( _AMQP_STATUS_TCP_NEXT_VALUE );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_SSL_ERROR()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_SSL_ERROR );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_SSL_HOSTNAME_VERIFY_FAILED()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_SSL_HOSTNAME_VERIFY_FAILED );
	OUTPUT:
		RETVAL

SV*
AMQP_STATUS_SSL_PEER_VERIFY_FAILED()
	CODE:
		RETVAL = newSViv( AMQP_STATUS_SSL_PEER_VERIFY_FAILED );
	OUTPUT:
		RETVAL

SV*
AMQP_DELIVERY_NONPERSISTENT()
	CODE:
		RETVAL = newSViv( AMQP_DELIVERY_NONPERSISTENT );
	OUTPUT:
		RETVAL

SV*
AMQP_DELIVERY_PERSISTENT()
	CODE:
		RETVAL = newSViv( AMQP_DELIVERY_PERSISTENT );
	OUTPUT:
		RETVAL

SV*
AMQP_SASL_METHOD_UNDEFINED()
	CODE:
		RETVAL = newSViv( AMQP_SASL_METHOD_UNDEFINED );
	OUTPUT:
		RETVAL

SV*
AMQP_SASL_METHOD_PLAIN()
	CODE:
		RETVAL = newSViv( AMQP_SASL_METHOD_PLAIN );
	OUTPUT:
		RETVAL

SV*
AMQP_SASL_METHOD_EXTERNAL()
	CODE:
		RETVAL = newSViv( AMQP_SASL_METHOD_EXTERNAL );
	OUTPUT:
		RETVAL

SV*
AMQP_RESPONSE_NONE()
	CODE:
		RETVAL = newSViv( AMQP_RESPONSE_NONE );
	OUTPUT:
		RETVAL

SV*
AMQP_RESPONSE_NORMAL()
	CODE:
		RETVAL = newSViv( AMQP_RESPONSE_NORMAL );
	OUTPUT:
		RETVAL

SV*
AMQP_RESPONSE_LIBRARY_EXCEPTION()
	CODE:
		RETVAL = newSViv( AMQP_RESPONSE_LIBRARY_EXCEPTION );
	OUTPUT:
		RETVAL

SV*
AMQP_RESPONSE_SERVER_EXCEPTION()
	CODE:
		RETVAL = newSViv( AMQP_RESPONSE_SERVER_EXCEPTION );
	OUTPUT:
		RETVAL

SV*
AMQP_FIELD_KIND_BOOLEAN()
	CODE:
		RETVAL = newSViv( AMQP_FIELD_KIND_BOOLEAN );
	OUTPUT:
		RETVAL

SV*
AMQP_FIELD_KIND_I8()
	CODE:
		RETVAL = newSViv( AMQP_FIELD_KIND_I8 );
	OUTPUT:
		RETVAL

SV*
AMQP_FIELD_KIND_U8()
	CODE:
		RETVAL = newSViv( AMQP_FIELD_KIND_U8 );
	OUTPUT:
		RETVAL

SV*
AMQP_FIELD_KIND_I16()
	CODE:
		RETVAL = newSViv( AMQP_FIELD_KIND_I16 );
	OUTPUT:
		RETVAL

SV*
AMQP_FIELD_KIND_U16()
	CODE:
		RETVAL = newSViv( AMQP_FIELD_KIND_U16 );
	OUTPUT:
		RETVAL

SV*
AMQP_FIELD_KIND_I32()
	CODE:
		RETVAL = newSViv( AMQP_FIELD_KIND_I32 );
	OUTPUT:
		RETVAL

SV*
AMQP_FIELD_KIND_U32()
	CODE:
		RETVAL = newSViv( AMQP_FIELD_KIND_U32 );
	OUTPUT:
		RETVAL

SV*
AMQP_FIELD_KIND_I64()
	CODE:
		RETVAL = newSViv( AMQP_FIELD_KIND_I64 );
	OUTPUT:
		RETVAL

SV*
AMQP_FIELD_KIND_U64()
	CODE:
		RETVAL = newSViv( AMQP_FIELD_KIND_U64 );
	OUTPUT:
		RETVAL

SV*
AMQP_FIELD_KIND_F32()
	CODE:
		RETVAL = newSViv( AMQP_FIELD_KIND_F32 );
	OUTPUT:
		RETVAL

SV*
AMQP_FIELD_KIND_F64()
	CODE:
		RETVAL = newSViv( AMQP_FIELD_KIND_F64 );
	OUTPUT:
		RETVAL

SV*
AMQP_FIELD_KIND_DECIMAL()
	CODE:
		RETVAL = newSViv( AMQP_FIELD_KIND_DECIMAL );
	OUTPUT:
		RETVAL

SV*
AMQP_FIELD_KIND_UTF8()
	CODE:
		RETVAL = newSViv( AMQP_FIELD_KIND_UTF8 );
	OUTPUT:
		RETVAL

SV*
AMQP_FIELD_KIND_ARRAY()
	CODE:
		RETVAL = newSViv( AMQP_FIELD_KIND_ARRAY );
	OUTPUT:
		RETVAL

SV*
AMQP_FIELD_KIND_TIMESTAMP()
	CODE:
		RETVAL = newSViv( AMQP_FIELD_KIND_TIMESTAMP );
	OUTPUT:
		RETVAL

SV*
AMQP_FIELD_KIND_TABLE()
	CODE:
		RETVAL = newSViv( AMQP_FIELD_KIND_TABLE );
	OUTPUT:
		RETVAL

SV*
AMQP_FIELD_KIND_VOID()
	CODE:
		RETVAL = newSViv( AMQP_FIELD_KIND_VOID );
	OUTPUT:
		RETVAL

SV*
AMQP_FIELD_KIND_BYTES()
	CODE:
		RETVAL = newSViv( AMQP_FIELD_KIND_BYTES );
	OUTPUT:
		RETVAL

SV*
AMQP_PROTOCOL_VERSION_MAJOR()
	CODE:
		RETVAL = newSViv( AMQP_PROTOCOL_VERSION_MAJOR );
	OUTPUT:
		RETVAL

SV*
AMQP_PROTOCOL_VERSION_MINOR()
	CODE:
		RETVAL = newSViv( AMQP_PROTOCOL_VERSION_MINOR );
	OUTPUT:
		RETVAL

SV*
AMQP_PROTOCOL_VERSION_REVISION()
	CODE:
		RETVAL = newSViv( AMQP_PROTOCOL_VERSION_REVISION );
	OUTPUT:
		RETVAL

SV*
AMQP_PROTOCOL_PORT()
	CODE:
		RETVAL = newSViv( AMQP_PROTOCOL_PORT );
	OUTPUT:
		RETVAL

SV*
AMQP_FRAME_METHOD()
	CODE:
		RETVAL = newSViv( AMQP_FRAME_METHOD );
	OUTPUT:
		RETVAL

SV*
AMQP_FRAME_HEADER()
	CODE:
		RETVAL = newSViv( AMQP_FRAME_HEADER );
	OUTPUT:
		RETVAL

SV*
AMQP_FRAME_BODY()
	CODE:
		RETVAL = newSViv( AMQP_FRAME_BODY );
	OUTPUT:
		RETVAL

SV*
AMQP_FRAME_HEARTBEAT()
	CODE:
		RETVAL = newSViv( AMQP_FRAME_HEARTBEAT );
	OUTPUT:
		RETVAL

SV*
AMQP_FRAME_MIN_SIZE()
	CODE:
		RETVAL = newSViv( AMQP_FRAME_MIN_SIZE );
	OUTPUT:
		RETVAL

SV*
AMQP_FRAME_END()
	CODE:
		RETVAL = newSViv( AMQP_FRAME_END );
	OUTPUT:
		RETVAL

SV*
AMQP_REPLY_SUCCESS()
	CODE:
		RETVAL = newSViv( AMQP_REPLY_SUCCESS );
	OUTPUT:
		RETVAL

SV*
AMQP_CONTENT_TOO_LARGE()
	CODE:
		RETVAL = newSViv( AMQP_CONTENT_TOO_LARGE );
	OUTPUT:
		RETVAL

SV*
AMQP_NO_ROUTE()
	CODE:
		RETVAL = newSViv( AMQP_NO_ROUTE );
	OUTPUT:
		RETVAL

SV*
AMQP_NO_CONSUMERS()
	CODE:
		RETVAL = newSViv( AMQP_NO_CONSUMERS );
	OUTPUT:
		RETVAL

SV*
AMQP_ACCESS_REFUSED()
	CODE:
		RETVAL = newSViv( AMQP_ACCESS_REFUSED );
	OUTPUT:
		RETVAL

SV*
AMQP_NOT_FOUND()
	CODE:
		RETVAL = newSViv( AMQP_NOT_FOUND );
	OUTPUT:
		RETVAL

SV*
AMQP_RESOURCE_LOCKED()
	CODE:
		RETVAL = newSViv( AMQP_RESOURCE_LOCKED );
	OUTPUT:
		RETVAL

SV*
AMQP_PRECONDITION_FAILED()
	CODE:
		RETVAL = newSViv( AMQP_PRECONDITION_FAILED );
	OUTPUT:
		RETVAL

SV*
AMQP_CONNECTION_FORCED()
	CODE:
		RETVAL = newSViv( AMQP_CONNECTION_FORCED );
	OUTPUT:
		RETVAL

SV*
AMQP_INVALID_PATH()
	CODE:
		RETVAL = newSViv( AMQP_INVALID_PATH );
	OUTPUT:
		RETVAL

SV*
AMQP_FRAME_ERROR()
	CODE:
		RETVAL = newSViv( AMQP_FRAME_ERROR );
	OUTPUT:
		RETVAL

SV*
AMQP_SYNTAX_ERROR()
	CODE:
		RETVAL = newSViv( AMQP_SYNTAX_ERROR );
	OUTPUT:
		RETVAL

SV*
AMQP_COMMAND_INVALID()
	CODE:
		RETVAL = newSViv( AMQP_COMMAND_INVALID );
	OUTPUT:
		RETVAL

SV*
AMQP_CHANNEL_ERROR()
	CODE:
		RETVAL = newSViv( AMQP_CHANNEL_ERROR );
	OUTPUT:
		RETVAL

SV*
AMQP_UNEXPECTED_FRAME()
	CODE:
		RETVAL = newSViv( AMQP_UNEXPECTED_FRAME );
	OUTPUT:
		RETVAL

SV*
AMQP_RESOURCE_ERROR()
	CODE:
		RETVAL = newSViv( AMQP_RESOURCE_ERROR );
	OUTPUT:
		RETVAL

SV*
AMQP_NOT_ALLOWED()
	CODE:
		RETVAL = newSViv( AMQP_NOT_ALLOWED );
	OUTPUT:
		RETVAL

SV*
AMQP_NOT_IMPLEMENTED()
	CODE:
		RETVAL = newSViv( AMQP_NOT_IMPLEMENTED );
	OUTPUT:
		RETVAL

SV*
AMQP_INTERNAL_ERROR()
	CODE:
		RETVAL = newSViv( AMQP_INTERNAL_ERROR );
	OUTPUT:
		RETVAL

SV*
AMQP_BASIC_CLASS()
	CODE:
		RETVAL = newSViv( AMQP_BASIC_CLASS );
	OUTPUT:
		RETVAL

SV*
AMQP_BASIC_CONTENT_TYPE_FLAG()
	CODE:
		RETVAL = newSViv( AMQP_BASIC_CONTENT_TYPE_FLAG );
	OUTPUT:
		RETVAL

SV*
AMQP_BASIC_CONTENT_ENCODING_FLAG()
	CODE:
		RETVAL = newSViv( AMQP_BASIC_CONTENT_ENCODING_FLAG );
	OUTPUT:
		RETVAL

SV*
AMQP_BASIC_HEADERS_FLAG()
	CODE:
		RETVAL = newSViv( AMQP_BASIC_HEADERS_FLAG );
	OUTPUT:
		RETVAL

SV*
AMQP_BASIC_DELIVERY_MODE_FLAG()
	CODE:
		RETVAL = newSViv( AMQP_BASIC_DELIVERY_MODE_FLAG );
	OUTPUT:
		RETVAL

SV*
AMQP_BASIC_PRIORITY_FLAG()
	CODE:
		RETVAL = newSViv( AMQP_BASIC_PRIORITY_FLAG );
	OUTPUT:
		RETVAL

SV*
AMQP_BASIC_CORRELATION_ID_FLAG()
	CODE:
		RETVAL = newSViv( AMQP_BASIC_CORRELATION_ID_FLAG );
	OUTPUT:
		RETVAL

SV*
AMQP_BASIC_REPLY_TO_FLAG()
	CODE:
		RETVAL = newSViv( AMQP_BASIC_REPLY_TO_FLAG );
	OUTPUT:
		RETVAL

SV*
AMQP_BASIC_EXPIRATION_FLAG()
	CODE:
		RETVAL = newSViv( AMQP_BASIC_EXPIRATION_FLAG );
	OUTPUT:
		RETVAL

SV*
AMQP_BASIC_MESSAGE_ID_FLAG()
	CODE:
		RETVAL = newSViv( AMQP_BASIC_MESSAGE_ID_FLAG );
	OUTPUT:
		RETVAL

SV*
AMQP_BASIC_TIMESTAMP_FLAG()
	CODE:
		RETVAL = newSViv( AMQP_BASIC_TIMESTAMP_FLAG );
	OUTPUT:
		RETVAL

SV*
AMQP_BASIC_TYPE_FLAG()
	CODE:
		RETVAL = newSViv( AMQP_BASIC_TYPE_FLAG );
	OUTPUT:
		RETVAL

SV*
AMQP_BASIC_USER_ID_FLAG()
	CODE:
		RETVAL = newSViv( AMQP_BASIC_USER_ID_FLAG );
	OUTPUT:
		RETVAL

SV*
AMQP_BASIC_APP_ID_FLAG()
	CODE:
		RETVAL = newSViv( AMQP_BASIC_APP_ID_FLAG );
	OUTPUT:
		RETVAL

SV*
AMQP_BASIC_CLUSTER_ID_FLAG()
	CODE:
		RETVAL = newSViv( AMQP_BASIC_CLUSTER_ID_FLAG );
	OUTPUT:
		RETVAL



