package RDF::NLP::SPARQLQuery::Query;

use utf8;
use strict;
use warnings;
use Data::Dumper;

# use JSON:PP;
use HTTP::Request;
use LWP::UserAgent;
use URL::Encode;
# use XML::Simple;

use Storable qw (dclone);

use Mouse;

our $VERSION='0.1';

has 'verbose'         => (is => 'rw', isa => 'Int');
has 'docId'         => (is => 'rw', isa => 'Str');
has 'language'      => (is => 'rw', isa => 'Str');
has 'queryString'      => (is => 'rw', isa => 'Str');
has 'queryXMLString'      => (is => 'rw', isa => 'Str');
has 'queryAnswers'     => (is => 'rw', isa => 'HashRef');
has 'selectPart'     => (is => 'rw', isa => 'ArrayRef');
has 'wherePart'       => (is => 'rw', isa => 'ArrayRef');
has 'aggregation' => (is => 'rw', isa => 'HashRef');
has 'conjunction' => (is => 'rw', isa => 'Int');
has 'sentences' => (is => 'rw', isa => 'ArrayRef');
has 'negation' => (is => 'rw', isa => 'HashRef');
has 'varPrefix' => (is => 'rw', isa => 'Str');
has 'variableCounter' => (is => 'rw', isa => 'Int');
has 'variableSet' => (is => 'rw', isa => 'HashRef');
has 'union'       => (is => 'rw', isa => 'ArrayRef');
has 'semanticCorrespondance' => (is => 'rw', isa => 'HashRef');
has 'questionTopic' => (is => 'rw', isa => 'Str');
has 'semFeaturesIndex' => (is => 'rw', isa => 'HashRef');
has 'sortedSemanticUnits' => (is => 'rw', isa => 'ArrayRef');
has 'config' => (is => 'rw', isa => 'HashRef');

# has '' => (is => 'rw', isa => 'HashRef');


# DOC
sub new {
    my $class = shift;
    my %args = @_;

    my $Query = {
	"verbose" => 0,
	"docId" => undef,
	"language" => undef,
	"selectPart" => [],
	"wherePart" => [],
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
	"conjunction" => 0,
	"sentences" => [],
	"negation" => {},
	"config" => undef,
	"union" => [],
	"varPrefix" => "?v",
	"variableCounter" => 0,
	"variableSet" => {},
	"semanticCorrespondance" => undef,
	"questionTopic" => undef,
	'semFeaturesIndex' => {},
	'queryString' => "",
	'queryXMLString' => "",
	'queryAnswers' => {},
    };
    bless $Query, $class;

    $Query->verbose($args{'verbose'});
    $Query->docId($args{'docId'});
    $Query->language($args{'language'});
    $Query->negation($args{'negation'});
    $Query->sentences($args{'sentences'});
    $Query->union($args{'union'});
    $Query->aggregation($args{'aggregation'});
    $Query->semFeaturesIndex($args{'semFeaturesIndex'});
    $Query->config($args{'config'});
    $Query->semanticCorrespondance($args{'semanticCorrespondance'});
    $Query->sortedSemanticUnits($args{'sortedSemanticUnits'});

    return($Query);
}

sub _sortedSemanticUnits {
    my $self = shift;

    return($self->sortedSemanticUnits);
}

sub _regexForm {
    my $self = shift;

    return($self->config->{'NLQUESTION'}->{'language="' . uc($self->language) . '"'}->{'REGEXFORM'});
}

sub _unionOpt {
    my $self = shift;

    return($self->config->{'NLQUESTION'}->{'language="' . uc($self->language) . '"'}->{'UNION'});
}


sub _addQueryString {
    my $self = shift;


    if (@_) {
	my $str = shift;
	my $newStr = $self->queryString . $str;
#	warn $newStr;
	$self->queryString($newStr);
    }

    return($self->queryString);
}

sub _addQueryXMLString {
    my $self = shift;


    if (@_) {
	my $str = shift;
	my $newStr = $self->queryXMLString . $str;
#	warn $newStr;
	$self->queryXMLString($newStr);
    }

    return($self->queryXMLString);
}

sub _IncrVariableCounter {
    my $self = shift;
    my $step = 1;

    if (@_) {
	$step = shift;
    }

    $self->variableCounter($self->variableCounter + $step);
    return($self->variableCounter);
}

sub wherePart {
    my ($self) = @_;

    my $wherePart = [];
#    $self->_newWherePartLine($wherePart);
    return($wherePart);
}

sub _newWherePartLine {
    my ($self, $wherePart) = @_;

    if (!defined $wherePart) {
	$wherePart = $self->wherePart;
    }

    push @{$wherePart}, {'SUBJECT'   => "",
		       'PREDICATE' => [],
		       'OBJECT'    => "",
		       'NEGATION'  => 0,
		       'SEEN'      => 0,
    };
    return(scalar(@{$wherePart})-1);
}

sub _addNegation2Predicate {
    my ($self,$line) = @_;

    $line->{'NEGATION'} = 1;
}

sub _cloneLine {
    my ($self, $position, $line) = @_;

    my $pos = $position;
    if ($position eq 'last') {
	$pos = scalar(@{$self->wherePart}) - 1;
    }
    if ($position eq 'first') {
	$pos = 0;
    }

#    my $line;
    $line = $self->wherePart->[$pos];
    $pos = $self->_newWherePartLine; # ($wherePart);
    
#    warn "position: $pos -- $position\n";;
    $self->_addPredicate($pos, $line->{'PREDICATE'}->[0]);

    $self->_addSubject($pos, $line->{'SUBJECT'}->[1]);
    $self->_addObject($pos, $line->{'OBJECT'}->[1]);
    return($self->wherePart->[$pos]);
}

sub _addPredicate {
    my ($self, $position, $predicate) = @_;

#    warn $position;
    my $pos = $position;
    if ($position eq 'last') {
	$pos = scalar(@{$self->wherePart}) - 1;
    }
    if ($position eq 'first') {
	$pos=0;
    }
#    warn "$pos : " . $self->wherePart . "\n";
    # warn "==> ".  $self->semanticCorrespondance->{$self->language}->{'PREDICATE'}->{$predicate}->{'SUBJECT_TYPE'} . "\n";
    $self->_printVerbose("\t\tPredicate: $predicate\n",2);
    $self->wherePart->[$pos]->{'SUBJECT'} = [ $self->semanticCorrespondance->{$self->language}->{'PREDICATE'}->{$predicate}->{'SUBJECT_TYPE'}, ""];
    $self->wherePart->[$pos]->{'PREDICATE'} = [ $predicate,
					  $self->semanticCorrespondance->{$self->language}->{'PREDICATE'}->{$predicate}->{'NAME'},
	];
    $self->wherePart->[$pos]->{'OBJECT'} = [$self->semanticCorrespondance->{$self->language}->{'PREDICATE'}->{$predicate}->{'OBJECT_TYPE'}, ""];
    $self->wherePart->[$pos]->{'SEEN'} = 0;
    return($self->wherePart->[$pos]);
}

sub _addPredicateSameAs {
    my ($self, $wherePart, $position, $subject) = @_;

    my $pos = $position;

    if ($position eq 'last') {
	$pos=$#$wherePart;
#	$pos = scalar(@{$self->wherePart}) - 1;
    }
    if ($position eq 'first') {
	$pos=0;
    }
#    warn "pos: $pos\n";
    # warn "==> ".  $self->semanticCorrespondance->{$self->language}->{'PREDICATE'}->{$predicate}->{'SUBJECT_TYPE'} . "\n";
    $wherePart->[$pos]->{'SUBJECT'} = [ $subject, ""];
    $wherePart->[$pos]->{'PREDICATE'} = [ "sameAs",
					  $self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'ROOT'},
	];
    $wherePart->[$pos]->{'OBJECT'} = [$self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$subject}, ""];
    $wherePart->[$pos]->{'SEEN'} = 0;
}

