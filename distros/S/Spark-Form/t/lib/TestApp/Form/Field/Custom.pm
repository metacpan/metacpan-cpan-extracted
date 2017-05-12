package TestApp::Form::Field::Custom;
our $VERSION = '0.2102';


use Moose;
extends 'Spark::Form::Field';

has 'min_length' => (
    isa      => 'Int',
    is       => 'rw',
    required => 0,
    default  => 6,
);

sub _validate {
    my ($self) = @_;
    if ($self->min_length > length $self->value) {
        $self->error('Customs must be at least ' . $self->min_length . ' characters long.');
    }
}

1;
