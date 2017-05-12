package RDF::Trine::Parser::OwlFn::Grammar;

use Parse::RecDescent;

our $VERSION = '0.001';

exit(__PACKAGE__->main) unless caller;

sub main
{
	(my $package = shift) =~ s/::([^:]+)$/::Compiled/;
	local $::RD_HINT = 1;
	Parse::RecDescent->Precompile(&grammar, $package);
	return 0;
}

sub new
{
	return Parse::RecDescent->new(&grammar);
}

sub grammar
{
	local $/;
	return <DATA>;
}

{{{ # experiments with prefixes
	
my $this_does_not_work = q{
# Definitions from SPARQL

PN_CHARS_BASE:  <skip:''> /([A-Z]|[a-z]|[\x{00C0}-\x{00D6}]|[\x{00D8}-\x{00F6}]|[\x{00F8}-\x{02FF}]|[\x{0370}-\x{037D}]|[\x{037F}-\x{1FFF}]|[\x{200C}-\x{200D}]|[\x{2070}-\x{218F}]|[\x{2C00}-\x{2FEF}]|[\x{3001}-\x{D7FF}]|[\x{F900}-\x{FDCF}]|[\x{FDF0}-\x{FFFD}]|[\x{10000}-\x{EFFFF}])/
PN_CHARS_U:     <skip:''> PN_CHARS_BASE | '_'
PN_CHARS:       <skip:''> PN_CHARS_U | /-|[0-9]|\x{00B7}|[\x{0300}-\x{036F}]|[\x{203F}-\x{2040}]/;
PN_PREFIX:      <skip:''> PN_CHARS_BASE PN_PREFIX_TAIL(?)
	{
		$return = $item{PN_CHARS_BASE};
		if (ref $item{'PN_PREFIX_TAIL(?)'} eq 'ARRAY')
		{
			$return .= $item{'PN_PREFIX_TAIL(?)'}->[0];
		}
		1;
	}
PN_PREFIX_TAIL: <skip:''> PN_PREFIX_MID(s?) PN_CHARS
	{
		if (ref $item{'PN_PREFIX_MID(s?)'} eq 'ARRAY')
		{
			$return = join '', @{$item{'PN_PREFIX_MID(s?)'}};
		}
		$return .= $item{PN_CHARS};
		1;
	}
PN_PREFIX_MID:  <skip:''> PN_CHARS | '.'
PN_LOCAL:       <skip:''> PN_LOCAL_START PN_LOCAL_TAIL(?)
	{
		$return = $item{PN_LOCAL_START};
		if (ref $item{'PN_LOCAL_TAIL(?)'} eq 'ARRAY')
		{
			$return .= $item{'PN_LOCAL_TAIL(?)'}->[0];
		}
		1;
	}
PN_LOCAL_START: <skip:''> PN_CHARS_U | /[0-9]/
PN_LOCAL_TAIL:  <skip:''> PN_LOCAL_MID(s?) PN_CHARS
	{
		if (ref $item{'PN_LOCAL_MID(s?)'} eq 'ARRAY')
		{
			$return = join '', @{$item{'PN_LOCAL_MID(s?)'}};
		}
		$return .= $item{PN_CHARS};
		1;
	}
PN_LOCAL_MID:   PN_PREFIX_MID
};

my $this_works = q{
# the following are too constrained...
PN_LOCAL:   /[A-Z0-9_]*/i
       { $return = $item{__PATTERN1__}; 1; }
PNAME_NS:   /([A-Z][A-Z0-9_]*)?:/i
       { $return = $item{__PATTERN1__}; 1; }
PNAME_LN:   PNAME_NS <skip:''> PN_LOCAL
       { $return = [ $item{PNAME_NS}, $item{PN_LOCAL} ]; 1; }
};

my $this_might_be_close_enough = q{
# the following are not quite right...
PN_LOCAL:   /(?:[A-Z0-9_]|[\x{00C0}-\x{00D6}]|[\x{00D8}-\x{00F6}]|[\x{00F8}-\x{02FF}]|[\x{0370}-\x{037D}]|[\x{037F}-\x{1FFF}]|[\x{200C}-\x{200D}]|[\x{2070}-\x{218F}]|[\x{2C00}-\x{2FEF}]|[\x{3001}-\x{D7FF}]|[\x{F900}-\x{FDCF}]|[\x{FDF0}-\x{FFFD}]|[\x{10000}-\x{EFFFF}])*/i
       { $return = $item{__PATTERN1__}; 1; }
PNAME_NS:   /(?:[A-Z](?:[A-Z0-9_]|[\x{00C0}-\x{00D6}]|[\x{00D8}-\x{00F6}]|[\x{00F8}-\x{02FF}]|[\x{0370}-\x{037D}]|[\x{037F}-\x{1FFF}]|[\x{200C}-\x{200D}]|[\x{2070}-\x{218F}]|[\x{2C00}-\x{2FEF}]|[\x{3001}-\x{D7FF}]|[\x{F900}-\x{FDCF}]|[\x{FDF0}-\x{FFFD}]|[\x{10000}-\x{EFFFF}])*)?:/i
       { $return = $item{__PATTERN1__}; 1; }
PNAME_LN:   PNAME_NS <skip:''> PN_LOCAL
       { $return = [ $item{PNAME_NS}, $item{PN_LOCAL} ]; 1; }
};

}}}

=head1 NAME

RDF::Trine::Parser::OwlFn::Grammar - provides a Parse::RecDescent grammar for OWL 2.0 Functional Syntax

=head1 DESCRIPTION

This package provides two methods:

=over