sub _addSubject {
    my ($self, $position, $subject) = @_;

    my $pos = $position;
    if ($position eq 'last') {
	$pos = scalar(@{$self->wherePart}) - 1;
    }
    if ($position eq 'first') {
	$pos=0;
    }
    $self->wherePart->[$pos]->{'SUBJECT'}->[1] = $subject;
    $self->wherePart->[$pos]->{'SEEN'} = 1;

}
sub _addSubjectLine {
    my ($self, $line, $subject) = @_;

    $line->{'SUBJECT'}->[1] = $subject;
    $line->{'SEEN'} = 1;

}

sub _addObject {
    my ($self, $position, $object) = @_;

    my $pos = $position;
    if ($position eq 'last') {
	$pos = scalar(@{$self->wherePart}) - 1;
    }
    if ($position eq 'first') {
	$pos=0;
    }
    # warn "pos: $pos\n";
    $self->wherePart->[$pos]->{'OBJECT'}->[1] = $object;
    $self->wherePart->[$pos]->{'SEEN'} = 1;

}

sub _addObjectLine {
    my ($self, $line, $object) = @_;

    $line->{'OBJECT'}->[1] = $object;
    $line->{'SEEN'} = 1;

}

sub _internalPrintOfWherePart {
    my ($self) = @_;
    my $line;
    
    if ($self->verbose == 0) {
	return(0);
    }

    foreach $line (@{$self->wherePart}) {
	warn $line->{'SUBJECT'}->[0] . " : " . $line->{'PREDICATE'}->[0] . " : " . $line->{'OBJECT'}->[0] . "\n";
	if ($line->{'SUBJECT'}->[1] ne "") {
	    print STDERR $line->{'SUBJECT'}->[1];
	} else {
	    print STDERR "    #    ";
	}
	print STDERR " : ";
	if ($line->{'PREDICATE'}->[1] ne "") {
	    print STDERR $line->{'PREDICATE'}->[1];
	} else {
	    print STDERR "    #    ";
	}
	print STDERR " : ";
	if ($line->{'OBJECT'}->[1] ne "") {
	    print STDERR $line->{'OBJECT'}->[1];
	} else {
	    print STDERR "    #    ";
	}
	print STDERR "\n\n";
    }
    print STDERR "********************\n";

}

# DOC
sub queryConstruction  {
    my $self = shift;
    my $questionTopic = shift;

    # my $varPrefix="?v";
    # my $variableCounter = 0;
    # my $variable = "";
    # my $i;

    $self->questionTopic($questionTopic);

    # Add question topic variable
    $self->_printVerbose("[LOG] Add question topic variable (" . $self->questionTopic . ")\n");
    $self->_setQuestionTopicVariable; # ($self->questionTopic);
    $self->_printVerbose("[LOG] Question Topic (1): " . $self->questionTopic . "\n");

    $self->_printVerbose("Select Part: " . join(';',@{$self->selectPart}) . "\n",2);

    $self->_internalPrintOfWherePart;

    
    $self->_printVerbose("[LOG] Unified internal subject/object\n");
    # PROBLEM HERE: KEEP THIS?
    if ($self->conjunction == 1) {
	$self->_unifiedVariables;
	$self->_internalPrintOfWherePart;
    }
    # Get Property
    $self->_printVerbose("[LOG] Get Property\n");
    $self->_getProperty;


    $self->_internalPrintOfWherePart;
    $self->_printVerbose("[LOG] Complete property with REGEX\n");
    # $self->_getPropertyFromRegex(\@wherePart, \%semFeaturesIndex, \$replacedPredicate, $conjunction, $lang);

    # $self->_internalPrintOfWherePart;
    $self->_printVerbose("[LOG] if semantic Type remaining\n");

    $self->_printVerbose("[LOG] Unified internal subject/object\n");
    $self->_unifiedVariables;
    $self->_internalPrintOfWherePart;


    $self->_UsingSameAs;
    $self->_internalPrintOfWherePart;

    $self->_printVerbose("[LOG] Unified internal subject/object (2)\n");
    $self->_unifiedVariables;
    $self->_internalPrintOfWherePart;


    $self->_printVerbose("[LOG] connect question Topic (2)\n");
    $self->_setQuestionTopicVariable2;
    $self->_printVerbose("Question Topic (2): $questionTopic\n");
    
    $self->_internalPrintOfWherePart;

    $self->_printVerbose("[LOG] Add variables for remaining unconnected Property\n");
    $self->_connectRemainingElementsWithString; # (\%semFeaturesIndex, \@sortedSemanticUnits);
    $self->_connectRemainingElements; # (\%semFeaturesIndex);

    $self->_internalPrintOfWherePart;

    $self->_printVerbose("[LOG] Add Negation\n");
    $self->_addNegation;
    $self->_internalPrintOfWherePart;

}

sub _setQuestionTopicVariable {
    my ($self) = @_;
    my $i;
    my $line;
    my $variable;
    my $aggregOp;

    for($i=0; $i < scalar(@{$self->wherePart}); $i++) {
	$line = $self->wherePart->[$i];
	if ($line->{'SUBJECT'}->[1] eq "") {
	    # new variable;
	    if (($self->questionTopic eq $line->{'SUBJECT'}->[0]) # ||
		# ($self->{'SEMTYPECORRESP'}->{$lang}->{'SAMEAS'}->{'CORRESP'}->{$line->{'SUBJECT'}->[0]} eq $self->questionTopic) ||
		# ($self->{'SEMTYPECORRESP'}->{$lang}->{'SAMEAS'}->{'CORRESP'}->{$self->questionTopic} eq $line->{'SUBJECT'}->[0])
		) {
		$variable=$self->varPrefix . $self->variableCounter;
		$self->_IncrVariableCounter;
		$self->_addSubjectLine($line, $variable);
#		    $line->{'SUBJECT'}->[1] = $variable;
		$self->variableSet->{$variable}++;
		$self->_printVerbose("\tvariable: $variable\n",2);
		push @{$self->selectPart}, $variable;
		foreach $aggregOp (keys %{$self->aggregation->{'TERM'}}) {
		    if (exists $self->aggregation->{'QT'}->{$aggregOp}->{$self->questionTopic}) {
			$self->_printVerbose("aggregation Op: $aggregOp (S)\n",2);
			$self->aggregation->{'QTVAR'}->{$aggregOp}->{$variable} = $self->questionTopic;
		    }
		}
		last;
	    }
	} 
	if ($line->{'OBJECT'}->[1] eq "") {
	    # new variable
	    # warn "new variable (Obj)?\n";
	    if (($self->questionTopic eq $line->{'OBJECT'}->[0]) # ||
		# ($self->{'SEMTYPECORRESP'}->{$lang}->{'SAMEAS'}->{'CORRESP'}->{$line->{'OBJECT'}->[0]} eq $self->questionTopic) ||
		# ($self->{'SEMTYPECORRESP'}->{$lang}->{'SAMEAS'}->{'CORRESP'}->{$self->questionTopic} eq $line->{'OBJECT'}->[0])
		) {
		$variable=$self->varPrefix . $self->variableCounter;
		# warn "\t==> $variable\n";
		$self->_IncrVariableCounter;
		$self->_addObjectLine($line, $variable);
#		    $line->{'OBJECT'}->[1] = $variable;
		$self->variableSet->{$variable}++;
		$self->_printVerbose("\tvariable: $variable\n",2);
		push @{$self->selectPart}, $variable;
		foreach $aggregOp (keys %{$self->aggregation->{'TERM'}}) {
		    if (exists $self->aggregation->{'QT'}->{$aggregOp}->{$self->questionTopic}) {
			$self->_printVerbose("aggregation Op: $aggregOp (O) $variable - $self->questionTopic\n",2);

			$self->aggregation->{'QTVAR'}->{$aggregOp}->{$variable} = $self->questionTopic;
		    }
		}
		last;
	    }
	}
    }
}

