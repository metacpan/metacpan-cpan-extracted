package Test01::CommandD;

use Moose;
use MooseX::App::Command;
extends qw(Test01);

use Moose::Util::TypeConstraints;

subtype 'ArrayRefOfInts',
      as 'ArrayRef[Int]';

  coerce 'ArrayRefOfInts',
      from 'Int',
      via { [ $_ ] };

option 'command_local1' => (
    isa             => 'ArrayRefOfInts',
    coerce          => 1,
    is              => 'rw',
    documentation   => 'some docs about the long texts that seem to occur randomly',
    cmd_tags        => [qw(Important)],
    cmd_env         => 'LOCAL1',
);

command_long_description "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras dui velit, varius nec iaculis vitae, elementum eget mi.
* bullet1
* bullet2
* bullet3
Cras eget mi nisi. In hac habitasse platea dictumst.";

command_short_description "Command A!";

sub run {
    my ($self) = @_;
    print "RUN COMMAND-D:".($self->command_local1 // 'undef');
}

1;