=item * C<< grammar >>

Returns the grammar as a string.

=item * C<< new >>

Returns a Parse::RecDescent parser object using the grammar

=back

Additionally, if you run this C<Grammar.pm> module directly at the
command line:

  perl -w Grammar.pm

It will generate a file called C<Compiled.pm> containing a pre-compiled
Parse::RecDescent parser.

=head1 CONFORMANCE

This grammar deviates from the official one in a few places:

=over

=item * QName (a.k.a. CURIE) syntax is slightly broken - in most cases you won't notice it.

=item * CSS-style comments (/* ... */) are allowed.

=item * Unquoted xsd:nonNegativeInteger tokens can be used as literals.

=item * The unquoted tokens 'true' and 'false' can be used as literals.

=item * Multiple C<< Ontology(...) >> instances are allowed in a single file.

=back

=head1 SEE ALSO

L<http://www.w3.org/TR/2009/REC-owl2-syntax-20091027/#Appendix:_Complete_Grammar_.28Normative.29>,
L<http://www.w3.org/TR/2009/REC-owl2-mapping-to-rdf-20091027/#Mapping_from_the_Structural_Specification_to_RDF_Graphs>.

L<RDF::Trine::Parser::OwlFn>.

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


=cut

1;

__DATA__

# Annotation = 1
# OntologyAnnotation = 2
# AnnotationAnnotation = 4

	{
		my $OWL  = RDF::Trine::Namespace->new('http://www.w3.org/2002/07/owl#');
		my $RDFS = RDF::Trine::Namespace->new('http://www.w3.org/2000/01/rdf-schema#');
		my $RDF  = RDF::Trine::Namespace->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#');
		my $XSD  = RDF::Trine::Namespace->new('http://www.w3.org/2001/XMLSchema#');

		my $declaredAnnotations;

		my %Prefixes = (
			'rdf:'   => $RDF,
			'rdfs:'  => $RDFS,
			'xsd:'   => $XSD,
			'owl:'   => $OWL,
			);
		
		sub _list_generator
		{
			my ($h, $items) = @_;
			my ($first, @rest) = @$items;
			return $RDF->nil unless $first;
			my $rv = RDF::Trine::Node::Blank->new;
			$h->($rv, $RDF->first, $first);
			$h->($rv, $RDF->rest, _list_generator($h, \@rest));
			$rv;
		}
		my $list_generator = \&_list_generator;
	}

# Definitions from SPARQL

# the following are not quite right...
PN_LOCAL:   /(?:[A-Z0-9_]|[\x{00C0}-\x{00D6}]|[\x{00D8}-\x{00F6}]|[\x{00F8}-\x{02FF}]|[\x{0370}-\x{037D}]|[\x{037F}-\x{1FFF}]|[\x{200C}-\x{200D}]|[\x{2070}-\x{218F}]|[\x{2C00}-\x{2FEF}]|[\x{3001}-\x{D7FF}]|[\x{F900}-\x{FDCF}]|[\x{FDF0}-\x{FFFD}]|[\x{10000}-\x{EFFFF}])*/i
       { $return = $item{__PATTERN1__}; 1; }
PNAME_NS:   /(?:[A-Z](?:[A-Z0-9_]|[\x{00C0}-\x{00D6}]|[\x{00D8}-\x{00F6}]|[\x{00F8}-\x{02FF}]|[\x{0370}-\x{037D}]|[\x{037F}-\x{1FFF}]|[\x{200C}-\x{200D}]|[\x{2070}-\x{218F}]|[\x{2C00}-\x{2FEF}]|[\x{3001}-\x{D7FF}]|[\x{F900}-\x{FDCF}]|[\x{FDF0}-\x{FFFD}]|[\x{10000}-\x{EFFFF}])*)?:/i
       { $return = $item{__PATTERN1__}; 1; }
PNAME_LN:   PNAME_NS <skip:''> PN_LOCAL
       { $return = [ $item{PNAME_NS}, $item{PN_LOCAL} ]; 1; }


# 13 Appendix: Complete Grammar (Normative)

# 13.1 General Definitions

nonNegativeInteger: /\d+/
	{ $return = $item{__PATTERN1__}; 1; }
