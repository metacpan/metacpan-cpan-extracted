package Storm::SQL::Fragment::Where::Boolean;
{
  $Storm::SQL::Fragment::Where::Boolean::VERSION = '0.240';
}

use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;

use Storm::Types qw( StormSQLWhereBoolean );

has 'operator' => (
    is       => 'ro',
    isa      => StormSQLWhereBoolean,
    required => 1,
);

sub BUILDARGS {
    my $class = shift;

    # one argument form
    if (@_ == 1) {
        return { operator => $_[0] };
    }
    else {
        return $class->SUPER::BUILDARGS(@_);
    }
}


sub sql {
    return uc $_[0]->operator();
}

no Moose;
__PACKAGE__->meta()->make_immutable();

1;