sub _setQuestionTopicVariable2 {
    my ($self) = @_;
    my $i;
    my $line;
    my $variable;
    my $aggregOp;

    my %invnegation = reverse %{$self->negation};

    for($i=0; $i < scalar(@{$self->wherePart}); $i++) {
	# warn "new variable ($i)?\n";
	if (!exists $invnegation{$i}) {
	    $line = $self->wherePart->[$i];
	    if ($line->{'SUBJECT'}->[1] eq "") {
		# new variable;
		# warn "$self->questionTopic eq " . $line->{'SUBJECT'}->[0] . "?\n";
		if (($self->questionTopic eq $line->{'SUBJECT'}->[0]) ||
		    ((exists $self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line->{'SUBJECT'}->[0]}) &&
		     ($self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line->{'SUBJECT'}->[0]} eq $self->questionTopic)) ||
		    ((exists $self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$self->questionTopic}) &&
		     ($self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$self->questionTopic} eq $line->{'SUBJECT'}->[0]))
		    ) {
		    if (scalar(@{$self->selectPart}) == 0) {
			$variable=$self->varPrefix . $self->variableCounter;
			$self->_IncrVariableCounter;
			push @{$self->selectPart}, $variable;
		    } else {
			$variable=$self->selectPart->[0];
		    }
		    $self->_printVerbose("ADD QT2S\n",2);
		    $self->_addSubjectLine($line, $variable);
		    $self->variableSet->{$variable}++;
		    foreach $aggregOp (keys %{$self->aggregation->{'TERM'}}) {
			if (exists $self->aggregation->{'QT'}->{$aggregOp}->{$self->questionTopic}) {
			    $self->_printVerbose("aggregation Op: $aggregOp (S)\n", 2);
			    $self->aggregation->{'QTVAR'}->{$aggregOp}->{$variable} = $self->questionTopic;
			}
		    }
		}
	    } 
	    if ($line->{'OBJECT'}->[1] eq "") {
		# new variable
		# warn "$self->questionTopic eq " . $line->{'OBJECT'}->[0] . "?\n";
		if (($self->questionTopic eq $line->{'OBJECT'}->[0]) ||
		    ((exists $self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line->{'OBJECT'}->[0]}) &&
		     ($self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line->{'OBJECT'}->[0]} eq $self->questionTopic)) ||
		    ((exists $self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$self->questionTopic}) &&
		     ($self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$self->questionTopic} eq $line->{'OBJECT'}->[0]))
		    ) {
		    if (scalar(@{$self->selectPart}) == 0) {
			$variable=$self->varPrefix . $self->variableCounter;
			$self->_IncrVariableCounter;
			push @{$self->selectPart}, $variable;
		    } else {
			$variable=$self->selectPart->[0];
		    }
		    $self->_printVerbose("ADD QT2O\n",2);
		    $self->_addObjectLine($line, $variable);
		    $self->variableSet->{$variable}++;
		    foreach $aggregOp (keys %{$self->aggregation->{'TERM'}}) {
			if (exists $self->aggregation->{'QT'}->{$aggregOp}->{$self->questionTopic}) {
			    $self->_printVerbose("aggregation Op: $aggregOp (O)\n",2);
			    $self->aggregation->{'QTVAR'}->{$aggregOp}->{$variable} = $self->questionTopic;
			}
		    }
		}
	    }
	}
    }
    # warn "done\n";
}

sub _addNegation {
    my ($self) = @_;

    my $line;
    my $lineNb;

    # warn "in addNegation\n";
    if (scalar(keys(%{$self->negation})) > 0) {
	foreach $lineNb (values %{$self->negation}) {
	    if (scalar(@{$self->wherePart}) == 1) {
		$self->_newWherePartLine;
		$line = $self->_addPredicate('last', 'rdf:type');
		# TO CHANGE
		$self->_addSubjectLine($line, $self->selectPart->[0]);
	    }
	    $self->_addNegation2Predicate($self->wherePart->[$lineNb]);

	    if ($self->wherePart->[$lineNb]->{'SUBJECT'}->[1] eq $self->selectPart->[0]) {
	    	$self->_printVerbose($self->wherePart->[$lineNb]->{'SUBJECT'}->[0] . "\n",2);
	    	$self->_addObjectLine($line, $self->semanticCorrespondance->{$self->language}->{'DEFAULT_ROOT'} . "/" . 
	    			      $self->semanticCorrespondance->{$self->language}->{'RDFTYPE'}->{$self->wherePart->[$lineNb]->{'SUBJECT'}->[0]});
	    } elsif ($self->wherePart->[$lineNb]->{'OBJECT'}->[1] eq $self->selectPart->[0]) {
	    	$self->_printVerbose($self->wherePart->[$lineNb]->{'OBJECT'}->[0] . "\n",2);
	    	$self->_addObjectLine($line, $self->semanticCorrespondance->{$self->language}->{'DEFAULT_ROOT'} .  "/" . 
	    			      $self->semanticCorrespondance->{$self->language}->{'RDFTYPE'}->{$self->wherePart->[$lineNb]->{'OBJECT'}->[0]});
	    }
	}
    }
    # warn "done\n";
}


