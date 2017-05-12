package OWL::DirectSemantics::Translator;

BEGIN {
	$OWL::DirectSemantics::Translator::AUTHORITY = 'cpan:TOBYINK';
	$OWL::DirectSemantics::Translator::VERSION   = '0.001';
};




use Moose;
use RDF::Trine qw[statement iri literal blank variable];
use RDF::Trine::Namespace qw[RDF RDFS OWL XSD];

has model    => (is=>'rw', isa=>'RDF::Trine::Model');
has ontology => (is=>'rw', isa=>'OWL::DirectSemantics::Element::Ontology');

has 'RIND' => ( is => 'rw', isa => 'ArrayRef', default => sub{[]} );
has 'CE'   => ( is => 'rw', isa => 'HashRef',  default => sub{{}} );
has 'DR'   => ( is => 'rw', isa => 'HashRef',  default => sub{{}} );
has 'OPE'  => ( is => 'rw', isa => 'HashRef',  default => sub{{}} );
has 'DPE'  => ( is => 'rw', isa => 'HashRef',  default => sub{{}} );
has 'AP'   => ( is => 'rw', isa => 'HashRef',  default => sub{{}} );
has 'ANN'  => ( is => 'rw', isa => 'HashRef',  default => sub{{}} );

sub translate
{
	my ($self, $model, $ontology_node) = @_;
	
	$self->init($model);

	$ontology_node ||= $self->guess_ontology_node;

	# OWL2RDF{3.1.2}
	$self
		->ontology_header($ontology_node)
		->enforce_dl_compatible
		->add_declarations
		->calculate_rind
		;

	# OWL2RDF{3.2.1}
	$self->analyze_declarations;

	# OWL2RDF{3.2.2}
	$self->parse_annotations;

	# OWL2RDF{3.2.3}
	$self->ontology_annotations($ontology_node);

	# OWL2RDF{3.2.4}
	$self
		->extend_ope
		->extend_dr
		->extend_ce
		->parse_dr_owl1dl
		->parse_ce_owl1dl
		;

	# OWL2RDF{3.2.5}
	$self
		->parse_axioms
		->parse_axioms_owl1dl;

	# Need to walk axiom list, and for each, if it contains blank nodes,
	# then provide it with information from CE, DR, OPE, DPE, AP.
	my $metadata = {
		CE  => $self->CE,
		DR  => $self->DR,
		OPE => $self->OPE,
		DPE => $self->DPE,
		AP  => $self->AP,
		};
	foreach my $ax ($self->ontology->axioms)
	{
		$ax->metadata($metadata);
	}
	
	my $ontology = $self->ontology;
	$self->init;
	return $ontology;
}

sub init
{
	my ($self, $model) = @_;
	
	$self->{ontology} = undef;
	$self->{model}    = $model;
	
	$self->RIND([]);
	$self->CE({});
	$self->DR({});
	$self->OPE({});
	$self->DPE({});
	$self->AP({});
	$self->ANN({});
}

sub guess_ontology_node
{
	my ($self) = @_;
	
	my @ontologies = $self->model->subjects($RDF->type, $OWL->Ontology);
	my %count;
	$self->model->get_statements(undef, $OWL->imports, undef)->each(sub{
		my ($s, $p, $o) = (shift)->nodes;
		push @ontologies, $s, $o;
		$count{ $o->sse }++;
	});
	
	# Make @ontologies unique.
	{
		my %tmp = map { $_->sse => $_ } @ontologies;
		@ontologies = values %tmp;
	}
	
	my ($node) = sort { ($count{$a->sse}||0) <=> ($count{$b->sse}||0) or $a->sse cmp $b->sse } @ontologies;
	return $node;
}

sub ontology_header
{
	my ($self, $node) = @_;
	
	$self->ontology( OWL::DirectSemantics::Element::Ontology->new )
		unless $self->ontology;
	
	# ontologyIRI
	{
		$self->ontology->ontologyIRI($node)
			if defined $node;
		$self->model->remove_statements($node, $RDF->type, $OWL->Ontology);
	}
	
	# versionIRI
	{
		my ($versionIRI) = $self->model->objects($node, $OWL->versionIRI, undef);
		$self->ontology->versionIRI($versionIRI)
			if defined $versionIRI;
		$self->model->remove_statements($node, $OWL->versionIRI, $versionIRI);
	}
	
	# imports
	{
		my @imports = $self->model->objects($node, $OWL->imports, undef);
		$self->ontology->imports(\@imports)
			if @imports;
		$self->model->remove_statements($node, $OWL->imports, undef);
	}

	return $self;
}

