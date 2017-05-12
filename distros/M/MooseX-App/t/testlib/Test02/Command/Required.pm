package Test02::Command::Required;

use Moose;
use MooseX::App::Command;
extends qw(Test02);

option 'local1' => (
    isa             => 'Int',
    is              => 'rw',
    required        => 1,
    cmd_term        => 1,
);

option 'local2' => (
    isa             => 'Bool',
    is              => 'rw',
    default         => 1,
    cmd_term        => 1,
);

1;