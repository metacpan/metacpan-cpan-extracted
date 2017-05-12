package Storm::Role::Query::HasWhereClause;
{
  $Storm::Role::Query::HasWhereClause::VERSION = '0.240';
}
use Moose::Role;
use MooseX::Types::Moose qw( ArrayRef HashRef );

use Storm::SQL::Column;
use Storm::SQL::Literal;
use Storm::SQL::Placeholder;
use Storm::SQL::Fragment::Where::Boolean;
use Storm::SQL::Fragment::Where::Comparison;
use Storm::SQL::Fragment::Where::SubgroupStart;
use Storm::SQL::Fragment::Where::SubgroupEnd;

with 'Storm::Role::Query::CanParseUserArgs';
with 'Storm::Role::Query::HasAttributeMap';
with 'Storm::Role::Query::HasSQLFunctions';

has '_where' => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [] },
    traits => [qw( Array )],
    handles => {
        '_add_where_element' => 'push',
        'where_clause_elements' => 'elements',
        '_has_no_where_elements' => 'is_empty',
        '_get_where_element' => 'get',
    }, 
);

has '_link' => (
    is => 'bare',
    isa => HashRef,
    default => sub { { } },
    traits  => [qw( Hash )],
    handles => {
        '_set_linked' => 'set',
        '_has_link' => 'exists',
    }    
);


sub where {
    my $self = shift;
    
    # if it is a single argument, it is a boolean (and,or) operator or subgroup (parenthesis)
    if (@_ == 1) {
        my $operator = $_[0];
        
        # do subgroup start
        if ($operator eq '(') {
            my $element = Storm::SQL::Fragment::Where::SubgroupStart->new;
            $self->_add_and_if_needed;
            $self->_add_where_element($element);
        }
        # do subroup end
        elsif ($operator eq ')') {
            my $element = Storm::SQL::Fragment::Where::SubgroupEnd->new;
            $self->_add_where_element($element);
        }
        # otherwise pass on assuming it is a boolean operator
        else {           
            my $element = Storm::SQL::Fragment::Where::Boolean->new($operator);
            $self->_add_where_element($element);
        }
    }
    # otherwise it is a comparison
    else {
        my ($arg1, $operator, @args) = @_;
        
        # perform substitution on arguments
        ( $arg1, @args ) = $self->args_to_sql_objects( $arg1, @args );    
        
        # create the comparison
        my $element = Storm::SQL::Fragment::Where::Comparison->new($arg1, $operator, @args);
        $self->_add_and_if_needed;
        $self->_add_where_element($element);
    }

    return $self;
}

sub and {
    my ( $self, @args ) = @_;
    $self->where( @args ) if @args;
}

sub or {
    my ( $self, @args ) = @_;
    $self->where( 'or' );
    $self->where( @args ) if @args;
}

sub group_start {
    my ( $self ) = @_;
    $self->where( '(' );
}

sub group_end {
    my ( $self ) = @_;
    $self->where( ')' );
}


sub _link {
        my ( $self, $attr, $class ) = @_;
    my $right_col = $class->meta->primary_key->column;
    
    if ( ! $self->_has_link( $attr->name ) ) {
        # create the comparison
        my $column1 = Storm::SQL::Column->new( $self->orm->table( $self->class ) . '.' . $attr->column->name );
        my $column2 = Storm::SQL::Column->new( $self->orm->table( $class ) . '.' . $class->meta->primary_key->column->name );
        my $element = Storm::SQL::Fragment::Where::Comparison->new($column1, '=', $column2);
        $self->_add_and_if_needed;
        $self->_add_where_element($element);
        $self->_set_linked( $attr->name, 1 );
    }
}


sub _where_clause {
    my ( $self, $skip_where ) = @_;
    return if $self->_has_no_where_elements;
    
    my $sql  = '';
    $sql .= 'WHERE ' unless $skip_where;
    $sql .= join q[ ], map { $_->sql } $self->where_clause_elements;
    
    return $sql;
}

sub _add_and_if_needed {
    my ( $self ) = @_;
    # no and needed for the first where clause
    return if ! $self->_get_where_element( -1 );
    
    # last element
    my $last = $self->_get_where_element( -1 );
    
    # no and after  AND, OR, NOT, XOR
    return if $last->isa('Storm::SQL::Fragment::Where::Boolean');
    
    # no and after opening parens
    return if $last->isa('Storm::SQL::Fragment::Where::SubgroupStart');

    $self->where('and');
}



no Moose::Role;
1;


__END__

=pod

=head1 NAME

Storm::Role::Query::HasWhereClause - Role for queries with a WHERE clause

=head1 AUTHOR

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

Modified from code in Dave Rolsky's L<Fey> module.

=head1 COPYRIGHT

    Copyright (c) 2010 Jeffrey Ray Hallock. All rights reserved.
    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut
