use strict;
use warnings;
package Composer;

use parent 'Clean';
use Role::Tiny 'with';
with 'Role';
use File::Spec::Functions 'catfile';
use namespace::clean;

sub child_stuff {}

use constant CAN => [ qw(method role_stuff child_stuff) ];
use constant CANT => [ qw(catdir devnull catfile with) ];

1;
