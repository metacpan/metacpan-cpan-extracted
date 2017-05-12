package Storm::Query::Select;
{
  $Storm::Query::Select::VERSION = '0.240';
}

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;

use Storm::Query::Select::Iterator;

use MooseX::Types::Moose qw( HashRef Str );

with 'Storm::Role::Query';
with 'Storm::Role::Query::HasAttributeOrder';
with 'Storm::Role::Query::HasBindParams';
with 'Storm::Role::Query::HasLimitClause';
with 'Storm::Role::Query::HasOrderByClause';
with 'Storm::Role::Query::HasWhereClause';

has '_join' => (
    is => 'rw',
    isa => Str,
);

has '_from_tables' => (
    is => 'bare',
    isa => HashRef,
    default => sub { { } },
    traits  => [qw( Hash )],
    handles => {
        '_set_from_table' => 'set',
        '_from_tables'    => 'values',
    }
);

sub _from  {
    my ( $self, @tables ) = @_;
    $self->_set_from_table( $self->orm->table( $_->name ), $_ ) for @tables;
}


sub BUILD {
    my $self = shift;
    $self->_from( $self->class->meta->storm_table );
}



sub _sql {
    my ( $self ) = @_;
    return join q[ ] ,
        $self->_select_clause  ,
        $self->_from_clause    ,
        $self->_where_clause   ,
        $self->_order_by_clause,
        $self->_limit_clause,
}

sub join {
    my ( $self, $table ) = @_;
    $self->_set_join( $table );
    return $self;
}


sub results  {
    my ( $self, @args ) = @_;
    my @params = $self->_combine_bind_params_and_args( [$self->bind_params], \@args );
    my $results = Storm::Query::Select::Iterator->new($self, @params);
    return $results;
}


sub _select_clause {
    my ( $self ) = @_;
    my $table = $self->orm->table( $self->class );
    return 'SELECT ' . CORE::join (', ', map { $_->column->sql( $table ) } $self->attribute_order);
}

sub _from_clause {
    my ( $self ) = @_;
    my $sql  = 'FROM ';
    $sql .= CORE::join(", ", map { $self->orm->table( $_->name ) } $self->_from_tables);
    $sql .= ' ' . $self->_join_clause if $self->_join;
    return $sql;
}

sub _join_clause {
    my ( $self ) = @_;
    return if ! defined $self->_join;
    return 'INNER JOIN ' . $self->_join;
}



sub bind_params {
    my ( $self ) = @_;
    return
        ( map { $_->bind_params() }
          grep { $_->can('bind_params') }
          $self->where_clause_elements, $self->order_by_elements
        );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