quotedString:       '"' /(?:\\\\|\\"|[^\\\\\\"])*/ '"'
	{
		$return = $item{__PATTERN1__};
		$return =~ s/\\([\\\"])/$1/g;
		1;
	}
languageTag:        '@' /[A-Z0-9]{1,8}(?:-[A-Z0-9]{1,8})*/i
	{ $return = $item{__PATTERN1__}; 1; }
nodeID:             '_:' PN_LOCAL
	{ $return = $item{PN_LOCAL}; 1; }

fullIRI:        '<' /[^\s><]*/ '>'
	{ $return = $item{__PATTERN1__}; 1; }
prefixName:     PNAME_NS
	{ $return = $item{PNAME_NS}; 1; }
abbreviatedIRI: PNAME_LN
	{ $return = $item{PNAME_LN}; 1; }
IRI:            fullIRI
	{ $return = RDF::Trine::Node::Resource->new($item{fullIRI}, $thisparser->{BASE_URI}); 1; }
IRI:            abbreviatedIRI
	{
		my ($pfx, $sfx) = @{ $item{abbreviatedIRI} };
		if ($Prefixes{$pfx})
		{
			$return = $Prefixes{$pfx}->uri($sfx);
		}
		else
		{
			warn "Undefined prefix '${pfx}' at line ${thisline}.";
			$return = RDF::Trine::Node::Resource->new($pfx.$sfx);
		}
		1;
	}

ontologyDocument: <skip:qr{\s*(?:/[*].*?[*]/\s*)*(?:#[^\n]*\n\s*)*\s*}> prefixDeclaration(s?) Ontology(s)
	{ $return = \%item; 1; }
prefixDeclaration: 'Prefix' '(' prefixName '=' fullIRI ')'
	{
		if (defined $Prefixes{ $item{prefixName} })
		{
			warn(sprintf("Ignoring attempt to redeclare prefix '%s'.", $item{prefixName}));
		}
		else
		{
			my $u = RDF::Trine::Node::Resource->new($item{fullIRI}, $thisparser->{BASE_URI});
			$Prefixes{ $item{prefixName} } = RDF::Trine::Namespace->new($u->uri);
			$thisparser->{PREFIX}->($item{prefixName}, $item{fullIRI});
		}
		$return = \%item;
		1;
	}
Ontology:          'Ontology' '('
                   versioningIRIs(?)
                   directlyImportsDocuments
                   ontologyAnnotations
                   axioms
                   ')'
	{ 
		my $h   = $thisparser->{TRIPLE};
		my ($ont_iri, $ver_iri) =
			$item{'versioningIRIs(?)'}->[0] && @{ $item{'versioningIRIs(?)'}->[0] }
			? @{ $item{'versioningIRIs(?)'}->[0] }
			: (RDF::Trine::Node::Blank->new);
		$h->($ont_iri, $RDF->type, $OWL->Ontology);
		if (ref $ver_iri)
		{
			$h->($ont_iri, $OWL->versionIRI, $ver_iri);
		}
		foreach my $st (@{ $item{'directlyImportsDocuments'} })
		{
			my $import = $st->bind_variables({ ontology => $ont_iri });
			$h->($import);
		}
		foreach my $ann (@{ $item{'ontologyAnnotations'} })
		{
			my $st = $ann->{template}->bind_variables({ subject => $ont_iri });
			$h->($st, 2);
			
			if (ref $ann->{annotationAnnotations} eq 'ARRAY'
			and @{ $ann->{annotationAnnotations} })
			{
				$thisparser->{ANNOTATE}->($ann->{annotationAnnotations}, $st, 4);
			}
		}
		$return = \%item;
		1;
	}
versioningIRIs:    ontologyIRI versionIRI
	{ $return = [$item{ontologyIRI}, $item{versionIRI}]; 1; }
ontologyIRI:       IRI
	{ $return = $item{IRI}; 1; }
versionIRI:        IRI(?)
	{ $return = $item{'IRI(?)'}->[0]; 1; }
directlyImportsDocuments: importStatement(s?)
	{ $return = $item{'importStatement(s?)'}; 1; }
importStatement:   'Import' '(' IRI ')'
	{
		$return = RDF::Trine::Statement->new(
			RDF::Trine::Node::Variable->new('ontology'),
			$OWL->imports,
			$item{IRI},
			);
		1;
	}
ontologyAnnotations: Annotation(s?)
	{ $return = ref $item{'Annotation(s?)'} eq 'ARRAY' ? $item{'Annotation(s?)'} : []; 1; }
axioms:            Axiom(s?)
	{ $return = \%item; 1; }

Declaration: 'Declaration' '(' axiomAnnotationsD Entity ')'
Entity:      'Class' '(' Class ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$declaredAnnotations,
			$h->($item{Class}, $RDF->type, $OWL->Class),
			);
		$return = $item{Class};
		$declaredAnnotations = undef;
		1;
	}
      |      'Datatype' '(' Datatype ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$declaredAnnotations,
			$h->($item{Datatype}, $RDF->type, $OWL->Datatype),
			);
		$return = $item{Datatype};
		$declaredAnnotations = undef;
		1;
	}
      |      'ObjectProperty' '(' ObjectProperty ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$declaredAnnotations,
			$h->($item{ObjectProperty}, $RDF->type, $OWL->ObjectProperty),
			);
		$return = $item{ObjectProperty};
		$declaredAnnotations = undef;
		1;
	}
      |      'DataProperty' '(' DataProperty ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$declaredAnnotations,
			$h->($item{DataProperty}, $RDF->type, $OWL->DatatypeProperty),
			);
		$return = $item{DataProperty};
		$declaredAnnotations = undef;
		1;
	}
      |      'AnnotationProperty' '(' AnnotationProperty ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$declaredAnnotations,
			$h->($item{AnnotationProperty}, $RDF->type, $OWL->AnnotationProperty),
			);
		$return = $item{AnnotationProperty};
		$declaredAnnotations = undef;
		1;
	}
      |      'NamedIndividual' '(' NamedIndividual ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$declaredAnnotations,
			$h->($item{NamedIndividual}, $RDF->type, $OWL->NamedIndividual),
			);
		$return = $item{NamedIndividual};
		$declaredAnnotations = undef;
		1;
	}

AnnotationSubject: IRI | AnonymousIndividual
AnnotationValue:   AnonymousIndividual | IRI | Literal
axiomAnnotations:  Annotation(s?)
	{ $return = $item{'Annotation(s?)'}; 1; }
axiomAnnotationsD: Annotation(s?)
	{ $declaredAnnotations = $return = $item{'Annotation(s?)'}; 1; }

Annotation:           'Annotation' '(' annotationAnnotations AnnotationProperty AnnotationValue ')'
	{
		$return = {
			template => RDF::Trine::Statement->new(
				RDF::Trine::Node::Variable->new('subject'),
				$item{AnnotationProperty},
				$item{AnnotationValue},
				),
			annotationAnnotations => $item{annotationAnnotations}
			};
		1;
	}
