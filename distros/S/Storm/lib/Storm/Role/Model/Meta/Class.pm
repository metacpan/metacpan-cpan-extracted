package Storm::Role::Model::Meta::Class;
{
  $Storm::Role::Model::Meta::Class::VERSION = '0.240';
}

use Moose::Role;
use MooseX::Types::Moose qw( HashRef );

has registered_classes => (
    is => 'bare',
    isa =>  HashRef,
    default => sub { { } },
    traits => [qw( Hash )],
    handles => {
        _register_class => 'set',
        remove_class => 'delete',
        registered_classes => 'keys',
        is_registered => 'exists',
    }
);

sub register_class {
    $_[0]->_register_class( $_[1], 1 );
    Class::MOP::load_class( $_[1] );
}

1;