sub enforce_dl_compatible
{
	my ($self) = @_;
	
	# "Table 5"
	my @removals = (
		pair(
			pattern(statement(variable('x'), $RDF->type, $OWL->Ontology)),
			pattern(statement(variable('x'), $RDF->type, $OWL->Ontology)),
			),
		pair(
			pattern(
				statement(variable('x'), $RDF->type, $OWL->Class),
				statement(variable('x'), $RDF->type, $RDFS->Class),
				),
			pattern(statement(variable('x'), $RDF->type, $RDFS->Class)),
			),
		pair(
			pattern(
				statement(variable('x'), $RDF->type, $RDFS->Datatype),
				statement(variable('x'), $RDF->type, $RDFS->Class),
				),
			pattern(statement(variable('x'), $RDF->type, $RDFS->Class)),
			),
		pair(
			pattern(
				statement(variable('x'), $RDF->type, $OWL->DataRange),
				statement(variable('x'), $RDF->type, $RDFS->Class),
				),
			pattern(statement(variable('x'), $RDF->type, $RDFS->Class)),
			),
		pair(
			pattern(
				statement(variable('x'), $RDF->type, $OWL->Restriction),
				statement(variable('x'), $RDF->type, $RDFS->Class),
				),
			pattern(statement(variable('x'), $RDF->type, $RDFS->Class)),
			),
		pair(
			pattern(
				statement(variable('x'), $RDF->type, $OWL->Restriction),
				statement(variable('x'), $RDF->type, $OWL->Class),
				),
			pattern(statement(variable('x'), $RDF->type, $OWL->Class)),
			),
		pair(
			pattern(
				statement(variable('x'), $RDF->type, $RDF->List),
				statement(variable('x'), $RDF->first, variable('y')),
				statement(variable('x'), $RDF->rest, variable('z')),
				),
			pattern(statement(variable('x'), $RDF->type, $RDF->List)),
			),
		);
		
	foreach (qw[ObjectProperty FunctionalProperty InverseFunctionalProperty
		TransitiveProperty DatatypeProperty AnnotationProperty OntologyProperty])
	{
		push @removals, pair(
			pattern(
				statement(variable('x'), $RDF->type, $OWL->uri($_)),
				statement(variable('x'), $RDF->type, $RDF->Property),
				),
			pattern(statement(variable('x'), $RDF->type, $RDF->Property)),
			);
	}
	
	# "Table 6"
	my @replacements = (
		pair(
			pattern(statement(variable('x'), $RDF->type, $OWL->OntologyProperty)),
			pattern(statement(variable('x'), $RDF->type, $OWL->AnnotationProperty)),
			),
		);
	
	my @additions;
	foreach (qw[InverseFunctionalProperty TransitiveProperty SymmetricProperty])
	{		
		push @additions, pair(
			pattern(statement(variable('x'), $RDF->type, $OWL->InverseFunctionalProperty)),
			pattern(statement(variable('x'), $RDF->type, $OWL->ObjectProperty)),
			);
	}
	
	# Process tables...
	foreach (@removals)
	{
		my ($match, $remove) = @$_;
		$self->model->get_pattern($match)->each(sub {
			my $remove_pattern = $remove->bind_variables($_[0]);
			$self->model->remove_statement($_)
				foreach $remove_pattern->triples;
		});
	}
	foreach (@replacements)
	{
		my ($match, $replace) = @$_;
		$self->model->get_pattern($match)->each(sub {
			my $remove_pattern = $match->bind_variables($_[0]);
			$self->model->remove_statement($_)
				foreach $remove_pattern->triples;
			my $replace_pattern = $replace->bind_variables($_[0]);
			$self->model->add_statement($_)
				foreach $replace_pattern->triples;
		});
	}
	foreach (@additions)
	{
		my ($match, $add) = @$_;
		$self->model->get_pattern($match)->each(sub {
			my $add_pattern = $add->bind_variables($_[0]);
			$self->model->add_statement($_)
				foreach $add_pattern->triples;
		});
	}
	
	return $self;
}

sub add_declarations
{
	my ($self) = @_;
	
	# Table 7
	my @declaration_patterns;
	foreach (qw[Class Datatype ObjectProperty DataProperty
		AnnotationProperty NamedIndividual])
	{
		my $uri = $OWL->uri($_);
		$uri = $RDFS->Datatype if $_ eq 'Datatype';
		$uri = $OWL->DatatypeProperty if $_ eq 'DataProperty';
		
		push @declaration_patterns, pair(
			pattern(statement(variable('d'), $RDF->type, $uri)),
			$_,
			);
		push @declaration_patterns, pair(
			pattern(
				statement(variable('x'), $RDF->type, $OWL->Axiom),
				statement(variable('x'), $OWL->annotatedSource, variable('d')),
				statement(variable('x'), $OWL->annotatedProperty, $RDF->type),
				statement(variable('x'), $OWL->annotatedTarget, $uri),
				),
			$_,
			);
	}
	
	# Process table...
	foreach (@declaration_patterns)
	{
		my ($pattern, $klass) = @$_;
		$klass = sprintf('OWL::DirectSemantics::Element::%s', $klass);
		
		$self->model->get_pattern($pattern)->each(sub {
			my $declared_node = shift->{d};
			next unless $declared_node;
			
			$self->ontology->add_axiom(
				OWL::DirectSemantics::Element::Declaration->new(
					declare => $klass->new( node => $declared_node ),
					)
				);
		});
	}
	
	return $self;
}