annotationAnnotations: Annotation(s?)
	{ $return = $item{'Annotation(s?)'}; 1; }

AnnotationAxiom: AnnotationAssertion | SubAnnotationPropertyOf | AnnotationPropertyDomain | AnnotationPropertyRange

AnnotationAssertion: 'AnnotationAssertion' '(' axiomAnnotations AnnotationProperty AnnotationSubject AnnotationValue ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{AnnotationSubject}, $item{AnnotationProperty}, $item{AnnotationValue}),
			);
		1;
	}
	
SubAnnotationPropertyOf: 'SubAnnotationPropertyOf' '(' axiomAnnotations subAnnotationProperty superAnnotationProperty ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{subAnnotationProperty}, $RDFS->subPropertyOf, $item{superAnnotationProperty}),
			);
		1;
	}
subAnnotationProperty:   AnnotationProperty
superAnnotationProperty: AnnotationProperty

AnnotationPropertyDomain: 'AnnotationPropertyDomain' '(' axiomAnnotations AnnotationProperty IRI ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{AnnotationProperty}, $RDFS->domain, $item{IRI}),
			);
		1;
	}

AnnotationPropertyRange: 'AnnotationPropertyRange' '(' axiomAnnotations AnnotationProperty IRI ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{AnnotationProperty}, $RDFS->range, $item{IRI}),
			);
		1;
	}

# 13.2 Definitions of OWL 2 Constructs

Class:              IRI
Datatype:           IRI
ObjectProperty:     IRI
DataProperty:       IRI
AnnotationProperty: IRI

Individual: NamedIndividual | AnonymousIndividual

NamedIndividual:     IRI
AnonymousIndividual: nodeID
	{ $return = RDF::Trine::Node::Blank->new($thisparser->{BPREFIX}.$item{nodeID}); 1; }

Literal: typedLiteral | stringLiteralWithLanguage | stringLiteralNoLanguage | numericLiteral | booleanLiteral
	
typedLiteral:              lexicalForm '^^' Datatype
	{
		if ($item{Datatype}->equal($RDF->PlainLiteral))
		{
			my ($lex, $lang) = ($item{lexicalForm} =~ m{^(.*)\@([^@]*)$});
			$return = RDF::Trine::Node::Literal->new($lex, $lang)
		}
		else
		{
			$return = RDF::Trine::Node::Literal->new($item{lexicalForm}, undef, $item{Datatype}->uri);
		}
		1;
	}
lexicalForm:               quotedString
stringLiteralNoLanguage:   quotedString
	{ $return = RDF::Trine::Node::Literal->new($item{quotedString}); 1; }
stringLiteralWithLanguage: quotedString languageTag
	{ $return = RDF::Trine::Node::Literal->new($item{quotedString}, $item{languageTag}); 1; }
numericLiteral:            nonNegativeInteger
	{ $return = RDF::Trine::Node::Literal->new($item{nonNegativeInteger}, undef, $XSD->nonNegativeInteger->uri); 1; }
booleanLiteral:            /(true|false|yes|no)/i
	{
		if ($item{__PATTERN1__} =~ /(true|yes)/i)
			{ $return = RDF::Trine::Node::Literal->new('true', undef, $XSD->boolean->uri); }
		elsif ($item{__PATTERN1__} =~ /(false|no)/i)
			{ $return = RDF::Trine::Node::Literal->new('false', undef, $XSD->boolean->uri); }
		else
			{ die "huh?"; }
		1;
	}

ObjectPropertyExpression: ObjectProperty | InverseObjectProperty

InverseObjectProperty: 'ObjectInverseOf' '(' ObjectProperty ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $OWL->inverseOf, $item{ObjectProperty});
		$return = $x;
		1;
	}
	
DataPropertyExpression: DataProperty

DataRange: Datatype
         | DataIntersectionOf
         | DataUnionOf
         | DataComplementOf
         | DataOneOf
         | DatatypeRestriction

DataIntersectionOf: 'DataIntersectionOf' '(' DataRange(2..) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $list = $list_generator->($h, $item{'DataRange(2..)'});
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $RDFS->Datatype);
		$h->($x, $OWL->intersectionOf, $list);
		$return = $x;
		1;
	}

DataUnionOf: 'DataUnionOf' '(' DataRange(2..) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $list = $list_generator->($h, $item{'DataRange(2..)'});
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $RDFS->Datatype);
		$h->($x, $OWL->unionOf, $list);
		$return = $x;
		1;
	}

DataComplementOf: 'DataComplementOf' '(' DataRange ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $RDFS->Datatype);
		$h->($x, $OWL->datatypeComplementOf, $item{DataRange});
		$return = $x;
		1;
	}

DataOneOf: 'DataOneOf' '(' Literal(2..) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $list = $list_generator->($h, $item{'Literal(2..)'});
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $RDFS->Datatype);
		$h->($x, $OWL->oneOf, $list);
		$return = $x;
		1;
	}

DatatypeRestriction: 'DatatypeRestriction' '(' Datatype dtConstraint(s) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $RDFS->Datatype);
		$h->($x, $OWL->onDatatype, $item{Datatype});
		my @y;
		foreach my $constraint (@{$item{'dtConstraint(s)'}})
		{
			my $y = RDF::Trine::Node::Blank->new;
			$h->($y, @$constraint);
			push @y, $y;
		}
		$h->($x, $OWL->withRestrictions, $list_generator->($h, \@y));
		$return = $x;
		1;
	}

dtConstraint:        constrainingFacet restrictionValue
	{ $return = [ $item{constrainingFacet}, $item{restrictionValue} ]; 1; }
constrainingFacet:   IRI
restrictionValue:    Literal

ClassExpression: Class
               | ObjectIntersectionOf | ObjectUnionOf | ObjectComplementOf
               | ObjectOneOf | ObjectSomeValuesFrom | ObjectAllValuesFrom
               | ObjectHasValue | ObjectHasSelf | ObjectMinCardinality
               | ObjectMaxCardinality | ObjectExactCardinality
               | DataSomeValuesFrom | DataAllValuesFrom | DataHasValue
               | DataMinCardinality | DataMaxCardinality | DataExactCardinality

ObjectIntersectionOf: 'ObjectIntersectionOf' '(' ClassExpression(2..) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $list = $list_generator->($h, $item{'ClassExpression(2..)'});
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->Class);
		$h->($x, $OWL->intersectionOf, $list);
		$return = $x;
		1;
	}

ObjectUnionOf: 'ObjectUnionOf' '(' ClassExpression(2..) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $list = $list_generator->($h, $item{'ClassExpression(2..)'});
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->Class);
		$h->($x, $OWL->unionOf, $list);
		$return = $x;
		1;
	}

ObjectComplementOf: 'ObjectComplementOf' '(' ClassExpression ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->Class);
		$h->($x, $OWL->complementOf, $item{ClassExpression});
		$return = $x;
		1;
	}

ObjectOneOf: 'ObjectOneOf' '(' Individual(s) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $list = $list_generator->($h, $item{'ClassExpression(2..)'});
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->Class);
		$h->($x, $OWL->oneOf, $list);
		$return = $x;
		1;
	}

ObjectSomeValuesFrom: 'ObjectSomeValuesFrom' '(' ObjectPropertyExpression ClassExpression ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->Restriction);
		$h->($x, $OWL->onProperty, $item{ObjectPropertyExpression});
		$h->($x, $OWL->someValuesFrom, $item{ClassExpression});
		$return = $x;
		1;
	}

ObjectAllValuesFrom: 'ObjectAllValuesFrom' '(' ObjectPropertyExpression ClassExpression ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->Restriction);
		$h->($x, $OWL->onProperty, $item{ObjectPropertyExpression});
		$h->($x, $OWL->allValuesFrom, $item{ClassExpression});
		$return = $x;
		1;
	}

ObjectHasValue: 'ObjectHasValue' '(' ObjectPropertyExpression Individual ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->Restriction);
		$h->($x, $OWL->onProperty, $item{ObjectPropertyExpression});
		$h->($x, $OWL->hasValue, $item{Individual});
		$return = $x;
		1;
	}

ObjectHasSelf: 'ObjectHasSelf' '(' ObjectPropertyExpression ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->Restriction);
		$h->($x, $OWL->onProperty, $item{ObjectPropertyExpression});
		$h->($x, $OWL->hasSelf, RDF::Trine::Node::Literal->new('true', undef, $XSD->boolean->uri));
		$return = $x;
		1;
	}

ObjectMinCardinality: 'ObjectMinCardinality' '(' nonNegativeInteger ObjectPropertyExpression ClassExpression(?) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->Restriction);
		$h->($x, $OWL->onProperty, $item{ObjectPropertyExpression});
		$h->($x, $OWL->minCardinality, RDF::Trine::Node::Literal->new($item{nonNegativeInteger}, undef, $XSD->nonNegativeInteger->uri));
		$h->($x, $OWL->onClass, $item{'ClassExpression(?)'}->[0])
			if $item{'ClassExpression(?)'} && @{ $item{'ClassExpression(?)'} };
		$return = $x;
		1;
	}

ObjectMaxCardinality: 'ObjectMaxCardinality' '(' nonNegativeInteger ObjectPropertyExpression ClassExpression(?) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->Restriction);
		$h->($x, $OWL->onProperty, $item{ObjectPropertyExpression});
		$h->($x, $OWL->maxCardinality, RDF::Trine::Node::Literal->new($item{nonNegativeInteger}, undef, $XSD->nonNegativeInteger->uri));
		$h->($x, $OWL->onClass, $item{'ClassExpression(?)'}->[0])
			if $item{'ClassExpression(?)'} && @{ $item{'ClassExpression(?)'} };
		$return = $x;
		1;
	}

ObjectExactCardinality: 'ObjectExactCardinality' '(' nonNegativeInteger ObjectPropertyExpression ClassExpression(?) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->Restriction);
		$h->($x, $OWL->onProperty, $item{ObjectPropertyExpression});
		$h->($x, $OWL->cardinality, RDF::Trine::Node::Literal->new($item{nonNegativeInteger}, undef, $XSD->nonNegativeInteger->uri));
		$h->($x, $OWL->onClass, $item{'ClassExpression(?)'}->[0])
			if $item{'ClassExpression(?)'} && @{ $item{'ClassExpression(?)'} };
		$return = $x;
		1;
	}

DataSomeValuesFrom: 'DataSomeValuesFrom' '(' DataPropertyExpression DataRange ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->Restriction);
		$h->($x, $OWL->onProperty, $item{DataPropertyExpression});
		$h->($x, $OWL->someValuesFrom, $item{DataRange});
		$return = $x;
		1;
	}

DataSomeValuesFrom: 'DataSomeValuesFrom' '(' DataPropertyExpression(2..) DataRange ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->Restriction);
		$h->(
			$x,
			$OWL->onProperties,
			$list_generator->($h, $item{'DataPropertyExpression(2)'}),
			);
		$h->($x, $OWL->someValuesFrom, $item{DataRange});
		$return = $x;
		1;
	}

DataAllValuesFrom: 'DataAllValuesFrom' '(' DataPropertyExpression DataRange ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->Restriction);
		$h->($x, $OWL->onProperty, $item{DataPropertyExpression});
		$h->($x, $OWL->allValuesFrom, $item{DataRange});
		$return = $x;
		1;
	}

DataAllValuesFrom: 'DataAllValuesFrom' '(' DataPropertyExpression(2..) DataRange ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->Restriction);
		$h->(
			$x,
			$OWL->onProperties,
			$list_generator->($h, $item{'DataPropertyExpression(2)'}),
			);
		$h->($x, $OWL->allValuesFrom, $item{DataRange});
		$return = $x;
		1;
	}

DataHasValue: 'DataHasValue' '(' DataPropertyExpression Literal ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->Restriction);
		$h->($x, $OWL->onProperty, $item{DataPropertyExpression});
		$h->($x, $OWL->hasValue, $item{Literal});
		$return = $x;
		1;
	}

DataMinCardinality: 'DataMinCardinality' '(' nonNegativeInteger DataPropertyExpression DataRange(?) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->Restriction);
		$h->($x, $OWL->onProperty, $item{DataPropertyExpression});
		$h->($x, $OWL->minCardinality, RDF::Trine::Node::Literal->new($item{nonNegativeInteger}, undef, $XSD->nonNegativeInteger->uri));
		$h->($x, $OWL->onClass, $item{'ClassExpression(?)'}->[0])
			if $item{'ClassExpression(?)'} && @{ $item{'ClassExpression(?)'} };
		$return = $x;
		1;
	}

DataMaxCardinality: 'DataMaxCardinality' '(' nonNegativeInteger DataPropertyExpression DataRange(?) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->Restriction);
		$h->($x, $OWL->onProperty, $item{DataPropertyExpression});
		$h->($x, $OWL->maxCardinality, RDF::Trine::Node::Literal->new($item{nonNegativeInteger}, undef, $XSD->nonNegativeInteger->uri));
		$h->($x, $OWL->onClass, $item{'ClassExpression(?)'}->[0])
			if $item{'ClassExpression(?)'} && @{ $item{'ClassExpression(?)'} };
		$return = $x;
		1;
	}

DataExactCardinality: 'DataExactCardinality' '(' nonNegativeInteger DataPropertyExpression DataRange(?) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->Restriction);
		$h->($x, $OWL->onProperty, $item{DataPropertyExpression});
		$h->($x, $OWL->cardinality, RDF::Trine::Node::Literal->new($item{nonNegativeInteger}, undef, $XSD->nonNegativeInteger->uri));
		$h->($x, $OWL->onClass, $item{'ClassExpression(?)'}->[0])
			if $item{'ClassExpression(?)'} && @{ $item{'ClassExpression(?)'} };
		$return = $x;
		1;
	}

Axiom: Declaration | ClassAxiom | ObjectPropertyAxiom | DataPropertyAxiom | DatatypeDefinition | HasKey | Assertion | AnnotationAxiom

ClassAxiom: SubClassOf | EquivalentClasses | DisjointClasses | DisjointUnion

SubClassOf:           'SubClassOf' '(' axiomAnnotations subClassExpression superClassExpression ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{subClassExpression}, $RDFS->subClassOf, $item{superClassExpression}),
			);
		1;
	}
subClassExpression:   ClassExpression
superClassExpression: ClassExpression

EquivalentClasses: 'EquivalentClasses' '(' axiomAnnotations ClassExpression(2..) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		foreach my $ce1 (@{ $item{'ClassExpression(2..)'} })
		{
			foreach my $ce2 (@{ $item{'ClassExpression(2..)'} })
			{
				$a->(
					$item{axiomAnnotations},
					$h->($ce1, $OWL->equivalentClass, $ce2),
					);
			}
		}
		1;
	}
	
DisjointClasses: 'DisjointClasses' '(' axiomAnnotations ClassExpression(2) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{'ClassExpression(2)'}->[0], $OWL->disjointWith, $item{'ClassExpression(2)'}->[1]),
			);
		1;
	}

DisjointClasses: 'DisjointClasses' '(' axiomAnnotations ClassExpression(3..) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		my $x = RDF::Trine::Node::Blank->new;
		my $list = $list_generator->($h, $item{'ClassExpression(3..)'});
		$h->($x, $RDF->type, $OWL->AllDisjointClasses);
		$h->($x, $OWL->members, $list);
		$a->($item{axiomAnnotations}, $x);
		1;
	}

DisjointUnion: 'DisjointUnion' '(' axiomAnnotations Class disjointClassExpressions ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		my $list = $list_generator->($h, $item{disjointClassExpressions});
		$a->(
			$item{axiomAnnotations},
			$h->($item{Class}, $OWL->disjointUnionOf, $list),
			);
		1;
	}
disjointClassExpressions: ClassExpression(2..)
	{ $return = $item{'ClassExpression(2..)'}; 1; }

ObjectPropertyAxiom:
    SubObjectPropertyOf | EquivalentObjectProperties |
    DisjointObjectProperties | InverseObjectProperties |
    ObjectPropertyDomain | ObjectPropertyRange |
    FunctionalObjectProperty | InverseFunctionalObjectProperty |
    ReflexiveObjectProperty | IrreflexiveObjectProperty |
    SymmetricObjectProperty | AsymmetricObjectProperty |
    TransitiveObjectProperty

