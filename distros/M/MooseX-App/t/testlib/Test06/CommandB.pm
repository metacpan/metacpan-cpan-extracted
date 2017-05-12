package Test06::CommandB;

use Moose;
#use MooseX::App::Command;
extends qw(Test06);

has 'email' => (
    isa         => 'Str',
    is          => 'rw',
);

sub run {
    my ($self) = @_;
    warn $self;
}

1;