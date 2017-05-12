package RDF::NLP::SPARQLQuery::Question;

use utf8;
use strict;
use warnings;
use Data::Dumper;

use Mouse;


use RDF::NLP::SPARQLQuery::Query;

our $VERSION='0.1';

has 'docId'         => (is => 'rw', isa => 'Str');
has 'verbose'         => (is => 'rw', isa => 'Int');
has 'language'      => (is => 'rw', isa => 'Str');
has 'sentences'     => (is => 'rw', isa => 'ArrayRef');
has 'postags'       => (is => 'rw', isa => 'ArrayRef');
has 'semanticUnits' => (is => 'rw', isa => 'ArrayRef');
has 'semanticCorrespondance' => (is => 'rw', isa => 'HashRef');
has 'aggregation' => (is => 'rw', isa => 'HashRef');
# has 'conjunction' => (is => 'rw', isa => 'Int');
has 'negation' => (is => 'rw', isa => 'HashRef');
# has 'varPrefix' => (is => 'rw', isa => 'Str');
# has 'variableCounter' => (is => 'rw', isa => 'Int');
# has 'variableSet' => (is => 'rw', isa => 'HashRef');
has 'union'       => (is => 'rw', isa => 'ArrayRef');
has 'query'       => (is => 'rw', isa => 'Object');
has 'questionTopic'       => (is => 'rw', isa => 'Str');
has 'semFeaturesIndex' => (is => 'rw', isa => 'HashRef');
has 'config' => (is => 'rw', isa => 'HashRef');

# has '' => (is => 'rw', isa => 'HashRef');


# DOC
sub new {
    my $class = shift;
    my %args = @_;
    my $i;

    my $Question = {
	"verbose" => 0,
	"docId" => undef,
	"language" => undef,
	"sentences" => undef,
	"postags" => undef,
	"semanticUnits" => undef,
	# "selectPart" => [],
	# "wherePart" => [],
	"sortedSemanticUnits" => undef,
	"semanticCorrespondance" => undef,
	"aggregation" => {'TERM' => {
	    'count' => {},
	    'max' => {},
	    'min' => {},
	    'distinct' => {},
	    'per' => {},
			   },
			   'QT' => {},
			   'QTVAR' => {},
			   'PREDICATE' => {},
			   'ASK' => 0,
	},
#	"conjunction" => 0,
	"negation" => {},
	"config" => undef,
	# "varPrefix" => "?v",
	# "variableCounter" => 0,
	# "variableSet" => {},
	"union" => [],
	"questionTopic" => undef,
	'semFeaturesIndex' => {}
    };
    bless $Question, $class;

    $Question->verbose($args{'verbose'});
    $Question->docId($args{'docId'});
    $Question->language($args{'language'});
    $Question->sentences([@{$args{'sentences'}}]);
    $Question->postags([@{$args{'postags'}}]);
    $Question->semanticUnits([@{$args{'semanticUnits'}}]);
    $Question->config($args{'config'});

    my $term;
    foreach $term (@{$Question->semanticUnits}) {
	for($i=$term->{'start_offset'}; $i <= $term->{'end_offset'};$i++) {
	    $Question->_termIndex($i, $term);
	}
	# warn "=> " . $term->{'semanticUnit'} . "\n";
	# warn "\t" . join(",", keys %{$term->{'semanticTypes'}}) . "\n";
    }

    # foreach $term (@{$Question->sortedSemanticUnits}) {
    # 	warn "=> " . $term->{'semanticUnit'} . "\n";
	
    # }


    return($Question);
}

sub _regexForm {
    my $self = shift;

    return($self->config->{'NLQUESTION'}->{'language="' . uc($self->language) . '"'}->{'REGEXFORM'});
}


sub _reset_sortedSemanticUnits {
    my $self = shift;

    $self->{'sortedSemanticUnits'} = undef;
    
}

sub _sortedSemanticUnits {
    my $self = shift;

    if (@_) {
	$self->{'sortedSemanticUnits'} = shift;
    } else {
	if (!defined $self->{'sortedSemanticUnits'}) {
	    $self->{'sortedSemanticUnits'} = [sort {$a->{'start_offset'} <=> $b->{'start_offset'}} @{$self->semanticUnits}];
	}
    }
    return($self->{'sortedSemanticUnits'});
}

sub _getTerms {
    my $self = shift;

    my $offset = shift;
    return($self->_termIndex($offset));
}

sub _termIndex {
    my $self = shift;
    my $offset = shift;

    if (@_) {
	my $term = shift;
	if (!exists $self->{'termIndex'}->{$offset}) {
	    $self->{'termIndex'}->{$offset} = [];
	}
	push @{$self->{'termIndex'}->{$offset}}, $term;
    } else {
	if (exists $self->{'termIndex'}->{$offset}) {
	    return($self->{'termIndex'}->{$offset});
	} else {
	    return(exists($self->{'termIndex'}->{$offset}));
	}
    }
    return($self->{'termIndex'});

}

