package t::Util;

use warnings;
use strict;

use Exporter "import";

our @EXPORT = qw/SvRO $mod/;

sub SvRO { goto &Internals::SvREADONLY }

our $mod = qr/
    Modification\ of\ a\ read-only\ value\ attempted    |
    Attempt\ to\ .*\ a\ restricted\ hash
/x;

1;
