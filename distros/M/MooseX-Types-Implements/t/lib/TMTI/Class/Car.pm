use strict;
use warnings;
package TMTI::Class::Car;

use Moose;

with qw(TMTI::Breakable TMTI::Driveable);

sub break { }
sub drive { }

__PACKAGE__->meta->make_immutable;

1;