sub calculate_rind
{
	my ($self) = @_;
	
	my %rind;
	
	# Table 8
	foreach (qw[Axiom Annotation AllDisjointClasses AllDisjointProperties
		AllDifferent NegativePropertyAssertion])
	{
		$self->model->subjects($RDF->type, $OWL->uri($_))->each(sub {
			my $bnode = shift;
			return unless $bnode->is_blank;
			
			$rind{ $bnode->sse } = $bnode;
		});
	}
	
	$self->RIND([ values %rind ]);
	
	return $self;
}

sub analyze_declarations
{
	my ($self) = @_;
	
	my $mappings= {};
	
	# Table 9
	foreach my $decl ($self->ontology->axioms)
	{
		next unless $decl->isa('OWL::DirectSemantics::Element::Declaration');
		next unless $decl->declare->can('MAPPING_CODE');
		push @{ $mappings->{ $decl->declare->MAPPING_CODE }{ $decl->declare->node->sse } },
			$decl->declare;
	}
	
	foreach (qw[CE DR OPE DPE AP])
	{
		$self->{$_} = $mappings->{$_} if exists $mappings->{$_};
	}
	
	return $self;
}

sub parse_annotations # NOT TESTED
{
	my ($self) = @_;

	my %ANN;

	# Table 10
	foreach my $ap (values %{$self->AP})
	{
		next unless ref($ap) eq 'ARRAY';
		foreach (@$ap)
		{
			my $y = $_->node;
			$self->model->get_statements(undef, $y, undef)->each(sub {
				my ($x, undef, $xlt) = $_[0]->nodes;
				
				my $has_reified = 0;
				my $reified_pattern = pattern(
					statement(variable('w'), $RDF->type, $OWL->Annotation),
					statement(variable('w'), $OWL->annotatedSource, $x),
					statement(variable('w'), $OWL->annotatedProperty, $y),
					statement(variable('w'), $OWL->annotatedTarget, $xlt),
					);
				my @w;
				$self->model->get_pattern($reified_pattern)->each(sub {
					$has_reified++;
					push @w, shift->{w};
				});
				
				if ($has_reified)
				{
					foreach my $w (@w)
					{
						if ($self->model->count_statements($w, undef, undef)==4
						&&  $self->model->count_statements(undef, undef, $w)==0)
						{							
							$ANN{ $w->sse } ||= [];
							push @{ $ANN{ $x->sse } }, OWL::DirectSemantics::Element::Annotation->new(
								source   => $w,
								property => $y,
								target   => $xlt,
								);
							$self->model->remove_statements($w, undef, undef);
						}
					}
					$self->model->remove_statements($x, $y, $xlt);
				}
				else
				{
					push @{ $ANN{ $x->sse } }, OWL::DirectSemantics::Element::Annotation->new(
						property => $y,
						target   => $xlt,
						);
					$self->model->remove_statements($x, $y, $xlt);
				}
			});
		}
	}
	
	$self->ANN(\%ANN);
	
	return $self;
}

sub ontology_annotations
{
	my ($self, $x) = @_;
	return $self unless $x;
	$self->ontology->annotations( $self->ANN->{ $x->sse } )
		if ref($self->ANN->{ $x->sse }) eq 'ARRAY';
	return $self;
}

sub extend_ope
{
	my ($self) = @_;
	
	$self->model->get_statements(undef, $OWL->inverseOf, undef)->each(sub {
		my ($x, undef, $y) = $_[0]->nodes;
		if ($self->OPE->{ $y->sse })
		{
			push @{ $self->OPE->{ $x->sse } },
				OWL::DirectSemantics::Element::ObjectInverseOf->new(node=>$y);
			$self->model->remove_statements($x, $OWL->sameAs, $y);
		}
	});
	
	return $self;
}

