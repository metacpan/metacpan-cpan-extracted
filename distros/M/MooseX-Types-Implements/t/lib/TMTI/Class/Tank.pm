use strict;
use warnings;
package TMTI::Class::Tank;

use Moose;

sub break { }
sub drive { }
sub fire { }

__PACKAGE__->meta->make_immutable;

1;

