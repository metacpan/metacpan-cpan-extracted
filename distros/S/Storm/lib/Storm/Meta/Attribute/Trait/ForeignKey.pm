package Storm::Meta::Attribute::Trait::ForeignKey;
{
  $Storm::Meta::Attribute::Trait::ForeignKey::VERSION = '0.240';
}
use Moose::Role;

use MooseX::Types::Moose qw(Undef);
use Storm::Types qw(StormForeignKeyConstraintValue);

has 'on_update' => (
    is => 'rw',
    isa => StormForeignKeyConstraintValue,
    default => 'CASCADE',
);

has 'on_delete' => (
    is => 'rw',
    isa => StormForeignKeyConstraintValue,
    default => 'RESTRICT',
);

package Moose::Meta::Attribute::Custom::Trait::ForeignKey;
{
  $Moose::Meta::Attribute::Custom::Trait::ForeignKey::VERSION = '0.240';
}
sub register_implementation { 'Storm::Meta::Attribute::Trait::ForeignKey' };
1;