sub extend_dr
{
	my ($self) = @_;

	my %predicates = (
		intersectionOf => 'OWL::DirectSemantics::Element::DataIntersectionOf',
		unionOf        => 'OWL::DirectSemantics::Element::DataUnionOf',
		oneOf          => 'OWL::DirectSemantics::Element::DataOneOf',
		);
	while (my ($predicate, $klass) = each %predicates)
	{
		my $pattern = pattern(
			statement(variable('x'), $RDF->type, $RDFS->Datatype),
			statement(variable('x'), $OWL->uri($predicate), variable('seq')),
			);
		$self->model->get_pattern($pattern)->each(sub {
			my ($x, $seq) = ($_[0]->{x}, $_[0]->{seq});
			my @seq = $self->model->get_list($seq);

			if ($predicate eq 'oneOf')
			{
				return unless scalar(@seq) > 0;
			}
			else
			{
				return unless scalar(@seq) > 1;
				return if grep { !@{$self->DR->{$_->sse}} } @seq;
			}
			
			push @{ $self->DR->{ $x->sse } }, $klass->new(nodes=>[@seq]);
				
			$self->model->remove_statements($x, $RDF->type, $RDFS->Datatype);
			$self->model->remove_statements($x, $OWL->uri($predicate), $seq);
			$self->model->remove_list($seq, orphan_check=>1);
		});
	}
	
	{
		my $pattern = pattern(
			statement(variable('x'), $RDF->type, $RDFS->Datatype),
			statement(variable('x'), $OWL->datatypeComplementOf, variable('y')),
			);
		$self->model->get_pattern($pattern)->each(sub {
			my ($x, $y) = ($_[0]->{x}, $_[0]->{y});
			
			return unless @{$self->DR->{$y->sse}};
			
			push @{ $self->DR->{ $x->sse } },
				OWL::DirectSemantics::Element::DataComplementOf->new(node=>$y);
			
			$self->model->remove_statements($x, $RDF->type, $RDFS->Datatype);
			$self->model->remove_statements($x, $OWL->datatypeComplementOf, $y);
		});
	}
	
	## @TODO - DatatypeRestriction
	
	return $self;
}

