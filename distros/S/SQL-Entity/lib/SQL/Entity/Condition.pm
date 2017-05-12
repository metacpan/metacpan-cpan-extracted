package SQL::Entity::Condition;

use strict;
use warnings;
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);

$VERSION = '0.01';

use Carp;
use base 'Exporter';

@EXPORT_OK = qw(
  sql_cond
  sql_and
  sql_or
);
%EXPORT_TAGS = (all => \@EXPORT_OK);


=head1 NAME

SQL::Entity::Condition - Entity SQL Condition abstraction.

=head1 DESCRIPTION

Represents sql condition.

=head1 SYNOPSIS

    use SQL::Entity::Condition ':all';

    #Creates "a = 1" condition
    my $cond = sql_cond('a', '=', 1);

    #Creates "a = 1 AND b > 1 AND c < 1" condition
    my $cond = sql_and( 
        sql_cond('a', '=', 1),
        sql_cond('b', '>', 1),
        sql_cond('c', '<', 1),
    );    

    Creates "a = 1 OR b > 1 OR c < 1" condition
    my $cond = sql_or( 
      sql_cond('a', '=', 1),
      sql_cond('b', '>', 1),
      sql_cond('c', '<', 1),
    );    

    Creates "(a = 1 AND  b = 1) OR c LIKE 1" condition
    my $cond = sql_and(
      sql_cond('a', '=', 1),
      sql_cond('b', '=', 1),
    )->or( 
      sql_cond('c', 'LIKE', 1)
    );

=head2 EXPORT

None by default.
 sql_cond
 sql_and
 sql_or
 by tag 'all'

=head2 ATTRIBUTES

=over

=item operand1

First operand for condition.

=cut

sub operand1 {shift->{operand1}}


=item set_operand1

Sets the first condition operand .

=cut


sub set_operand1 {
    my ($self, $value) = @_;
    $self->{operand1} = $value;
}


=item operator

Operator

=cut

sub operator {shift->{operator}}


=item operand2

Second operand for condition.

=cut

sub operand2 {shift->{operand2}}


=item set_operand2

Sets the secound condition operand .

=cut

sub set_operand2 {
    my ($self, $value) = @_;
    $self->{operand2} = $value;
}


=item relation

Relation between compsite condition.

=cut

sub relation {
    my ($self, $value) = @_;
    $self->{relation} = $value if defined $value;
    $self->{relation};
}


=item conditions

Association to composie condition

=cut

sub conditions {
    my ($self) = @_;
    $self->{conditions} ||= [];
}



=back

=head2 METHOD

=over

=item new

=cut

{
    my @attributes = qw(operand1 operator operand2 relation conditions);
    sub new {
        my ($class, %args) = @_;
        for my $attribute (keys %args) {
            confess "inknown attribute: $attribute" unless grep { $attribute  eq $_} @attributes;
        }
        bless {%args}, $class;
    }


=item condition_iterator

=cut

    my $dynamic_condition = __PACKAGE__->new;
    sub condition_iterator {
        my ($slef) = @_;
        my @conditions = @{$slef->conditions};
        my $i = 0;
        sub  {
            my $result = $conditions[$i++];
            if(ref($result) eq 'HASH') {
                $dynamic_condition->{$_} = $result->{$_} for @attributes;
                $result = $dynamic_condition;
            }
            $result;
        }
    }

}

=item sql_cond( string | SQL::Entity::Column: $operand1, string: $operator, string | SQL::Entity::Column: $operand2)  returns SQL::Entity::Condition

Create simple Condition object.

=cut

sub sql_cond {
    my ($op1, $op, $op2) = @_;
    SQL::Entity::Condition->new( 
      operand1 => $op1,
      operator => $op,
      operand2 => $op2,
    );
}


=item and

Create a composite Condition object with AND relation between current object and
passed in condition list.

=cut

sub and {
    my $self = shift;
    $self->relation('AND')
      unless $self->relation;
    if($self->relation eq 'AND') {
        push @{$self->conditions}, @_;
    } else {
        return sql_composite('AND',$self, @_);
    }
    $self;
}


=item or

Create a composite Condition object with OR relation between current object an
passed in condition list.

=cut

sub or {
    my $self = shift;
    $self->relation('OR')
      unless $self->relation;

    if($self->relation eq 'OR') {
        push @{$self->conditions}, @_;
    } else {
        return sql_composite('OR',$self, @_);
    }
    $self;
}


=item sql_and

Create a composite Condition object with AND relation.

=cut

sub sql_and {
    unshift @_, 'AND';
    &sql_composite;
}


=item sql_or

Create a composite Condition object with OR relation.

=cut

sub sql_or {
     unshift @_, 'OR';
    &sql_composite;
}


=item sql_composite

Create a composite Condition object.

=cut

sub sql_composite {
    my ($relation, @args) = @_;
    my $composite_condition = SQL::Entity::Condition->new( relation => $relation );
    push @{$composite_condition->conditions}, @args;
    $composite_condition;
}



=item as_string

Converts condition to string

=cut

