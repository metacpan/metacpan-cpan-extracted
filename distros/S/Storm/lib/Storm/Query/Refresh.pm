package Storm::Query::Refresh;
{
  $Storm::Query::Refresh::VERSION = '0.240';
}

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;

with 'Storm::Role::CanInflate';
with 'Storm::Role::Query';
with 'Storm::Role::Query::HasAttributeOrder';
with 'Storm::Role::Query::IsExecutable';


sub _sql {
    my ( $self ) = @_;
    return join q[ ] ,
        $self->_select_clause,
        $self->_from_clause  ,
        $self->_where_clause ;
}


sub refresh {
    
    my ( $self, @objects ) = @_;

    for my $o (@objects) {
        my $id = $o->meta->primary_key->get_value( $o );
        
        # retrieve the object from the database
        my $sth  = $self->_sth;
        $sth->execute($id);
        my  @data = $sth->fetchrow_array;
        return undef if ! @data;
        
        # build the object from the data retrieved
        my %struct;
        my @attributes = $self->attribute_order;
        @data = $self->_inflate_values(\@attributes, \@data);
        $attributes[$_]->set_value( $o, $data[$_] ) for ( 0..$#attributes );
    }
    
    return 1;
}


sub _select_clause  {
    my ( $self ) = @_;
    return 'SELECT ' . join (', ', map { $_->column->sql } $self->attribute_order);
}

sub _from_clause ( ) {
    my ( $self ) = @_;
    return 'FROM ' . $self->orm->table( $self->class );
}

sub _where_clause ( ) {
    my ( $self ) = @_;
    return 'WHERE ' . $self->class->meta->primary_key->column->sql . ' = ?';
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

