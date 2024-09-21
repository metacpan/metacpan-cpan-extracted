use v5.18;
use warnings;

use Object::Pad 0.800;

role R {
    my $name = "Gantenbein";
    method name { $name };
}

0x55AA;
