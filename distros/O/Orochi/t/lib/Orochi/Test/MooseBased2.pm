package Orochi::Test::MooseBased2;
use Moose;
use MooseX::Orochi;

bind_constructor '/orochi/test/MooseBased2' => (
    args => {
        foo => bind_value '/orochi/test/MooseBased1',
    }
);

has foo => (
    is => 'ro',
    isa => 'Orochi::Test::MooseBased1',
    required => 1
);

__PACKAGE__->meta->make_immutable();

1;