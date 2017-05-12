package Mock::Container;
use strict;
use warnings;
use Object::Container::Exporter -base;

register_namespace form => 'Mock::Api::Form';

register 'foo' => sub {
    my $self = shift;
    $self->load_class('Mock::Foo');
    Mock::Foo->new;
};

1;

