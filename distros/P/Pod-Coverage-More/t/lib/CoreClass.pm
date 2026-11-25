# Methods of the core class feature, whose implicit $self perl 5.38 to 5.42
# leave out of the signature ops and perl 5.44 lists in them.
# t/Pod-Coverage-More-Analyzer.t loads this only on 5.38 and later.

use 5.038;
use warnings FATAL => q{all};
use experimental q{class};

# PPI does not know the method keyword, so it reads both methods and the final 1; as one statement.
## no critic (Modules::RequireEndWithOne)

class CoreClass;

field $name : param;

method add ( $item, $qty = 1 ) {
    return [ $item, $qty, $name ];
}

method name {
    return $name;
}

1;
