use strict;
use warnings;
package MooseyRole;

use Moose::Role;
use File::Spec::Functions 'devnull';
use namespace::clean;

sub role_stuff {}

our $CAN;
use constant CAN => [ qw(role_stuff) ];
use constant CANT => [ qw(devnull devnull with meta) ];

1;
