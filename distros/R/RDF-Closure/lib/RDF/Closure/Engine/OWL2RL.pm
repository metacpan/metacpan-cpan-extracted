package RDF::Closure::Engine::OWL2RL;

use 5.008;
use strict;
use utf8;

use Error qw[:try];
use RDF::Trine qw[statement iri];
use RDF::Trine::Namespace qw[RDF RDFS OWL XSD];
use RDF::Closure::AxiomaticTriples qw[
	$OWLRL_Datatypes_Disjointness
	$OWLRL_Axiomatic_Triples
	$OWLRL_D_Axiomatic_Triples
	];
use RDF::Closure::DatatypeHandling qw[
	literals_identical
	literal_valid
	];
use RDF::Closure::XsdDatatypes qw[
	$OWL_RL_Datatypes
	$OWL_Datatype_Subsumptions
	];
use RDF::Closure::Rule::Programmatic;
use RDF::Closure::Rule::StatementMatcher;
use Scalar::Util qw[blessed];

use constant {
	TRUE    => 1,
	FALSE   => 0,
	};
use namespace::clean;

use base qw[RDF::Closure::Engine::Core];

our $VERSION = '0.001';

our @OneTimeRules = (

	# dt-type2, dt-not-type, dt-diff, dt-eq
	RDF::Closure::Rule::Programmatic->new(
		sub {
				my ($cl, $rule) = @_;
				
				my $implicit = {};
				my $explicit = {};
				my $used_datatypes = {};
				
				local *_add_to_explicit = sub
				{
					my ($s, $o) = map { $_->sse } @_;
					$explicit->{$s} = {}
						unless exists $explicit->{$s};
					$explicit->{$s}{$o}++;
				};

				local *_append_to_explicit = sub
				{
					my ($s, $o) = map { $_->sse } @_;
					$explicit->{$s} = {}
						unless exists $explicit->{$s};
					for my $d (keys %{ $explicit->{$o} })
					{
						$explicit->{$s}{$d}++;
					}
				};
				
				local *_add_to_used_datatypes = sub
				{
					my ($d) = @_;
					$d = $d->uri if blessed($d);
					$used_datatypes->{$d}++;
				};
				
				local *_handle_subsumptions = sub
				{
					my ($r, $dt) = @_;
					if (exists $OWL_Datatype_Subsumptions->{$dt})
					{
						foreach my $new_dt (@{ $OWL_Datatype_Subsumptions->{$dt} })
						{
							$cl->store_triple($r, $RDF->type, $new_dt);
							$cl->store_triple($new_dt, $RDF->type, $RDFS->Datatype);
							_add_to_used_datatypes($new_dt);
						}
					}
				};
				
				my %literals;
				$cl->graph->get_statements(undef, undef, undef)->each(sub
				{
					my $st    = shift;
					my @nodes = $st->nodes;
					foreach my $lt (@nodes)
					{
						next unless $lt->is_literal;
						# We're now effectively in a foreach literal loop...
						
						# Add to %literals, but skip rest of this iteration if it was already there.
						next if $literals{ $lt->sse };
						$literals{ $lt->sse } = $lt;
						
						next unless $lt->has_datatype;
						$cl->store_triple($lt, $RDF->type, iri($lt->literal_datatype));
						
						next unless grep { $_->uri eq $lt->literal_datatype } @$OWL_RL_Datatypes;
						
						# RULE dt-type2
						$implicit->{ $lt->sse } = $lt->literal_datatype
							unless exists $implicit->{ $lt->sse };
						_add_to_used_datatypes($lt->literal_datatype);
						
						# RULE dt-not-type
						$cl->add_error("Literal's lexical value and datatype do not match: (%s,%s)",
							$lt->literal_value, $lt->literal_datatype)
							unless $cl->dt_handling->literal_valid($lt);
					}
				});
				
				# RULE dt-diff
				# RULE dt-eq
				foreach my $lt1 (keys %literals)
				{
					foreach my $lt2 (keys %literals)
					{
						if ($lt1 ne $lt2) # @@TODO doesn't work ???
						{
							my $l1 = $literals{$lt1};
							my $l2 = $literals{$lt2};
							
							if ($cl->dt_handling->literals_identical($l1, $l2))
							{
								$cl->store_triple($l1, $OWL->sameAs, $l2);
							}
							else
							{
								$cl->store_triple($l1, $OWL->differentFrom, $l2);
							}
						}
					}
				}

				# this next bit catches triples like { [] a xsd:string . }
				$cl->graph->get_statements(undef, $RDF->type, undef)->each(sub {
					my $st = shift;
					my ($s, $p, $o) = ($st->subject, $st->predicate, $st->object);
					if (grep { $_->equal($o); } @$OWL_RL_Datatypes)
					{
						_add_to_used_datatypes($o);
						_add_to_explicit($s, $o)
							unless exists $explicit->{ $s->sse };
					}
				});

				$cl->graph->get_statements(undef, $OWL->sameAs, undef)->each(sub {
					my $st = shift;
					my ($s, $p, $o) = ($st->subject, $st->predicate, $st->object);
					_append_to_explicit($s, $o) if exists $explicit->{$o};
					_append_to_explicit($o, $s) if exists $explicit->{$s};
				});
				
				foreach my $dt (@$OWL_RL_Datatypes)
				{
					$cl->store_triple($dt, $RDF->type, $RDFS->Datatype);
				}
				foreach my $dts (values %$explicit)
				{
					foreach my $dt (keys %$dts)
					{
						$cl->store_triple(iri($dt), $RDF->type, $RDFS->Datatype);
					}
				}
				
				foreach my $r (keys %$explicit)
				{
					my @dtypes = keys %{ $explicit->{$r} };
					$r = RDF::Trine::Node->from_sse($r);
					foreach my $dt (@dtypes)
					{
						$dt = $1 if $dt =~ /^<(.+)>$/;
						_handle_subsumptions($r, $dt);
					}
				}
				
				foreach my $r (keys %$implicit)
				{
					my $dt = $implicit->{$r};
					$r = RDF::Trine::Node->from_sse($r);
					_handle_subsumptions($r, $dt);
				}
				
				foreach my $t (@$OWLRL_Datatypes_Disjointness)
				{
					my ($l, $r) = ($t->subject, $t->object);
					$cl->store_triple($t)
						if exists $used_datatypes->{$l->uri}
						&& exists $used_datatypes->{$r->uri};
				}
			},
		'dt-type2, dt-not-type, dt-diff, dt-eq'
		),

	# cls-thing
	RDF::Closure::Rule::Programmatic->new(
		sub {
				my ($cl, $rule) = @_;
				$cl->store_triple($OWL->Thing, $RDF->type, $OWL->Class);
			},
		'cls-thing'
		),

	# cls-nothing
	RDF::Closure::Rule::Programmatic->new(
		sub {
				my ($cl, $rule) = @_;
				$cl->store_triple($OWL->Nothing, $RDF->type, $OWL->Class);
			},
		'cls-nothing'
		),

	# prp-ap
	RDF::Closure::Rule::Programmatic->new(
		sub {
				my ($cl, $rule) = @_;
				
				my $OWLRL_Annotation_properties = [
					$RDFS->label,
					$RDFS->comment,
					$RDFS->seeAlso,
					$RDFS->isDefinedBy,
					$OWL->deprecated,
					$OWL->versionInfo,
					$OWL->priorVersion,
					$OWL->backwardCompatibleWith,
					$OWL->incompatibleWith,
					];
				
				$cl->store_triple($_, $RDF->type, $OWL->AnnotationProperty)
					foreach @$OWLRL_Annotation_properties;
			},
		'prp-ap'
		),

	);

