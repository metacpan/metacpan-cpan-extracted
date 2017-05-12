package t::Test::UseScaffolder;

use strict;
use warnings;

use MooseX::Scaffold;

MooseX::Scaffold->setup_scaffolding_import;

sub SCAFFOLD {
    my ($class, %given) = @_;

    $class->class_has(melon => qw/is rw/);
    $class->class_has(apricot => qw/is rw/);

    $class->package->melon(1);
    $class->package->apricot(2);
}

1;

