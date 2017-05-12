package Persistence::Entity::Query;

use strict;
use warnings;
use vars qw($VERSION);

use Abstract::Meta::Class ':all';
use base 'SQL::Query';

$VERSION = 0.02;

=head1 NAME

Persistence::Entity::Query - Database entity query.

=head1 CLASS HIERARCHY

 SQL::Query
    |
    +----Persistence::Entity::Query

=head1 SYNOPSIS

    my $entity_manager = $class->new(connection_name => 'my_connection');


    $entity_manager->add_entities(SQL::Entity->new(
        name                  => 'emp',
        unique_expression     => 'empno',
        columns               => [
            sql_column(name => 'ename'),
            sql_column(name => 'empno'),
            sql_column(name => 'deptno')
        ],
        indexes => [
            sql_index(name => 'emp_idx1', columns => ['empno'])
        ]
    ));

    package Employee;

    use Abstract::Meta::Class ':all';
    use Persistence::ORM ':all';
    entity 'emp';

    column empno => has('$.no') ;
    column ename => has('$.name');
    column deptno => has('$.deptno');

    my $query = $entity_manager->query(emp => 'Employee');
    $query->set_offset(20);
    $query->set_limit(5);
    my @emp = $query->execute();
   # do stuff $emp[0]->name

    my $query = $entity_manager->query('emp');
    $query->set_offset(20);
    $query->set_limit(5);
    my @emp = $query->execute();
    # do stuff $emp[0]->{ename}

=head1 DESCRIPTION

    Represents database query based on entity definition.

=head1 EXPORT

None

=head2 ATTRIBUTES

=over

=item name

=cut

has '$.name' => (required => 1);


=item cursor_callback

=cut

has '&.cursor_callback' => (required => 1);


=item condition_converter_callback

=cut

has '&.condition_converter_callback' => (required => 1);

=back

=head2 METHODS

=over

=item execute

=cut

sub execute {
    my ($self, $requested_columns, @args) = @_;
    my $condition_converter_callback =  $self->condition_converter_callback;
    my $condition = $condition_converter_callback->(@args);
    my ($sql, $bind_variables) = $self->query($requested_columns, $condition);
    my $cursor_callback = $self->cursor_callback;
    $cursor_callback->($self, $sql, $bind_variables);
}


=item query_setup

=cut

sub query_setup {
    my $self = shift;
    $self->_entity_limit_wrapper->query_setup(@_);
}

1;    

__END__

=back

=head1 SEE ALSO

L<SQL::Query>
L<Persistence::Entity>

=head1 COPYRIGHT AND LICENSE

The Persistence::Entity::Query module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut

1;