my $_EQ_REF = {};

our @Rules = (

	# prp-dom
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDFS->domain, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($prop, undef, $class) = $st->nodes;
				$cl->graph->subjects($prop)->each(sub {
					$cl->store_triple(shift, $RDF->type, $class);
				});
			},
		'prp-dom' # Same as rdfs2
		),
		
	# prp-rng
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDFS->range, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($prop, undef, $class) = $st->nodes;
				$cl->graph->objects(undef, $prop)->each(sub {
					$cl->store_triple(shift, $RDF->type, $class);
				});
			},
		'prp-rng' # Same as rdfs3
		),
	
	# prp-fp
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDF->type, $OWL->FunctionalProperty],
		sub {
				my ($cl, $st, $rule) = @_; my ($prop) = $st->nodes;
				$cl->graph->get_statements(undef, $prop, undef)->each(sub {
					my $x  = $st->subject;
					my $y1 = $st->object;
					$cl->graph->objects($x, $prop)->each(sub{
						my $y2 = shift;
						$cl->store_triple($y1, $OWL->sameAs, $y2)
							unless $y1->equal($y2);
					});
				});
			},
		'prp-fp'
		),

	# prp-ifp
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDF->type, $OWL->InverseFunctionalProperty],
		sub {
				my ($cl, $st, $rule) = @_; my ($prop) = $st->nodes;
				$cl->graph->get_statements(undef, $prop, undef)->each(sub {
					my $st = shift;
					my $x  = $st->object;
					my $y1 = $st->subject;
					$cl->graph->subjects($prop, $x)->each(sub{
						my $y2 = shift;
						$cl->store_triple($y1, $OWL->sameAs, $y2)
							unless $y1->equal($y2);
					});
				});
			},
		'prp-ifp'
		),

	# prp-irp
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDF->type, $OWL->IrreflexiveProperty],
		sub {
				my ($cl, $st, $rule) = @_; my ($prop) = $st->nodes;
				$cl->graph->get_statements(undef, $prop, undef)->each(sub{
					my $st = shift;
					$cl->add_error("Irreflexive property %s used reflexively on %s", $st->predicate, $st->subject)
						if $st->subject->equal($st->object);
				});
			},
		'prp-irp'
		),

	# prp-symp
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDF->type, $OWL->SymmetricProperty],
		sub {
				my ($cl, $st, $rule) = @_; my ($prop) = $st->nodes;
				$cl->graph->get_statements(undef, $prop, undef)->each(sub{
					my $st = shift;
					$cl->store_triple($st->object, $prop, $st->subject);
				});
			},
		'prp-symp'
		),

	# prp-asym
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDF->type, $OWL->AsymmetricProperty],
		sub {
				my ($cl, $st, $rule) = @_; my ($prop) = $st->nodes;
				$cl->graph->get_statements(undef, $prop, undef)->each(sub{
					my $st = shift;
					$cl->add_error("Asymmetric property %s used symmetrically on (%s,%s)", $st->predicate, $st->subject, $st->object)
						if $cl->graph->count_statements($st->object, $st->predicate, $st->subject);
				});
			},
		'prp-asym'
		),

	# prp-trp
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDF->type, $OWL->TransitiveProperty],
		sub {
				my ($cl, $st, $rule) = @_; my ($prop) = $st->nodes;
				$cl->graph->get_statements(undef, $prop, undef)->each(sub{
					my ($x, undef, $y) = $_[0]->nodes;
					$cl->graph->objects($y, $prop)->each(sub{
						my $z = $_[0];
						$cl->store_triple($x, $prop, $z);
					});
				});
			},
		'prp-trp'
		),

	# prp-adp
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDF->type, $OWL->AllDisjointProperties],
		sub {
				my ($cl, $st, $rule) = @_; my ($x) = $st->nodes;
				$cl->graph->get_statements($x, $OWL->members, undef)->each(sub {
					my @pis = $cl->graph->get_list($_[0]->object);
					for my $i (0 .. scalar(@pis)-1)
					{
						for my $j ($i+1 .. scalar(@pis)-1)
						{
							my $pi = $pis[$i];
							my $pj = $pis[$j];
							
							$cl->graph->get_statements(undef, $pi, undef)->each(sub {
								my ($x, undef, $y) = $_[0]->nodes;
								if ($cl->graph->count_statements($x, $pj, $y))
								{
									$cl->add_error("Disjoint properties in an 'AllDisjointProperties' are not really disjoint: %s %s %s and %s %s %s.", $x, $pi, $y, $x, $pj, $y);
								}
							});
						}						
					}
				});
			},
		'prp-adp'
		),

	# prp-spo1
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDFS->subPropertyOf, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($prop1, undef, $prop2) = $st->nodes;
				$cl->graph->get_statements(undef, $prop1, undef)->each(sub {
					my $st = shift;
					$cl->store_triple($st->subject, $prop2, $st->object);
				});
			},
		'prp-spo1' # Same as rdfs7
		),
	
	# prp-spo2
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->propertyChainAxiom],
		sub {
				my ($cl, $st, $rule) = @_; my ($prop, undef, $chain) = $st->nodes;
				_property_chain($cl, $prop, $chain);
			},
		'prp-spo2'
		),

	# prp-eqp1, prp-eqp2
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->equivalentProperty, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($prop1, undef, $prop2) = $st->nodes;
				return if $prop1->equal($prop2);
				$cl->graph->get_statements(undef, $prop1, undef)->each(sub {
					my $st = shift;
					$cl->store_triple($st->subject, $prop2, $st->object);
				});
				$cl->graph->get_statements(undef, $prop2, undef)->each(sub {
					my $st = shift;
					$cl->store_triple($st->subject, $prop1, $st->object);
				});
			},
		'prp-eqp1, prp-eqp2'
		),

	# prp-pdw
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->propertyDisjointWith, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($prop1, undef, $prop2) = $st->nodes;
				$cl->graph->get_statements(undef, $prop1, undef)->each(sub {
					my $st = shift;
					$cl->add_error('Erronous usage of disjoint properties %s and %s on %s and %s', $prop1, $prop2, $st->subject, $st->object)
						if $cl->graph->count_statements($st->subject, $prop2, $st->object);
				});
			},
		'prp-pdw'
		),

	# prp-inv1, prp-inv2
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->inverseOf, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($prop1, undef, $prop2) = $st->nodes;
				$cl->graph->get_statements(undef, $prop1, undef)->each(sub {
					my $st = shift;
					$cl->store_triple($st->object, $prop2, $st->subject);
				});
				return if $prop1->equal($prop2);
				$cl->graph->get_statements(undef, $prop2, undef)->each(sub {
					my $st = shift;
					$cl->store_triple($st->object, $prop1, $st->subject);
				});
			},
		'prp-inv1, prp-inv2'
		),

	# prp-key
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->hasKey, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($c, $t, $u) = $st->nodes;
				my $G   = $cl->graph;
				my @pis = $G->get_list($u);
				if (@pis)
				{
					foreach my $x ($G->subjects($RDF->type, $c))
					{
						my $finalList = [ map { [$_] } $G->objects($x, $pis[0]) ];
						my (undef, @otherPIS) = @pis;
						foreach my $pi (@otherPIS)
						{
							my $newList = [];
							foreach my $zi ($G->objects($x, $pi))
							{
								foreach my $l (@$finalList)
								{
									push @$newList, [@$l, $zi];
								}
							}
							$finalList = $newList;
						}
						
						my $valueList = [ grep { scalar(@$_)==scalar(@pis) } @$finalList ];
						
						#use Data::Dumper;
						#printf("%s is member of class %s, has key values:\n%s\n",
						#	$x->as_ntriples,
						#	$c->as_ntriples,
						#	Dumper($valueList));
					
						INDY: foreach my $y ($G->subjects($RDF->type, $c))
						{
							next if $x->equal($y);
							next if $G->count_statements($x, $OWL->sameAs, $y);
							next if $G->count_statements($y, $OWL->sameAs, $x);
							
							foreach my $vals (@$valueList)
							{
								my $same = TRUE;
								PROP: for my $i (0 .. scalar(@pis)-1)
								{
									unless ($G->count_statements($y, $pis[$i], $vals->[$i]))
									{
										$same = FALSE;
										next PROP;
									}
								}
								
								if ($same)
								{
									$cl->store_triple($x, $OWL->sameAs, $y);
									$cl->store_triple($y, $OWL->sameAs, $x);
									next INDY;
								}
							}
						}
					}					
				}
			},
		'prp-key'
		),

	# prp-npa1
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->targetIndividual, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($x, undef, $target) = $st->nodes;
				my @sources = $cl->graph->objects($x, $OWL->sourceIndividual);
				my @props   = $cl->graph->objects($x, $OWL->assertionProperty);
				foreach my $s (@sources)
				{
					foreach my $p (@props)
					{
						if ($cl->graph->count_statements($s, $p, $target))
						{
							$cl->add_error('Negative (object) property assertion violated for: (%s %s %s .)', $s, $p, $target);
						}
					}
				}
			},
		'prp-npa1'
		),

	# prp-npa2
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->targetValue, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($x, undef, $target) = $st->nodes;
				my @sources = $cl->graph->objects($x, $OWL->sourceIndividual);
				my @props   = $cl->graph->objects($x, $OWL->assertionProperty);
				foreach my $s (@sources)
				{
					foreach my $p (@props)
					{
						if ($cl->graph->count_statements($s, $p, $target))
						{
							$cl->add_error('Negative (datatype) property assertion violated for: (%s %s %s .)', $s, $p, $target);
						}
					}
				}
			},
		'prp-npa2'
		),

	# eq-ref
	RDF::Closure::Rule::StatementMatcher->new(
		[],
		sub {
				my ($cl, $st, $rule) = @_;
				my @nodes = $st->nodes;
				for (0..2)
				{
					next if $_EQ_REF->{ $nodes[$_]->sse }++; # optimisation
					$cl->store_triple($nodes[$_], $OWL->sameAs, $nodes[$_]);
				}
			},
		'eq-ref'
		),

	# eq-sym
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->sameAs, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				$cl->store_triple($o, $OWL->sameAs, $s);
			},
		'eq-sym'
		),

	# eq-trans
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->sameAs, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				foreach my $z ($cl->graph->objects($o, $OWL->sameAs))
				{
					$cl->store_triple($s, $OWL->sameAs, $z);
					$cl->store_triple($z, $OWL->sameAs, $s);
				}
			},
		'eq-trans'
		),

	# eq-rep-s
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->sameAs, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				$cl->graph->get_statements($s, undef, undef)->each(sub {
					$cl->store_triple($o, $_[0]->predicate, $_[0]->object);
				});
			},
		'eq-rep-s'
		),

	# eq-rep-p
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->sameAs, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				$cl->graph->get_statements(undef, $s, undef)->each(sub {
					$cl->store_triple($_[0]->subject, $o, $_[0]->object);
				});
			},
		'eq-rep-p'
		),

	# eq-rep-o
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->sameAs, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				$cl->graph->get_statements(undef, undef, $s)->each(sub {
					$cl->store_triple($_[0]->subject, $_[0]->predicate, $o);
				});
			},
		'eq-rep-o'
		),

	# eq-diff
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->sameAs, undef],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				$cl->add_error("'sameAs' and 'differentFrom' cannot be used on the same subject-object pair: (%s, %s)", $s, $o)
					if $cl->graph->count_statements($s, $OWL->differentFrom, $o)
					|| $cl->graph->count_statements($o, $OWL->differentFrom, $s);
			},
		'eq-diff'
		),

	# eq-diff2 and eq-diff3
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDF->type, $OWL->AllDifferent],
		sub {
				my ($cl, $st, $rule) = @_; my ($s, $p, $o) = $st->nodes;
				my $x = $s;
				my @m1 = $cl->graph->objects($x, $OWL->members);
				my @m2 = $cl->graph->objects($x, $OWL->distinctMembers);
				LOOPY: foreach my $y ((@m1, @m2))
				{
					my @zis = $cl->graph->get_list($y);
					LOOPI: foreach my $i (0 .. scalar(@zis)-1)
					{
						my $zi = $zis[$i];
						LOOPJ: foreach my $j ($i+1 .. scalar(@zis)-1)
						{
							my $zj = $zis[$j];
							next LOOPJ if $zi->equal($zj); # caught by another rule
							
							$cl->add_error("'sameAs' and 'AllDifferent' cannot be used on the same subject-object pair: (%s, %s)", $zi, $zj)
								if $cl->graph->count_statements($zi, $OWL->sameAs, $zj)
								|| $cl->graph->count_statements($zj, $OWL->sameAs, $zi);
						}
					}
				}
			},
		'eq-diff2, eq-diff3'
		),

	# Ivan doesn't seem to have this rule, but it's required by test cases.
	# { ?x1 owl:differentFrom ?x2 . } => { ?x2 owl:differentFrom ?x1 . } .
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->differentFrom, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($x1, undef, $x2) = $st->nodes;
				$cl->store_triple($x2, $OWL->differentFrom, $x1);
			},
		'????'
		),

	# cls-nothing2
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDF->type, $OWL->Nothing],
		sub {
				my ($cl, $st, $rule) = @_;
				$cl->add_error("%s is defined of type 'Nothing'", $st->subject);
			},
		'cls-nothing'
		),

	# cls-int1, cls-int2
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->intersectionOf, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($c, undef, $x) = $st->nodes;
				my @classes = $cl->graph->get_list($x);
				return unless @classes;
				# cls-int1
				foreach my $y ($cl->graph->subjects($RDF->type, $classes[0]))
				{
					my $isInIntersection = TRUE;
					unless ($cl->graph->count_statements($y, $RDF->type, $c)) # Ivan doesn't do this check
					{
						CI: foreach my $ci (@classes[1 .. scalar(@classes)-1])
						{
							unless ($cl->graph->count_statements($y, $RDF->type, $ci))
							{
								$isInIntersection = FALSE;
								last CI;
							}
						}
						if ($isInIntersection)
						{
							$cl->store_triple($y, $RDF->type, $c);
						}
					}
				}
				# cls-int2
				foreach my $y ($cl->graph->subjects($RDF->type, $c))
				{
					$cl->store_triple($y, $RDF->type, $_) foreach @classes;
				}
			},
		'cls-int1, cls-int2'
		),

	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->unionOf, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($c, undef, $x) = $st->nodes;
				my @classes = $cl->graph->get_list($x);
				foreach my $cu (@classes)
				{
					$cl->graph->subjects($RDF->type, $cu)->each(sub {
						$cl->store_triple($_[0], $RDF->type, $c);
					});
				}
			},
		'cls-uni'
		),

	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->complementOf, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($c1, undef, $c2) = $st->nodes;
				$cl->graph->subjects($RDF->type, $c1)->each(sub{
					$cl->add_error("Violation of complementarity for classes %s and %s on element %s", $c1, $c2, $_[0])
						if $cl->graph->count_statements($_[0], $RDF->type, $c2);
				});
			},
		'cls-comm'
		),

	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->someValuesFrom, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($xx, undef, $y) = $st->nodes;
				$cl->graph->objects($xx, $OWL->onProperty)->each(sub{
					my $pp = shift;
					$cl->graph->get_statements(undef, $pp, undef)->each(sub{
						my ($u, undef, $v) = $_[0]->nodes;
						if ($y->equal($OWL->Thing) or $cl->graph->count_statements($u, $RDF->type, $y))
						{
							$cl->store_triple($u, $RDF->type, $xx);
						}
					});
				});				
			},
		'cls-svf1, cls-svf2'
		),

	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->allValuesFrom, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($xx, undef, $y) = $st->nodes;
				$cl->graph->objects($xx, $OWL->onProperty)->each(sub{
					my $pp = shift;
					$cl->graph->subjects($RDF->type, $xx)->each(sub{
						my $u = shift;
						$cl->graph->objects($u, $pp)->each(sub{
							my $v = shift;
							$cl->store_triple($v, $RDF->type, $y);
						});
					});
				});				
			},
		'cls-avf'
		),

	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->hasValue, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($xx, undef, $y) = $st->nodes;
				$cl->graph->objects($xx, $OWL->onProperty)->each(sub{
					my $pp = shift;
					$cl->graph->subjects($RDF->type, $xx)->each(sub{
						my $u = shift;
						$cl->store_triple($u, $pp, $y);
					});
					$cl->graph->subjects($pp, $y)->each(sub{
						my $u = shift;
						$cl->store_triple($u, $RDF->type, $xx);
					});
				});				
			},
		'cls-hv1, cls-hv2'
		),

	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->maxCardinality, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($xx, undef, $x) = $st->nodes;
				my $val = int( $x->is_literal ? $x->literal_value : -1 );
				# maxc1
				if ($val == 0)
				{
					$cl->graph->objects($xx, $OWL->onProperty)->each(sub{
						my $pp = shift;
						$cl->graph->get_statements(undef, $pp, undef)->each(sub{
							my ($u, undef, $y) = $_[0]->nodes;
							$cl->add_error("Erronous usage of maximum cardinality with %s, %s", $xx, $y)
								if $cl->graph->count_statements($u, $RDF->type, $xx);
						});
					});				
				}
				# maxc2
				elsif ($val == 1)
				{
					$cl->graph->objects($xx, $OWL->onProperty)->each(sub{
						my $pp = shift;
						$cl->graph->get_statements(undef, $pp, undef)->each(sub{
							my ($u, undef, $y1) = $_[0]->nodes;
							if ($cl->graph->count_statements($u, $RDF->type, $xx))
							{
								$cl->graph->objects($u, $pp)->each(sub{
									my $y2 = shift;
									unless ($y1->equal($y2))
									{
										$cl->store_triple($y1, $OWL->sameAs, $y2);
										$cl->store_triple($y2, $OWL->sameAs, $y1);
									}
								});
							}
						});
					});				
				}
				else
				{
					# awesome, we can't do anything!
				}
			},
		'cls-maxc1, cls-maxc2'
		),

	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->maxCardinality, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($xx, undef, $x) = $st->nodes;
				my $val = int( $x->is_literal ? $x->literal_value : -1 );
				# cls-maxqc1 and cls-maxqc2
				if ($val == 0)
				{
					my @cc = $cl->graph->objects($xx, $OWL->onClass);
					$cl->graph->objects($xx, $OWL->onProperty)->each(sub{
						my $pp = shift;
						foreach my $cc (@cc)
						{
							$cl->graph->get_statements(undef, $pp, undef)->each(sub{
								my ($u, undef, $y) = $_[0]->nodes;
								$cl->add_error("Erronous usage of maximum qualified cardinality with %s, %s, and %s", $xx, $cc, $y)
									if $cl->graph->count_statements($u, $RDF->type, $xx)
									&& ($cc->equal($OWL->Thing) or $cl->graph->count_statements($y, $RDF->type, $cc));
							});
						}
					});				
				}
				# cls-maxqc3 and cls-maxqc4
				elsif ($val == 1)
				{
					my @cc = $cl->graph->objects($xx, $OWL->onClass);
					$cl->graph->objects($xx, $OWL->onProperty)->each(sub{
						my $pp = shift;
						foreach my $cc (@cc)
						{
							$cl->graph->get_statements(undef, $pp, undef)->each(sub{
								my ($u, undef, $y1) = $_[0]->nodes;
								if ($cl->graph->count_statements($u, $RDF->type, $xx))
								{
									if ($cc->equal($OWL->Thing))
									{
										$cl->graph->objects($u, $pp)->each(sub{
											my $y2 = shift;
											unless ($y1->equal($y2))
											{
												$cl->store_triple($y1, $OWL->sameAs, $y2);
												$cl->store_triple($y2, $OWL->sameAs, $y1);
											}
										});
									}
									elsif ($cl->graph->count_statements($y1, $RDF->type, $cc))
									{
										$cl->graph->objects($u, $pp)->each(sub{
											my $y2 = shift;
											if (!$y1->equal($y2)
											and $cl->graph->count_statements($y2, $RDF->type, $cc))
											{
												$cl->store_triple($y1, $OWL->sameAs, $y2);
												$cl->store_triple($y2, $OWL->sameAs, $y1);
											}
										});
									}
								}
							});
						}
					});				
				}
				else
				{
					# awesome, we can't do anything!
				}
			},
		'cls-maxqc1, cls-maxqc2, cls-maxqc3, cls-maxqc4'
		),

	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->oneOf, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($c, undef, $x) = $st->nodes;
				my @indivs = $cl->graph->get_list($x);
				foreach my $i (@indivs)
				{
					$cl->store_triple($i, $RDF->type, $c);
				}
			},
		'cls-oo'
		),

	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDFS->subClassOf, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($c1, undef, $c2) = $st->nodes;
				unless ($c1->equal($c2))
				{
					$cl->graph->subjects($RDF->type, $c1)->each(sub {
						$cl->store_triple($_[0], $RDF->type, $c2);
					});
				}
			},
		'cax-sco'
		),

	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->equivalentClass, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($c1, undef, $c2) = $st->nodes;
				$cl->store_triple($c2, $OWL->equivalentClass, $c1); # Toby added
				$cl->store_triple($c1, $RDFS->subClassOf, $c2);
				$cl->store_triple($c2, $RDFS->subClassOf, $c1);
				unless ($c1->equal($c2))
				{
					$cl->graph->subjects($RDF->type, $c1)->each(sub {
						$cl->store_triple($_[0], $RDF->type, $c2);
					});
					$cl->graph->subjects($RDF->type, $c2)->each(sub {
						$cl->store_triple($_[0], $RDF->type, $c1);
					});
				}
			},
		'cax-eqc, cax-eqc1'
		),

	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->disjointWith, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($c1, undef, $c2) = $st->nodes;
				$cl->graph->subjects($RDF->type, $c1)->each(sub {
					$cl->add_error('Disjoint classes %s and %s have a common individual %s', $c1, $c2, $_[0])
						if $cl->graph->count_statements($_[0], $RDF->type, $c2);
				});
			},
		'cax-dw'
		),

	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDF->type, $OWL->AllDisjointClasses],
		sub {
				my ($cl, $st, $rule) = @_;
				my $x = $st->subject;
				$cl->graph->objects($x, $OWL->members)->each(sub{
					my @classes = $cl->graph->get_list($_[0]);
					if (@classes)
					{
						for my $i (0 .. scalar(@classes)-1)
						{
							my $cl1 = $classes[$i];
							$cl->graph->subjects($RDF->type, $cl1)->each(sub{
								my $z = shift;
								for my $j ($i+1 .. scalar(@classes)-1)
								{
									my $cl2 = $classes[$j];
									$cl->add_error("Disjoint classes %s and %s have a common individual %s", $cl1, $cl2, $z)
										if $cl->graph->count_statements($z, $RDF->type, $cl2);
								}
							});
						}
					}
				});
			},
		'cax-adc'
		),
	
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDF->type, $OWL->Class],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($c) = $st->nodes;
				$cl->store_triple($c, $RDFS->subClassOf, $c);
				$cl->store_triple($c, $OWL->equivalentClass, $c);
				$cl->store_triple($c, $RDFS->subClassOf, $OWL->Thing);
				$cl->store_triple($OWL->Nothing, $RDFS->subClassOf, $c);
			},
		'scm-cls'
		),

	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDFS->subClassOf, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($c1, undef, $c2) = $st->nodes;
				$cl->graph->objects($c2, $RDFS->subClassOf)->each(sub {
					my $c3 = $_[0];
					if ($c1->equal($c3))
					{
						# scm-eqc2
						$cl->store_triple($c1, $OWL->equivalentClass, $c3);
					}
					else
					{
						# scm-sco
						$cl->store_triple($c1, $RDFS->subClassOf, $c3);
					}
					# Ivan could optimise his version better.
				});
			},
		'scm-sco, scm-eqc2'
		),
	
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDF->type, $OWL->ObjectProperty],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($pp) = $st->nodes;
				$cl->store_triple($pp, $RDFS->subPropertyOf, $pp);
				$cl->store_triple($pp, $OWL->equivalentProperty, $pp);
			},
		'scm-op'
		),
		
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDF->type, $OWL->DatatypeProperty],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($pp) = $st->nodes;
				$cl->store_triple($pp, $RDFS->subPropertyOf, $pp);
				$cl->store_triple($pp, $OWL->equivalentProperty, $pp);
			},
		'scm-dp'
		),
		
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDF->type, $RDF->Property],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($pp) = $st->nodes;
				$cl->store_triple($pp, $RDFS->subPropertyOf, $pp);
				$cl->store_triple($pp, $OWL->equivalentProperty, $pp);
			},
		'????' # Ivan made this up
		),
		
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->equivalentProperty, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($p1, undef, $p2) = $st->nodes;
				$cl->store_triple($p2, $OWL->equivalentProperty, $p1); # Toby added
				$cl->store_triple($p1, $RDFS->subPropertyOf, $p2); 
				$cl->store_triple($p2, $RDFS->subPropertyOf, $p1); 
				unless ($p1->equal($p2))
				{
					$cl->graph->subjects($RDF->type, $p1)->each(sub {
						$cl->store_triple($_[0], $RDF->type, $p2);
					});
					$cl->graph->subjects($RDF->type, $p2)->each(sub {
						$cl->store_triple($_[0], $RDF->type, $p1);
					});
				}
			},
		'cax-eqp, cax-eqp1'
		),

	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDFS->subPropertyOf, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($p1, undef, $p2) = $st->nodes;
				$cl->graph->objects($p2, $RDFS->subPropertyOf)->each(sub {
					my $p3 = $_[0];
					if ($p1->equal($p3))
					{
						# scm-eqp2
						$cl->store_triple($p1, $OWL->equivalentProperty, $p3);
					}
					else
					{
						# scm-spo
						$cl->store_triple($p1, $RDFS->subPropertyOf, $p3);
					}
					# Ivan could optimise his version better.
				});
			},
		'scm-spo, scm-eqp2'
		),
	
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDFS->domain, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($pp, undef, $c1) = $st->nodes;
				$cl->graph->objects($c1, $RDFS->subClassOf)->each(sub {
					my $c2 = $_[0];
					$cl->store_triple($pp, $RDFS->domain, $c2) unless $c1->equal($c2);
				});
				my ($p2, undef, $c) = $st->nodes;
				$cl->graph->subjects($RDFS->subPropertyOf, $p2)->each(sub {
					my $p1 = $_[0];
					$cl->store_triple($p1, $RDFS->domain, $c) unless $p1->equal($p2);
				});
			},
		'scm-dom1, scm-dom2'
		),

	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $RDFS->range, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($pp, undef, $c1) = $st->nodes;
				$cl->graph->objects($c1, $RDFS->subClassOf)->each(sub {
					my $c2 = $_[0];
					$cl->store_triple($pp, $RDFS->range, $c2) unless $c1->equal($c2);
				});
				my ($p2, undef, $c) = $st->nodes;
				$cl->graph->subjects($RDFS->subPropertyOf, $p2)->each(sub {
					my $p1 = $_[0];
					$cl->store_triple($p1, $RDFS->range, $c) unless $p1->equal($p2);
				});
			},
		'scm-rng1, scm-rng2'
		),

	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->hasValue, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($c1, undef, $i)  = $st->nodes;
				my @p1 = $cl->graph->objects($c1, $OWL->onProperty);
				my @c2 = $cl->graph->subjects($OWL->hasValue, $i);
				foreach my $p1 (@p1)
				{
					foreach my $c2 (@c2)
					{
						foreach my $p2 ($cl->graph->objects($c2, $OWL->onProperty))
						{
							$cl->store_triple($c1, $RDFS->subClassOf, $c2)
								if $cl->graph->count_statements($p1, $RDFS->subPropertyOf, $p2);
						}
					}
				}
			},
		'scm-hv'
		),
		
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->someValuesFrom, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($xx, undef, $y) = $st->nodes;
				$cl->graph->objects($xx, $OWL->onProperty)->each(sub{
					my $pp = shift;
					$cl->graph->get_statements(undef, $pp, undef)->each(sub{
						my ($u, undef, $v) = (shift)->nodes;
						if ($y->equal($OWL->Thing) or $cl->graph->count_statements($v, $RDF->type, $y))
						{
							$cl->store_triple($u, $RDF->type, $xx);
						}
					});
				});
			},
		'scm-svf1, scm-svf2'
		),
		
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->allValuesFrom, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($xx, undef, $y) = $st->nodes;
				$cl->graph->objects($xx, $OWL->onProperty)->each(sub{
					my $pp = shift;
					$cl->graph->subjects($RDF->type, $xx)->each(sub {
						my $u = shift;
						$cl->graph->objects($u, $pp)->each(sub {
							my $v = shift;
							$cl->store_triple($v, $RDF->type, $y);
						});
					});
				});
			},
		'scm-avf'
		),
			
	# scm-int
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->intersectionOf, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($c, undef, $x) = $st->nodes;
				$cl->store_triple($c, $RDFS->subClassOf, $_) foreach $cl->graph->get_list($x);
			},
		'scm-int'
		),
	
	# scm-uni
	RDF::Closure::Rule::StatementMatcher->new(
		[undef, $OWL->unionOf, undef],
		sub {
				my ($cl, $st, $rule) = @_;
				my ($c, undef, $x) = $st->nodes;
				$cl->store_triple($_, $RDFS->subClassOf, $c) foreach $cl->graph->get_list($x);
			},
		'scm-uni'
		),
		
	);

