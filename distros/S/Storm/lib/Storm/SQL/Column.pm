package Storm::SQL::Column;
{
  $Storm::SQL::Column::VERSION = '0.240';
}
use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

has 'name' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
);

sub sql {
    return $_[0]->name;
}

sub BUILDARGS {
    my $class = shift;

    if ( @_ == 1 && ! ref $_[0] ) {
        return { name => $_[0] };
    }
    else {
        return $class->SUPER::BUILDARGS(@_);
    }
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;
