package RDF::Helper::RDFRedland::Query;
use Moose;
use RDF::Redland::Query;

has [qw(query_string query_lang)] => (
    isa      => 'Str',
    is       => 'ro',
    required => 1
);

has model => ( is => 'ro', required => 1 );

has query => (
    isa     => 'RDF::Redland::Query',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_query',
    handles => { _execute => 'execute' }
);

sub _build_query {
    my $self = shift;
    RDF::Redland::Query->new( $self->query_string, undef, undef,
        $self->query_lang );
}

has results => (
    is        => 'ro',
    lazy      => 1,
    predicate => 'has_results',
    clearer   => '_clear_results',
    default   => sub { shift->execute },
);

sub execute {
    my ($self, $model) = @_;
    $self->_execute( $model || $self->model );
}

sub BUILDARGS {
    my $class = shift;
    my ( $query_string, $query_lang, $model ) = @_;
    return {
        query_string => $query_string,
        query_lang   => $query_lang,
        model        => $model
    };
}

sub selectrow_hashref {
    my $self = shift;
    $self->execute unless $self->has_results;

    if ( $self->results->finished ) {
        $self->_clear_results;
        return;
    }

    my $found_data = {};
    for ( my $i = 0 ; $i < $self->results->bindings_count() ; $i++ ) {
        my $node = $self->results->binding_value($i);
        my $value =
          $node->is_literal ? $node->literal_value : $node->uri->as_string;
        my $key = $self->results->binding_name($i);
        $found_data->{$key} = $value;
    }
    $self->results->next_result;
    return $found_data;
}

sub selectrow_arrayref {
    my $self = shift;
    unless ( defined( $self->results ) ) {
        $self->execute;
    }

    if ( $self->results->finished ) {
        $self->_clear_results;
        return;
    }

    my $found_data = [];
    for ( my $i = 0 ; $i < $self->results->bindings_count() ; $i++ ) {
        my $node = $self->results->binding_value($i);
        my $value =
          $node->is_literal ? $node->literal_value : $node->uri->as_string;
        push @{$found_data}, $value;
    }
    $self->results->next_result;
    return $found_data;
}

1;

__END__

=head1 NAME

RDF::Helper::RDFReland::Query - Perlish convenience extension for RDF::Redland::Query

=head1 SYNOPSIS

  my $model = RDF::Redland::Model->new( 
      RDF::Redland::Storage->new( %storage_options )
  );

  my $rdf = RDF::Helper->new(
    Namespaces => \%namespaces,
    BaseURI => 'http://domain/NS/2004/09/03-url#'
  );
  
  my $q_obj = $rdf->new_query( $sparql_text, 'sparql' );
  
  # arrays
  while ( my $row = $q_obj->selectrow_arrayref ) {
      # $row is an array reference.
  }

  # hashes
  while ( my $row = $q_obj->selectrow_hashref ) {
      # $row is a hash reference.
  }

=head1 DESCRIPTION

RDF::Helper::RDFRedland::Query is the object retuned from RDF::Helper's new_query() method when using RDF::Redland as the base interface class. This object provides everything that an instance of RDF::Redland::Query offers, plus the convenience methods  detailed below.

=head1 METHODS

=head2 selectrow_arrayref

Returns each row as a Perl array references. The order of the array's indices will correspond to the order of the variable bindings in the query.

=head2 selectrow_hashref

Returns each row as a Perl hash references. The keys in the hash will have the same names as the variable bindings in the query.

=head1 AUTHOR

Kip Hampton, khampton@totalcinema.com

=head1 COPYRIGHT

Copyright (c) 2004 Kip Hampton.  
=head1 LICENSE

This module is free sofrware; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<RDF::Helper> L<RDF::Redland::Query>.

=cut

