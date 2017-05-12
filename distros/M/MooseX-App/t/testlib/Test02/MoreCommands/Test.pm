# ============================================================================
package Test02::MoreCommands::Test;
# ============================================================================
use strict;
use warnings;
use utf8;

use Moose;
use MooseX::App::Command;
extends qw(Test02);

use Moose::Util::TypeConstraints;

parameter 'first' => (
    isa             => enum([qw(a1 b2 b3)]),
    is              => 'rw',
    required        => 1,
    cmd_term        => 1,
);

option 'second' => (
    isa             => 'Int',
    is              => 'rw',
    cmd_term        => 1,
);

1;