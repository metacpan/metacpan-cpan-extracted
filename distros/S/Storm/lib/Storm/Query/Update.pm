package Storm::Query::Update;
{
  $Storm::Query::Update::VERSION = '0.240';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

with 'Storm::Role::CanDeflate';
with 'Storm::Role::Query';
with 'Storm::Role::Query::HasAttributeOrder';
with 'Storm::Role::Query::IsExecutable';

sub update {
    my ( $self, @objects ) = @_;
    my $sth  = $self->_sth;
    
    my @attributes = $self->attribute_order;
    my $primary_key = $self->class->meta->primary_key;
    
    for my $o ( @objects ) {
        
        my @data = map {$_->get_value( $o ) } $self->attribute_order;
        @data = $self->_deflate_values(\@attributes, \@data);
        $sth->execute( @data, $primary_key->get_value( $o ) );
        
        # throw exception if update failed
        if ($sth->err) {
            confess qq[could not update $o in database: ] .  $sth->errstr;
        }
        
        # add the object to the live objects cache
        my $live = $self->orm->live_objects;
        $live->insert( $o ) if $live->current_scope && ! $live->is_registered( $o );
    }
    
    return 1;
}

sub _sql {
    my ( $self ) = @_;
    my $table = $self->orm->table( $self->class );
    my $primary_key = $self->class->meta->primary_key->column->name;
    
    # NOTE: column->name should probably be column->sql, problem is that
    # sql lite does not support fully qualified column names (table.column)
    
    my $sql = qq[UPDATE $table SET ];
    my @set_statements = map { join (' = ', $_->column->name, '?') } $self->attribute_order;
    $sql .= join ', ', @set_statements;
    $sql .= qq[ WHERE $primary_key = ?];
    
    return $sql;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
