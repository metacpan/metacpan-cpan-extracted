package Test::MyAny::Mouse::Command::foo;
use Mouse;

extends 'MouseX::App::Cmd::Command';

has bar => (
    isa           => 'Str',
    is            => 'ro',
    required      => 1,
    documentation => 'required option field',
);

sub execute {
    my ( $self, $opt, $arg ) = @_;

    die 'my Mouse bar is ', $self->bar . "\n";
}

1;
