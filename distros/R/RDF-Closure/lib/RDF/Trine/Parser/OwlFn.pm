package RDF::Trine::Parser::OwlFn;

use 5.008;
use strict;
use utf8;

use Data::UUID;
#use RDF::Trine;
use RDF::Trine::Namespace qw[RDF RDFS OWL XSD];
use URI;

our @ISA = qw[RDF::Trine::Parser];

our ($ParserClass, $VERSION);

use constant AXIOMATIC  => 0;
use constant ANNOTATION => 1;
use constant ONTOLOGY_ANNOTATION   => 2;
use constant ANNOTATION_ANNOTATION => 4;

BEGIN
{
	$VERSION = '0.001';
	
	# Perl package name
	my $class = __PACKAGE__;
	$RDF::Trine::Parser::parser_names{'owlfn'} = $class;
	
	# Common file extension
	$RDF::Trine::Parser::parser_names{'ofn'}    = $class;
	$RDF::Trine::Parser::file_extensions{'ofn'} = $class;
	$RDF::Trine::Parser::file_extensions{'OFN'} = $class;
	
	# Format URI
	$RDF::Trine::Parser::parser_names{'owlfunctional'} = $class;
	$RDF::Trine::Parser::format_uris{'http://www.w3.org/ns/formats/OWL_Functional'} = $class;
	
	# Media type
	$RDF::Trine::Parser::media_types{'text/owl-functional'} = $class;
	
	$RDF::Trine::Parser::canonical_media_types{$class} = 'text/owl-functional';
	$RDF::Trine::Parser::encodings{$class}             = 'utf8';
}

sub new
{
	my ($class, %args) = @_;
	
	unless ($ParserClass)
	{
		if (eval "use ${class}::Compiled; 1;")
		{
			$ParserClass = "${class}::Compiled";
		}
		elsif (eval "use ${class}::Grammar; 1;")
		{
			$ParserClass = "${class}::Grammar";
		}
	}
	
	return bless {
		ParserClass => $ParserClass,
		Options     => \%args,
		}, $class;
}

sub parse
{
	my ($self, $uri, $text, $handler, %args) = @_;
	
	$self->{PRD} = undef;
	$self->_blank_slate($handler, $args{prefix_handler}||0, $uri);
	die "PRD parser could not be instantiated.\n" unless defined $self->{PRD};
	$self->{PRD}->ontologyDocument(\$text);
	return $text;
}

sub _blank_slate
{
	my ($self, $st_handler, $b_handler, $base_uri) = @_;
	my $parser = $self->{PRD} = $self->{ParserClass}->new;

	$self->{Handler}        = $st_handler || 0;
	$self->{BindingHandler} = $b_handler  || 0;
	$parser->{BASE_URI}     = $base_uri   || undef;

	# Accept a statement from the PRD parser and hand it to the Trine parser.
	$parser->{STATEMENT} = sub
	{
		my ($st, $type) = @_;
		
		unless (($self->{Options}{filter}||0) & $type)
		{
			if (ref $self->{Handler} eq 'CODE')
			{
				$self->{Handler}->($st);
			}
			elsif ($self->{Handler} == 1)
			{
				printf("%s #%d\n", $st->sse, $type);
			}
		}
	};
	
	# Process a statement from the PRD parser.
	$parser->{TRIPLE} = sub
	{
		my ($st, $source);

		if ($_[0]->isa('RDF::Trine::Node'))
		{
			$st     = RDF::Trine::Statement->new(@_[0..2]);
			$source = $_[3];
		}
		else
		{
			$st     = $_[0];
			$source = $_[1];
		}

		$source = AXIOMATIC unless defined $source;

		$parser->{STATEMENT}->($st, $source);
		return $st;
	};
	
	# Process a set of annotations from the PRD parser.
	$parser->{ANNOTATE} = sub
	{
		my ($annotations, $things, $source) = @_;
		$things = [$things] unless ref $things eq 'ARRAY';
		$source = ANNOTATION unless defined $source;
		
		if (ref $annotations eq 'ARRAY' and @$annotations)
		{
			foreach my $st (@$things)
			{
				my $reified = $st->isa('RDF::Trine::Node') ? $st : RDF::Trine::Node::Blank->new;
				my $reification_done = 0;
				
				foreach my $ann (@$annotations)
				{
					unless ($reification_done or $st->isa('RDF::Trine::Node'))
					{
						my $type = ($source==ANNOTATION_ANNOTATION) ? $OWL->Annotation : $OWL->Axiom;
						$parser->{STATEMENT}->(RDF::Trine::Statement->new($reified, $RDF->type, $type), $source);
						$parser->{STATEMENT}->(RDF::Trine::Statement->new($reified, $OWL->annotatedSource, $st->subject), $source);
						$parser->{STATEMENT}->(RDF::Trine::Statement->new($reified, $OWL->annotatedProperty, $st->predicate), $source);
						$parser->{STATEMENT}->(RDF::Trine::Statement->new($reified, $OWL->annotatedTarget, $st->object), $source);
						$reification_done++;
					}
					
					my $x = $ann->{template}->bind_variables({ subject => $reified });
					$parser->{STATEMENT}->($x, $source);
					
					if (ref $ann->{annotationAnnotations} eq 'ARRAY'
					and @{$ann->{annotationAnnotations}})
					{
						$parser->{ANNOTATE}->($ann->{annotationAnnotations}, $x, ANNOTATION_ANNOTATION);
					}
				}
			}
		}
	};
	
	# Accept a prefix binding from the PRD parser.
	$parser->{PREFIX} = sub
	{
		if (ref $self->{BindingHandler} eq 'CODE')
		{
			$self->{BindingHandler}->(@_);
		}
		elsif ($self->{BindingHandler} == 1)
		{
			printf("(binding \"%s\" <%s>)\n", @_);
		}
	};
	
	# The PRD parser needs a blank node prefix.
	$parser->{BPREFIX} = Data::UUID->new->create_str;
	$parser->{BPREFIX} =~ s/-//g;
	
	return $self;
}

