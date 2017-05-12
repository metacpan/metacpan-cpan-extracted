package Storm::Query::DeleteWhere;
{
  $Storm::Query::DeleteWhere::VERSION = '0.240';
}

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;

with 'Storm::Role::Query';
with 'Storm::Role::Query::HasBindParams';
with 'Storm::Role::Query::HasWhereClause';
with 'Storm::Role::Query::IsExecutable';

sub delete  {
    my ( $self, @args ) = @_;
    
    my $sth = $self->_sth;
    my @params = $self->_combine_bind_params_and_args( [$self->bind_params], \@args );
    $sth->execute( @params );
    
    # throw exception if execution failed
    if ($sth->err) {
        confess qq[could not delete objects from database: ] .  $sth->errstr;
    }
    
    return 1;
}


sub _sql {
    my ( $self ) = @_;
    my $table = $self->orm->table( $self->class );
    my $sql = qq[DELETE FROM $table ];
    $sql .= $self->_where_clause;
    return $sql;
}


sub bind_params {
    my ( $self ) = @_;
    return
        ( map { $_->bind_params() } grep { $_->can('bind_params') } $self->where_clause_elements  );
}




no Moose;
__PACKAGE__->meta->make_immutable;


1;

