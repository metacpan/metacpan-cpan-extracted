
package Tangram::Driver::SQLite::Storage;

use Tangram::Storage;
use vars qw(@ISA);
 @ISA = qw( Tangram::Storage );

sub connect
{
    my $class = shift;

    my ($schema, $dsn, $u, $p, $attr) = @_;
    $attr ||= {};
    my $self;

    {
	local($attr->{no_tx}) = 1;  # *cough cough HACK cough*
	$self = $class->SUPER::connect($schema, $dsn, $u, $p, $attr);
    }
    $self->{no_tx} = $attr->{no_tx} || 0;

    $self->{db}->{RaiseError} = 1;
    #$self->{db}->{sqlite_handle_binary_nulls} = 1;
    return $self;
}


sub has_tx()         { 1 }
sub has_subselects() { 0 }
#sub from_dual()      { " FROM DUAL" }

1;
