use strict;
use warnings;

use Test::More tests => 1;
use Test::Exception;

require TAP::Tree;

throws_ok { TAP::Tree->new } qr[No required parameter], 'no paramter';
