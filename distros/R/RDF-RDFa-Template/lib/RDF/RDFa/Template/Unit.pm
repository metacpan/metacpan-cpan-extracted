package RDF::RDFa::Template::Unit;

use warnings;
use strict;

use Carp;

=head1 NAME

RDF::RDFa::Template::Unit - An individual graph pattern of an RDFa Template

=cut


use RDF::Query::Algebra::BasicGraphPattern;

sub new {
  my ($class, %args) = @_;
  use Data::Dumper;
  my $self = {
	      PATTERN => RDF::Query::Algebra::BasicGraphPattern->new(@{$args{triples}}),
	      ENDPOINT => $args{endpoint},
	      DOC_GRAPH => $args{doc_graph},
	      ITERATOR => {},
	     };

  bless ($self, $class);
  return $self;
}


=head1 SYNOPSIS

This class holds an individual graph pattern of an RDFa Template. This
has several elements, a Basic Graph Pattern, a query endpoint and a
graph name from the RDFa document.

  $doc = RDF::RDFa::Template::Unit->new(triples => \@triples,
                                        endpoint => 'http://dbpedia.org/sparql',
                                        doc_graph => 'http://example.org/graph'



=head1 METHODS

=head2 new

The constructor. Takes three named arguments:

=over

=item C<triples>

An arrayref with L<RDF::Trine::Statement>s, or subclasses thereof.

=item C<endpoint>

A SPARQL endpoint can optionally be set in the constructor.

=item C<doc_graph>

A graph name for the document. TODO: Not used.

=back

=head2 pattern

Will return an L<RDF::Query::Algebra::BasicGraphPattern> object
containing the Basic Graph Pattern of this unit.

=cut

sub pattern {
  my $self = shift;
  return $self->{PATTERN};
}

=head2 endpoint

If no argument is given and the unit contains a SPARQL endpoint, this will
be returned as a string. If a string argument is given, this will be
used to set the endpoint URL.

=cut

sub endpoint {
  my ($self, $endpoint) = @_;
  if ($endpoint) {
    $self->{ENDPOINT} = $endpoint;
  }
  return $self->{ENDPOINT};
}

=head2 results

Used to set and get a L<RDF::Trine::Iterator> object that can be used
to explore the query results for this unit.

To set the iterator, send a L<RDF::Trine::Iterator> object as the only
argument.

If no argument is given, this will return an L<RDF::Trine::Iterator>
object that can be used to explore the query results for this unit, or
an empty hashref if no results are available.

=cut


sub results {
  my ($self, $iterator) = @_;
  if ($iterator) {
    if ($iterator->isa('RDF::Trine::Iterator')) {
      $self->{ITERATOR} = $iterator;
    } else {
      croak "Argument is not a RDF::Trine::Iterator";
    }
  }
  return $self->{ITERATOR};
}


=head1 AUTHOR

Kjetil Kjernsmo, C<< <kjetilk at cpan.org> >>


=head1 COPYRIGHT & LICENSE

Copyright 2010 Kjetil Kjernsmo.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
