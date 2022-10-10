package Net::HTTP2::Client::AnyEvent;

use strict;
use warnings;

use constant _CLIENT_IO => 'AnyEvent';

use parent 'Net::HTTP2::Client';

1;