sub _delSemanticUnit {
    my $self = shift;
    my $term = shift;
    my $max;
    my $i;
    my $deleted;
    # del in semanticUnits
#    $self->semanticUnits->[$term

    $max = scalar(@{$self->semanticUnits});
    $i=0;
    $deleted = 0;
    do {
    	if ($self->semanticUnits->[$i]->{'id'} == $term->{'id'}) {
    	    splice(@{$self->semanticUnits}, $i, 1);
    	    $deleted = 1;
    	}
    	$i++;
    } while(($i < $max)&&($deleted==0));
    if ($deleted==0) {
    	$self->_printVerbose("term (" . $term->{'id'} . ") to delete not found in SemanticUnits\n",2);
    }
    
    # del in index
    # warn "$term\n";
    # warn "\n". $term->{'start_offset'} . "\n";
    # warn $self->_termIndex($term->{'start_offset'});
    $max = scalar(@{$self->_termIndex($term->{'start_offset'})});
    $deleted = 0;
    $i=0;
    do {
    	if ($self->_termIndex($term->{'start_offset'})->[$i]->{'id'} == $term->{'id'}) {
    	    splice(@{$self->_termIndex($term->{'start_offset'})}, $i, 1);
    	    $deleted=1;
    	}
    	$i++;
    } while(($i < $max)&&($deleted==0));
    if ($deleted==0) {
    	$self->_printVerbose("term (" . $term->{'id'} . ") to delete not found in index\n",2);
    }
    return(0);
}

sub _delSemanticType {
    my $self = shift;
    my $term = shift;
    my $semf = shift;

    delete $term->{'semanticTypes'}->{$semf};
    return(0);
}

sub _modifySemanticType {
    my $self = shift;
    my $term = shift;
    my $oldsemf = shift;
    my $newsemf = shift;
    my $semf;

    # warn $term->{'semanticUnit'};
    # if (exists $term->{'semanticTypes'}->{$oldsemf}) {
    # 	warn $oldsemf;

    # }
    delete $term->{'semanticTypes'}->{$oldsemf};
    foreach $semf (split /;/, $newsemf) {
	$self->_addSemanticType($term, $semf);
#	$term->{'semanticTypes'}->{$semf} = [split /\//, $semf];
    }
    return($newsemf);
}