sub _property_chain
{
	my ($self, $p, $x) = @_;
	
	my @chain = $self->graph->get_list($x);
	return unless @chain;
	
	$self->graph->get_statements(undef, $chain[0], undef)->each(sub {
		my ($u1, $_y, $_z) = $_[0]->nodes;
		
		my $finalList   = [[$u1,$_z]];
		my $chainExists = TRUE;
		
		PI: foreach my $pi (@chain[1 .. scalar(@chain)-1])
		{
			my $newList = [];
			foreach my $q (@$finalList)
			{
				my ($_u, $ui) = @$q;
				foreach my $u ($self->graph->objects($ui, $pi))
				{
					push @$newList, [$u1, $u];
				}
			}
			if (@$newList)
			{
				$finalList = $newList;
			}
			else
			{
				$chainExists = FALSE;
				last PI;
			}
		}
		if ($chainExists)
		{
			foreach my $q (@$finalList)
			{
				my ($_u, $un) = @$q;
				$self->store_triple(($u1, $p, $un));
			}
		}
	});
}

sub __init__
{
	my ($self, @args) = @_;
	$self->SUPER::__init__(@args);
	$self->{bnodes} = [];
	$self->{options}{technique} = 'RULE';
	return $self;
}

sub _get_resource_or_literal
{
	my ($self, $node) = @_;
	$node; # ????
}

sub post_process
{
	# Python version removes bnode predicate triples, but I'm going to keep them.
}

sub add_axioms
{
	my ($self) = @_;
	$self->store_triple(statement($_->nodes, $self->{axiom_context}))
		foreach @$OWLRL_Axiomatic_Triples;
}

sub add_daxioms
{
	my ($self) = @_;
	$self->store_triple(statement($_->nodes, $self->{daxiom_context}))
		foreach @$OWLRL_D_Axiomatic_Triples;
}

sub entailment_regime
{
	return 'http://www.w3.org/ns/owl-profile/RL';
}

1;

=head1 NAME

RDF::Closure::Engine::OWL2RL - OWL 2 RL inference

=head1 ANALOGOUS PYTHON

RDFClosure/OWLRL.py

=head1 DESCRIPTION

Performs OWL 2 inference, using the RL profile of OWL.

=head1 SEE ALSO

L<RDF::Closure::Engine>.

L<http://www.perlrdf.org/>.

L<http://www.w3.org/TR/2009/REC-owl2-profiles-20091027/#OWL_2_RL>.

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

