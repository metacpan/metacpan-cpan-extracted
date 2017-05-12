package Test01::CommandA;

use Moose;
use MooseX::App::Command;
extends qw(Test01);

option 'command_local1' => (
    isa             => 'Int',
    is              => 'rw',
    documentation   => 'some docs about the long texts that seem to occur randomly',
    cmd_tags        => [qw(Important)],
    cmd_env         => 'LOCAL1',
);

option 'command_local2' => (
    isa             => 'Str',
    is              => 'rw',
    documentation   => q[Verylongwordwithoutwhitespacestotestiftextformatingworksproperly],
    cmd_env         => 'LOCAL2',
);

has 'anotherprivate' => (
    is              => 'rw',
    isa             => 'Str',
);

command_long_description "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras dui velit, varius nec iaculis vitae, elementum eget mi. 
* bullet1
* bullet2
* bullet3
Cras eget mi nisi. In hac habitasse platea dictumst.";

command_short_description "Command A!";

sub run {
    my ($self) = @_;
    print "RUN COMMAND-A:".($self->command_local2 // 'undef');
}

1;