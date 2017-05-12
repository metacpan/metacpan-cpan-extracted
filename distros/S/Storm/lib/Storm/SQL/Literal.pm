package Storm::SQL::Literal;
{
  $Storm::SQL::Literal::VERSION = '0.240';
}
use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

has 'string' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
);

sub sql {
    return $_[0]->string;
}

sub BUILDARGS {
    my $class = shift;

    if ( @_ == 1 && ! ref $_[0] ) {
        return { string => $_[0] };
    }
    else {
        return $class->SUPER::BUILDARGS(@_);
    }
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;
