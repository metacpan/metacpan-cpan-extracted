use strict;
use warnings;
use Test::More tests => 1;

use Test::Warn;

warnings_are {
    eval q| use SOAP::Lite +trace => [ transport => sub { } ]; |;
}
[], "No warnings found when importing +trace with subs";
