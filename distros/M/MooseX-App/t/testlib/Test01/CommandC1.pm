package Test01::CommandC1 ;

use Moose;
use MooseX::App::Command;
extends qw(Test01);

option 'param_internal_name' => (
    isa         => 'Str',
    is          => 'rw',
    cmd_flag    => 'external_name',
    required    => 1,
);

# ABSTRACT: Test C1

1;