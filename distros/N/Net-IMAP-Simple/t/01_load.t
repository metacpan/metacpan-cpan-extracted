
use strict;
use warnings;

use Test;

plan tests => 1;

ok(eval "use Net::IMAP::Simple; 1") or warn " $@";