sub _UsingSameAs {
    my ($self) = @_;

    my $i;
    my $line;
    my $j;
    my $line2;
    $self->_printVerbose("[LOG] UsingSameAs?\n");

    my @wherePartAdd;

    for($i=0; $i < scalar(@{$self->wherePart}); $i++) {
	$line = $self->wherePart->[$i];
	if ($line->{'SUBJECT'}->[1] eq "") {
	    for($j=$i+1;$j < scalar(@{$self->wherePart}); $j++) {
		$line2 = $self->wherePart->[$j];
		if ((exists $self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line->{'SUBJECT'}->[0]}) && 
		    ($self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line->{'SUBJECT'}->[0]} eq $line2->{'SUBJECT'}->[0])) {
		    $self->_newWherePartLine(\@wherePartAdd);
		    $self->_addPredicateSameAs(\@wherePartAdd, 'last', $line->{'SUBJECT'}->[0]);
		    $self->_printVerbose("1a\n",2);
		} elsif ((exists $self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line->{'SUBJECT'}->[0]}) &&
		    ($self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line->{'SUBJECT'}->[0]} eq $line2->{'OBJECT'}->[0])) {
		    $self->_newWherePartLine(\@wherePartAdd);
		    $self->_addPredicateSameAs(\@wherePartAdd, 'last', $line->{'SUBJECT'}->[0]);
		    $self->_printVerbose("2a\n",2);
		} elsif ((exists $self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line2->{'SUBJECT'}->[0]}) && 
		    ($line->{'SUBJECT'}->[0] eq $self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line2->{'SUBJECT'}->[0]})) {
		    $self->_newWherePartLine(\@wherePartAdd);
		    $self->_addPredicateSameAs(\@wherePartAdd, 'last', $line2->{'SUBJECT'}->[0]);
		    $self->_printVerbose("3a\n",2);
		} elsif ((exists $self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line2->{'OBJECT'}->[0]}) &&
		    ($line->{'SUBJECT'}->[0] eq $self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line2->{'OBJECT'}->[0]})) {
		    $self->_newWherePartLine(\@wherePartAdd);
		    $self->_addPredicateSameAs(\@wherePartAdd, 'last', $line2->{'OBJECT'}->[0]);
		    $self->_printVerbose("4a\n",2);
		}
	    }
	} 
	if ($line->{'OBJECT'}->[1] eq "") {
	    for($j=$i+1;$j < scalar(@{$self->wherePart}); $j++) {
		$line2 = $self->wherePart->[$j];
		if ((exists $self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line->{'OBJECT'}->[0]}) && 
		    ($self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line->{'OBJECT'}->[0]} eq $line2->{'SUBJECT'}->[0])) {
		    $self->_printVerbose("1b\n",2);
		    $self->_newWherePartLine(\@wherePartAdd);
		    $self->_addPredicateSameAs(\@wherePartAdd, 'last', $line->{'OBJECT'}->[0]);
		} elsif ((exists $self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line->{'OBJECT'}->[0]}) &&
			($self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line->{'OBJECT'}->[0]} eq $line2->{'OBJECT'}->[0])) {
		    $self->_printVerbose("2b\n",2);
		    $self->_newWherePartLine(\@wherePartAdd);
		    $self->_addPredicateSameAs(\@wherePartAdd, 'last', $line->{'OBJECT'}->[0]);
		} elsif ((exists $self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line2->{'OBJECT'}->[0]}) &&
			($line->{'OBJECT'}->[0] eq $self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line2->{'OBJECT'}->[0]})) {
		    $self->_printVerbose("3b\n",2);
		    $self->_newWherePartLine(\@wherePartAdd);
		    $self->_addPredicateSameAs(\@wherePartAdd, 'last', $line2->{'OBJECT'}->[0]);
		} elsif ((exists $self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line2->{'SUBJECT'}->[0]}) &&
			($line->{'OBJECT'}->[0] eq $self->semanticCorrespondance->{$self->language}->{'SAMEAS'}->{'CORRESP'}->{$line2->{'SUBJECT'}->[0]})) {
		    $self->_printVerbose("4b\n",2);
		    $self->_newWherePartLine(\@wherePartAdd);
		    $self->_addPredicateSameAs(\@wherePartAdd, 'last', $line2->{'SUBJECT'}->[0]);
		}
	    }
	}
    }
    push @{$self->wherePart}, @wherePartAdd;
    $self->_printVerbose("done\n");
    
}

sub _unifiedVariables {
    my ($self) = @_;

    # Unified internal subject/object
    my $variable;
    my $i;
    my $line;
    my $j;
    my $line2;
    for($i=0; $i < scalar(@{$self->wherePart}); $i++) {
	$line = $self->wherePart->[$i];
	if ($line->{'SUBJECT'}->[1] eq "") {
	    for($j=$i+1;$j < scalar(@{$self->wherePart}); $j++) {
		$line2 = $self->wherePart->[$j];
		if (($line2->{'SUBJECT'}->[1] eq "") && ($line->{'SUBJECT'}->[0] eq $line2->{'SUBJECT'}->[0])) {
		    $variable=$self->varPrefix . $self->variableCounter;
		    # warn "\t==> $variable (Subj/Subj)\n";
		    $self->_IncrVariableCounter;
		    $self->_addSubjectLine($line, $variable);
		    $self->_addSubjectLine($line2, $variable);
		} elsif (($line2->{'OBJECT'}->[1] eq "") && ($line->{'SUBJECT'}->[0] eq $line2->{'OBJECT'}->[0])) {
		    $variable=$self->varPrefix . $self->variableCounter;
		    # warn "\t==> $variable (Obj/Subj)\n";
		    $self->_IncrVariableCounter;
		    $self->_addSubjectLine($line, $variable);
		    $self->_addObjectLine($line2, $variable);
		}
	    }
	} 
	if ($line->{'OBJECT'}->[1] eq "") {
	    for($j=$i+1;$j < scalar(@{$self->wherePart}); $j++) {
		$line2 = $self->wherePart->[$j];
		if (($line2->{'SUBJECT'}->[1] eq "") && ($line->{'OBJECT'}->[0] eq $line2->{'SUBJECT'}->[0])) {
		    $variable=$self->varPrefix . $self->variableCounter;
		    # warn "\t==> $variable (Subj/Subj)\n";
		    $self->_IncrVariableCounter;
		    $self->_addObjectLine($line, $variable);
		    $self->_addSubjectLine($line2, $variable);
		} elsif (($line2->{'OBJECT'}->[1] eq "") && ($line->{'OBJECT'}->[0] eq $line2->{'OBJECT'}->[0])) {
		    $variable=$self->varPrefix . $self->variableCounter;
		    # warn "\t==> $variable (Obj/Subj)\n";
		    $self->_IncrVariableCounter;
		    $self->_addObjectLine($line, $variable);
		    $self->_addObjectLine($line2, $variable);
		}
	    }
	}
    }
}


sub _connectRemainingElements {
    my ($self) = @_;

    # Unified internal subject/object
    my $variable;
    my $i;
    my $line;
    my $term;
    my $indexCat;
    my $str;

    for($i=0; $i < scalar(@{$self->wherePart}); $i++) {
	$line = $self->wherePart->[$i];
	if ($line->{'SUBJECT'}->[1] eq "") {
	    $variable=$self->varPrefix .$self->variableCounter;
	    # warn "\t==> $variable (Subj/Subj)\n";
	    $self->_IncrVariableCounter;
	    $self->_addSubjectLine($line, $variable);
	} 
	if ($line->{'OBJECT'}->[1] eq "") {
	    $variable=$self->varPrefix .$self->variableCounter;
	    # warn "\t==> $variable (Subj/Subj)\n";
	    $self->_IncrVariableCounter;
	    $self->_addObjectLine($line, $variable);
	}
    }

}