sub as_string {
    my ($self, $columns, $bind_variables, $entity, $join_methods) = @_;
    $columns ||= {};
    my $conditions = $self->conditions;
    my $result;
    my $operand1 = $self->operand1;
    my $operand2 = $self->operand2;
    my $column = '';
    
    if(ref($operand1) eq 'SQL::Entity::Column') {
        $column = $operand1;
        
    } else {
        $column =  $operand1 && $columns->{$operand1} ? $columns->{$operand1} : undef;        
    }
    
    my $case_insensitive = ($column && ! $column->case_sensitive);
    my $subquery = ($column && ref($column) eq 'SQL::Entity::Column::SubQuery') ? 1 : 0;
    $result .= " EXISTS(" if $subquery;
    
    $result .= $operand1
      ? operand($operand1, $columns, undef, $entity, $join_methods, $operand2)
      . ($self->operator ? " " . $self->operator . " ": "")
      . ($case_insensitive ? 'UPPER(' : '')
      . operand($operand2, $columns, $bind_variables, $entity, $join_methods, $operand1)
      . ($case_insensitive ? ')' : '')
      : '';
    $result .= ") " if $subquery;
    
    if(@$conditions) {
        my $relation = $self->relation;
        my $iterator = $self->condition_iterator;
        while(my $condition = $iterator->()) {
            $result .= ($result ? " $relation " : "")
              . ($condition->relation ? "(" : '')
              . $condition->as_string($columns, $bind_variables, $entity, $join_methods)
              . ($condition->relation  ? ")" : "" );
        }
    }
    
    $result;
}


=item operand

Return expression for passed in operand.

=cut

sub operand {
    my ($operand, $columns, $bind_variables, $entity, $join_methods, $reflective_operand) = @_;
    my $result = $operand;
    return '' unless defined $operand;
    
    if (ref($operand) eq 'SQL::Entity::Column') {
        $result = $operand->as_operand;
        $entity->set_relationship_join_method($operand, 'JOIN', $join_methods);
          die "column ". $operand->as_string ." cant be queried " 
          unless $operand->queryable;
            
    } elsif (ref($bind_variables) eq 'ARRAY') {
            if (ref($operand)) {
                push @$bind_variables, @$operand;
                $result = "(" . (join ",", map {'?'} @$operand) . ")";
            } else {
                push @$bind_variables, $operand;
                $result = '?';
            }
    } elsif (ref($bind_variables) eq 'HASH') {
        if (ref($operand)) {
            $result = "(" . (join ",",
                map { (':' . extend_bind_variables($bind_variables, $_, $reflective_operand)) } @$operand) . ")";
            
        } else {
            $result = ':' . extend_bind_variables($bind_variables, $operand, $reflective_operand);
        }
            
    } elsif (my $column = $columns->{$operand}) {
        die "column ". $column->as_string ." cant be queried " 
          unless $column->queryable;
        $entity->set_relationship_join_method($column, 'JOIN', $join_methods);
        $result = $column->as_operand;
        
    } else {
        if(ref($operand) eq 'ARRAY') {
            $result = "(" . join(",", @$operand). ")";
            
        } else {
            $result = $operand;
        }
    }
    $result;
}


=item extend_bind_variables

=cut

sub extend_bind_variables {
    my ($bind_variables, $value, $column, $counter) = @_;
    my $column_name = (ref $column) ? $column->name : $column;
    my $result = $column_name;
    $counter ||= 0;
    if (exists $bind_variables->{$result}) {
        $result = $column_name . ($counter++);
        extend_bind_variables($bind_variables, $value, $column, $counter)
            if (exists $bind_variables->{$result});
    }
    $bind_variables->{$result} = $value;
    $result;
}


=item struct_to_condition

Converts passed in data structure to condition object.
SQL::Entity::Condition->struct_to_condition(a => 1, b => 3);
converts to a = 1 AND b = 3

SQL::Entity::Condition->struct_to_condition(a => 1, b => [1,3]);
converts to a = 1 AND b IN (1,3)

SQL::Entity::Condition->struct_to_condition(a => 1, b => {operator => '!=', operand => 3});
converts to a = 1 AND b != 3

SQL::Entity::Condition->struct_to_condition(a => 1, b => {operator => 'LIKE', operand => "'A%'", relation => 'OR'});
coverts to a = 1 OR b LIKE 'A%'

=cut

sub struct_to_condition {
    my ($class, @args) = @_;
    my $result;
    for (my $i = 0; $i < $#args; $i+=2) {
        my ($operator, $operand, $relation) = convert_extended_operand($args[$i + 1]);
        unless($result) {
            $result = sql_cond($args[$i], $operator, $operand);
        } else {
            $result  = $result->$relation({operand1 => $args[$i], operator => $operator, operand2 => $operand});
        }
    }
    $result;
}



=item convert_extended_operand

Return operator, operand2, relation for passed in operand

=cut

sub convert_extended_operand {
    my ($operand) = @_;
    my $operator = '=';
    my $relation = 'and';
    my $operand_type = ref($operand);
    if($operand_type eq 'ARRAY') {
        $operator = 'IN';
    } elsif($operand_type eq 'HASH') {
        $relation = $operand->{relation} if $operand->{relation};
        $operator = $operand->{operator};
        $operand = $operand->{operand};
    } 
    ($operator, $operand, lc $relation);
}

1;

__END__

=back

=head1 SEE ALSO

L<SQL::Query>
L<SQL::Entity>
L<SQL::Entity::Column>

=head1 COPYRIGHT AND LICENSE

The SQL::Entity::Condition module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut
