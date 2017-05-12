package Test::Cmd::Perl;

use Moose;

with 'MooseX::Role::Cmd';

has 'e' => ( isa => 'Str', is => 'rw' );

sub output {
    my ( $self, @args ) = @_;

    $self->run(@args);
    my $stdout = join '', @{$self->stdout};
    return split '/', $stdout;
}

1;
