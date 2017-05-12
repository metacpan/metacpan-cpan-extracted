package URI::nats;

our $VERSION = 0.715;

require URI::_server;
require URI::_userpass;
@URI::nats::ISA=qw(URI::_server URI::_userpass);

1;