sub _connectRemainingElementsWithString {
    my ($self) = @_;

    # Unified internal subject/object
    my $variable;
    my $i;
    my $line;
    my $term;
    my $term2;
    my $indexCat;
    my $str;
    my $found = 0;
    my $j;

    for($i=scalar(@{$self->wherePart}) - 1; $i >= 0; $i--) {
	$line = $self->wherePart->[$i];
	if (($line->{'SUBJECT'}->[1] eq "") && ($line->{'SUBJECT'}->[0] eq "STRING")) {
#	    warn $line->{'PREDICATE'}->[0] . " (S)\n";

	    $found = 0;
	    for($j=scalar(@{$self->_sortedSemanticUnits})-1;$j>=0;$j--) {
		$term = $self->_sortedSemanticUnits->[$j];
		foreach $indexCat (keys %{$self->semFeaturesIndex}) {
#		    warn "indexCat: $indexCat\n";
		    if ((exists $self->semFeaturesIndex->{$indexCat}->{'TERM'}->{$term->{'id'}}) &&
			(($self->semFeaturesIndex->{$indexCat}->{'SEEN_S'} == -1) && ($self->semFeaturesIndex->{$indexCat}->{'SEEN_O'} == -1))) {
			$self->_printVerbose("=-> " . $term->{'semanticUnit'} . " ($indexCat)\n",2);
			if ($self->_regexForm == 1) {
			    $str = "REGEX/:LABELREGEX:" . $term->{'semanticUnit'} ;
			} else  {
			    $str = "REGEX/:LABELREGEX:" . $term->{'canonical_form'} ;
			}
			$self->_addSubjectLine($line, $str);
			if ($self->conjunction == 1) {
			    my $line2 = $self->_cloneLine($i, $line);
			    foreach $term2 (values %{$self->semFeaturesIndex->{$indexCat}->{'TERM'}}) {
				if ($term2->{'id'} ne $term->{'id'}) {
				    $self->_printVerbose("=-> " . $term2->{'semanticUnit'} . " ($indexCat - 2 - conj)\n",2);
				    if ($self->_regexForm == 1) {
					$str = "REGEX/:LABELREGEX:" . $term2->{'semanticUnit'} ;
				    } else  {
					$str = "REGEX/:LABELREGEX:" . $term2->{'canonical_form'} ;
				    }
				    $self->_addSubjectLine($line2, $str);
				}
			    }
			}
			$found = 1;
			last;
		    }
		}
		$self->_printVerbose("==\n",2);
		if ($found == 1) {
		    last;
		}
	    }
	} 
	if (($line->{'OBJECT'}->[1] eq "") && ($line->{'OBJECT'}->[0] eq "STRING")) {
	    $self->_printVerbose($line->{'PREDICATE'}->[0] . " (O)\n",2);

	    $found = 0;
	    for($j=scalar(@{$self->_sortedSemanticUnits})-1;$j>=0;$j--) {
		$term = $self->_sortedSemanticUnits->[$j];
		foreach $indexCat (keys %{$self->semFeaturesIndex}) {
		    $self->_printVerbose("indexCat: $indexCat\n",2);
		    if ((exists $self->semFeaturesIndex->{$indexCat}->{'TERM'}->{$term->{'id'}}) &&
			(($self->semFeaturesIndex->{$indexCat}->{'SEEN_S'} == -1) && ($self->semFeaturesIndex->{$indexCat}->{'SEEN_O'} == -1))) {
			$self->_printVerbose("=-> " . $term->{'semanticUnit'} . " ($indexCat)\n",2);
			if ($self->_regexForm == 1) {
			    $str = "REGEX/:LABELREGEX:" . $term->{'semanticUnit'} ;
			} else  {
			    $str = "REGEX/:LABELREGEX:" . $term->{'canonical_form'} ;
			}
			$self->_addObjectLine($line, $str);
			if ($self->conjunction == 1) {
			    my $line2 = $self->_cloneLine($i, $line);
			    foreach $term2 (values %{$self->semFeaturesIndex->{$indexCat}->{'TERM'}}) {
				if ($term2->{'id'} ne $term->{'id'}) {
				    $self->_printVerbose("=-> " . $term2->{'semanticUnit'} . " ($indexCat - 2 - conj)\n",2);
				    if ($self->_regexForm == 1) {
					$str = "REGEX/:LABELREGEX:" . $term2->{'semanticUnit'} ;
				    } else  {
					$str = "REGEX/:LABELREGEX:" . $term2->{'canonical_form'} ;
				    }
				    $self->_addObjectLine($line2, $str);
				}
			    }
			}
			$found = 1;
			last;
		    }
		}
		$self->_printVerbose("==\n",2);
		if ($found == 1) {
		    last;
		}
	    }
	}
    }

}