SubObjectPropertyOf:           'SubObjectPropertyOf' '(' axiomAnnotations subObjectPropertyExpression superObjectPropertyExpression ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{subObjectPropertyExpression}, $RDFS->subPropertyOf, $item{superObjectPropertyExpression}),
			);
		1;
	}
SubObjectPropertyOf:           'SubObjectPropertyOf' '(' axiomAnnotations 'ObjectPropertyChain' '(' ObjectPropertyExpression(2..) ')' superObjectPropertyExpression ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		my $list = $list_generator->($h, $item{'ObjectPropertyExpression(2..)'});
		$a->(
			$item{axiomAnnotations},
			$h->($item{superObjectPropertyExpression}, $OWL->propertyChainAxiom, $list),
			);
		1;
	}

subObjectPropertyExpression:   ObjectPropertyExpression
superObjectPropertyExpression: ObjectPropertyExpression

EquivalentObjectProperties: 'EquivalentObjectProperties' '(' axiomAnnotations ObjectPropertyExpression(2..) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		foreach my $ce1 (@{ $item{'ObjectPropertyExpression(2..)'} })
		{
			foreach my $ce2 (@{ $item{'ObjectPropertyExpression(2..)'} })
			{
				$a->(
					$item{axiomAnnotations},
					$h->($ce1, $OWL->equivalentProperty, $ce2),
					);
			}
		}
		1;
	}

DisjointObjectProperties: 'DisjointObjectProperties' '(' axiomAnnotations ObjectPropertyExpression(2) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{'ObjectPropertyExpression(2)'}->[0], $OWL->propertyDisjointWith, $item{'ObjectPropertyExpression(2)'}->[1]),
			);
		1;
	}

DisjointObjectProperties: 'DisjointObjectProperties' '(' axiomAnnotations ObjectPropertyExpression(3..) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		my $x = RDF::Trine::Node::Blank->new;
		my $list = $list_generator->($h, $item{'ObjectPropertyExpression(3..)'});
		$h->($x, $RDF->type, $OWL->AllDisjointProperties);
		$h->($x, $OWL->members, $list);
		$a->($item{axiomAnnotations}, $x);
		1;
	}

ObjectPropertyDomain: 'ObjectPropertyDomain' '(' axiomAnnotations ObjectPropertyExpression ClassExpression ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{ObjectPropertyExpression}, $RDFS->domain, $item{ClassExpression}),
			);
		1;
	}

ObjectPropertyRange: 'ObjectPropertyRange' '(' axiomAnnotations ObjectPropertyExpression ClassExpression ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{ObjectPropertyExpression}, $RDFS->range, $item{ClassExpression}),
			);
		1;
	}

InverseObjectProperties: 'InverseObjectProperties' '(' axiomAnnotations ObjectPropertyExpression(2) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{'ObjectPropertyExpression(2)'}->[0], $OWL->inverseOf, $item{'ObjectPropertyExpression(2)'}->[1]),
			);
		1;
	}

FunctionalObjectProperty: 'FunctionalObjectProperty' '(' axiomAnnotations ObjectPropertyExpression ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{'ObjectPropertyExpression'}, $RDF->type, $OWL->FunctionalProperty),
			);
		1;
	}

InverseFunctionalObjectProperty: 'InverseFunctionalObjectProperty' '(' axiomAnnotations ObjectPropertyExpression ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{'ObjectPropertyExpression'}, $RDF->type, $OWL->InverseFunctionalProperty),
			);
		1;
	}

ReflexiveObjectProperty: 'ReflexiveObjectProperty' '(' axiomAnnotations ObjectPropertyExpression ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{'ObjectPropertyExpression'}, $RDF->type, $OWL->ReflexiveProperty),
			);
		1;
	}

IrreflexiveObjectProperty: 'IrreflexiveObjectProperty' '(' axiomAnnotations ObjectPropertyExpression ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{'ObjectPropertyExpression'}, $RDF->type, $OWL->IrreflexiveProperty),
			);
		1;
	}

SymmetricObjectProperty: 'SymmetricObjectProperty' '(' axiomAnnotations ObjectPropertyExpression ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{'ObjectPropertyExpression'}, $RDF->type, $OWL->SymmetricProperty),
			);
		1;
	}

AsymmetricObjectProperty: 'AsymmetricObjectProperty' '(' axiomAnnotations ObjectPropertyExpression ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{'ObjectPropertyExpression'}, $RDF->type, $OWL->AsymmetricProperty),
			);
		1;
	}

TransitiveObjectProperty: 'TransitiveObjectProperty' '(' axiomAnnotations ObjectPropertyExpression ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{'ObjectPropertyExpression'}, $RDF->type, $OWL->TransitiveProperty),
			);
		1;
	}

DataPropertyAxiom:
    SubDataPropertyOf | EquivalentDataProperties | DisjointDataProperties |
    DataPropertyDomain | DataPropertyRange | FunctionalDataProperty

SubDataPropertyOf:           'SubDataPropertyOf' '(' axiomAnnotations subDataPropertyExpression(2) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{subDataPropertyExpression}, $RDFS->subPropertyOf, $item{superDataPropertyExpression}),
			);
		1;
	}
subDataPropertyExpression:   DataPropertyExpression
superDataPropertyExpression: DataPropertyExpression

EquivalentDataProperties: 'EquivalentDataProperties' '(' axiomAnnotations DataPropertyExpression(2..) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		foreach my $ce1 (@{ $item{'DataPropertyExpression(2..)'} })
		{
			foreach my $ce2 (@{ $item{'DataPropertyExpression(2..)'} })
			{
				$a->(
					$item{axiomAnnotations},
					$h->($ce1, $OWL->equivalentProperty, $ce2),
					);
			}
		}
		1;
	}

