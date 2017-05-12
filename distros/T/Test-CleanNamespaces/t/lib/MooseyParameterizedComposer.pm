use strict;
use warnings;
package MooseyParameterizedComposer;

use Moose;
extends 'MooseyClean';
with 'MooseyParameterizedRole' => { foo => 1 };
use File::Spec::Functions 'catfile';
use namespace::clean;

sub child_stuff {}

use constant CAN => [ qw(stuff role_stuff child_stuff meta) ];
use constant CANT => [ qw(catdir catfile devnull has with parameter role) ];

1;
