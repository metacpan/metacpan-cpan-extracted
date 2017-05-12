package SQL::Abstract::Query::Insert;
{
  $SQL::Abstract::Query::Insert::VERSION = '0.03';
}
use Moose;
use namespace::autoclean;

=head1 NAME

SQL::Abstract::Query::Insert - An object that represents a SQL INSERT.

=head1 SYNOPSIS

    use SQL::Abstract::Query;
    my $query = SQL::Abstract::Query->new( $dbh );
    
    # Insert a new country:
    my ($sql, @bind_values) = $query->insert( 'country', { country=>$name } );
    $dbh->do( $sql, undef, @bind_values );
    
    # Use the OO interface to re-use the query and insert multiple countries:
    my $insert = $query->insert( 'country', ['country'] );
    my $sth = $dbh->prepare( $insert->sql() );
    $sth->execute( $insert->values({ country => $country1_name });
    $sth->execute( $insert->values({ country => $country2_name });

=head1 DESCRIPTION

The insert query is a very lightweight wrapper around L<SQL::Abstract>'s insert()
method and provides no additional SQL syntax.

Instances of this class should be created using L<SQL::Abstract::Query/insert>.

This class applies the L<SQL::Abstract::Query::Statement> role.

=cut

with 'SQL::Abstract::Query::Statement';

sub _build_positional_args {
    return ['table', 'field_values'];
}

sub _build_abstract_result {
    my ($self) = @_;

    my ($sql, @bind_values) = $self->query->abstract->insert(
        $self->table(),
        $self->field_values(),
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

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

