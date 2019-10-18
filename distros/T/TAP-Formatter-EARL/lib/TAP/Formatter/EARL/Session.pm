package TAP::Formatter::EARL::Session;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.001';

use Moo;
use Data::Dumper;

use Types::Standard qw(ConsumerOf);
use Attean;
use Attean::RDF;
use Types::Namespace qw( Namespace NamespaceMap );
use Types::Attean qw(AtteanIRI to_AtteanIRI);


has model => (is => 'ro',
				  required => 1,
				  isa => ConsumerOf['Attean::API::MutableModel']);


has software_uri => (
							is => "ro",
							isa => AtteanIRI,
							required => 1
						);



has ns => (
			  is => "ro",
			  isa => NamespaceMap,
			  required => 1,
			 );

has graph_name => (
						 is => "rw",
						 isa => AtteanIRI,
						 required => 1
						);

has result_prefix =>     (is => "ro", isa => Namespace, coerce => 1, required => 1 );
has assertion_prefix =>  (is => "ro", isa => Namespace, coerce => 1, required => 1 );

sub result {
  my ($self, $result) = @_;
  my $giri = $self->graph_name;
  my $ns = $self->ns;
  if ($result->isa('TAP::Parser::Result::Test')) {
	 my $tiri = to_AtteanIRI($self->result_prefix->iri('test_num_' . $result->number));
	 my $airi = to_AtteanIRI($self->assertion_prefix->iri('test_num_' . $result->number));
	 $self->model->add_quad(quad($airi, to_AtteanIRI($ns->rdf->type), to_AtteanIRI($ns->earl->Assertion), $giri));
	 $self->model->add_quad(quad($airi, to_AtteanIRI($ns->earl->assertedBy), $self->software_uri, $giri));
	 $self->model->add_quad(quad($airi, to_AtteanIRI($ns->earl->result), $tiri, $giri));
	 # TODO: Subject and test properties are metadata given by test
	 $self->model->add_quad(quad($tiri, to_AtteanIRI($ns->rdf->type), to_AtteanIRI($ns->earl->TestResult), $giri));
	 my $outcome = $result->is_ok ? $ns->earl->passed : $ns->earl->failed;
	 if ($result->directive) {
		# Then, the test is either TODO or SKIP, they lack description
		$outcome = $ns->earl->untested;
		$self->model->add_quad(quad($tiri, to_AtteanIRI($ns->earl->info), langliteral($result->directive . ': ' . $result->explanation, 'en'), $giri));
	 } else {
		$self->model->add_quad(quad($tiri, to_AtteanIRI($ns->dc->title), langliteral($result->description, 'en'), $giri));
	 }
	 $self->model->add_quad(quad($tiri, to_AtteanIRI($ns->earl->outcome), to_AtteanIRI($outcome), $giri));
	 return 1;
  }
  return 0;
}

sub close_test {
  return; # No-op for now
}
1;

__END__

=pod

=encoding utf-8

=head1 NAME

TAP::Formatter::EARL::Session - Session implementation for TAP Formatter to EARL

=head1 SYNOPSIS

 use TAP::Formatter::EARL::Session;
 use Attean;
 use Attean::RDF;
 use URI::NamespaceMap;

 TAP::Formatter::EARL::Session->new(
                                    model            => Attean->temporary_model,
                                    software_uri     => iri('http://example.org/script'),
                                    ns               => URI::NamespaceMap->new( [ 'rdf', 'dc', 'earl', 'doap' ] ),
                                    graph_name       => iri('http://example.org/graph'),
                                    result_prefix    => URI::Namespace->new('http://example.org/result#'),
                                    assertion_prefix => URI::Namespace->new('http://example.org/assertion#')
                                   );

=head1 DESCRIPTION

This defines a session for each individual part of the test
result. You would probably not call this directly.


=head2 Attributes

It has a number of attributes, they are all required.

=over

=item * C<< software_uri >>

An L<Attean::IRI> object that identifies the software itself. This URI
will typically be minted by L<TAP::Formatter::EARL> and therefore
passed as to this class as a IRI rather than just a prefix.

=back

The following attributes are passed from L<TAP::Formatter::EARL>, see the documentation there:

=over

=item * C<< model >>

=item * C<< ns >>

=item * C<< graph_name >>

=item * C<< assertion_prefix >>

=item * C<< result_prefix >>

=back

Note that the attributes do not have defaults in this class, but the
implementation of L<TAP::Formatter::EARL> will pass them on.


=head2 Methods

The methods are implementations of methods required by the framework.

=over

=item * C<< result( $result ) >>

A L<TAP::Parser::Result> object will be passed as argument to this
method, and based on its contents, RDF will be added to the model as a
side-effect. Will return true if any statements were added, 0
otherwise. Currently, only subclasses of L<TAP::Parser::Result::Test>
will be formulated as RDF.

=item * C<< close_test >>

No-op for now.

=back


=head1 BUGS

Please report any bugs to
L<https://github.com/kjetilk/p5-tap-formatter-earl/issues>.

=head1 SEE ALSO

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Inrupt Inc.

This is free software, licensed under:

  The MIT (X11) License


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

