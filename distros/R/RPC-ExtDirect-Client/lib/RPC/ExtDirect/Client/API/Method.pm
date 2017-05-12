package RPC::ExtDirect::Client::API::Method;

use strict;
use warnings;

use RPC::ExtDirect::API::Method;
use base 'RPC::ExtDirect::API::Method';

############## PRIVATE METHODS BELOW ##############

### PRIVATE INSTANCE METHOD ###
#
# Override base method to forgo metadata arg checks.
#

sub _get_meta_arg {}

1;
