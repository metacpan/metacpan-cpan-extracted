package Test03::SomeCommand;

use MooseX::App::Command;
extends qw(Test03);
with qw(Test03::Role::TestRole);

use Moose::Util::TypeConstraints;

parameter 'param_a' => (
    is            => 'rw',
    isa           => 'Str',
);

parameter 'param_b' => (
    is            => 'rw',
    isa           => enum([qw(aaa bbb ccc ddd eee fff)]),
);


option 'some_option' => (
    is            => 'rw',
    isa           => 'Str',
    documentation => q[Very important option!],
);

option 'another_option' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    cmd_flag      => 'another',
    cmd_tags      => ['Not important'],
);

option 'list' => (
    is            => 'rw',
    isa           => 'ArrayRef[Maybe[Str]]',
);

has 'private' => (
    is              => 'rw',
    isa             => 'Str',
);

sub run {
    my ($self) = @_;
    print "RUN:".($self->some_option||'').":".($self->another_option||'');
}

1;