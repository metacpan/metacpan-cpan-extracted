package SQL::Query::Limit::PostgreSQL;

use warnings;
use strict;
use vars qw($VERSION);

$VERSION = '0.02';

use Abstract::Meta::Class ':all';
use SQL::Entity::Column ':all';
use SQL::Entity::Condition ':all';
use base 'SQL::Entity';

=head1 NAME

SQL::Query::Limit::PostgreSQL - LIMIT emulation for PostgreSQL database.

=cut  

=head1 NAME

SQL::Query::Limit::PostgreSQL

=head1 SYNOPSIS

    use SQL::Query::Limit::PostgreSQL;

=head1 DESCRIPTION

SQL navigation for PostgreSQL.

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

=item sql_definition

=cut

{
    my %SQL = (
        find_sequence => "SELECT 1 AS has_seq FROM pg_class JOIN  pg_authid ON pg_class.relowner = pg_authid.oid
        WHERE pg_class.relkind = 'S' AND pg_class.relname = ? AND pg_authid.rolname = ?",
    );


=item sql_defintion

Retuns sql defintion.
Takes sql statement name.

=cut

    sub sql_defintion {
        my ($self, $name) = @_;
        $SQL{$name};
    }
}


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
    $the_rownum ||= $self->the_rownum(SQL::Entity::Column->new(name => "nextval('". $self->sequence_name  . "')", id => 'the_rownum'));
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
    my $result_set = $connection->record($self->sql_defintion('find_sequence'), $sequence_name, $connection->username);
    if ($result_set->{has_seq}) {
        $connection->do("SELECT setval('${sequence_name}', 1);") if $result_set->{has_seq};
    } else {
        $connection->do("create temp sequence " . $sequence_name) unless $result_set->{has_seq};
    }
}

1;

__END__

=back

=head1 SEE ALSO

L<SQL::Query>.

=head1 COPYRIGHT AND LICENSE

The SQL::Query::Limit::PostgreSQL module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut