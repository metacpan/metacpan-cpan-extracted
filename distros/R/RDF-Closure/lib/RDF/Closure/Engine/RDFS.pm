package RDF::Closure::Engine::RDFS;

use 5.008;
use strict;
use utf8;

use Error qw[:try];
use RDF::Trine qw[statement iri];
use RDF::Trine::Namespace qw[RDF RDFS OWL XSD];
use RDF::Closure::AxiomaticTriples qw[$RDFS_Axiomatic_Triples $RDFS_D_Axiomatic_Triples];
use RDF::Closure::DatatypeHandling qw[literals_identical];
use RDF::Closure::Rule::Programmatic;
use RDF::Closure::Rule::StatementMatcher;

use constant {
	TRUE    => 1,
	FALSE   => 0,
	};
use namespace::clean;

use base qw[RDF::Closure::Engine::Core];

our $VERSION = '0.001';

our @OneTimeRules = (

	# Identical literal values
	RDF::Closure::Rule::Programmatic->new(
		sub {
				my ($cl, $rule) = @_;
				my %literals;
				$cl->graph->get_statements->each(sub
				{
					my @nodes = $_[0]->nodes;
					foreach my $n (@nodes[0..2])
					{
						next unless $n->is_literal;
						$literals{ $n->sse } = $n;
					}
				});
				
				foreach my $lit1 (keys %literals)
				{
					foreach my $lit2 (keys %literals)
					{
						if ($lit1 ne $lit2)
						{
							my $l1 = $literals{$lit1};
							my $l2 = $literals{$lit2};
							
							if ($cl->dt_handling->literals_identical($l1, $l2))
							{
								$cl->graph->get_statements(undef, undef, $l1)->each(sub {
									$cl->store_triple($_[0]->subject, $_[0]->predicate, $l2);
								});
								$cl->graph->get_statements(undef, $l1, undef)->each(sub {
									$cl->store_triple($_[0]->subject, $l2, $_[0]->object);
								});
								$cl->graph->get_statements($l1, undef, undef)->each(sub {
									$cl->store_triple($l2, $_[0]->predicate, $_[0]->object);
								});
							}
						}
					}
				}
			},
		'x-rdfs-literal-identity'
		),
		
	# rdfs4
	RDF::Closure::Rule::StatementMatcher->new(
		[],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				$cl->store_triple($s, $RDF->type, $RDFS->Resource); # rdfs4a
				$cl->store_triple($o, $RDF->type, $RDFS->Resource); # rdfs4b
			},
		'rdfs4'
		),

	);

our @Rules = (

	# rdfs1
	RDF::Closure::Rule::StatementMatcher->new(
		[],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				$cl->store_triple($p, $RDF->type, $RDF->Property);
			},
		'rdfs1'
		),

	# rdfs2
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDFS->domain, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				my $iter = $cl->graph->get_statements(undef, $s, undef);
				while (my $st = $iter->next)
				{
					$cl->store_triple($st->subject, $RDF->type, $o);
				}
			},
		'rdfs2'
		),

	# rdfs3
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDFS->range, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				my $iter = $cl->graph->get_statements(undef, $s, undef);
				while (my $st = $iter->next)
				{
					$cl->store_triple($st->object, $RDF->type, $o);
				}
			},
		'rdfs3'
		),

	# rdfs5
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDFS->subPropertyOf, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				my $iter = $cl->graph->get_statements($o, $RDFS->subPropertyOf, undef);
				while (my $st = $iter->next)
				{
					$cl->store_triple($s, $RDFS->subPropertyOf, $st->object);
				}
			},
		'rdfs5'
		),

	# rdfs6
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDFS->type, $RDF->Property],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				$cl->store_triple($s, $RDFS->subPropertyOf, $s);
			},
		'rdfs6'
		),
		
	# rdfs7
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDFS->subPropertyOf, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				my $iter = $cl->graph->get_statements(undef, $s, undef);
				while (my $st = $iter->next)
				{
					$cl->store_triple($st->subject, $o, $st->object);
				}
			},
		'rdfs7'
		),
		
	# rdfs8
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDF->type, $RDFS->Class],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				$cl->store_triple($s, $RDFS->subClassOf, $RDFS->Resource);
			},
		'rdfs8'
		),
		
	# rdfs9
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDFS->subClassOf, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				my $iter = $cl->graph->get_statements(undef, $RDF->type, $s);
				while (my $st = $iter->next)
				{
					$cl->store_triple($st->subject, $RDF->type, $o);
				}
			},
		'rdfs9'
		),
		
	# rdfs10
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDF->type, $RDFS->Class],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				$cl->store_triple($s, $RDFS->subClassOf, $s);
			},
		'rdfs10'
		),
	
	# rdfs11
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDFS->subClassOf, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				my $iter = $cl->graph->get_statements($o, $RDFS->subClassOf, undef);
				while (my $st = $iter->next)
				{
					$cl->store_triple($s, $RDFS->subClassOf, $st->object);
				}
			},
		'rdfs11'
		),
		
	# rdfs12
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDF->type, $RDFS->ContainerMembershipProperty],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				$cl->store_triple($s, $RDFS->subPropertyOf, $RDFS->member);
			},
		'rdfs12'
		),

	# ????
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDF->type, $RDFS->Datatype],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				$cl->store_triple($s, $RDFS->subClassOf, $RDFS->Literal);
			},
		'x-rdfs-literal-dt'
		),
		
	);
	
