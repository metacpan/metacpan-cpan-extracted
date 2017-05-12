package Storm::Query::Delete;
{
  $Storm::Query::Delete::VERSION = '0.240';
}

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;

with 'Storm::Role::Query';
with 'Storm::Role::Query::IsExecutable';

sub _sql {
    my ( $self ) = @_;
    my $table = $self->orm->table( $self->class );
    my $column = $self->class->meta->primary_key->column->sql;
    return  qq[DELETE FROM $table WHERE $column = ?];
}


sub delete  {
    my ( $self, @objects ) = @_;
    my $sth     = $self->_sth;
    
    for my $o (@objects) {
        $sth->execute(  $o->meta->primary_key->get_value( $o ) );
        
        # throw exception if insert failed
        if ($sth->err) {
            confess qq[could not delete $o from database: ] .  $sth->errstr;
        }
    }
    
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;


1;

