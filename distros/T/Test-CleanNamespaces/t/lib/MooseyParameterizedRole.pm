use strict;
use warnings;
package MooseyParameterizedRole;

use MooseX::Role::Parameterized;
with 'MooseyRole';
use File::Spec::Functions 'devnull';
use namespace::clean;

parameter foo => ( is => 'ro', isa => 'Str' );

role {
    1;
};

sub parameterized_role_stuff {}

use constant CAN => [ qw(role_stuff) ];  # TODO: meta
use constant CANT => [ qw(devnull parameter role with) ];

1;
