package Orochi::Test::MooseBased1;
use Moose;
use MooseX::Orochi;

bind_constructor '/orochi/test/MooseBased1' => (
    args => {
        foo => bind_value '/orochi/test/MooseBased1/foo',
        bar => bind_value '/orochi/test/MooseBased1/bar',
    }
);

has foo => (is => 'ro', required => 1);
has bar => (is => 'ro', required => 1);

__PACKAGE__->meta->make_immutable();

1;