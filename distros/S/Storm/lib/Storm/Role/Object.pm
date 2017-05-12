package Storm::Role::Object;
{
  $Storm::Role::Object::VERSION = '0.240';
}

use Moose::Role;
use Storm::Meta::Table;

use Storm::Types qw( Storm );
use MooseX::Types::Moose qw( Undef );

has 'orm' => (
    reader => 'orm',
    writer => '_set_orm',
    isa => Storm|Undef,
    default => undef,
);

1;