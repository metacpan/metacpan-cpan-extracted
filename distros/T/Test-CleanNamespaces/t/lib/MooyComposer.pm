use strict;
use warnings;
package MooyComposer;

use Moo;
extends 'MooyClean';
with 'MooyRole';
use File::Spec::Functions 'catfile';
use namespace::clean;

sub child_stuff {}

use constant CAN => [ qw(stuff role_stuff meta) ];
use constant CANT => [ qw(catdir devnull catfile with) ];

1;
