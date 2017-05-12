package SQL::Entity::Index;

use strict;
use warnings;
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);

$VERSION = 0.01;

use base 'Exporter';
use Abstract::Meta::Class ':all';

@EXPORT_OK = qw(sql_index);
%EXPORT_TAGS = (all => \@EXPORT_OK);

=head1 NAME

SQL::Entity::Index - Entity index abstraction.

=cut  

=head1 SYNOPSIS

    use SQL::Entity::Index;

    my $index = SQL::Entity::Index->new(
        name    => 'idx_empno',
        columns => ['empno'],
        hint    => ' INDEX_ASC( emp empno ) '
    );

=head1 DESCRIPTION

    Represents index, that force resultset order by either generating ORDER BY sql fragment,
    or by adding hint sql fragement (Oracle, MySQL)


    my $entity = SQL::Entity->new(
        name                  => 'emp',
        primary_key           => ['empno'],
        unique_expression     => 'rowid',
        columns               => [
            sql_column(name => 'ename'),
            sql_column(name => 'empno'),
            sql_column(name => 'deptno')
        ],
        indexes => [
            sql_index(name => 'idx_emp_empno', columns => ['empno'], hint => 'INDEX_ASC(emp idx_emp_empno)'),
            sql_index(name => 'idx_emp_ename', columns => ['ename']),
        ],
        order_index => 'idx_emp_ename'
    );


    my ($sql, $bind_variables) = $query->query();
    will return
    SELECT emp.*
    FROM (
    SELECT /*+ INDEX_ASC(emp idx_emp_ename) */ ROWNUM AS the_rownum,
      emp.rowid AS the_rowid,
      emp.deptno,
      emp.ename,
      emp.empno
    FROM emp
    WHERE ROWNUM < ?) emp
    WHERE the_rownum >=

=head1 EXPORT

sql_index by 'all' tag.

=head2 ATTRIBUTES

=over

=item name

=cut

has '$.name' => (required => 1);


=item order_by_cluase

order_by_cluase => 'empno desc, ename asc' 

=cut

has '$.order_by_cluase';

=item columns

=cut

has '@.columns';


=item hint

Cost base optymizer hitn (Oracle, MySQL)

#TODO add dybnamic hint based on condition objects

=cut

has '$.hint';

=back

=head2 METHODS

=over

=item sql_index

Creates a new instance of the SQL::Entity::Index

=cut

sub sql_index {
    __PACKAGE__->new(@_);
}


=item order_by_operand

Returns sql fragment operand to ORDER BY cluase

=cut

sub order_by_operand {
    my ($self, $entity) = @_;
    my @columns = $self->columns;
    my $order_by_cluase = $self->order_by_cluase;
    $order_by_cluase ? $order_by_cluase : (join ",",@columns);
}

1;    

__END__

=back

=head1 SEE ALSO

L<SQL::Entity>
L<SQL::Entity::Column>

=head1 COPYRIGHT AND LICENSE

The SQL::Entity::Index module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut

1;
