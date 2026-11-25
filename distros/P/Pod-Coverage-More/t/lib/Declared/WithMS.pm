package Declared::WithMS;

use 5.036;
use warnings FATAL => q{all};

use Method::Signatures;

# PPI does not know the keywords of Method::Signatures, so it reads the sub and the final 1; as one statement.
## no critic (Modules::RequireEndWithOne)

func scale( Int $x, Num $by = 2 ) {
    return $x * $by;
}

1;