sub add_axioms
{
	my ($self) = @_;
	
	$self->store_triple(statement($_->nodes, $self->{axiom_context}))
		foreach @$RDFS_Axiomatic_Triples;
	
	for my $i (1 .. $self->{IMaxNum}+1)
	{
		my $ci = $RDF->uri(sprintf('_%d', $i));
		$self->store_triple(statement($ci, $RDF->type, $RDF->Property, $self->{axiom_context}));
		$self->store_triple(statement($ci, $RDF->type, $RDFS->ContainerMembershipProperty, $self->{axiom_context}));
		$self->store_triple(statement($ci, $RDFS->domain, $RDFS->Resource, $self->{axiom_context}));
		$self->store_triple(statement($ci, $RDF->range, $RDFS->Resource, $self->{axiom_context}));
	}
}

sub add_daxioms
{
	my ($self) = @_;
	
	$self->store_triple(statement($_->nodes, $self->{daxiom_context}))
		foreach @$RDFS_D_Axiomatic_Triples;
	
	$self->graph->get_statements->each(sub{
		my $st = shift;
		foreach my $node ($st->nodes)
		{
			if ($node->is_literal and $node->has_datatype)
			{
				$self->store_triple(statement(
					$node,
					$RDF->type,
					iri($node->literal_datatype),
					$self->{daxiom_context}
					));
			}
		}
	});
}

sub entailment_regime
{
	return 'http://www.w3.org/ns/entailment/RDFS';
}

1;

=head1 NAME

RDF::Closure::Engine::RDFS - RDF Schema inference

=head1 ANALOGOUS PYTHON

RDFClosure/RDFSClosure.py

=head1 DESCRIPTION

Performs RDFS inference, but not RDFS D-entailment (datatype stuff).

=head1 SEE ALSO

L<RDF::Closure::Engine>.

L<http://www.perlrdf.org/>.

L<http://www.w3.org/TR/2004/REC-rdf-schema-20040210/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2008-2011 Ivan Herman

Copyright 2011-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under any of the following licences:

=over

=item * The Artistic License 1.0 L<http://www.perlfoundation.org/artistic_license_1_0>.

=item * The GNU General Public License Version 1 L<http://www.gnu.org/licenses/old-licenses/gpl-1.0.txt>,
or (at your option) any later version.

=item * The W3C Software Notice and License L<http://www.w3.org/Consortium/Legal/2002/copyright-software-20021231>.

=item * The Clarified Artistic License L<http://www.ncftp.com/ncftp/doc/LICENSE.txt>.

=back


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

