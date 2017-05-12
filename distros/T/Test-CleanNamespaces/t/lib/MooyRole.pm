use strict;
use warnings;
package MooyRole;

use File::Spec::Functions 'devnull';
use Moo::Role;  # order is significant here
use namespace::clean;

sub role_stuff {}

use constant CAN => [ qw(role_stuff) ];
use constant CANT => [ qw(devnull with) ];

1;
