package Storm::Meta::Column;
{
  $Storm::Meta::Column::VERSION = '0.240';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use MooseX::Types::Moose qw( Bool Str Undef );

has 'table' => (
    is => 'rw',
    isa => 'Storm::Meta::Table',
);

has 'name' => (
    is       => 'ro' ,
    isa      => Str  ,
    required => 1    ,
);

has 'auto_increment' => (
    is       => 'rw'  ,
    isa      => Bool  ,
    default  => 0     ,
);


sub sql  {
    my ( $self, $table ) = @_;
    $table ? $table . '.' . $self->name :  $self->name;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
