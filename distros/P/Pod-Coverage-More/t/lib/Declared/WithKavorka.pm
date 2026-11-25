package Declared::WithKavorka;

use 5.036;
use warnings FATAL => q{all};

use Kavorka;

# PPI does not know the keywords of Kavorka, so it reads the sub and the final 1; as one statement.
## no critic (Modules::RequireEndWithOne)

fun scale( Int $x, Num $by = 2 ) {
    return $x * $by;
}

1;
