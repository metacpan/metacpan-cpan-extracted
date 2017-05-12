package SQL::DMLGenerator;

use strict;
use warnings;
use vars qw($VERSION);

use Abstract::Meta::Class ':all';
use SQL::Entity::Condition;

$VERSION = 0.01;

=head1 NAME

SQL::DMLGenerator - Data Manipulation Language SQL generator.

=cut

=head1 SYNOPSIS

    use SQL::DMLGenerator;

=head1 DESCRIPTION

Represent DML SQL generator.(insert/update/delete)

=head1 EXPORT

None

=head2 METHODS

=over

=item insert

Returns insert sql statements, bind variables as array ref.
Takes entity object, filed values as hash ref

    my ($sql, $bind_variables) = SQL::DMLGenerator->insert($entity, $field_values)

=cut

sub insert {
    my ($class, $entity, $field_values) = @_;
    my @fields = sort keys %$field_values;
    my $sql = sprintf "INSERT INTO %s (%s) VALUES (%s)",
        $entity->name, join(",", @fields), join(",", ("?")x @fields);
    ($sql, [map {$field_values->{$_}} @fields]);
}


=item update

Returns update sql statements, bind variables as array ref.
Takes entity object, filed values as hash ref, condition - that may be hash ref or condition object

    my ($sql, $bind_variables) = SQL::DMLGenerator->update($entity, $field_values, $codition)

=cut

sub update {
    my ($class, $entity, $field_values, $conditions) = @_;
    my @fields = sort keys %$field_values;
    return () unless @fields;
    my $condition = ref($conditions) eq 'SQL::Entity::Condition'
        ? $conditions
        : SQL::Entity::Condition->struct_to_condition($entity->normalise_field_names(%$conditions));
    my $bind_variables = [];
    my $where_clause = $condition->as_string({}, $bind_variables);
    my $sql = sprintf "UPDATE %s SET %s WHERE %s",
        $entity->name,
        join (", ", map { $_ . ' = ?' } @fields),
        $where_clause;
    ($sql, [(map {$field_values->{$_}} @fields), @$bind_variables]);
}


=item delete

Returns delete sql statements, bind variables as array ref.
Takes entity object, filed values as hash ref, condition - that may be hash ref or condition object

    my ($sql, $bind_variables) = SQL::DMLGenerator->delete($entity, $codition);

=cut

sub delete {
    my ($class, $entity, @args) = @_;
    my $condition = @args == 1 
        ? $args[0]
        : SQL::Entity::Condition->struct_to_condition($entity->normalise_field_names(@args));
    my $bind_variables = [];
    my $where_clause = $condition->as_string({}, $bind_variables);    
    my $sql = sprintf "DELETE FROM %s WHERE %s",
        $entity->name,
        $where_clause;
    ($sql, $bind_variables);
}


1;

__END__

=back

=head1 SEE ALSO

L<SQL::Entity>

=head1 COPYRIGHT AND LICENSE

The SQL::DMLGenerator module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut

1;
