package Storm::Role::Query::HasSQLFunctions;
{
  $Storm::Role::Query::HasSQLFunctions::VERSION = '0.240';
}
use Moose::Role;

use Storm::SQL::Literal;
use Storm::SQL::Placeholder;
use Storm::SQL::Function;

sub function {
    my ( $self, $function, @args ) = @_;
    
    # perform substitution on arguments
    @args = $self->args_to_sql_objects( @args );
    
    my $element = Storm::SQL::Function->new( $function, @args );
    return $element;
}

no Moose::Role;
1;
