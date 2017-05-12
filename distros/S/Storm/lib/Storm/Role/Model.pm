package Storm::Role::Model;
{
  $Storm::Role::Model::VERSION = '0.240';
}

use Moose::Role;
use MooseX::Types::Moose qw( HashRef );

sub register {
    $_[0]->meta->register_class( $_[1] );
}

sub remove {
    $_[0]->meta->remove_class( $_[1], 1 );
}

sub members {
    $_[0]->meta->registered_classes;
}

sub registered {
    $_[0]->meta->is_registered( $_[1] );
}

1;