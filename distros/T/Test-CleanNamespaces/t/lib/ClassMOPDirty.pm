use strict;
use warnings;
package ClassMOPDirty;

use metaclass;
use File::Spec::Functions 'catdir';

sub stuff {}

use constant CAN => [ qw(stuff catdir meta) ];
use constant CANT => [ ];
use constant DIRTY => [ qw(catdir) ];

1;
