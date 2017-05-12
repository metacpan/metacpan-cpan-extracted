use strict;
use warnings;
package MouseyComposer;

use Mouse;
extends 'MouseyClean';
with 'MouseyRole';
use File::Spec::Functions 'catfile';
use namespace::clean;

sub child_stuff {}

use constant CAN => [ qw(stuff role_stuff child_stuff meta) ];
use constant CANT => [ qw(catdir devnull catfile with) ];

1;
