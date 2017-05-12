package t::Test::Scaffolder;

use strict;
use warnings;

sub SCAFFOLD {
    my ($class, %given) = @_;

    $class->class_has(apple => qw/is rw/);
    $class->class_has(banana => qw/is rw/);

    $class->package->apple(1);
    $class->package->banana(2);
}

1;