sub extend_ce
{
	my ($self) = @_;

	my %predicates = (
		intersectionOf => 'OWL::DirectSemantics::Element::ObjectIntersectionOf',
		unionOf        => 'OWL::DirectSemantics::Element::ObjectUnionOf',
		oneOf          => 'OWL::DirectSemantics::Element::ObjectOneOf',
		);
	while (my ($predicate, $klass) = each %predicates)
	{
		my $pattern = pattern(
			statement(variable('x'), $RDF->type, $OWL->Class),
			statement(variable('x'), $OWL->uri($predicate), variable('seq')),
			);
		$self->model->get_pattern($pattern)->each(sub {
			my ($x, $seq) = ($_[0]->{x}, $_[0]->{seq});
			my @seq = $self->model->get_list($seq);

			if ($predicate eq 'oneOf')
			{
				return unless scalar(@seq) > 0;
			}
			else
			{
				return unless scalar(@seq) > 1;
				return if grep { !@{$self->CE->{$_->sse}} } @seq;
			}
			
			push @{ $self->CE->{ $x->sse } }, $klass->new(nodes=>[@seq]);
				
			$self->model->remove_statements($x, $RDF->type, $OWL->Class);
			$self->model->remove_statements($x, $OWL->uri($predicate), $seq);
			$self->model->remove_list($seq, orphan_check=>1);
		});
	}
	
	{
		my $pattern = pattern(
			statement(variable('x'), $RDF->type, $OWL->Class),
			statement(variable('x'), $OWL->complementOf, variable('y')),
			);
		$self->model->get_pattern($pattern)->each(sub {
			my ($x, $y) = ($_[0]->{x}, $_[0]->{y});
			
			return unless @{$self->CE->{$y->sse}};
			
			push @{ $self->CE->{ $x->sse } },
				OWL::DirectSemantics::Element::ObjectComplementOf->new(node=>$y);
			
			$self->model->remove_statements($x, $RDF->type, $OWL->Class);
			$self->model->remove_statements($x, $OWL->complementOf, $y);
		});
	}

	{
		my $pattern = pattern(
			statement(variable('x'), $RDF->type, $OWL->Restriction),
			statement(variable('x'), $OWL->onProperty, variable('y')),
			statement(variable('x'), $OWL->hasSelf, variable('z')),
			);
		$self->model->get_pattern($pattern)->each(sub {
			my ($x, $y, $z) = ($_[0]->{x}, $_[0]->{y}, $_[0]->{z});
			
			return unless @{$self->OPE->{$y->sse}};
			
			# This is a little less strict than OWL2 - we allow almost any value except /false/i and 0.
			return if $z->is_literal && $z->literal_value =~ /^(false)|(\-?0+(\.0+)?)$/i;
			
			push @{ $self->CE->{ $x->sse } },
				OWL::DirectSemantics::Element::ObjectHasSelf->new(property=>$y);
			
			$self->model->remove_statements($x, $RDF->type, $OWL->Class);
			$self->model->remove_statements($x, $OWL->complementOf, $y);
		});
	}

	%predicates = (
		minQualifiedCardinality => 'MinCardinality',
		maxQualifiedCardinality => 'MaxCardinality',
		qualifiedCardinality    => 'ExactCardinality',
		);
	while (my ($predicate, $klass) = each %predicates)
	{
		my $pattern = pattern(
			statement(variable('x'), $RDF->type, $OWL->Restriction),
			statement(variable('x'), $OWL->onProperty, variable('y')),
			statement(variable('x'), $OWL->onClass, variable('z')),
			statement(variable('x'), $OWL->uri($predicate), variable('n')),
			);
		$self->model->get_pattern($pattern)->each(sub {
			my ($n, $x, $y, $z) = $_[0]->{qw[n x y z]};

			my $qklass = sprintf('OWL::DirectSemantics::Element::Object%s', $klass);

			return unless @{$self->OPE->{$y->sse}};
			return unless @{$self->CE->{$z->sse}};

			push @{ $self->CE->{ $x->sse } }, $qklass->new(property=>$y, class=>$z, value=>$n);
			
			$self->model->remove_statements($x, $RDF->type, $OWL->Restriction);
			$self->model->remove_statements($x, $OWL->onProperty, $y);
			$self->model->remove_statements($x, $OWL->onClass, $z);
			$self->model->remove_statements($x, $OWL->uri($predicate), $n);
		});
		
		$pattern = pattern(
			statement(variable('x'), $RDF->type, $OWL->Restriction),
			statement(variable('x'), $OWL->onProperty, variable('y')),
			statement(variable('x'), $OWL->onDataRange, variable('z')),
			statement(variable('x'), $OWL->uri($predicate), variable('n')),
			);
		$self->model->get_pattern($pattern)->each(sub {
			my ($n, $x, $y, $z) = $_[0]->{qw[n x y z]};

			my $qklass = sprintf('OWL::DirectSemantics::Element::Data%s', $klass);

			return unless @{$self->DPE->{$y->sse}};
			return unless @{$self->DR->{$z->sse}};

			push @{ $self->CE->{ $x->sse } }, $qklass->new(property=>$y, datarange=>$z, value=>$n);
			
			$self->model->remove_statements($x, $RDF->type, $OWL->Restriction);
			$self->model->remove_statements($x, $OWL->onProperty, $y);
			$self->model->remove_statements($x, $OWL->onDataRange, $z);
			$self->model->remove_statements($x, $OWL->uri($predicate), $n);
		});
	}
	
	%predicates = (
		someValuesFrom => 'SomeValuesFrom',
		allValuesFrom  => 'AllValuesFrom',
		hasValue       => 'HasValue',
		minCardinality => 'MinCardinality',
		maxCardinality => 'MaxCardinality',
		cardinality    => 'ExactCardinality',
		);
	while (my ($predicate, $klass) = each %predicates)
	{
		my $pattern = pattern(
			statement(variable('x'), $RDF->type, $OWL->Restriction),
			statement(variable('x'), $OWL->onProperty, variable('y')),
			statement(variable('x'), $OWL->uri($predicate), variable('z')),
			);
		
		$self->model->get_pattern($pattern)->each(sub {
			my ($x, $y, $z) = ($_[0]->{x}, $_[0]->{y}, $_[0]->{z});

			my ($qklass, $zname); # fully-qualified class; name of $z.
			
			# Some of these need a class expression in $z. 
			if ($predicate =~ m'^(someValuesFrom|allValuesFrom)$')
			{
				return unless @{$self->CE->{$z->sse}};
				$zname = 'class';
			}
			else
			{
				$zname = 'value';
			}
			
			if (@{ $self->OPE->{$y->sse} || [] })
			{
				$qklass = sprintf('OWL::DirectSemantics::Element::Object%s', $klass);
			}
			elsif (@{ $self->DPE->{$y->sse} || []  })
			{
				$qklass = sprintf('OWL::DirectSemantics::Element::Data%s', $klass);
			}
			else
			{
				return;
			}
			
			push @{ $self->CE->{ $x->sse } }, $qklass->new(property=>$y, $zname=>$z);
			
			$self->model->remove_statements($x, $RDF->type, $OWL->Restriction);
			$self->model->remove_statements($x, $OWL->onProperty, $y);
			$self->model->remove_statements($x, $OWL->uri($predicate), $z);
		});
	}

	%predicates = (
		someValuesFrom => 'SomeValuesFrom',
		allValuesFrom  => 'AllValuesFrom',
		);
	while (my ($predicate, $klass) = each %predicates)
	{
		my $pattern = pattern(
			statement(variable('x'), $RDF->type, $OWL->Restriction),
			statement(variable('x'), $OWL->onProperties, variable('seq')),
			statement(variable('x'), $OWL->uri($predicate), variable('z')),
			);
		$self->model->get_pattern($pattern)->each(sub {
			my ($x, $seq, $z) = ($_[0]->{x}, $_[0]->{seq}, $_[0]->{z});

			my $qklass = sprintf('OWL::DirectSemantics::Element::Data%s', $klass);
			
			my @y = $self->model->get_list($seq);
			push @{ $self->CE->{ $x->sse } }, $qklass->new(property=>\@y, class=>$z);
			
			$self->model->remove_statements($x, $RDF->type, $OWL->Restriction);
			$self->model->remove_statements($x, $OWL->onProperties, $seq);
			$self->model->remove_statements($x, $OWL->uri($predicate), $z);			
			$self->model->remove_list($seq, orphan_check=>1);
		});
	}

	return $self;
}

