package SQL::Query::Limit::MySQL;

use warnings;
use strict;
use vars qw($VERSION);

$VERSION = '0.02';

use Abstract::Meta::Class ':all';
use SQL::Entity::Column ':all';
use SQL::Entity::Condition ':all';
use base 'SQL::Entity';

=head1 NAME

SQL::Query::Limit::MySQL - LIMIT emulation for MySQL database.

=cut

=head1 NAME

SQL::Query::Limit::Oracle

=head1 SYNOPSIS

    use SQL::Query::Limit::MySQL;

=head1 DESCRIPTION

SQL navigation wrapper for MySQL.

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
    my ($sql, $bind_variables) = $self->SUPER::query($requested_columns, $condition);
    $sql = "SELECT " . $self->alias . ".*," . $self->the_rownum_column->as_string
    . "\nFROM (\n" . $sql . ") " . $self->alias
    . "\nLIMIT ? OFFSET ?";
    push @$bind_variables, $limit, ($offset - 1);
    ($sql, $bind_variables);
}

   
=item the_rownum_column

=cut

sub the_rownum_column {
    my ($self) = @_;
    my $the_rownum = $self->the_rownum;
    $the_rownum ||= $self->the_rownum(SQL::Entity::Column->new(name => '@rownum = @rownum + 1', id => 'the_rownum'));
}


=item sequence_name

=cut

sub sequence_name {
    'rownum';
}


=item query_setup

TODO. Improve collision in threads,
- add ower to PLSQL

=cut

sub query_setup {
    my ($self, $connection) = @_;
    my $sequence_name = $self->sequence_name;
    $connection->do('SET @rownum = 1;');
}




1;

__END__

=back

=head1 SEE ALSO

L<SQL::Query>.

=head1 COPYRIGHT AND LICENSE

The SQL::Query::Limit::MySQL module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut