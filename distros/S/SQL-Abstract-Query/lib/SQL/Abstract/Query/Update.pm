package SQL::Abstract::Query::Update;
{
  $SQL::Abstract::Query::Update::VERSION = '0.03';
}
use Moose;
use namespace::autoclean;

=head1 NAME

SQL::Abstract::Query::Update - An object that represents a SQL UPDATE.

=head1 SINOPSYS

    use SQL::Abstract::Query;
    my $query = SQL::Abstract::Query->new( $dbh );
    
    # Disable all existing customers:
    my ($sql, @bind_values) = $query->update( 'customer', { active => 0 } );
    $dbh->do( $sql, undef, @bind_values );
    
    # Disable all customers in a particular store:
    my ($sql, @bind_values) = $query->update(
        'customer',
        { active => 0 },
        { store_id => $store_id },
    );
    $dbh->do( $sql, undef, @bind_values );
    
    # Use the OO interface to re-use the query and disabled all customers
    # in several stores:
    my $update = $query->update( 'customer', {active=>0}, {store_id=>'id'} );
    my $sth = $dbh->prepare( $update->sql() );
    $sth->execute( $update->values({ id => $store1_id });
    $sth->execute( $update->values({ id => $store2_id });

=head1 DESCRIPTION

The update query is a very lightweight wrapper around L<SQL::Abstract>'s update()
method and provides no additional SQL syntax.

Instances of this class should be created using L<SQL::Abstract::Query/update>.

This class applies the L<SQL::Abstract::Query::Statement> role.

=cut

with 'SQL::Abstract::Query::Statement';

sub _build_positional_args {
    return ['table', 'field_values', 'where'];
}

sub _build_abstract_result {
    my ($self) = @_;

    my $abstract = $self->query->abstract();

    my ($sql, @bind_values) = $abstract->update(
        $self->table(),
        $self->field_values(),
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

=head2 field_values

See L<SQL::Abstract::Query::Statement/FieldValues>.

=cut

has field_values => (
    is       => 'ro',
    isa      => 'SQL::Abstract::Query::Types::FieldValues',
    coerce   => 1,
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

