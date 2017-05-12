package RDF::Closure::Engine::OWL2Plus;

BEGIN {
	$RDF::Closure::Engine::OWL2Plus::AUTHORITY = 'cpan:TOBYINK';
	$RDF::Closure::Engine::OWL2Plus::VERSION   = '0.001';
}

use 5.008;
use strict;
use utf8;

use RDF::Closure::Engine::RDFS;
use RDF::Closure::RestrictedDatatype;
use RDF::Closure::Rule::StatementMatcher;
use RDF::Closure::DatatypeHandling qw[$XSD $OWL $RDF $RDFS];
use RDF::Closure::XsdDatatypes qw[$OWL_Datatype_Subsumptions];
use RDF::Trine qw[statement iri];
use Number::Fraction;

use base qw[RDF::Closure::Engine::OWL2RL];

our $hasSelfRule = RDF::Closure::Rule::StatementMatcher->new(
	[undef, $OWL->hasSelf, undef],
	sub {
		my ($cl, $st, $rule) = @_;
		my $z = $st->subject;
		$cl->graph->objects($z, $OWL->onProperty)->each(sub{
			my $p = shift;
			$cl->graph->subjects($RDF->type, $z)->each(sub{
				my $y = shift;
				$cl->store_triple($y, $p, $y);
			});
			$cl->graph->get_statements(undef, $p, undef)->each(sub{
				my ($y1, undef, $y2) = (shift)->nodes;
				$cl->store_triple($y1, $RDF->type, $z)
					if $y1->equal($y2);
			});
		});
	},
	'x-hasSelf-1'
	);

our $subsumptionRule = RDF::Closure::Rule::StatementMatcher->new(
	[undef, $RDF->type, undef],
	sub {
		my ($cl, $st, $rule) = @_;
		return unless $st->subject->is_literal;
		
		TYPE: foreach my $r (values %{ $cl->{restricted_datatypes} })
		{
			eval {
				next TYPE unless $st->object->equal($r->base_type);
				next TYPE unless $r->check($st->subject);
				$cl->store_triple($st->subject, $RDF->type, $r->datatype);
			};
		}
	},
	'x-restricted-dt-subsumption-1'
	);

sub one_time_rules
{
	my @rdfs = RDF::Closure::Engine::RDFS->one_time_rules;
	my @owl  = RDF::Closure::Engine::OWL2RL->one_time_rules;
	return (@owl, @rdfs, $subsumptionRule);
}

sub rules
{
	my @rdfs = RDF::Closure::Engine::RDFS->rules;
	my @owl  = RDF::Closure::Engine::OWL2RL->rules;
	return (@rdfs, @owl, $hasSelfRule);
}

sub add_axioms
{
	my ($self) = @_;
	RDF::Closure::Engine::RDFS::add_axioms($self);
	RDF::Closure::Engine::OWL2RL::add_axioms($self);
	$self->store_triple(statement($OWL->hasSelf, $RDF->type, $RDF->Property, $self->{axiom_context}));
	$self->store_triple(statement($OWL->hasSelf, $RDFS->domain, $OWL->Restriction, $self->{axiom_context}));
	$self->store_triple(statement($OWL->hasSelf, $RDFS->range, $RDFS->Resource, $self->{axiom_context}));
	$self->store_triple(statement($OWL->Thing, $OWL->equivalentClass, $RDFS->Resource, $self->{axiom_context}));
	$self->store_triple(statement($OWL->Class, $OWL->equivalentClass, $RDFS->Class, $self->{axiom_context}));
	$self->store_triple(statement($OWL->DataRange, $OWL->equivalentClass, $RDFS->Datatype, $self->{axiom_context}));
	return $self;
}

sub add_daxioms
{
	my ($self) = @_;
	RDF::Closure::Engine::RDFS::add_daxioms($self);
	RDF::Closure::Engine::OWL2RL::add_daxioms($self);
	return $self;
}

sub create_dt_handling
{
	my %mapping = (
		$OWL->rational->uri => sub
			{
				my ($v) = @_;
				my $fraction = Number::Fraction->new($v);
				return RDF::Closure::Engine::OWL2Plus::DatatypeTuple::Rational
					->new("$fraction", $fraction);
			},
		);
	my @ichecks = (
		sub 
		{
			my ($dth, $lit1, $lit2) = @_;
			if ($lit1->[0] eq 'RDF::Closure::DatatypeTuple::Decimal'
			and $lit2->[0] eq 'RDF::Closure::Engine::OWL2Plus::DatatypeTuple::Rational')
			{
				# Convert $lit1->[1] to a fraction.
				my ($whole, $part) = split /\./, $lit1->[1];	
				my $numerator   = $whole.$part;
				my $denominator = '1'.('0' x length $part);
				my $lit1d = Number::Fraction->new($numerator, $denominator);
				
				return 1
					if "$lit1d" eq $lit2->[1];
			}
			return 0;
		},
	);
	
	return RDF::Closure::DatatypeHandling->new(
		force_utc       => 1,
		identity_checks => [ @ichecks ],
		mapping         => { %mapping },
		);
}

sub __init__
{
	my ($self, @args) = @_;
	$self->SUPER::__init__(@args);
	$self->{dt_handling}  = &create_dt_handling;
	$self->{subsumptions} = {%$OWL_Datatype_Subsumptions};
	$self->{restricted_datatypes} = { map { $_->datatype => $_ } RDF::Closure::RestrictedDatatype->extract_from_graph($self->graph, $self->{dt_handling}) };
	foreach my $r (values %{ $self->{restricted_datatypes} })
	{
		$self->{subsumptions}->{ $r->datatype } = [ $r->base_type.'' ];
	}
	return $self;
}

sub entailment_regime
{
	return 'tag:buzzword.org.uk,2011:entailment:owl2plus';
}

1;

package RDF::Closure::Engine::OWL2Plus::DatatypeTuple::Rational;
use base qw[RDF::Closure::DatatypeTuple];
1;

=head1 NAME

RDF::Closure::Engine::OWL2Plus - as much OWLish inference as possible

=head1 ANALOGOUS PYTHON

RDFClosure/OWLRLExtras.py

=head1 DESCRIPTION

Includes all rules from RDFS and OWL2 RL, some additional axioms, plus
support for owl:hasSelf and the owl:rational datatype.

=head1 SEE ALSO

L<RDF::Closure::Engine>.

L<http://www.perlrdf.org/>.

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

