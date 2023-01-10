package StructLess::Role::Something;

use Role::Tiny;

# ABSTRACT: turns baubles into trinkets

sub snorg {
    my $self = shift;
    return  __PACKAGE__ ;
}

1;
