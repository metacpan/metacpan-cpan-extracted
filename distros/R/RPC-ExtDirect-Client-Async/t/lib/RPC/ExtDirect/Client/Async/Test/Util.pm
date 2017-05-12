package RPC::ExtDirect::Client::Async::Test::Util;

use strict;
use warnings;

use Exporter;

use base 'Exporter';

our @EXPORT = qw/ clean_env /;

### EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Clean the %ENV so that AnyEvent::HTTP doesn't trip on the
# proxy variables
#

sub clean_env {

    # The list of variables is taken from HTTP::Tiny::_set_proxies code
    # I guess it's the same that AnyEvent::HTTP may use eventually
    delete @ENV{ qw/ all_proxy ALL_PROXY http_proxy https_proxy no_proxy / };

    return;
}

1;

