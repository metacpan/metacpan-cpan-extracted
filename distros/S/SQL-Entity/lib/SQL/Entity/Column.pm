package SQL::Entity::Column;

use strict;
use warnings;
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);

$VERSION = '0.02';

use Abstract::Meta::Class ':all';
use base 'Exporter';

@EXPORT_OK = qw(sql_column);
%EXPORT_TAGS = (all => \@EXPORT_OK);

=head1 NAME

SQL::Entity::Column - Entity column abstraction.

=head1 SYNOPSIS

    use SQL::Entity::Column ':all';

    my $column = SQL::Entity::Column->new(name  => 'name');
    or 
    my $column = sql_column(name  => 'name');

=head1 DESCRIPTION

Represents entities column, that maps to the table column, or sql expression.

=head2 EXPORT

None by default.

sql_column  by tag 'all'

=head2 ATTRIBUTES

=over

=item id

Column alias

=cut

has '$.id';


=item name

=cut

has '$.name';


=item table

Table association

=cut

has '$.table' => (associated_class => 'SQL::Entity::Table');

=item entity

Entity association

=cut

has '$.entity' => (associated_class => 'SQL::Entity');


=item expression

Column expression:
f.e. col1 || col2 

=cut

has '$.expression';


=item case_sensitive

=cut

has '$.case_sensitive' => (default => 1);


=item queryable

Flag is column can be use in where caluse

=cut

has '$.queryable' => (default => 1);


=item insertable

=cut

has '$.insertable' => (default => 1);


=item update_allowed

=cut

has '$.updatable' => (default => 1);


=item unique

=cut

has '$.unique';


=back

=head2 METHODS

=over

=item initialise

=cut

sub initialise {
    my ($self) = @_;
    $self->set_id($self->name) unless $self->id;
    if ($self->expression) {
        $self->insertable(0);
        $self->updatable(0);
    }
}


=item as_string

=cut

sub as_string {
    my ($self, $source, $join_methods) = @_;
    my $table = $self->table;
    return $self->subquery_to_string($source, $join_methods)
      if ($table && $source && $table ne $source);
    my $table_alias = $table ?  $table->alias . "." : '';
    my $id = $self->id;
    my $expression = $self->expression;
    my $name = $self->name;
    my $result = ($expression ? "($expression)" : $table_alias . $name);
    $result . ($id && $id ne ($name || '') ? " AS $id": '');
}


=item subquery_to_string

=cut

sub subquery_to_string {
    my ($self, $source, $join_methods) = @_;
    return () unless $self->entity;
    my $table = $self->table;
    my $id = $self->id;
    my $table_alias = $table ?  $table->alias . "." : '';
    my $table_id = $table->id;
    my $relationship = $self->entity->to_one_relationship($table_id);
    my $join_method = $join_methods->{$table_id};
    unless ($join_method) {
        #enforce subquery
        my ($sql, $bind_variable) = $table->query([$id], $relationship->join_condition($self->entity), undef, {$source->id => 'SUBQUERY'});
        
        return "($sql) AS $id";
    } else {
        $self->as_string;
    }
}


=item as_operand

Returns column as condition operand.

=cut

sub as_operand {
    my $self = shift;
    my $table = $self->table;
    my $table_alias = $table ?  $table->alias . "." : '';
    my $case_sensitive = $self->case_sensitive;
    (! $case_sensitive ? 'UPPER(' : '')
      . $table_alias . ($self->name || $self->expression)
      . (! $case_sensitive ? ')' : '');
}

=item sql_column

=cut

sub sql_column {
    __PACKAGE__->new(@_);
}


1;

__END__

=back

=head1 COPYRIGHT

The SQL::Entity::Column module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 SEE ALSO

L<SQL::Entity>
L<SQL::Entity::Table>
L<SQL::Entity::Condition>

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut