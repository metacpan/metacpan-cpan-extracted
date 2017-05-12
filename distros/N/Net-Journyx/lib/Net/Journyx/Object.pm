package Net::Journyx::Object;
use Moose;

has jx => (
    is      => 'rw',
    required => 1,
    isa => 'Net::Journyx',
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;
