use strict;
use warnings;
package MouseyRole;

use Mouse::Role;
use File::Spec::Functions 'devnull';
use namespace::clean;

sub role_stuff {}

use constant CAN => [ qw(role_stuff) ];
use constant CANT => [ qw(devnull with) ];

1;
