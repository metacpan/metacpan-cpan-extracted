# ============================================================================
package MooseX::App::Role::Common;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

has extra_argv => (
    is => 'rw',
    isa => 'ArrayRef',
);

has 'help_flag' => (
    is              => 'ro',
    isa             => 'Bool',
    traits          => ['MooseX::App::Meta::Role::Attribute::Option'],
    cmd_flag        => 'help',
    cmd_aliases     => [ qw(h usage ?) ], # LOCALIZE
    cmd_type        => 'proto',
    cmd_position    => 99999,
    documentation   => 'Prints this usage information.', # LOCALIZE
);

1;