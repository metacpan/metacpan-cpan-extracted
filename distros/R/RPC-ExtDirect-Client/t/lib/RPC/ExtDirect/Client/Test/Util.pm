package RPC::ExtDirect::Client::Test::Util;

use strict;
use warnings;

use Exporter;

use base 'Exporter';

our @EXPORT = qw/ clean_env /;

### NON-EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Clean the %ENV so that HTTP::Tiny doesn't trip on the
# proxy variables
#

sub clean_env {

    # The list of variables is taken from HTTP::Tiny::_set_proxies code
    delete @ENV{ qw/ all_proxy ALL_PROXY http_proxy https_proxy no_proxy / };

    return;
}

1;