sub parse_dr_owl1dl
{
	my ($self) = @_;
	## @@TODO
	return $self;
}

sub parse_ce_owl1dl
{
	my ($self) = @_;
	## @@TODO
	return $self;
}

sub parse_axioms
{
	my ($self) = @_;
	
	$self->ontology->axioms([]);
	
	{
		my @declaration_patterns;
		foreach (qw[Class Datatype ObjectProperty DataProperty
			AnnotationProperty NamedIndividual])
		{
			my $uri = $OWL->uri($_);
			$uri = $RDFS->Datatype if $_ eq 'Datatype';
			$uri = $OWL->DatatypeProperty if $_ eq 'DataProperty';
			
			push @declaration_patterns, pair(
				pattern(statement(variable('d'), $RDF->type, $uri)),
				$_,
				);
		}
		
		# Process table...
		foreach (@declaration_patterns)
		{
			my ($pattern, $klass) = @$_;
			$klass = sprintf('OWL::DirectSemantics::Element::%s', $klass);
			
			$self->model->get_pattern($pattern)->each(sub {
				my $bindings = shift;
				my $bound    = $pattern->bind_variables($bindings);

				next unless $bindings->{d};

				my $axiom = OWL::DirectSemantics::Element::Declaration->new(
					declare => $klass->new( node => $bindings->{d} ),
					);
				$self->ontology->add_axiom($axiom);
				
				$self->_annotate($axiom, $bound);
				$self->model->remove_statement($_) foreach $bound->triples;
			});
		}
	}
	
	$self->model->get_statements(undef, $RDFS->subClassOf, undef)->each(sub {
		my $st = shift;

		return unless $self->CE->{ $st->subject->sse };
		return unless $self->CE->{ $st->object->sse };

		my $axiom = OWL::DirectSemantics::Element::SubClassOf->new(
			subclass    => $st->subject,
			superclass  => $st->object,
			);
		$self->ontology->add_axiom($axiom);
		
		$self->_annotate($axiom, pattern($st));
		$self->model->remove_statement($st);
	});

	$self->model->get_statements(undef, $OWL->equivalentClass, undef)->each(sub {
		my $st = shift;

			my $klass;
			if ($self->CE->{ $st->subject->sse } && $self->CE->{ $st->object->sse })
			{
				$klass = 'OWL::DirectSemantics::Element::EquivalentClasses';
			}
			elsif ($self->DR->{ $st->subject->sse } && $self->DR->{ $st->object->sse })
			{
				$klass = 'OWL::DirectSemantics::Element::DatatypeDefinition';
			}
			else
			{
				return;
			}

		my $axiom = $klass->new(
			classes => [$st->subject, $st->object],
			);
		$self->ontology->add_axiom($axiom);
		
		$self->_annotate($axiom, pattern($st));
		$self->model->remove_statement($st);
	});

	$self->model->get_statements(undef, $OWL->disjointWith, undef)->each(sub {
		my $st = shift;

		return unless $self->CE->{ $st->subject->sse };
		return unless $self->CE->{ $st->object->sse };

		my $axiom = OWL::DirectSemantics::Element::DisjointClasses->new(
			classes => [$st->subject, $st->object],
			);
		$self->ontology->add_axiom($axiom);
		
		$self->_annotate($axiom, pattern($st));
		$self->model->remove_statement($st);
	});
	
	## @@TODO AllDisjointClasses
	## @@TODO disjointUnionOf
	
	$self->model->get_statements(undef, $RDFS->subPropertyOf, undef)->each(sub {
		my $st = shift;

		my $klass;
		if ($self->OPE->{ $st->subject->sse } && $self->OPE->{ $st->object->sse })
		{
			$klass = 'OWL::DirectSemantics::Element::SubObjectPropertyOf';
		}
		elsif ($self->DPE->{ $st->subject->sse } && $self->DPE->{ $st->object->sse })
		{
			$klass = 'OWL::DirectSemantics::Element::SubDataPropertyOf';
		}
		else
		{
			return;
		}

		my $axiom = $klass->new(
			subprop    => $st->subject,
			superprop  => $st->object,
			);
		$self->ontology->add_axiom($axiom);
		
		$self->_annotate($axiom, pattern($st));
		$self->model->remove_statement($st);
	});
	
	## @@TODO propertyChainAxiom

	$self->model->get_statements(undef, $OWL->equivalentProperty, undef)->each(sub {
		my $st = shift;

		my $klass;
		if ($self->OPE->{ $st->subject->sse } && $self->OPE->{ $st->object->sse })
		{
			$klass = 'OWL::DirectSemantics::Element::EquivalentObjectProperties';
		}
		elsif ($self->DPE->{ $st->subject->sse } && $self->DPE->{ $st->object->sse })
		{
			$klass = 'OWL::DirectSemantics::Element::EquivalentDataProperties';
		}
		else
		{
			return;
		}

		my $axiom = $klass->new( props => [$st->subject, $st->object] );
		$self->ontology->add_axiom($axiom);
		
		$self->_annotate($axiom, pattern($st));
		$self->model->remove_statement($st);
	});
	
	$self->model->get_statements(undef, $OWL->propertyDisjointWith, undef)->each(sub {
		my $st = shift;

		my $klass;
		if ($self->OPE->{ $st->subject->sse } && $self->OPE->{ $st->object->sse })
		{
			$klass = 'OWL::DirectSemantics::Element::DisjointObjectProperties';
		}
		elsif ($self->DPE->{ $st->subject->sse } && $self->DPE->{ $st->object->sse })
		{
			$klass = 'OWL::DirectSemantics::Element::DisjointDataProperties';
		}
		else
		{
			return;
		}

		my $axiom = $klass->new( props => [$st->subject, $st->object] );
		$self->ontology->add_axiom($axiom);
		
		$self->_annotate($axiom, pattern($st));
		$self->model->remove_statement($st);
	});
	
	## @@TODO AllDisjointProperties

	foreach my $role (qw[domain range])
	{
		$self->model->get_statements(undef, $RDFS->uri($role), undef)->each(sub {
			my $st = shift;

			my $klass;
			if ($self->OPE->{ $st->subject->sse } && $self->CE->{ $st->object->sse })
			{
				$klass = sprintf('OWL::DirectSemantics::Element::ObjectProperty%s', ucfirst $role);
			}
			elsif ($self->DPE->{ $st->subject->sse } && $self->DR->{ $st->object->sse })
			{
				$klass = sprintf('OWL::DirectSemantics::Element::DataProperty%s', ucfirst $role);
			}
			else
			{
				return;
			}

			my $axiom = $klass->new( prop=>$st->subject, class=>$st->object );
			$self->ontology->add_axiom($axiom);
			
			$self->_annotate($axiom, pattern($st));
			$self->model->remove_statement($st);
		});
	}

	$self->model->get_statements(undef, $OWL->inverseOf, undef)->each(sub {
		my $st = shift;

		my $klass;
		if ($self->OPE->{ $st->subject->sse } && $self->OPE->{ $st->object->sse })
		{
			$klass = 'OWL::DirectSemantics::Element::InverseObjectProperties';
		}
		else
		{
			return;
		}

		my $axiom = $klass->new( props => [$st->subject, $st->object] );
		$self->ontology->add_axiom($axiom);
		
		$self->_annotate($axiom, pattern($st));
		$self->model->remove_statement($st);
	});

	foreach my $role (qw[Functional InverseFunctional Reflexive Irreflexive
		Symmetric Asymmetric Transitive])
	{
		$self->model->get_statements(undef, $RDF->type, $OWL->uri($role.'Property'))->each(sub {
			my $st = shift;

			my $klass;
			if ($self->OPE->{ $st->subject->sse })
			{
				$klass = sprintf('OWL::DirectSemantics::Element::%sObjectProperty', $role);
			}
			elsif ($self->DPE->{ $st->subject->sse } && $role eq 'Functional')
			{
				$klass = sprintf('OWL::DirectSemantics::Element::%sDataProperty', $role);
			}
			else
			{
				return;
			}

			my $axiom = $klass->new( prop => $st->subject );
			$self->ontology->add_axiom($axiom);
			
			$self->_annotate($axiom, pattern($st));
			$self->model->remove_statement($st);
		});
	}
	
	## @@TODO hasKey
	
	$self->model->get_statements(undef, $OWL->sameAs, undef)->each(sub {
		my $st = shift;
		my $axiom = OWL::DirectSemantics::Element::SameIndividual->new(
			nodes => [$st->subject, $st->object],
			);
		$self->ontology->add_axiom($axiom);		
		$self->_annotate($axiom, pattern($st));
		$self->model->remove_statement($st);
	});

	$self->model->get_statements(undef, $OWL->differentFrom, undef)->each(sub {
		my $st = shift;
		my $axiom = OWL::DirectSemantics::Element::DifferentIndividuals->new(
			nodes => [$st->subject, $st->object],
			);
		$self->ontology->add_axiom($axiom);		
		$self->_annotate($axiom, pattern($st));
		$self->model->remove_statement($st);
	});

	# @@TODO AllDifferent
	
	# @@TODO NegativePropertyAssertion + targetValue
	# @@TODO NegativePropertyAssertion + targetIndividual
	
	## @@TODO DeprecatedClass
	## @@TODO DeprecatedProperty
	
	$self->model->get_statements(undef, $RDF->type, undef)->each(sub {
		my $st = shift;
		return unless $self->CE->{ $st->object->sse };
		my $axiom = OWL::DirectSemantics::Element::ClassAssertion->new(
			node  => $st->subject,
			class => $st->object,
			);
		$self->ontology->add_axiom($axiom);		
		$self->_annotate($axiom, pattern($st));
		$self->model->remove_statement($st);
	});

	$self->model->get_statements(undef, undef, undef)->each(sub {
		my $st = shift;
		my $klass;
		if ($self->OPE->{ $st->predicate->sse })
			{ $klass = 'OWL::DirectSemantics::Element::ObjectPropertyAssertion'; }
		elsif ($self->DPE->{ $st->predicate->sse })
			{ $klass = 'OWL::DirectSemantics::Element::DataPropertyAssertion'; }
		else
			{ return ; }
		my $axiom = $klass->new(
			s => $st->subject,
			p => $st->predicate,
			o => $st->object,
			);
		$self->ontology->add_axiom($axiom);		
		$self->_annotate($axiom, pattern($st));
		$self->model->remove_statement($st);
	});

	return $self;
}

