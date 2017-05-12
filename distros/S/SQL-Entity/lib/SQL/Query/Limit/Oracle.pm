package SQL::Query::Limit::Oracle;

use warnings;
use strict;
use vars qw($VERSION);

$VERSION = '0.01';

use Abstract::Meta::Class ':all';
use SQL::Entity::Column ':all';
use SQL::Entity::Condition ':all';
use base 'SQL::Entity';


=head1 NAME

SQL::Query::Limit::Oracle - LIMIT emulation for Oracle database.

=head1 SYNOPSIS

    use SQL::Query::Limit::Oracle;

=head1 DESCRIPTION

    SQL navigation wrapper for Oracle.

=head2 EXPORT

None.

=head2 ATTRIBUTES

=over

=item the_rownum

=cut

has '$.the_rownum';


=back

=head2 METHODS

=over

=item query

=cut

sub query {
    my ($self, $offset, $limit, $requested_columns, $condition) = @_;
    $condition = $self->limit_clause($offset, $limit, $condition);
    my ($sql, $bind_variables) = $self->SUPER::query($requested_columns, $condition);
    $sql = "SELECT " . $self->alias . ".*"
    . "\nFROM (\n" . $sql . ") " . $self->alias
    . "\nWHERE the_rownum >= ?";
    push @$bind_variables, $offset;
    ($sql, $bind_variables);
}


=item limit_clause

=cut

sub limit_clause {
    my ($self, $offset, $limit, $condition) = @_;
    my $result;
    my $to_rownum = $offset + $limit;  
    if($condition) {
        $result = sql_cond('the_rownum', '<', $to_rownum)->and($condition);
    } else {
        $result = sql_cond('the_rownum', '<', $to_rownum);
    }
    $result;
}

    
=item selectable_columns

=cut

sub selectable_columns {
    my ($self, $requested_columns) = @_;
    ($self->the_rownum_column, $self->SUPER::selectable_columns($requested_columns))
}


=item the_rownum_column

=cut

sub the_rownum_column {
    my ($self) = @_;
    my $the_rownum = $self->the_rownum;
    $the_rownum ||= $self->the_rownum(SQL::Entity::Column->new(name => 'ROWNUM', id => 'the_rownum'));
}


=item query_columns

Returns query column for the object.

=cut

sub query_columns {
    my ($self) = @_;
    (the_rownum =>  $self->the_rownum_column, $self->SUPER::query_columns);
}


=item query_setup

=cut

sub query_setup {}


=item order_by_clause

Returns " ORDER BY ..." SQL fragment

=cut

sub order_by_clause {
    my ($self) = @_;
    my $index = $self->index or return "";
    return "" if $index->hint;
    " ORDER BY " . $index->order_by_operand($self);
}


=item select_hint_clause

Return hinst cluase that will be placed as SELECT operand

=cut

sub select_hint_clause {
    my ($self) = @_;
    my $index = $self->index or return "";
    return "" unless $index->hint;
    "/*+ " . $index->hint . " */ ";
}


1;

__END__

=back

=head1 SEE ALSO

L<SQL::Query>.

=head1 COPYRIGHT AND LICENSE

The SQL::Query::Limit::Oracle module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut