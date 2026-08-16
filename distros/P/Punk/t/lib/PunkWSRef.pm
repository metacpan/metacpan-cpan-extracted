package PunkWSRef;

use 5.010;
use strict;
use warnings;

# The reference codec grew up and moved into the dist as Punk::Test::WS
# (still transcribed from Hypersonic's Protocol::WebSocket::Frame, still
# independent of the C in punk_ws.h - that independence is the property
# that matters, not which directory it sits in). This shim keeps the
# existing tests' imports working.

use Punk::Test::WS ();

use Exporter 'import';
our @EXPORT_OK = qw(
    encode_client encode_server decode_ref accept_key handshake_request
);

*encode_client     = \&Punk::Test::WS::encode_client;
*encode_server     = \&Punk::Test::WS::encode_server;
*decode_ref        = \&Punk::Test::WS::decode_ref;
*accept_key        = \&Punk::Test::WS::accept_key;
*handshake_request = \&Punk::Test::WS::handshake_request;

1;