sub _annotate
{
	my ($self, $axiom, $triples, $type, $klass) = @_;
	my ($main_triple) = $triples->triples;
	$type  ||= 'Axiom';
	$klass ||= 'Annotation';
	$klass = "OWL::DirectSemantics::Element::${klass}" unless $klass =~ /::/;
	
	my $reification = pattern(
		statement(variable('x'), $RDF->type, $OWL->uri($type)),
		statement(variable('x'), $OWL->annotatedSource, $main_triple->subject),
		statement(variable('x'), $OWL->annotatedProperty, $main_triple->predicate),
		statement(variable('x'), $OWL->annotatedTarget, $main_triple->object),
		);
	my @annotations;
	
	$self->model->get_pattern($reification)->each(sub {
		my $bindings = shift;
		my $bound    = $reification->bind_variables($bindings);
		
		my $x = $bindings->{x};
		push @annotations, @{ $self->ANN->{ $x->sse } }
			if defined $self->ANN->{ $x->sse };
		
		$self->model->get_statements($x, undef, undef)->each(sub {
			my $st = shift;
			return if $bound->subsumes($st);
			
			push @annotations, $klass->new(source=>$x, property=>$st->predicate, target=>$st->object);
			$self->_annotate($annotations[-1], pattern($st), 'Annotation');
			$self->model->remove_statement($st);
		});
		
		$self->model->remove_statement($_) foreach $bound->triples;
	});
	
	$axiom->annotations(\@annotations);

	return $self;
}