sub _addSemanticType {
    my $self = shift;
    my $term = shift;
    my $newsemf = shift;

    $term->{'semanticTypes'}->{$newsemf} = [split /\//, $newsemf];
    return($newsemf);
}

# DOC
sub Question2Query {
    my $self = shift;
    # my $format = shift;
    my $semanticCorrespondance = shift;
    # my $outStr = shift;

    # warn $semanticCorrespondance;
    $self->semanticCorrespondance($semanticCorrespondance);

    $self->query(RDF::NLP::SPARQLQuery::Query->new(
		     'verbose' => $self->verbose,
		     'docId' => $self->docId,
		     'language' => $self->language,
		     'sentences' => $self->sentences,
		     'negation' => $self->negation,
		     'union' => $self->union,
		     'aggregation' => $self->aggregation,
		     'semanticCorrespondance' => $self->semanticCorrespondance,
		     'semFeaturesIndex' => $self->semFeaturesIndex,
		     'sortedSemanticUnits' => $self->_sortedSemanticUnits,
		     'config' => $self->config,
		 )
	);
   
    # warn $self->query->semanticCorrespondance;
    $self->questionAbstraction;
    $self->query->queryConstruction($self->questionTopic);
    $self->query->queryGeneration;
#    $$outStr .= $self->query->queryString;
    return(1);
}


# DOC
sub questionAbstraction  {
    my $self = shift;

    # my %aggregation = ('TERM' => {
    # 	'count' => {},
    # 	'max' => {},
    # 	'min' => {},
    # 	'distinct' => {},
    # 	'per' => {},
    # 		     },
    # 		     'QT' => {},
    # 		     'QTVAR' => {},
    # 		     'PREDICATE' => {},
    # 		     'ASK' => 0,
    # 	);
#    my @union = ();
#    my $conjunction = 0;
    my $conjunction2 = 0;
    # my %negation = ();

#    my $questionTopic;

    # my @wherePart;
    # my @selectPart;
    my %viewedPredicates;
    my %term2semFeatures;
#    my %semFeaturesIndex;
    my %variableSet;

    my %lastsemf;
    my $semCat;
    my $indexCat;
    my $term;
    my $root;
    my $semf;
    my $i;
    my $aggregOp;

    my $line;

#    my @sortedSemanticUnits = ();
    $self->_removeLargerExtractedTerms;
    $self->_contextualRewriting;
#    $self->_getSortedSemanticUnits(\@sortedSemanticUnits, \$conjunction, \%negation);
    $self->_getSortedSemanticUnits; # (\$conjunction, \%negation);

    $self->_detecteNegation; # (\%negation);

    # AGGREGATION/OPERATION FUNCTION?
    $self->_identifyAggregationOperator;#(\%aggregation);

    # QUESTION TOPIC ?
    # $questionTopic = 
    $self->_getQuestionTopic;#(\%aggregation);

    if (defined $self->questionTopic) {
	# $questionTopic = $self->semanticCorrespondance->{$lang}->{'VARIABLE'}->{$questionTopicCat};
	$self->_printVerbose("Question Topic: " . $self->questionTopic . "\n");

	# @wherePart = @{$self->query->wherePart};
	%viewedPredicates = ();
#	@selectPart = ();
	%term2semFeatures = ();
#	%semFeaturesIndex = ();
	%variableSet = ();

	# Identify role of the semantic elements
	$self->_printVerbose("\n[LOG] recording semanticTypes (Property vs Predicate)\n");

	for($i=0; $i < scalar(@{$self->_sortedSemanticUnits});$i++) {
	    $term = $self->_sortedSemanticUnits->[$i];
	    $self->_printVerbose(">> " . $term->{'semanticUnit'} . " ($conjunction2)\n",2);
	    foreach $semf (keys %{$term->{'semanticTypes'}}) {
		$self->_printVerbose("    " . $semf . "\n",2);
		if (!exists $term2semFeatures{$term->{'semanticUnit'}}) {
		    $term2semFeatures{$term->{'semanticUnit'}} = [];
		}
		push @{$term2semFeatures{$term->{'semanticUnit'}}}, $semf;

		$semCat = $term->{'semanticTypes'}->{$semf};
#		    foreach $semCat (@{$semf->semantic_category}) {
		# warn join('/', @$semCat) . " ($conjunction2)\n";
		if (scalar(@{$semCat}) > 1) {
		    $self->_printVerbose(join('/', @$semCat) . " ($conjunction2)\n",2);
		    if ((exists $self->semanticCorrespondance->{$self->language}->{'RESOURCE'}->{$semCat->[0]."/".$semCat->[1]}->{'CORRESP'}) &&
			(exists $self->semanticCorrespondance->{$self->language}->{'RESOURCE'}->{$semCat->[0]."/".$semCat->[1]}->{'CORRESP'}->{$semCat->[$#$semCat-1]})) {
			$indexCat=$self->semanticCorrespondance->{$self->language}->{'RESOURCE'}->{$semCat->[0]."/".$semCat->[1]}->{'CORRESP'}->{$semCat->[$#$semCat-1]};
			$root=$semCat->[0]."/".$semCat->[1];
		    } else {
			my @tmp = @$semCat;
			pop @tmp;
			$indexCat=join('/', @tmp);
			$root=$self->semanticCorrespondance->{$self->language}->{'DEFAULT_ROOT'};
		    }
		    $self->_printVerbose("indexCat: $indexCat ($root)\n",2);
		    if (!exists($self->semFeaturesIndex->{$indexCat})) {
			$self->semFeaturesIndex->{$indexCat}->{'ROOT'} = $root;
			$self->semFeaturesIndex->{$indexCat}->{'CAT'} = [];
			$self->semFeaturesIndex->{$indexCat}->{'CAT2'} = {};
			$self->semFeaturesIndex->{$indexCat}->{'SEEN_S'} = -1;
			$self->semFeaturesIndex->{$indexCat}->{'SEEN_O'} = -1;
		    }
		    # warn ">> $indexCat : " . join("/", @$semCat) . "\n";

#			    @lastsemf=@{$document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $term->{'id'})};
		    # @lastsemf = keys %{$term->{'semanticTypes'};
		    %lastsemf = %{$term->{'semanticTypes'}};
		    push @{$self->semFeaturesIndex->{$indexCat}->{'CAT'}}, $semCat;
		    $self->semFeaturesIndex->{$indexCat}->{'TERM'}->{$term->{'id'}} = $term;
		    # warn "   " . $semf . "\n";
		    $self->semFeaturesIndex->{$indexCat}->{'CAT2'}->{join("/", @$semCat)} = $semCat;
		    #warn "=====> " . $indexCat . "\n";
		} elsif ((scalar(@{$semCat}) == 1) &&
			 (exists $self->semanticCorrespondance->{$self->language}->{'CONST'}->{$semCat->[0]})) {
		    $self->_printVerbose("\t\tCONST\n",2);
		    $indexCat=$semCat->[0];
		    if (!exists($self->semFeaturesIndex->{$indexCat})) {
			$self->semFeaturesIndex->{$indexCat}->{'ROOT'} = "const";
			$self->semFeaturesIndex->{$indexCat}->{'CAT'} = [];
			$self->semFeaturesIndex->{$indexCat}->{'CAT2'} = {};
			$self->semFeaturesIndex->{$indexCat}->{'SEEN_S'} = -1;
			$self->semFeaturesIndex->{$indexCat}->{'SEEN_O'} = -1;
		    }
		    # warn ">> $indexCat : " . join("/", @$semCat) . "\n";
		    push @{$self->semFeaturesIndex->{$indexCat}->{'CAT'}}, [$term->{'semanticUnit'}];
		    $self->semFeaturesIndex->{$indexCat}->{'TERM'}->{$term->{'id'}} = $term;
		    # warn "   " . $semf . "\n";
		    $self->semFeaturesIndex->{$indexCat}->{'CAT2'}->{join("/", @$semCat)} = [$term->{'semanticUnit'}];
		    
		} elsif ((scalar(@{$semCat}) == 1) &&
			 ($semCat->[0] eq "STRING")) {
		    $self->_printVerbose("\t\tSTRING\n",2);
		    $indexCat=$semCat->[0];
		    if (!exists($self->semFeaturesIndex->{$indexCat})) {
			$self->semFeaturesIndex->{$indexCat}->{'ROOT'} = "STRING";
			# $self->semFeaturesIndex->{$indexCat}->{'TERM'} = [];
			$self->semFeaturesIndex->{$indexCat}->{'CAT'} = [];
			$self->semFeaturesIndex->{$indexCat}->{'CAT2'} = {};
			$self->semFeaturesIndex->{$indexCat}->{'SEEN_S'} = -1;
			$self->semFeaturesIndex->{$indexCat}->{'SEEN_O'} = -1;
		    }
		    # warn ">> $indexCat : " . join("/", @$semCat) . "\n";
		    push @{$self->semFeaturesIndex->{$indexCat}->{'CAT'}}, [$term->{'canonical_form'}];
		    $self->semFeaturesIndex->{$indexCat}->{'TERM'}->{$term->{'id'}} = $term;
		    # warn "   " . $semf . "\n";
		    $self->semFeaturesIndex->{$indexCat}->{'CAT2'}->{join("/", @$semCat)} = [$term->{'canonical_form'}];
		    
		} elsif ((scalar(@{$semCat}) == 1) &&
			 ($semCat->[0] eq "REGEX")) {
		    $self->_printVerbose("\t\tREGEX\n",2);
		    if ($conjunction2 eq 1) {
			my $semCat2;
			my $semf2;
			foreach $semf2 (keys %lastsemf) {
			    $self->_printVerbose("\t\t\t -> " . $semf2 . "\n",2);
			    $semCat2 = 	$lastsemf{$semf2}; # $semCat = $term->{'semanticTypes'}->{$semf};
#				    foreach $semCat2 (@{$semf2->semantic_category}) {
			    $self->_printVerbose("\t\t\t---> " . join("/", @$semCat2) . "\n",2);
			    my $indexCat2=$self->semanticCorrespondance->{$self->language}->{'RESOURCE'}->{$semCat2->[0]."/".$semCat2->[1]}->{'CORRESP'}->{$semCat2->[$#$semCat2-1]};
			    my @newSemCat = @$semCat2;
			    if ($self->_regexForm == 1) {
				$newSemCat[$#newSemCat]=":NODEREGEX:".$term->{'semanticUnit'};
			    } else {
				$newSemCat[$#newSemCat]=":NODEREGEX:".$term->{'canonical_form'};
			    }
			    if (!exists($self->semFeaturesIndex->{$indexCat2})) {
				$self->semFeaturesIndex->{$indexCat2}->{'ROOT'} = "REGEX";
				$self->semFeaturesIndex->{$indexCat2}->{'CAT'} = [];
				$self->semFeaturesIndex->{$indexCat2}->{'CAT2'} = {};
				$self->semFeaturesIndex->{$indexCat2}->{'SEEN_S'} = -1;
				$self->semFeaturesIndex->{$indexCat2}->{'SEEN_O'} = -1;
			    }
			    
			    # warn ">> indexCat2: $indexCat2 : " . join("/", @newSemCat) . "\n";
			    push @{$self->semFeaturesIndex->{$indexCat2}->{'CAT'}}, [@newSemCat];
			    $self->semFeaturesIndex->{$indexCat2}->{'TERM'}->{$term->{'id'}} = $term;
			    # warn "   " . $lastsemf{$semf2} . "\n";
			    $self->semFeaturesIndex->{$indexCat2}->{'CAT2'}->{join("/", @newSemCat)} = [@newSemCat];
#				    }
			}
		    } else {
			$indexCat="STRINGREGEX";
			my @newSemCat;
			if ($self->_regexForm == 1) {
			    @newSemCat = (":LABELREGEX:".$term->{'semanticUnit'});
			} else {
			    @newSemCat = (":LABELREGEX:".$term->{'canonical_form'});
			}
			if (!exists($self->semFeaturesIndex->{$indexCat})) {
			    $self->semFeaturesIndex->{$indexCat}->{'ROOT'} = "REGEX";
			    $self->semFeaturesIndex->{$indexCat}->{'CAT'} = [];
			    $self->semFeaturesIndex->{$indexCat}->{'CAT2'} = {};
			    $self->semFeaturesIndex->{$indexCat}->{'SEEN_S'} = -1;
			    $self->semFeaturesIndex->{$indexCat}->{'SEEN_O'} = -1;
			}
			push @{$self->semFeaturesIndex->{$indexCat}->{'CAT'}}, [@newSemCat];
			$self->semFeaturesIndex->{$indexCat}->{'TERM'}->{$term->{'id'}} = $term;
			$self->semFeaturesIndex->{$indexCat}->{'CAT2'}->{join("/", @newSemCat)} = [@newSemCat];
		    }
		    $conjunction2 = 0;
		    
		} elsif ((scalar(@{$semCat}) == 1) &&
			 ($semCat->[0] eq "conjunction")) {
		    $conjunction2 = 1;
		} elsif (scalar(@{$semCat}) == 1) {
		    # $self->_addPredicate('last', $self->semanticCorrespondance->{$self->language}->{'PREDICATE'}->{$indexCat}->{'NAME'});
		    # warn "Predicate: " . $semCat->[0] . "\n";
		    if ((!exists $viewedPredicates{$semCat->[0]}) && 
			(exists $self->semanticCorrespondance->{$self->language}->{'PREDICATE'}->{$semCat->[0]})) {
			# warn "Predicate: " . $semCat->[0] . "\n";
			$viewedPredicates{$semCat->[0]}++;
			$self->query->_newWherePartLine;
			$self->query->_addPredicate('last', $semCat->[0]);
			if (exists $self->negation->{$term->{'id'}}) {
			    $self->negation->{$term->{'id'}} = scalar(@{$self->query->wherePart}) - 1;
			}
			foreach $aggregOp (keys %{$self->aggregation->{'TERM'}}) {
			    if (exists $self->aggregation->{'TERM'}->{$aggregOp}->{$term->{'id'}}) {
				$self->aggregation->{'TERM'}->{$aggregOp}->{$term->{'id'}} = $semCat->[0];
				$self->aggregation->{'PREDICATE'}->{$semCat->[0]} = $aggregOp; # = $term->{'id'};
				$self->_printVerbose("aggregation ($aggregOp) for " . $term->{'semanticUnit'} . " at " . $self->aggregation->{'TERM'}->{$aggregOp}->{$term->{'id'}} . " (" . $semCat->[0] . ")\n",2); 
			    }
			}
		    }
		    # }
		}
	    }
	}

	$self->_printVerbose("[LOG] Remove Property from semFeaturesIndex\n");
	# remove Property from semFeaturesIndex
	foreach $line (@{$self->query->wherePart}) {
	    delete $self->semFeaturesIndex->{$line->{'PREDICATE'}->[0]};
	}
	$self->query->_internalPrintOfWherePart; # (\@wherePart);

    } else {
	return(-1);
    }
    return(0);
}


sub _removeLargerExtractedTerms {
    my ($self) = @_;

    my $term;
    my $subterm;
    my $offset;
    my $delete;
    my @termstodelete;

    $self->_printVerbose("[LOG] remove larger extracted terms\n");

    for $term (@{$self->semanticUnits}) {
	# warn $term->{'semanticUnit'} . "\n";
	$delete = 0;
	if (scalar(keys %{$term->{'semanticTypes'}}) == 0) {
	    $offset = $term->{'start_offset'};
	    do {
		# warn "offset: $offset\n";
		# warn "=>" . ref($self->_getTerms($offset)) . "\n";
		if ($self->_getTerms($offset)) {
		    foreach $subterm (@{$self->_getTerms($offset)}) {
			if ($subterm->{'id'} != $term->{'id'}) {
			    # warn "\t" . $subterm->{'semanticUnit'} . "\n";
			    if (scalar(keys %{$subterm->{'semanticTypes'}}) > 0) {
				$delete = 1;
				push @termstodelete, $term;
				# warn "\t\t\t " . $term->{'semanticUnit'} . " to delete\n";
				last;
			    }
			}
		    }
		}
		$offset++;
	    } while(($delete == 0) && ($offset <= $term->{'end_offset'}));
	}

    }
    foreach $term (@termstodelete) {
	$self->_delSemanticUnit($term);
	$self->_printVerbose("remove " . $term->{'semanticUnit'} . "\n", 2);
    }
    $self->_printVerbose("done\n");
    return(scalar(@termstodelete));
}

sub _contextualRewriting {
    my ($self) = @_;

    my $term;
    my $semf;
    my $newsemf;
    my $semf2;
    my $newsemf2;
    my @tmpnewsemf2;
    my @tmpnewsemf;
    my $i;
    my $j;
    my $k;
#    my $lang = $self->language;
    my $rule;
    my $rules;
    my $semCat;

#    my @sortedSemanticUnits = sort {$a->start_token->getFrom <=> $b->start_token->getFrom} @{$document->getAnnotations->getSemanticUnitLevel->getElements};

    # foreach $term (@{$self->sortedSemanticUnits}) {
    # 	warn "=> " . $term->{'semanticUnit'} . "\n";
	
    # }

    $self->_printVerbose("[LOG] contextual rewriting\n");
    for($i=0; $i < scalar(@{$self->_sortedSemanticUnits}); $i++) {
	# warn "\n>>> " . $self->_sortedSemanticUnits->[$i]->{'semanticUnit'} . "\n";
	foreach $semf (keys %{$self->_sortedSemanticUnits->[$i]->{'semanticTypes'}}) {
	    # warn $semf . "\n";
	    if (exists $self->semanticCorrespondance->{$self->language}->{'CTXTL_REWRITE'}->{'RULE'}->{$semf}) {
		if (ref($self->semanticCorrespondance->{$self->language}->{'CTXTL_REWRITE'}->{'RULE'}->{$semf}) eq "HASH") {
		    $rules = [$self->semanticCorrespondance->{$self->language}->{'CTXTL_REWRITE'}->{'RULE'}->{$semf}];
		} else {
		    $rules = $self->semanticCorrespondance->{$self->language}->{'CTXTL_REWRITE'}->{'RULE'}->{$semf};
		}
	    } else {
		$rules = [];
	    }
	    # warn "rules: $rules\n";
	    for($k=0;$k < scalar(@$rules);$k++) {
#	    foreach $rule (@$rules) {
		$rule = $rules->[$k];
		for($j=$i+1;$j < scalar(@{$self->_sortedSemanticUnits}); $j++) {
		    foreach $semf2 (keys %{$self->_sortedSemanticUnits->[$j]->{'semanticTypes'}}) {
			# warn "\t" . $semf2 . " (" . $rule->{'CTXT'} . ")\n";
			# TEST TO REWRITE with a HASH TABLE
			if (($semf2 eq $rule->{'CTXT'}) || (index($semf2, $rule->{'CTXT'} . ":") == 0) || 
			    (index($semf2, $rule->{'CTXT'} . "/") == 0) || 
			    (index($semf2, ":" . $rule->{'CTXT'}) > 0)) {
			    if ($rule->{'NEWCTXT'} eq "") {
				$self->_printVerbose($self->_sortedSemanticUnits->[$j]->{'semanticUnit'} . ": del semf " . $semf2 . "\n",2);
				$self->_delSemanticType($self->_sortedSemanticUnits->[$j],$semf2);
			    } elsif ($rule->{'NEWCTXT'} ne "-") {
				$self->_printVerbose($self->_sortedSemanticUnits->[$j]->{'semanticUnit'} . ": rewrite ctxt " . $semf2 . " into " . $rule->{'NEWCTXT'} . "\n",2);
				$self->_modifySemanticType($self->_sortedSemanticUnits->[$j], $semf2, $rule->{'NEWCTXT'});
				# @tmpnewsemf2 = ();
				# foreach $newsemf2 (split /;/, $rule->{'NEWCTXT'}) {
				#     push @tmpnewsemf2, [split /\//, $newsemf2];
				# }
				# $semf2->semantic_category('list_refid_ontology_node', [@tmpnewsemf2]);
			    } else {
				$self->_printVerbose($self->_sortedSemanticUnits->[$j]->{'semanticUnit'} . ": keep same ctxt (" . $semf2 . ")\n",2);
			    }
			    $newsemf = $rule->{'NEWSF'};
			    if ($newsemf eq "") {
				$self->_printVerbose($self->_sortedSemanticUnits->[$i]->{'semanticUnit'} . ": del semf " . $semf . "\n",2);
				$self->_delSemanticType($self->_sortedSemanticUnits->[$i],$semf);
			    } elsif ($rule->{'NEWSF'} ne "-") {
				$self->_printVerbose($self->_sortedSemanticUnits->[$i]->{'semanticUnit'} . ": rewrite " . $semf . " into " . $rule->{'NEWSF'} . "\n\n",2);
				$self->_modifySemanticType($self->_sortedSemanticUnits->[$i], $semf, $rule->{'NEWSF'});
				# @tmpnewsemf = ();
				
				# foreach $newsemf (split /;/, $rule->{'NEWSF'}) {
				#     push @tmpnewsemf, [split /\//, $newsemf];
				# }
				# $semf->semantic_category('list_refid_ontology_node', [@tmpnewsemf]);
				$j=scalar(@{$self->_sortedSemanticUnits});
				$k=scalar(@$rules);
				last;
			    } else {
				$self->_printVerbose($self->_sortedSemanticUnits->[$i]->{'semanticUnit'} . ": keep same semf (" . $semf . ")\n\n",2);
			    }
			}
		    }
		}
	    }
	}
    }
    $self->_printVerbose("done\n\n");
}

sub _getSortedSemanticUnits {
    my ($self) = @_;

    my $semf;
    my $term;
    my @sortedSemanticUnits1;
    my @sortedSemanticUnits2;
    my @terms;

    $self->_printVerbose("[LOG] getSortedSemanticUnit\n");

    $self->_reset_sortedSemanticUnits;
    
    # my @sortedTermList = sort {$a->start_token->getFrom <=> $b->start_token->getFrom} @{$document->getAnnotations->getSemanticUnitLevel->getElements};


#    $document->getAnnotations->getSemanticFeaturesLevel->printIndex("refid_semantic_unit");
    foreach $term (@{$self->_sortedSemanticUnits}) {
	$self->_printVerbose("-> " . $term->{'semanticUnit'} . " : " . $term->{'id'} .  "\n", 2);
	if (scalar(keys %{$term->{'semanticTypes'}}) > 0) {
	    # warn "ok\n";
	    push @sortedSemanticUnits1, $term;
	    foreach $semf (keys %{$term->{'semanticTypes'}}) {
		# warn "==> " . $semf . " (" . $term->{'semanticUnit'} . ")\n";
		if ($semf eq "conjunction") {
		    $self->query->conjunction(1);
		}
	    }
	} else {
	    push @sortedSemanticUnits1, $term;
	    # REGEX
	    # warn "-> " . $term->{'semanticUnit'} . " -> REGEX\n";
	    $self->_addSemanticType($term, "REGEX");
	    # my $semFeatures = $self->_createSemanticFeaturesFromString("REGEX", $term->{'id'});
	    # if (defined $semFeatures) {
	    # 	$document->getAnnotations->addSemanticFeatures($semFeatures);
	    # }
	}
    }
#    push @$sortedSemanticUnits, @sortedSemanticUnits1;
    foreach $term (@sortedSemanticUnits1) {
	# warn "=> ". $term->{'semanticUnit'} . "\n";
    	if (scalar(@terms) == 0) {
    	    @terms = ($term);
    	} else {
    	    if ($term->{'start_offset'} == $terms[$#terms]->{'start_offset'}) {
    		push @terms, $term;		
    	    } else {
    		if (scalar(@terms) > 1) {
    		    # foreach my $term2 (@terms) {
    		    # 	# warn "\t" . $term2->{'semanticUnit'}. "\n";
    		    # }
    		    push @sortedSemanticUnits2, $self->_getLargerTerm(\@terms);
    		    # warn "keep: " . $sortedSemanticUnits->[$#$sortedSemanticUnits]->{'semanticUnit'} . "\n";
    		} else {
    		    push @sortedSemanticUnits2, @terms;
    		}
    		@terms = ($term);
    	    }
    	}
    }
    if (scalar(@terms) > 1) {
	# foreach my $term2 (@terms) {
	#     warn "\t" . $term2->{'semanticUnit'}. "\n";
	# }
	push @sortedSemanticUnits2, $self->_getLargerTerm(\@terms);
	# warn "keep: " . $sortedSemanticUnits->[$#$sortedSemanticUnits]->{'semanticUnit'} . "\n";
    } else {
	push @sortedSemanticUnits2, @terms;
    }

    @terms = ();
    my @sortedSemanticUnits = ();
    foreach $term (sort {$a->{'start_offset'} <=> $b->{'start_offset'}} @sortedSemanticUnits2) {
	 if (scalar(@terms) == 0) {
	     @terms = ($term);
	 } else {
    	    if ($term->{'end_offset'} <= $terms[$#terms]->{'end_offset'}) {
    		push @terms, $term;				
	    } else {
		push @sortedSemanticUnits, $self->_getLargerTerm(\@terms);
		@terms = ($term);
	    }
	 }
    
    }
    if (scalar(@terms) > 1) {
	# foreach my $term2 (@terms) {
	#     warn "\t" . $term2->{'semanticUnit'}. "\n";
	# }
	push @sortedSemanticUnits, $self->_getLargerTerm(\@terms);
#	$self->sortedSemanticUnits([$self->_getLargerTerm(\@terms)]);
	# warn "keep: " . $sortedSemanticUnits->[$#$sortedSemanticUnits]->{'semanticUnit'} . "\n";
    } else {
#	$self->sortedSemanticUnits([@terms]);
	push @sortedSemanticUnits, @terms;
    }

    $self->_sortedSemanticUnits([@sortedSemanticUnits]);

    # warn "---\n";
    # foreach $term (@{$self->_sortedSemanticUnits}) {
    #     warn "\t" . $term->{'semanticUnit'}. "\n";
    # }

    $self->_printVerbose("done\n\n");
}


sub _getLargerTerm {
    my ($self, $terms) = @_;

    my $largerTerm;
    my $tmpTerm;

    $largerTerm = $terms->[0];

    foreach $tmpTerm (@$terms) {
	if ($tmpTerm->{'id'} != $largerTerm->{'id'})  {
	    if (($tmpTerm->{'start_offset'} < $largerTerm->{'start_offset'}  ) ||
		($largerTerm->{'end_offset'}  < $tmpTerm->{'end_offset'})) {
		$largerTerm = $tmpTerm
	    }
	}
    }
    return($largerTerm);
}

sub _detecteNegation {
    my ($self) = @_;

    my $semf;
    my $term;
    my @terms;
    my $neg;

    $self->_printVerbose("[LOG] DetecteNegation\n");
    # # warn "semf#: " . scalar (@{$document->getAnnotations->getSemanticFeaturesLevel->getElements}) . "\n";
    # my @sortedTermList = sort {$a->start_token->getFrom <=> $b->start_token->getFrom} @{$document->getAnnotations->getSemanticUnitLevel->getElements};

    $neg=0;
    foreach $term (@{$self->_sortedSemanticUnits}) {
	# warn "-> " . $term->{'semanticUnit'} . "\n";
	if (scalar(keys %{$term->{'semanticTypes'}}) > 0) {
	    foreach $semf (keys %{$term->{'semanticTypes'}}) {
		# warn "==> " . $semf . " (" . $term->{'semanticUnit'} . ")\n";
		# foreach $semCat (@{$term->{'semanticTypes'}-{$semf}}) {
		# warn "\t" .  join('/', @$semCat) . "\n";
		if (exists $self->semanticCorrespondance->{$self->language}->{'PREDICATE'}->{$semf}) {
		    if ($neg == 1) {
			$self->negation->{$term->{'id'}}="";
			$self->_printVerbose($term->{'semanticUnit'} . " is negated\n",2);
			$neg=0;
		    }
		}
		if ($semf eq "negation") {
		    $self->_printVerbose("found negation\n",2);
		    $neg=1;
		}
#		}
	    }
	}
    }
}

sub _identifyAggregationOperator {
    my ($self) = @_;

    my $semf;
    my $term;
    my @sortedSemanticUnits1;
    my @terms;
    my @aggregOp = ();
    my $op;

    $self->_printVerbose("[LOG] _identifyAggregationOperator\n");
    foreach $term (@{$self->_sortedSemanticUnits}) {
	if (scalar(keys %{$term->{'semanticTypes'}}) > 0) {
	    foreach $semf (keys %{$term->{'semanticTypes'}}) {
		$self->_printVerbose("==> " . $semf . " (" . $term->{'semanticUnit'} . ")\n",2);
		# warn "$semf: " .  $term->{'semanticTypes'}->{$semf} . "\n";
#		foreach $semCat (@{$term->{'semanticTypes'}->{$semf}}) {
		if (exists $self->aggregation->{'TERM'}->{$semf}) {
		    push @aggregOp, $semf;
		}

		if (exists $self->semanticCorrespondance->{$self->language}->{'VARIABLE'}->{$semf}) {
		    if (scalar(@aggregOp) != 0) {
			foreach $op (@aggregOp) {
			    $self->aggregation->{'TERM'}->{$op}->{$term->{'id'}}="";
			    $self->_printVerbose($term->{'semanticUnit'} . " is aggregated ($op)\n",2);
			}
			@aggregOp = ();
		    }
		}
		if ($semf eq "exists") {
		    $self->aggregation->{'ASK'} = 1;
		}
#		}
	    }
	}
    }
}

sub _getQuestionTopic {
    my ($self) = @_;

    my $semf;
    my $found = 0;
#    my $questionTopic;
    my $questionTopicCat;
    my $i;
    my $aggregOp;

    # warn scalar(@{$self->_sortedSemanticUnits}) . "\n";
    $i = 0;
    do {
	if ($i < scalar(@{$self->_sortedSemanticUnits})) {
	    $self->_printVerbose("QT? " . $self->_sortedSemanticUnits->[$i]->{'semanticUnit'} . "\n",2);
	    foreach $semf (keys %{$self->_sortedSemanticUnits->[$i]->{'semanticTypes'}}) {
		$self->_printVerbose($semf . "\n",2);
		# foreach $semCat (@{$self->_sortedSemanticUnits->[$i]->{'semanticTypes'}->{$semf}}) {
		# $self->_printVerbose($self->language . "\n",2);
		# warn "\t" .  join('/', @$semCat) . "\n";
		$questionTopicCat = join('/', @{$self->_sortedSemanticUnits->[$i]->{'semanticTypes'}->{$semf}});
		$self->_printVerbose("questionTopicCat $questionTopicCat\n", 2);
		if (exists $self->semanticCorrespondance->{$self->language}->{'VARIABLE'}->{$questionTopicCat}) {
		    $self->questionTopic($self->semanticCorrespondance->{$self->language}->{'VARIABLE'}->{$questionTopicCat});
		    $self->_printVerbose("Question Topic: " . $questionTopicCat . " : " . $self->questionTopic . "\n",2);
		    $found = 1;
		    
		    foreach $aggregOp (keys %{$self->aggregation->{'TERM'}}) {
			if (exists $self->aggregation->{'TERM'}->{$aggregOp}->{$self->_sortedSemanticUnits->[$i]->{'id'}}) {
			    $self->aggregation->{'TERM'}->{$aggregOp}->{$self->_sortedSemanticUnits->[$i]->{'id'}} = $self->questionTopic;
				$self->aggregation->{'QT'}->{$aggregOp}->{$self->questionTopic} = $self->_sortedSemanticUnits->[$i]->{'id'};
			    $self->_printVerbose("aggregation ($aggregOp) for " . $self->_sortedSemanticUnits->[$i]->{'semanticUnit'} . " at " . $self->aggregation->{'TERM'}->{$aggregOp}->{$self->_sortedSemanticUnits->[$i]->{'id'}} . " (" . $self->questionTopic . ")\n",2); 
			}
		    }
		    # }
		} else {
		    # warn "no\n";
		}
	    }
	    $i++;
	}
    } while(($i < scalar(@{$self->_sortedSemanticUnits})) && (!$found));

    $self->_printVerbose("questionTopic: " . $self->questionTopic . "\n", 2);

    return($self->questionTopic);
}

sub _printVerbose {
    my($self, $msg, $level) = @_;

    if (!defined $level) {
	$level = 1;
    }

    if (($self->verbose > 0) && ($self->verbose >= $level)) {
	warn "$msg";
    }

}

1;

__END__

=head1 NAME

RDF::NLP::SPARQLQuery::Question - Perl extension for representing the natural language question.

=head1 SYNOPSIS

use RDF::NLP::SPARQLQuery::Question;

$question = RDF::NLP::SPARQLQuery::Question->new("docId" => $docId,
    'verbose' => 0,
    "language" => uc($language),
    "sentences" => \@sentences,
    "postags" => \@postags,
    "semanticUnits" => \@semanticUnits,
    "config" => $nlquestion->config,
    );

=head1 DESCRIPTION

This object represents the natural language question and provides methods for converting question in a SPARQL query.
The representation of the question includes several fields:

=over 4


=item *

C<docId>: identifier of the natural language question

=item *

C<verbose>: specification of the verbose

=item *

C<language>: language of the natural language question

=item *

C<sentences>: sentences of the natural language question

=item *

C<postags>: word information of the natural language question

=item *

C<semanticUnits>: semantic entities of the natural language question

=item *

C<sortedSemanticUnits>: sorted array of the semantic entities of the natural language question

=item *

C<semanticCorrespondance>: structure containing the semantic correspondance and the rewriting rules

=item *

C<aggregation>: structure recording the presence of aggregation operators

=item *

C<negation>: structure recording the negated semantic entities

=item *

C<union>: structure recording the semantic entities on which the union operator is applied

=item *

C<query>: reference to the SPARQL query (object C<RDF::NLP::SPARQLQuery::Query>)

=item *

C<questionTopic>: semantic type referring to the question topic

=item *

C<semFeaturesIndex>: index of the semantic types

=item *

C<config>: structure containing the configuration of the converter

=back

=head1 METHODS

=head2 new()

    new(%arguments);

The method creates and returns an object C<RDF::NLP::SPARQLQuery::Question> and sets the fields specified in C<%arguments>(usually C<verbose>, C<docId>, C<language>, C<sentences>, C<postags>, C<semanticUnits>, C<config>).

=head2 Question2Query()

    Question2Query($semanticCorrespondance);

The method converts the current natural language question in SPARQL query by using semantic correspondance and rewriting rules specified in C<$semanticCorrespondance>. The SPARQL query string is defined in the object referring to the SPARQL query (field C<query>).

=head2 questionAbstraction()

    questionAbstraction();

The method performs the question abstraction. This first step of the
conversion aims at identifying the relevant elements within the
questions and at building the representation of these elements.  It
relies on the linguistic and semantic annotations associated to the
question, and specified in the field C<semanticUnits>. Rewriting rules
may be applied. The aggregation operator, negation, question topic and
predicate/arguments are identifed at this step.


=head1 SEE ALSO

Documentation of the module C<RDF::NLP::SPARQLQuery>

=head1 AUTHORS

Thierry Hamon, E<lt>hamon@limsi.frE<gt>

=head1 LICENSE

Copyright (C) 2014 by Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

