#include <gperl.h>
#include <loudmouth/loudmouth.h>
#include "perlmouth-gtypes.h"

#ifndef PERLMOUTH_TYPE_CONNECTION
#define PERLMOUTH_TYPE_CONNECTION (perlmouth_lm_connection_get_type ())
GType perlmouth_lm_connection_get_type (void) G_GNUC_CONST;
#endif

#ifndef PERLMOUTH_TYPE_MESSAGE
#define PERLMOUTH_TYPE_MESSAGE (perlmouth_lm_message_get_type ())
GType perlmouth_lm_message_get_type (void) G_GNUC_CONST;
#endif

#ifndef PERLMOUTH_TYPE_SSL
#define PERLMOUTH_TYPE_SSL (perlmouth_lm_ssl_get_type ())
GType perlmouth_lm_ssl_get_type (void) G_GNUC_CONST;
#endif

#ifndef PERLMOUTH_TYPE_PROXY
#define PERLMOUTH_TYPE_PROXY (perlmouth_lm_proxy_get_type ())
GType perlmouth_lm_proxy_get_type (void) G_GNUC_CONST;
#endif

#ifndef PERLMOUTH_TYPE_MESSAGE_HANDLER
#define PERLMOUTH_TYPE_MESSAGE_HANDLER (perlmouth_lm_message_handler_get_type ())
GType perlmouth_lm_message_handler_get_type (void) G_GNUC_CONST;
#endif

#ifndef PERLMOUTH_TYPE_MESSAGE_NODE
#define PERLMOUTH_TYPE_MESSAGE_NODE (perlmouth_lm_message_node_get_type ())
GType perlmouth_lm_message_node_get_type (void) G_GNUC_CONST;
#endif

#include "loudmouth-autogen.h"
