package # Hide from CPAN
    DVTest;
use Moose;

with 'MooseX::Role::Data::Verifier';

has 'mysterious' => (
    is => 'rw'
);

has 'name' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

1;