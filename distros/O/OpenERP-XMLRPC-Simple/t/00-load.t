# vim: filetype=perl :

use strict;
use warnings;

use Test::More tests => 1; # last test to print

BEGIN {
   use_ok('OpenERP::XMLRPC::Client');
}

diag("Testing OpenERP::XMLRPC::Client " );
