package Test::MyCmd::Command::frobulate;
use Moose;

extends 'MooseX::App::Cmd::Command';

sub command_names {
    return qw(frobulate frob);
}

has foo_bar => (
    traits        => [qw(Getopt)],
    isa           => "Bool",
    is            => "ro",
    cmd_aliases   => "F",
    documentation => "enable foo-bar subsystem",
);

has widget => (
    traits        => [qw(Getopt)],
    isa           => "Str",
    is            => "ro",
    documentation => "set widget name",
);

sub execute {
    my ( $self, $opt, $arg ) = @_;

    die "the widget name is " . $self->widget . " - @$arg\n";
}

1;
