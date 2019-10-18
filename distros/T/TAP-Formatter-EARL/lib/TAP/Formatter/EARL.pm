package TAP::Formatter::EARL;

use 5.010001;
use strict;
use warnings;


our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.001';

use Moo;
use Data::Dumper;

use TAP::Formatter::EARL::Session;
use Types::Standard qw(ConsumerOf);
use Types::Namespace qw( Namespace NamespaceMap );
use Attean;
use Attean::RDF;
use Types::Attean qw(AtteanIRI to_AtteanIRI);
use MooX::Attribute::ENV;
use Types::DateTime -all;
use Carp qw(croak);

extends qw(
    TAP::Formatter::Console
);

has model => (is => 'rw',
				  isa => ConsumerOf['Attean::API::MutableModel'],
				  builder => '_build_model');

sub _build_model {
  my $self = shift;
  return Attean->temporary_model;
}

has ns => (
			  is => "ro",
			  isa => NamespaceMap,
			  builder => '_build_ns'
			 );

sub _build_ns {
  my $self = shift;
  return URI::NamespaceMap->new( [ 'rdf', 'dc', 'earl', 'doap' ] );
}

has graph_name => (
						 is => "rw",
						 isa => AtteanIRI,
						 coerce => 1,
						 env_prefix => 'earl',
						 default => sub {'http://example.test/graph'});

has base => (
				 is => "rw",
				 isa => AtteanIRI,
				 coerce => 1,
				 predicate => 'has_base',
				 env_prefix => 'earl'
				);


has _test_time => (
						is => 'ro',
						isa => DateTime,
						coerce  => 1,
						default => sub { return "now" }
					  );

has [qw(software_prefix result_prefix assertion_prefix)] => (
																				 is => "lazy",
																				 isa => Namespace,
																				 coerce => 1,
																				 required => 1,
																				 env_prefix => 'earl'
																				);

sub _build_software_prefix {
  return 'script#';
}

sub _build_result_prefix {
  my $self = shift;
  return 'result/' . $self->_test_time . '#';
}

sub _build_assertion_prefix {
  my $self = shift;
  return 'assertion/' . $self->_test_time . '#';
}




sub open_test {
  my ($self, $script, $parser) = @_;
  my $giri = $self->graph_name;
  my $ns = $self->ns;
  my $siri = to_AtteanIRI($self->software_prefix->iri('script-' . $script));
  $self->model->add_quad(quad($siri, to_AtteanIRI($ns->rdf->type), to_AtteanIRI($ns->earl->Software), $giri));
  $self->model->add_quad(quad($siri, to_AtteanIRI($ns->doap->name), literal($script), $giri));
  # TODO: Add richer metadata, pointer to software, with seeAlso
  #  $self->model->add_quad(quad($siri, to_AtteanIRI($ns->doap->release), blank('rev'), $giri));
  #  $self->model->add_quad(quad(blank('rev'), to_AtteanIRI($ns->doap->revision), literal($VERSION), $giri));

  return TAP::Formatter::EARL::Session->new(model => $self->model,
														  software_uri => $siri,
														  result_prefix => $self->result_prefix,
														  assertion_prefix => $self->assertion_prefix,
														  ns => $self->ns,
														  graph_name => $giri
														 )
}

sub summary {
  my $self = shift;
  my $s = Attean->get_serializer('Turtle')->new(namespaces => $self->ns);
  open(my $fh, ">-:encoding(UTF-8)") || croak "Could not open STDOUT";
  if ($self->has_base) {
	 print $fh '@base <' . $self->base->as_string . "> .\n"; # TODO, the URLs are probably not interpreted as relative
  }
  $s->serialize_iter_to_io( $fh, $self->model->get_quads);
  close $fh;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

TAP::Formatter::EARL - Formatting TAP output using the Evaluation and Report Language

=head1 SYNOPSIS

Use on the command line:

  prove --formatter TAP::Formatter::EARL -l

=head1 DESCRIPTION

This is a formatter for TAP-based test results to output them using
the L<Evaluation and Report
Language|https://www.w3.org/TR/EARL10-Guide/>, which is a vocabulary
based on the Resource Description Framework (RDF) to describe test
results, so that they can be shared, for example as part of an audit.

This module has a number of attributes, but they are all optional, as
they have reasonable defaults. Many of them can be set using
environment variables. It further extends L<TAP::Formatter::Console>.

=head2 Attributes

=over

=item * C<< model >>

An L<Attean> mutable model that will contain the generated RDF
triples. A temporary model is used by default.

=item * C<< ns >>

A L<URI::NamespaceMap> object. This can be used internally in
programming with prefixes, and to abbreviate using the given prefixes
in serializations. It is initialized by default with the prefixes used
internally.

=item * C<< graph_name >>

An L<Attean::IRI> to use as graph name for all triples. In normal
operations, the formatter will not use the graph name, and so the
default is set to C<http://example.test/graph>. Normal coercions
apply.

It can be set using the environment variable C<EARL_GRAPH_NAME>.

=item * C<< base >>

An L<Attean::IRI> to use as the base URI for relative URIs in the
serialized output. The default is no base. Normal coercions apply.

It can be set using the environment variable C<EARL_BASE>.

=item * C<< software_prefix >>,  C<< assertion_prefix >>, C<< result_prefix >>

Prefixes for URIs of the script running the test, the assertion that a
certain result has been found, and the result itself, respectively.

They accept a L<URI::Namespace> object. They have relative URIs as
defaults. These will not be set as a prefix in the serializer. Normal
coercions apply.

They can be set using environment variables, C<EARL_SOFTWARE_PREFIX>,
C<EARL_ASSERTION_PREFIX> and C<EARL_RESULT_PREFIX>, respectively.

=back

=head2 Methods

These methods are specialised implementations of methods in the
superclass L<TAP::Formatter::Base>.

=over

=item * C<< open_test >>

This is called to create a new test session. It first describes the
software used in RDF before calling L<TAP::Formatter::EARL::Session>.

=item * C<< summary >>

Serializes the model to Turtle and prints it to STDOUT.

=back


=head1 TODO

This is a rudimentary first release, it will only make use of data
parsed from each individual test result.

EARL reports can be extended to become a part of an extensive Linked
Data cloud. It can also link to tests as formulated by
e.g. L<Test::FITesque::RDF>.

=head1 BUGS

Please report any bugs to
L<https://github.com/kjetilk/p5-tap-formatter-earl/issues>.

=head1 SEE ALSO

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Inrupt Inc

This is free software, licensed under:

  The MIT (X11) License


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

