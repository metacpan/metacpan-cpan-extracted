package Test06::CommandA;

use Moose;
use MooseX::App::Command;
extends qw(Test06);

use Moose::Util::TypeConstraints;

subtype 'Test06::local2'
    => as 'Str'
    => where { $_  =~ /^[aA]/ };
    #=> message { "Must start with an 'A'" };

no Moose::Util::TypeConstraints;

option 'command_local2' => (
    isa             => 'Test06::local2',
    is              => 'rw',
    documentation   => q[Verylongwordwithoutwhitespacestotestiftextformatingworksproperly],
    cmd_env         => 'LOCAL2',
);

sub run {
    my ($self) = @_;
    print "NEW WITH A";
    ref($self)->initialize_command_class('Test06::CommandB')->run;
    #$self->initialize_command_class('Test06::CommandB');
}

1;