sub _getProperty {
    my ($self) = @_;

#	    $conjunction2 = 0;

    my $replacedPredicate;
    my $i;
    my $line;
    my $semCat;
    my $wherePartSize = scalar(@{$self->wherePart})-1;

    my $tmpSuffix="";
    for($i=$wherePartSize;$i >= 0; $i--) {
	$self->_printVerbose("# " . $wherePartSize . "\n",2);
	$line = $self->wherePart->[$i];
	$replacedPredicate=0;
	$self->_printVerbose(">> " . $line->{'PREDICATE'}->[0] . " ($i)\n",2);
	if (($self->semanticCorrespondance->{$self->language}->{'PREDICATE'}->{$line->{'PREDICATE'}->[0]}->{'OBJECT_TYPE'} ne "")
	    && ($line->{'OBJECT'}->[1] eq "")
	    ) {
	    my $tmp = $self->semanticCorrespondance->{$self->language}->{'PREDICATE'}->{$line->{'PREDICATE'}->[0]}->{'OBJECT_TYPE'};
	    $self->_printVerbose("==> $tmp\n",2);
	    # if (exists $self->semanticCorrespondance->{$self->language}->{'RESOURCE'}->{$tmp}) {
	    if ((exists $self->semFeaturesIndex->{$tmp}) && ($self->semFeaturesIndex->{$tmp}->{'SEEN_O'} == -1)){
#		    if (exists $self->semFeaturesIndex->{$tmp}) {
#		warn "OK\n";
		# warn "ROOT: " .  $self->semanticCorrespondance->{$self->language}->{'RESOURCE'}->{$self->semFeaturesIndex->{$tmp}->{'ROOT'}}->{'ROOT'} . "\n";
		my $str;
		my @t;
		if (exists $self->semanticCorrespondance->{$self->language}->{'RESOURCE'}->{$self->semFeaturesIndex->{$tmp}->{'ROOT'}}->{'ROOT'}) {
		    $str = $self->semanticCorrespondance->{$self->language}->{'RESOURCE'}->{$self->semFeaturesIndex->{$tmp}->{'ROOT'}}->{'ROOT'};
		    $str .= "/";
		    
		    @t = @{$self->semFeaturesIndex->{$tmp}->{'CAT'}->[0]};
		    $str .= $self->semanticCorrespondance->{$self->language}->{'RESOURCE'}->{$self->semFeaturesIndex->{$tmp}->{'ROOT'}}->{'CORRESP'}->{$t[$#t-1]};
		    $str .= "/" . $t[$#t];
		} else {
		    $str=$self->semFeaturesIndex->{$tmp}->{'ROOT'} . '/' . join('/', @{$self->semFeaturesIndex->{$tmp}->{'CAT'}->[0]});
		    @t = @{$self->semFeaturesIndex->{$tmp}->{'CAT'}->[0]};
		}
		$self->_printVerbose(">>>>$str (S - " . $self->conjunction . ")\n",2);
		$self->_addObjectLine($line, $str);			
		$self->semFeaturesIndex->{$tmp}->{'SEEN_O'}++;
		$replacedPredicate=1;
#			delete $self->semFeaturesIndex->{$tmp};
		if ($self->conjunction == 1) {
		    $self->_printVerbose(">>>>$str (S - conj)\n",2);
		    $self->_printVerbose("    " . join(':',keys(%{$self->semFeaturesIndex->{$tmp}->{'CAT2'}})) . "\n",2);
		    $self->_printVerbose("    " . join(':',@t) . "\n",2);
		    if (($t[0] eq "drug") && ($self->_unionOpt == 1)) {
			$self->_printVerbose("UNION ($i)\n",2);
			push @{$self->union}, $i;
		    }
		    foreach $semCat (keys(%{$self->semFeaturesIndex->{$tmp}->{'CAT2'}})) {
			$self->_printVerbose("$semCat\n",2);
			# warn "ROOT: ". $self->semFeaturesIndex->{$tmp}->{'ROOT'} . "\n";
			if ($semCat ne join('/', @t)) {
			    $self->_printVerbose("==> Duplicate last (S - $i)\n",2);
			    my $line2 = $self->_cloneLine($i, $line);
			    my @t2 = @{$self->semFeaturesIndex->{$tmp}->{'CAT2'}->{$semCat}};
			    $self->_printVerbose(join('/', @t2) . " - $tmp\n",2);
			    my $str = $self->semanticCorrespondance->{$self->language}->{'RESOURCE'}->{$self->semFeaturesIndex->{$tmp}->{'ROOT'}}->{'ROOT'};
			    $str .= "/";
			    $str .= $self->semanticCorrespondance->{$self->language}->{'RESOURCE'}->{$self->semFeaturesIndex->{$tmp}->{'ROOT'}}->{'CORRESP'}->{$t2[$#t2-1]};
			    $str .= "/" . $t2[$#t2];
			    $self->_addObjectLine($line2, $str);
			    $self->_printVerbose("done - $str\n",2);
			}
		    }
		}
	    }
	}
	if (($self->semanticCorrespondance->{$self->language}->{'PREDICATE'}->{$line->{'PREDICATE'}->[0]}->{'SUBJECT_TYPE'} ne "") 
	    && ($line->{'SUBJECT'}->[1] eq "")
	    ) {
	    my $tmp = $self->semanticCorrespondance->{$self->language}->{'PREDICATE'}->{$line->{'PREDICATE'}->[0]}->{'SUBJECT_TYPE'};
	    if ((exists $self->semFeaturesIndex->{$tmp}) && ($self->semFeaturesIndex->{$tmp}->{'SEEN_S'} == -1) && ($replacedPredicate==0)){
		my $str = $self->semanticCorrespondance->{$self->language}->{'RESOURCE'}->{$self->semFeaturesIndex->{$tmp}->{'ROOT'}}->{'ROOT'};
		$str .= "/";
		
		my @t = @{$self->semFeaturesIndex->{$tmp}->{'CAT'}->[0]};
		$str .= $self->semanticCorrespondance->{$self->language}->{'RESOURCE'}->{$self->semFeaturesIndex->{$tmp}->{'ROOT'}}->{'CORRESP'}->{$t[$#t-1]};
		$str .= "/" . $t[$#t];
		$self->_printVerbose(">>>>$str (O - " . $self->conjunction . ")\n",2);
		$self->_addSubjectLine($line, $str);
		$self->semFeaturesIndex->{$tmp}->{'SEEN_S'}++;
#			delete $self->semFeaturesIndex{$tmp};
		if ($self->conjunction == 1) {
		    $self->_printVerbose(">>>>$str (O - conj)\n",2);
		    $self->_printVerbose("    " . join(':',keys(%{$self->semFeaturesIndex->{$tmp}->{'CAT2'}})) . "\n",2);
		    $self->_printVerbose("    " . join(':',@t) . "\n",2);
		    if (($t[0] eq "drug") && ($self->_unionOpt == 1)) {
			$self->_printVerbose("UNION ($i)\n",2);
			push @{$self->union}, $i;
		    }
		    foreach $semCat (keys(%{$self->semFeaturesIndex->{$tmp}->{'CAT2'}})) {
			$self->_printVerbose("$semCat\n",2);
			# warn "ROOT: ". $self->semFeaturesIndex->{$tmp}->{'ROOT'} . "\n";
			if ($semCat ne join('/', @t)) {
			    $self->_printVerbose("==> Duplicate last (O - $i)\n",2);
			    my $line2 = $self->_cloneLine($i, $line);
			    my @t2 = @{$self->semFeaturesIndex->{$tmp}->{'CAT2'}->{$semCat}};
			    $self->_printVerbose(join('/', @t2) . " - $tmp\n",2);
			    my $str = $self->semanticCorrespondance->{$self->language}->{'RESOURCE'}->{$self->semFeaturesIndex->{$tmp}->{'ROOT'}}->{'ROOT'};
			    $str .= "/";
			    $str .= $self->semanticCorrespondance->{$self->language}->{'RESOURCE'}->{$self->semFeaturesIndex->{$tmp}->{'ROOT'}}->{'CORRESP'}->{$t2[$#t2-1]};
			    $str .= "/" . $t2[$#t2];
			    $self->_addSubjectLine($line2, $str);
			    $self->_printVerbose("done - $str\n",2);
			}
		    }
		}
	    }
	}
    }
}


# DOC
sub queryGeneration  {
    my $self = shift;
    # my $format = shift;

    my $sentence;
    my $docId;
    my $docHeadId;

    $self->docId =~ /\-([\d\w]+)$/;
    $docId = $1;
    $docHeadId = $`;

    # if ($format eq "XML") {
	# print $fh '<?xml version="1.0" ?>' . "\n";
	# print $fh '<dataset id="' . $docHeadId . '">' . "\n";
	$self->_addQueryXMLString('<question id="' . $docId . '">' . "\n");
    # }
    # if ($format eq "SPARQL") {
	$self->_printSPARQLComment("");
	$self->_printSPARQLComment($self->docId);
    # }
    foreach $sentence (@{$self->sentences}) {
	# if ($format eq "XML") {
	    $self->_addQueryXMLString('<string lang="' . lc($self->language) . '"><![CDATA[' . $sentence . ']]></string>' . "\n");
	    $self->_addQueryXMLString('<query><![CDATA[' . "\n");
	# }
	# if ($format eq "SPARQL") {
	    $self->_printSPARQLComment($sentence);
	# }
	$self->_printVerbose("\n************************************************************\n");
	$self->_printVerbose($sentence . "\n");
    }

########################################################################

    $self->_printSPARQLQueryWithPREFIX;
    $self->_addQueryXMLString($self->queryString);
########################################################################
    # if ($format eq "XML") {
	$self->_addQueryXMLString(']]></query>' . "\n");
	$self->_addQueryXMLString('</question>' . "\n\n");
    # warn $self->queryXMLString;
    # }
    # if ($format eq "XML") {
    # 	$outStr .= '</dataset>' . "\n";
    # }

}

sub _printSPARQLComment {
    my ($self, $string) = @_;

#    warn "-- $string\n";
    $self->_addQueryString("# $string\n");
}

sub _printSPARQLQueryWithPREFIX {
    my ($self) = @_;
    my $query;

    # if (!defined $fh) {
    # 	$fh = *STDOUT;
    # }

    $self->_addQueryString("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>\n");
    $self->_addQueryString("PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>\n");

    ($query,) = $self->_printSPARQLQuery($self->wherePart, $self->aggregation, 0);
    $self->_addQueryString($query);
}

sub _printSPARQLQuery {
    my ($self, $wherePart, $aggregation, $embeded) = @_;

    my $line;
    my $str;
    my $query = "";
    my $varAggreg;
    my $i;

    # warn "\t in _printSPARQLQuery (" . scalar(@$wherePart) . ")\n";
    if ($aggregation->{'ASK'} == 1) {
	$query .= "ASK \n";
	$query .= $self->_printWherePart($wherePart, $aggregation, $embeded);

    } else {
	if (scalar(@{$self->selectPart}) >= 1) {
	    if (scalar(@$wherePart) != 0) {
		# warn "AGGREG: " .join(':', keys %{$aggregation->{'PREDICATE'}}) . " (1a)\n";
		# warn "AGGREG: " .join(':', keys %{$aggregation->{'QTVAR'}}) . " (1b)\n";
		$query .= "SELECT ";
		if ((exists $aggregation->{'QTVAR'}->{'count'}) && (exists $aggregation->{'QTVAR'}->{'count'}->{$self->selectPart->[0]})) {
		    # warn "in COUNT\n";
		    $str = "(COUNT(";
		    if ((exists $aggregation->{'QTVAR'}->{'distinct'}->{$self->selectPart->[0]}) && 
			(!exists  $aggregation->{'QTVAR'}->{'per'}->{$self->selectPart->[0]})) {
			$str .= "DISTINCT ";
		    } else {
			if ($embeded == 1) {
			    $str = "DISTINCT " . $self->selectPart->[0] . " $str";
			} else {
			    $str = "DISTINCT $str ";
			}
		    }
		    $varAggreg = $self->selectPart->[0] ."count";
		    $str .= $self->selectPart->[0] . ") as $varAggreg)";
		    $query .= "$str\n";
		    # } elsif ((exists $aggregation->{'QTVAR'}->{'max'}->{$self->selectPart->[0]}) ||
		    # 	     (exists $aggregation->{'QTVAR'}->{'min'}->{$self->selectPart->[0]})) {
		    # 	$self->
		} else {
		    $query .= "DISTINCT " . $self->selectPart->[0] . "\n";
		}
		$query .= "WHERE ";
		if (scalar(@{$self->union}) == 0) {
		    $query .= $self->_printWherePart($wherePart, $aggregation, $embeded);
		} else {
		    $query .= "{\n";
		    my @wherePart1;
		    for($i=scalar(@{$self->union}) -1 ; $i >= 0; $i--) {
			push @wherePart1, $wherePart->[$self->union->[$i]];
		    }
		    $query .= $self->_printWherePart(\@wherePart1, $aggregation, $embeded);
		    $query.="UNION\n";
		    my @wherePart2;
		    for($i=$self->union->[0]+1;$i < scalar(@$wherePart);$i++) {
			push @wherePart2, $wherePart->[$i];
		    }
		    $query .= $self->_printWherePart(\@wherePart2, $aggregation, $embeded);
		    $query .= "}\n";

		}
		# warn "AGGREG: " .join(':', keys %{$aggregation->{'PREDICATE'}}) . " (3a)\n";
		# warn "AGGREG: " .join(':', keys %{$aggregation->{'QTVAR'}}) . " (3b)\n";
		if ((exists $aggregation->{'QTVAR'}->{'count'}->{$self->selectPart->[0]}) &&
		    ((!exists $aggregation->{'QTVAR'}->{'distinct'}->{$self->selectPart->[0]}) ||
		     (exists  $aggregation->{'QTVAR'}->{'per'}->{$self->selectPart->[0]}))) {
		    $query .= "GROUP BY " .$self->selectPart->[0] . " \n";
		}
	    } else {
		$self->_printVerbose("Error in wherePart - empty\n");
	    }
	} else {
	    $self->_printVerbose("*** ERROR IN selectPart ***\n");	
	}
    }
    # warn "\t out _printSPARQLQuery\n";
    return($query, $varAggreg);
}

sub _printWherePart {
    my ($self, $wherePart, $aggregation, $embeded) = @_;

    my $line;
    my $lineNb;
    my @addlines;
    my $query;
    my $query2;
    my $varAggreg;
    my %regexvar;

    $query .= "{\n";
    for($lineNb=0;$lineNb < scalar(@$wherePart);$lineNb++){
	$line = $wherePart->[$lineNb];
	if (exists $aggregation->{'PREDICATE'}->{$line->{'PREDICATE'}->[0]}) {
	    $self->_printVerbose("AGGREG: " . $aggregation->{'PREDICATE'}->{$line->{'PREDICATE'}->[0]} . " (2)\n",2);
	    ($query2, $varAggreg) = $self->_printAggregateLine($wherePart, $aggregation, $line, $aggregation->{'PREDICATE'}->{$line->{'PREDICATE'}->[0]}, \@addlines, \%regexvar);
	    $query .=  $query2;
	}
	# warn "=> addlin size: " . scalar(@addlines) . " (a)\n";
	if ($line->{'NEGATION'} == 1) {
	    $query .= "        FILTER NOT EXISTS {\n";
	}
	$query .= $self->_printSPARQLSelectLine($line, \@addlines, \%regexvar);
	# warn "=> addlin size: " . scalar(@addlines) . " (b)\n";
	if ($line->{'NEGATION'} == 1) {
	    $query .= "\n        }\n";
	}
    }
    $query .= join("\n", @addlines);
    $query .= "\n}\n";
    return($query);
}


sub _printAggregateLine {
    my ($self, $wherePart, $aggregation, $line, $aggregOp, $addlines, $regexvar) = @_;

    my $variable;
    my $aggregRole;
    my $query = "";
#    my %aggregationOp2;
    my $query2;
    my $varAggreg;
    my $varAggregOp;
    my $query3;

    # warn "in _printAggregateLine ($aggregOp)\n";
    if (($aggregOp ne 'count') && ($aggregOp ne 'distinct')) {
	if ((exists $self->semanticCorrespondance->{$self->language}->{'VARIABLE'}->{$line->{'PREDICATE'}->[0]}) && 
	    ($self->semanticCorrespondance->{$self->language}->{'VARIABLE'}->{$line->{'PREDICATE'}->[0]} eq "INT")) {
	    $query .= "    {\n";
	    if ($line->{'SUBJECT'}->[0] eq "INT") {
		$aggregRole = "SUBJECT";
	    } elsif ($line->{'OBJECT'}->[0] eq "INT") {
		$aggregRole = "OBJECT";
	    } else {
		warn "** error in the aggregated variable identification\n";
		return("",undef);
	    }

	    $variable = "?$aggregOp" . $line->{'PREDICATE'}->[0];
	    
	    $query .= "    SELECT (" . lc($aggregOp) . "(" . $line->{$aggregRole}->[1] . ") as $variable)\n";
	    $query .= "    WHERE {\n";
	    $query .= $self->_printSPARQLSelectLine($line, $addlines, $regexvar);
	    $query .= "    }\n";
	    if ($line->{$aggregRole}->[0] eq "INT") {
		$line->{$aggregRole}->[1] = $variable;
	    }
	    $query .= "    }\n";
	} else {
	    $self->_printVerbose("AGGREG: $aggregOp (3)\n", 2);
	    my $aggregation2 = dclone($aggregation);
#	    $self->_duplicateAggregationOp($aggregation, %aggregationOp2);

	    $aggregation2->{'QTVAR'}->{'count'}->{$self->selectPart->[0]} = $aggregation2->{'QTVAR'}->{$aggregOp}->{$self->selectPart->[0]};
	    delete $aggregation2->{'QTVAR'}->{$aggregOp}->{$self->selectPart->[0]};
	    delete $aggregation2->{'PREDICATE'}->{$line->{'PREDICATE'}->[0]};
	    ($query2, $variable) = $self->_printSPARQLQuery($wherePart, $aggregation2, 1);
	    $query3 = "    {\n$query2    }\n";
	    if (($aggregOp eq "min") || ($aggregOp eq "max")) {
		$varAggregOp = "$variable$aggregOp";
		$query .= "{\n" . "SELECT DISTINCT ($aggregOp($variable) as $varAggregOp)\n";
		$query .= "WHERE {\n";
		$query .= $self->_printSPARQLSelectLine($line, $addlines, $regexvar); # , $union);
		$query .= $query3;
		$query .= "}\n}\n$query3",
		$query .= "FILTER ($varAggregOp = $variable).\n";
	    }

#	$query .= $query2;
	}
    }
#     warn "out _printAggregateLine ($aggregOp)\n";
    return($query, $variable);
}

# sub _duplicateAggregationOp {
#     my ($self, $aggregation, $aggregation2) = @_;

#     my $infoType;
#     foreach $infoType () {
	
	
#     }
    
# }

sub _printSPARQLSelectLine {
    my ($self, $line, $addlines, $regexvar) = @_;
    my $query = "";

    $query .= "        ";
    if (defined ($line->{'SUBJECT'})) {
	$query .= $self->_printSPARQLQUERYElement($line->{'SUBJECT'}, $addlines, $regexvar);
	$query .= " ";
    }
    if (defined ($line->{'PREDICATE'})) {
	$query .= $self->_printSPARQLQUERYElement($line->{'PREDICATE'}, $addlines, $regexvar);
	$query .= " ";
    }
    if (defined ($line->{'OBJECT'})) {
	$query .= $self->_printSPARQLQUERYElement($line->{'OBJECT'}, $addlines, $regexvar);
    }
    $query .= ".\n";
    return($query);
}

sub _printSPARQLQUERYElement {
    my ($self, $queryElement, $addlines, $regexvar) = @_;

    my $variable;
    my $regex;
    my $query = "";
    
    if ($queryElement->[1] =~ /:NODEREGEX:/) {
	$regex=$'; # '
        $self->_printVerbose("NODEREGEX: $regexvar\n", 2);
	if (!exists $regexvar->{$queryElement->[1]}) {
	    $variable=$self->varPrefix . $self->variableCounter;
	# warn "\t==> $variable (Subj/Subj)\n";
	    $self->_IncrVariableCounter;
	    $query .= $variable;
	    push @$addlines, "        $variable rdfs:label ?l" . $self->variableCounter . ".\n        FILTER(REGEX(?l" . $self->variableCounter . ",'$regex','i')).";
	    $regexvar->{$queryElement->[1]} = $variable;
	} else {
	    $query .= $regexvar->{$queryElement->[1]};
	}
    } elsif ($queryElement->[1] =~ /:LABELREGEX:/) {
	$regex=$'; # '
        $self->_printVerbose("LABELREGEX: $regexvar\n",2);;
	if (!exists $regexvar->{$queryElement->[1]}) {
	    $variable=$self->varPrefix . $self->variableCounter;
	# warn "\t==> $variable (Subj/Subj)\n";
	    $self->_IncrVariableCounter;
	    $query .= $variable;
	    push @$addlines, "        FILTER(REGEX($variable,'$regex','i')).";
	    $regexvar->{$queryElement->[1]} = $variable;
	} else {
	    $query .= $regexvar->{$queryElement->[1]};
	}
    } elsif ($queryElement->[1] =~ /^http:/) {
	$query .= "<" . $queryElement->[1] . ">";
    } elsif ($queryElement->[1] =~ /^const\/(?<type>.*)/) {
	$query .= '"' . $+{type} . '"^^<' . $self->semanticCorrespondance->{$self->language}->{'CONST'}->{$queryElement->[0]} .">";
    } elsif ($queryElement->[1] =~ /^\?/) {
	$query .= $queryElement->[1];
    } elsif ($queryElement->[1] =~ /^rdf/) {
	$query .= $queryElement->[1];
    } elsif ($queryElement->[1] =~ /^STRING/) {
	$queryElement->[1] =~ s/STRING\///;
	$query .= "\"" . $queryElement->[1] . "\"";
    } elsif ($queryElement->[1] =~ /^\"/) {
	$query .= $queryElement->[1];
    } else {
	$query .= "\"" . $queryElement->[1] . "\"";
    }
    return($query);
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

sub getQueryAnswers {
    my ($self) = @_;

    # my $prefix = "http://vtentacle.techfak.uni-bielefeld.de:443/sparql?default-graph-uri=&query=";
    # my $suffix = "&format=text%2Ftab-separated-values&timeout=0&verbose=on";

    my $encod_str = URL::Encode::url_encode_utf8($self->queryString);
    my $webPage = "";
    my $answer;
    my @answers;

    $self->_printVerbose("get question " . $self->docId . "\n");

#     my $url = "$prefix$encod_str$suffix";
    my $url = $self->config->{'NLQUESTION'}->{'language="' . uc($self->language) . '"'}->{'URL_PREFIX'};
    $url .= $encod_str;
    $url .= $self->config->{'NLQUESTION'}->{'language="' . uc($self->language) . '"'}->{'URL_SUFFIX'};

    $self->_printVerbose("\t$url\n");

    my $request = HTTP::Request->new(GET => $url);
    my $ua = LWP::UserAgent->new;
    my  $response = $ua->request($request);

    if ($response->is_success) {
	$self->_printVerbose("\tSuccess\n",2);
	$webPage = $response->decoded_content;
    } else {
	warn $self->docId . ": " . $response->status_line . "\n";
	# $self->_printVerbose($response->status_line . "\n");
    }

    # CSV
    @answers = split /\n/, $webPage;
    shift @answers;
    foreach $answer (@answers) {
    	$answer =~ s/\"//go;
    	$self->_printVerbose("\t=>$answer",2);
    	$self->queryAnswers->{$answer} = 0;
    }

    # XML/SPARQL
    # $self->_printVerbose($webPage, 2);
    # my $xs = XML::Simple->new();
    # my $webPage_struct = $xs->XMLin($webPage);
    # warn Dumper($webPage_struct);
}


1;

__END__

=head1 NAME

RDF::NLP::SPARQLQuery::Query - Perl extension for representing the SPARQL query.

=head1 SYNOPSIS

use RDF::NLP::SPARQLQuery::Query;

my $query = RDF::NLP::SPARQLQuery::Query->new(
    'verbose' => 0,
    'docId' => $docId,
    'language' => uc($language),
    'sentences' => \@sentences,
    'negation' => \%negation,
    'union' => \@union,
    'aggregation' => \%aggregation,
    'semanticCorrespondance' => \%semanticCorrespondance,
    'semFeaturesIndex' => \%semFeaturesIndex,
    'sortedSemanticUnits' => \@sortedSemanticUnits,
    'config' => \%config,
    );

$query->queryConstruction($questionTopic);

$query->queryGeneration;



=head1 DESCRIPTION

This object represents the SPARQL query and provides methods to perform the query construction and the query generation.
The representation of the query includes several fields:

=over 4


=item *

C<docId>: identifier of the natural language question

=item *

C<verbose>: specification of the verbose

=item *

C<language>: language of the natural language question

=item *

C<queryString>: the generated string corresponding to the SPARQL query

=item *

C<queryXMLString>: the generated XML string corresponding to the SPARQL query

=item *

C<queryAnswers>: the list of answers correspong to the query

=item *

C<selectPart>: array containing the information related to the select part of the query

=item *

C<wherePart>: array containing the information related to the where part of the query

=item *

C<aggregation>: structure recording the presence of aggregation operators

=item *

C<conjunction>: boolean indicated if the semantic entities are in conjunction

=item *

C<sentences>: sentences of the natural language question

=item *

C<negation>: structure recording the negated semantic entities

=item *

C<varPrefix>: prefix of the SPARQL variable

=item *

C<variableCounter>: counter of the variables (mainly used to define new variable in the query)

=item *

C<variableSet>: Set of the variables defined in the query

=item *

C<union>: structure recording the semantic entities on which the union operator is applied

=item *

C<semanticCorrespondance>: structure containing the semantic correspondance and the rewriting rules

=item *

C<questionTopic>: semantic type referring to the question topic

=item *

C<semFeaturesIndex>: index of the semantic types

=item *

C<sortedSemanticUnits>: sorted array of the semantic entities of the natural language question

=item *

C<config>: structure containing the configuration of the converter

=back


=head1 METHODS


=head2 queryConstruction()

    queryConstruction($questionTopic);

The method performs the construction step of the query, after the
question abstraction. The objective of the query construction step is
to build a representation of the SPARQL graph pattern from the
elements identified during the question abstraction step.  The
question topic field is also set with C<$questionTopic>. Then it is
used to define the select part.


=head2 queryGeneration()

    queryGeneration();

The method generates the string corresponding to the query.

=head2 getQueryAnswers()

    getQueryAnswers();


The method build the answers corresponding to the queries by sending the generated SPARQL query to a Virtoso server.

=head2 wherePart()

    wherePart();

This methods sets the empty array representing the  where part of the query.

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

