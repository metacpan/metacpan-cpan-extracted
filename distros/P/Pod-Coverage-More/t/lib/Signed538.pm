package Signed538;

# Signature syntax that perl 5.38 added: defaults that apply only to an undef or a false argument.
# t/Pod-Coverage-More-Analyzer.t loads this only on 5.38 and later, because 5.36 cannot compile it.

use 5.038;
use warnings FATAL => q{all};

sub defaults ( $x, $z //= 'z', $w ||= [] ) {
    return [ $x, $z, $w ];
}

1;
