package DataTest;

use Module::Compile;

sub foo {
    return shift() + shift();
}

1;

__DATA__

one
two

three

