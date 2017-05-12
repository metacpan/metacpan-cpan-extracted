package t::FooBar;

use Moove;

func foo (Int $a, Str $b) {
    return $a.$b;
}

method bar (Int $a, Str $b) {
    return $a.$b;
}

1;
