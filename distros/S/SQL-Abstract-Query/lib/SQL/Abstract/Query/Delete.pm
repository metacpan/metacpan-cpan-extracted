package SQL::Abstract::Query::Delete;
{
  $SQL::Abstract::Query::Delete::VERSION = '0.03';
}
use Moose;
use namespace::autoclean;

=head1 NAME

SQL::Abstract::Query::Delete - An object that represents a SQL DELETE.

=head1 SINOPSYS

    use SQL::Abstract::Query;
    my $query = SQL::Abstract::Query->new( $dbh );
    
    # Delete all records from the rental table:
    my ($sql) = $query->delete( 'rental' );
    $dbh->do( $sql );
    
    # Delete all inventory for a particular film:
    my ($sql, @bind_values) = $query->delete( 'inventory', {film_id => $film_id} );
    $dbh->do( $sql, undef, @bind_values );
    
    # Use the OO interface to re-use the query and delete all staff in
    # several stores:
    my $delete = $query->delete( 'staff', {store_id => 'id'} );
    my $sth = $dbh->prepare( $delete->sql() );
    $sth->execute( $delete->values({ id => $store1_id });
    $sth->execute( $delete->values({ id => $store2_id });

=head1 DESCRIPTION

The delete query is a very lightweight wrapper around L<SQL::Abstract>'s delete()
method and provides no additional SQL syntax.

Instances of this class should be created using L<SQL::Abstract::Query/delete>.

This class applies the L<SQL::Abstract::Query::Statement> role.

=cut

with 'SQL::Abstract::Query::Statement';

sub _build_positional_args {
    return ['table', 'where'];
}

sub _build_abstract_result {
    my ($self) = @_;

    my ($sql, @bind_values) = $self->query->abstract->delete(
        $self->table(),
        $self->where(),
    );

    return [$sql, @bind_values];
}

=head1 ARGUMENTS

=head2 table

See L<SQL::Abstract::Query::Statement/Table>.

=cut

has table => (
    is       => 'ro',
    isa      => 'SQL::Abstract::Query::Types::Table',
    required => 1,
);

=head2 where

Optional.  See L<SQL::Abstract::Query::Statement/Where>.

=cut

has where => (
    is => 'ro',
    isa => 'SQL::Abstract::Query::Types::Where',
);

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

