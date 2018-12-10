use strict;
use warnings;
package MooseyComposer;

use Moose;
extends 'MooseyClean';
with 'MooseyRole';
use File::Spec::Functions 'catfile';
use namespace::clean;

sub child_stuff {}

our $CAN;
use constant CAN => [ qw(stuff role_stuff child_stuff meta) ];
use constant CANT => [ qw(catdir devnull catfile with) ];

1;