sub parse_axioms_owl1dl
{
	my ($self) = @_;
	## @@TODO
	return $self;
}

sub pattern
{
	return RDF::Trine::Pattern->new(@_);
}

sub pair
{
	return [@_];
}

1;


=head1 NAME

OWL::DirectSemantics::Translator - lift an OWL2 model from an RDF model

=head1 SYNOPSIS

  use RDF::Trine;
  my $model = RDF::Trine::Model->temporary_model;
  RDF::Trine::Mode->parse_url_into_model($url, $model);
  
  use OWL::DirectSemantics;
  my $translator = OWL::DirectSemantics::Translator->new;
  my $ontology   = $translator->translate($model);

=head1 DESCRIPTION

This translator is only about 90% complete.

=head2 Constructor

=over

=item C<new>

Creates a new translator object, primed and ready for action!

=back

=head2 Method

=over

=item C<< translate($model [,$ontology_node]) >>

Translates the data in the L<RDF::Trine::Model> provided into OWL, returning an
L<OWL::DirectSemantics::Element::Ontology> object. The model is generally assumed
to contain a single ontology.

C<< $ontology_node >> is an optional L<RDF::Trine::Node> object containing the
ontology's URIor blank node identifier.

C<< $model >> B<will be modified> by the translation process. Any triples translated
to OWL are removed from the model. Any triples remaining are ones that could not be
translated. (If the model provided is OWL DL-compatible, there I<should> be no triples
remaining after translation.)

=back

=head1 SEE ALSO

L<OWL::DirectSemantics>.

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

