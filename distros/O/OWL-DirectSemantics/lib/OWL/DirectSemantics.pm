package OWL::DirectSemantics;

BEGIN {
	$OWL::DirectSemantics::AUTHORITY = 'cpan:TOBYINK';
	$OWL::DirectSemantics::VERSION   = '0.001';
};

use 5.008;

use RDF::Trine '0.133';
use RDF::Trine::Serializer::OwlFn;
use OWL::DirectSemantics::Element;
use OWL::DirectSemantics::Translator;
use OWL::DirectSemantics::Writer;
use Module::Pluggable
	search_path => 'OWL::DirectSemantics::Element',
	sub_name    => 'element_modules',
	require     => 1,
	;
use Module::Pluggable
	search_path => 'OWL::DirectSemantics::TraitFor::Element',
	sub_name    => 'element_traits',
	require     => 1,
	;
use Scalar::Util qw[];

BEGIN
{
	OWL::DirectSemantics->element_traits;
	OWL::DirectSemantics->element_modules;
}

unless(RDF::Trine::Model->can('remove_list'))
{
	# Patch current versions of Trine with remove_list
	*{'RDF::Trine::Model::remove_list'} = sub
	{
		my $self = shift;
		my $head = shift;
		my $rdf  = RDF::Trine::Namespace->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#');
		my %args = @_;
		my %seen;
		
		while (Scalar::Util::blessed($head) and not($head->isa('RDF::Trine::Node::Resource') and $head->uri_value eq $rdf->nil->uri_value)) {
			if ($seen{ $head->as_string }++) {
				throw RDF::Trine::Error -text => "Loop found during rdf:List traversal";
			}
			my $stream = $self->get_statements($head, undef, undef);
			my %statements;
			while (my $st = $stream->next) {
				my $statement_type = {
					$rdf->first->uri  => 'rdf:first',
					$rdf->rest->uri   => 'rdf:rest',
					$rdf->type->uri   => 'rdf:type',
					}->{$st->predicate->uri} || 'other';
				$statement_type = 'other'
					if $statement_type eq 'rdf:type' && !$st->object->equal($rdf->List);
				push @{$statements{$statement_type}}, $st;
			}
			if ($args{orphan_check}) {
				return $head if defined $statements{other} && scalar(@{ $statements{other} }) > 0;
				return $head if $self->count_statements(undef, undef, $head) > 0;
			}
			unless (scalar(@{ $statements{'rdf:first'} })==1 and scalar(@{ $statements{'rdf:rest'} })==1) {
				throw RDF::Trine::Error -text => "Invalid structure found during rdf:List traversal";
			}
			$self->remove_statement($_)
				foreach (@{$statements{'rdf:first'}}, @{$statements{'rdf:rest'}}, @{$statements{'rdf:type'}});
			
			$head = $statements{'rdf:rest'}->[0]->object;
		}
		
		return;
	}
}

1;

=head1 NAME

OWL::DirectSemantics - representation of the direct semantics of OWL2

=head1 SYNOPSIS

  use RDF::Trine;
  my $model = RDF::Trine::Model->temporary_model;
  RDF::Trine::Mode->parse_url_into_model($url, $model);
  
  use OWL::DirectSemantics;
  my $translator = OWL::DirectSemantics::Translator->new;
  my $ontology   = $translator->translate($model);
  
  foreach my $ax ($ontology->axioms)
  {
    if ($ax->element_name eq 'ClassAssertion')
    {
      printf("%s is of type %s.\n", $ax->node, $ax->class);
    }
  }
  
  print "The following data couldn't be translated to OWL:\n";
  print RDF::Trine::Serializer
    ->new('ntriples')
    ->serialize_model_to_string($model);

=head1 DESCRIPTION

This distribution provides a basic framework for representing the OWL 2 direct semantics
model, and a translator to build that model from an RDF-based model.

=head1 SEE ALSO

L<OWL::DirectSemantics::Translator>,
L<OWL::DirectSemantics::Element>,
L<RDF::Trine::Serializer::OwlFn>.

L<RDF::Closure>,
L<RDF::Trine::Parser::OwlFn>.

L<RDF::Trine>,
L<RDF::Query>,
L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

