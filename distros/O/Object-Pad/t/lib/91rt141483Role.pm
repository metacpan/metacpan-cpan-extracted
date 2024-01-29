use v5.14;
use warnings;

use Object::Pad 0.800;

role R {
    my $name = "Gantenbein";
    method name { $name };
}

0x55AA;
