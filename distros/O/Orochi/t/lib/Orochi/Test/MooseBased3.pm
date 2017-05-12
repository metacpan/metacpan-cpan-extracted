package Orochi::Test::MooseBased3;
use Moose;
use MooseX::Orochi;

bind_constructor '/orochi/test/MooseBased3' => (
    injection_class => 'Setter',
    setter_params => {
        baz => bind_value [ 'abc', 'def' ],
    }
);

has baz => (is => 'rw', isa => 'Int');

__PACKAGE__->meta->make_immutable;

1;
