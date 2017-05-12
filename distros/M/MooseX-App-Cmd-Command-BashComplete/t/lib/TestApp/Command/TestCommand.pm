package TestApp::Command::TestCommand;

use Moose;
extends 'MooseX::App::Cmd::Command';

has 'foo' => (
    is  => 'rw',
    isa => 'Str',
);

1;
