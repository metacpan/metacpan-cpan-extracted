package Test::MyCmd::Command::justusage;
use Moose;

extends 'MooseX::App::Cmd::Command';

=head1 NAME

Test::MyCmd::Command::justusage - it just dies its own usage, no matter what

=cut

sub execute {
    my ( $self, $opt, $arg ) = @_;

    die $self->usage->text;
}

1;
