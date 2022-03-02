use v5.14;
use warnings;

use Object::Pad;

role R {
    my $name = "Gantenbein";
    method name { $name };
}

0x55AA;
