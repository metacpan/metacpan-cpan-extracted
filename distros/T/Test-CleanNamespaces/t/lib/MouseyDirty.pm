use strict;
use warnings;
package MouseyDirty;

use Mouse;
use File::Spec::Functions 'catdir';

sub stuff {}

use constant CAN => [ qw(catdir stuff has with meta) ];
use constant CANT => [ ];
use constant DIRTY => [ qw(catdir has with) ];

1;
