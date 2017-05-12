package SQL::Query;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = 0.01;

use Abstract::Meta::Class ':all';
use SQL::Entity::Column ':all';

=head1 NAME

SQL::Query - Sql query generator for database entities.

=head1 SYNOPSIS

    my $entity = SQL::Entity->new(
        name                  => 'emp',
        unique_expression     => 'rowid',
        columns               => [
            sql_column(name => 'ename'),
            sql_column(name => 'empno'),
            sql_column(name => 'deptno')
        ],
        indexes => [
            sql_index(name => 'foo', columns => ['empno', hint => 'INDEX_ASC(emp FORCE_ORDER)'])
        ].
        order_index => 'foo',
    );

    my $query = SQL::Query->new(entity => $entity);
    my ($sql, $bind_variables) = $query->query();

=head1 DESCRIPTION

Generates sql for entity definition,

- navigation feature (limit/offset)

- ad hoc query optimialization  (for where condition uses (subquerties or join dynamically))

Lets into account the following use cases:

    1, Retrieve employers with thier department:
    Physically it requries retrieving N rows starts from X row (offset/limit),
    so assuming that you have to fetch physically only 50 rows at the time
    from a few millions rows subquery will executes 50 times in the outer results.
    It may be faster the the join clause, especially when using single table CBO hint that
    is forcing result order rather then ORDER BY ...

=begin text

    For Oracle you will have:

    SELECT
        t.*,
        (SELECT dname FROM dept d WHERE d.deptno = t.deptno) as dname
    FROM  (
        SELECT /*+ INDEX_ASC(t FORCE_ORDER) */
            t.*,
            ROWNUM as THE_ROWNUM
        FROM
            emp t
        WHERE ROWNUM < 120
    ) t
    WHERE THE_ROWNUM > 100


=end text

    2, Retrieve employers with thier department for departaments 'hr','ho' :

=begin text

    SELECT
        t.*
    FROM  (
        SELECT /*+ INDEX_ASC(FORCE_ORDER) */
            t.*,
            d.dname,
            ROWNUM as THE_ROWNUM
        FROM
            emp t
        JOIN
            dept d ON (d.deptno = t.deptno)
        WHERE d.dname IN ('hr', 'ho')
        AND ROWNUM < 120
    ) t
    WHERE THE_ROWNUM > 100

=end text        

=head2 EXPORT

None.

=head2 ATTRIBUTES

=over

=item limit

=cut

has '$.limit' => (default => '20');


=item offset

=cut

has '$.offset' => (default => '1');


=item dialect

=cut

has '$.dialect' => (default => 'Oracle');


=item entity

=cut

has '$.entity' => (associated_class => 'SQL::Entity');


=item _entity_limit_wrapper

Stores entity object that is wrapped by limit implementation.

=cut


has '$._entity_limit_wrapper';


=back

=head2 METHODS

=over

=item initialise

=cut

sub initialise {
    my ($self) = @_;
    my $class = $self->load_module($self->dialect);
    my $entity_manager;
    my $entity = $self->entity->clone;
    $self->_entity_limit_wrapper(bless $entity, $class);
}




=item query

Returns sql statement and bind variables array ref.
Takes optionally array ref of the requested columns(undef return all columns in projection), condition object,

=cut

sub query {
    my ($self, $requested_columns, $condition) = @_;
    my $wrapper = $self->_entity_limit_wrapper;
    my ($sql, $bind_variables) = $wrapper->query($self->offset, $self->limit, $requested_columns, $condition);
    ($sql, $bind_variables);
}


=item set_sql_template_parameters

=cut

sub set_sql_template_parameters {
    my ($self, $value) = @_;
    $self->_entity_limit_wrapper->set_sql_template_parameters($value);
}

=item order_index

Change order_index for associated entity

=cut

sub order_index {
    my ($self, $index_name) = @_;
    $self->_entity_limit_wrapper->set_order_index($index_name);
}


=item load_module

Loads specyfic limit module wrapper.

=cut

{
    my %loaded_modules = ();
    sub load_module {
        my ($self, $module) = @_;
        my $module_name = __PACKAGE__ . "::Limit::\u$module";
        return $loaded_modules{$module_name} if $loaded_modules{$module_name};
        my $module_to_load =  $module_name;
        $module_to_load =~ s/::/\//g;
        eval { require "${module_to_load}.pm" };
        $loaded_modules{$module_name} = $module_name;
        $module_name;
    }
}


1;

__END__

=back

=head1 SEE ALSO

L<SQL::Entity>
L<SQL::Entity::Column>
L<SQL::Entity::Condition>

=head1 COPYRIGHT AND LICENSE

The SQL::Query module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut