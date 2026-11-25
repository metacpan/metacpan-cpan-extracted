package Declared::WithPad;

use 5.036;
use warnings FATAL => q{all};

use Object::Pad;

# PPI does not know the keywords of Object::Pad, so it reads the class and the final 1; as one statement.
## no critic (Modules::RequireEndWithOne)

class Declared::WithPad {
    field $name : param : reader;

    method hello($x) {
        return "$name $x";
    }
}

1;