sub test
{
	local $/ = undef;
	my $base     = 'http://rdf.example.com/ontologies/family_guy#';
	my $document = <DATA>;
	my $model    = RDF::Trine::Model->temporary_model;
	my $parser   = __PACKAGE__->new;
	my $ns       = { rdf => $RDF->uri->uri, rdfs => $RDFS->uri->uri, owl => $OWL->uri->uri, xsd => $XSD->uri->uri, ''=>$base };
	my $turtle   = RDF::Trine::Serializer->new(
		'Turtle',
		namespaces => $ns,
		);
	my $r = $parser->parse_into_model($base, $document, $model);
	print $turtle->serialize_model_to_string($model);
	0;
}

exit(__PACKAGE__->test)
	unless caller;

1;

=head1 NAME

RDF::Trine::Parser::OwlFn - OWL Functional Syntax Parser

=head1 SYNOPSIS

	use RDF::Trine::Parser;
	my $parser = RDF::Trine::Parser->new('owlfn');
	$parser->parse_into_model($base_uri, $data, $model);

=head1 DESCRIPTION

=head2 Methods

Beyond the methods documented below, this class inherits methods from
the L<RDF::Trine::Parser> class.

=over

=item C<< new(\%options) >>

The only option supported is C<filter> which can be used to tell the parser
to ignore certain potentially boring triples.

  $flt = RDF::Trine::Parser::OwlFn::ANNOTATION
       + RDF::Trine::Parser::OwlFn::ANNOTATION_ANNOTATION;
  $parser = RDF::Trine::Parser->new('owlfn', filter=>$flt);

The following constants are defined for filtering purposes:

=over

=item * C<ANNOTATION> - axiom annotations

=item * C<ONTOLOGY_ANNOTATION> - ontology annotations

=item * C<ANNOTATION_ANNOTATION> - annotation annotations

=back

=back

The usual C<< parse_* >> methods accept an argument C<prefix_handler>
which can take a coderef which is called every time a prefix is
defined by the ontology being parsed. The coderef is called with two
arguments: the prefix being defined (including trailing colon), and
the full URI as a string.

The C<< parse_* >> methods return a string containing the remainder
of the input (i.e. potentially a tail which could not be parsed).

=head1 SEE ALSO

L<RDF::Closure>, L<RDF::Trine::Parser>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

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

__DATA__
Prefix(a:=<family_guy#>)
Prefix(foaf:=<http://xmlns.com/foaf/0.1/>)
/* Hello world. */
# foo bar baz
Ontology( <example> <example_1.1>
	Import(foaf:)
	Annotation( Annotation( Annotation ( a:dated "2011-03-01"^^xsd:date ) a:assertedBy a:Seth ) foaf:maker a:Seth )
	Declaration( Annotation( a:test a:annotation ) Class( a:Person ) )
	Declaration( Class( a:Dog ) )
	Declaration( Class( a:Species ) )
	Declaration( NamedIndividual( a:Peter ) )
	Declaration( NamedIndividual( a:Brian ) )
	ClassAssertion( a:Person a:Peter )
	ClassAssertion( a:Dog a:Brian ) #quux
	ClassAssertion( a:Species a:Dog )
	ClassAssertion( a:Species a:Person )
	HasKey(a:Person (a:surname a:forename a:placeOfBirth a:dateOfBirth) ())
	DisjointClasses( a:Human a:Fish a:Dog a:Cat )
	EquivalentClasses( a:Person a:Human foaf:Person )
	SubObjectPropertyOf( ObjectPropertyChain( a:hasMother a:hasSister ) a:hasAunt )
	ObjectPropertyAssertion(
		Annotation(
			Annotation ( a:dated "2011-03-02"^^xsd:date )
			a:assertedBy a:Peter
			)
		Annotation( a:assertedBy a:Brian )
		a:owns a:Peter a:Brian
		)
	NegativeObjectPropertyAssertion(
		Annotation( a:assertedBy a:Peter )
		a:owns a:Lois a:Brian
		)
	DataPropertyAssertion(a:isMarried a:Peter yes)
	DataPropertyAssertion(rdfs:label a:Peter "Peter"@en)
	DataPropertyAssertion(rdfs:label a:Brian "Brian@en"^^rdf:PlainLiteral)
	DataPropertyAssertion(rdfs:label a:Lois "Lois@"^^rdf:PlainLiteral)
	DataPropertyAssertion(rdfs:label a:Meg "Meg")
	DataPropertyAssertion(rdfs:label a:Monkey "\"Evil\" Monkey")
	DataPropertyRange(
		Annotation( rdfs:comment "Labels shouldn't be too long or too short." )
		rdfs:label
		DatatypeRestriction( xsd:string xsd:maxLength 256 xsd:minLength 2 )
		)
)

# lalalala