DisjointDataProperties: 'DisjointDataProperties' '(' axiomAnnotations DataPropertyExpression(2) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{'DataPropertyExpression(2)'}->[0], $OWL->propertyDisjointWith, $item{'DataPropertyExpression(2)'}->[1]),
			);
		1;
	}

DisjointDataProperties: 'DisjointDataProperties' '(' axiomAnnotations DataPropertyExpression(3..) ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		my $x = RDF::Trine::Node::Blank->new;
		my $list = $list_generator->($h, $item{'DataPropertyExpression(3..)'});
		$h->($x, $RDF->type, $OWL->AllDisjointProperties);
		$h->($x, $OWL->members, $list);
		$a->($item{axiomAnnotations}, $x);
		1;
	}

DataPropertyDomain: 'DataPropertyDomain' '(' axiomAnnotations DataPropertyExpression ClassExpression ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{DataPropertyExpression}, $RDFS->domain, $item{ClassExpression}),
			);
		1;
	}

DataPropertyRange: 'DataPropertyRange' '(' axiomAnnotations DataPropertyExpression DataRange ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{DataPropertyExpression}, $RDFS->range, $item{DataRange}),
			);
		1;
	}

FunctionalDataProperty: 'FunctionalDataProperty' '(' axiomAnnotations DataPropertyExpression ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{DataPropertyExpression}, $RDF->type, $OWL->FunctionalProperty),
			);
		1;
	}

DatatypeDefinition: 'DatatypeDefinition' '(' axiomAnnotations Datatype DataRange ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{Datatype}, $OWL->equivalentClass, $item{DataRange}),
			);
		1;
	}

HasKey: 'HasKey' '(' axiomAnnotations ClassExpression '(' ObjectPropertyExpression(s?) ')' '(' DataPropertyExpression(s?) ')' ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		
		my @list_items;
		push @list_items, @{$item{'ObjectPropertyExpression(s?)'}}
			if ref $item{'ObjectPropertyExpression(s?)'} eq 'ARRAY'
			&& @{ $item{'ObjectPropertyExpression(s?)'} };
		push @list_items, @{$item{'DataPropertyExpression(s?)'}}
			if ref $item{'DataPropertyExpression(s?)'} eq 'ARRAY'
			&& @{ $item{'DataPropertyExpression(s?)'} };
		my $list = $list_generator->($h, \@list_items);
		
		$a->(
			$item{axiomAnnotations},
			$h->($item{ClassExpression}, $OWL->hasKey, $list),
			);
		1;
	}

Assertion:
    SameIndividual | DifferentIndividuals | ClassAssertion |
    ObjectPropertyAssertion | NegativeObjectPropertyAssertion |
    DataPropertyAssertion | NegativeDataPropertyAssertion

sourceIndividual: Individual
targetIndividual: Individual
targetValue:      Literal

SameIndividual:  'SameIndividual' '(' axiomAnnotations sourceIndividual targetIndividual ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{sourceIndividual}, $OWL->sameAs, $item{targetIndividual}),
			);
		1;
	}

DifferentIndividuals: 'DifferentIndividuals' '(' axiomAnnotations sourceIndividual targetIndividual ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{sourceIndividual}, $OWL->differentFrom, $item{targetIndividual}),
			);
		1;
	}
	
DifferentIndividuals: 'DifferentIndividuals' '(' axiomAnnotations Individual(2..) ')'

ClassAssertion:  'ClassAssertion' '(' axiomAnnotations ClassExpression Individual ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{Individual}, $RDF->type, $item{ClassExpression}),
			);
		1;
	}

ObjectPropertyAssertion: 'ObjectPropertyAssertion' '(' axiomAnnotations ObjectPropertyExpression sourceIndividual targetIndividual ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		$a->(
			$item{axiomAnnotations},
			$h->($item{sourceIndividual}, $item{ObjectPropertyExpression}, $item{targetIndividual}),
			);
		1;
	}

NegativeObjectPropertyAssertion: 'NegativeObjectPropertyAssertion' '(' axiomAnnotations ObjectPropertyExpression sourceIndividual targetIndividual ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $a = $thisparser->{ANNOTATE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->NegativePropertyAssertion);
		$h->($x, $OWL->sourceIndividual, $item{sourceIndividual});
		$h->($x, $OWL->assertionProperty, $item{ObjectPropertyExpression});
		$h->($x, $OWL->targetIndividual, $item{targetIndividual});
		$a->($item{axiomAnnotations}, $x);
		1;
	}

DataPropertyAssertion: 'DataPropertyAssertion' '(' axiomAnnotations DataPropertyExpression sourceIndividual targetValue ')'
	{
		my $h = $thisparser->{TRIPLE};
		$h->($item{sourceIndividual}, $item{DataPropertyExpression}, $item{targetValue});
		1;
	}

NegativeDataPropertyAssertion: 'NegativeDataPropertyAssertion' '(' axiomAnnotations DataPropertyExpression sourceIndividual targetValue ')'
	{
		my $h = $thisparser->{TRIPLE};
		my $x = RDF::Trine::Node::Blank->new;
		$h->($x, $RDF->type, $OWL->NegativePropertyAssertion);
		$h->($x, $OWL->sourceIndividual, $item{sourceIndividual});
		$h->($x, $OWL->assertionProperty, $item{DataPropertyExpression});
		$h->($x, $OWL->targetValue, $item{targetValue});
		my $a = $thisparser->{ANNOTATE};
		$a->($item{axiomAnnotations}, $x);
		1;
	}

