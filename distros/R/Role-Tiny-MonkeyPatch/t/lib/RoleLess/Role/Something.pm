use strict;
use warnings;
package RoleLess::Role::Something;

use Mojo::Base -role;

has "foo";

# ABSTRACT: turns baubles into trinkets


sub snorg {
    my $self = shift;
}

1;
