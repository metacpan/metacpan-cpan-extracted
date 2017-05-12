#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 1 }

use POE::Component::Server::XMLRPC; ok(1);
exit;
__END__
