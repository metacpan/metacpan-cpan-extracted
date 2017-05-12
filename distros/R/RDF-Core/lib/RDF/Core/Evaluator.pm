# 
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
# 
# The Original Code is the RDF::Core module
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 2001 Ginger Alliance Ltd.
# All Rights Reserved.
# 
# Contributor(s):
# 
# Alternatively, the contents of this file may be used under the
# terms of the GNU General Public License Version 2 or later (the
# "GPL"), in which case the provisions of the GPL are applicable 
# instead of those above.  If you wish to allow use of your 
# version of this file only under the terms of the GPL and not to
# allow others to use your version of this file under the MPL,
# indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by
# the GPL.  If you do not delete the provisions above, a recipient
# may use your version of this file under either the MPL or the
# GPL.
# 

package RDF::Core::Evaluator;

use strict;
require Exporter;

use RDF::Core::Query qw(:syntax);
use RDF::Core::Constants qw(:rdf);
require RDF::Core::Function;
require RDF::Core::Statement;
require RDF::Core::Resource;
require RDF::Core::Enumerator::Memory;
use Carp;

sub new {
    my ($pkg,%options) = @_;
    $pkg = ref $pkg || $pkg;
    my $self = {};
    $self->{_options} = \%options;
    bless $self, $pkg;
}
sub getOptions {
    my $self = shift;
    return $self->{_options};
}


sub evaluate {
    my ($self, $query, $substitutions) = @_;
    my $rs = [[undef]];
    my $descr = {};
    $self->{_query} = $query;
    $self->{_subst} = $substitutions;
    $self->_namespaces($query);
    my @result;
    my $wantResult = $self->_prepareHandler($self->getOptions->{Row},
					    sub {push @result, \@_});
    if ($self->getOptions->{TURBO}) {
	$self->_prepareResultSet_new($query, $rs, $descr)
    } else {
	($rs, $descr) = $self->_prepareResultSet($query);
	$self->_applyConditions($rs, $descr, $query->{+Q_CONDITION}->[0]);
	$self->_formatResult($rs, $descr, $query);
    }
    return $wantResult ? \@result : undef;
}

############################################################
# Result set setup

sub _prepareResultSet {
    #get result set and it's description
    my ($self, $query) = @_;
    
    my $resultSets = [];
    my $descriptions = [];
    my $idx = 0;
    my $description = $descriptions->[0] = {};
    my $rs = $resultSets->[0] = [[undef]];
    my @condSet = $self->_analyzeCondition($query->{+Q_CONDITION}->[0]);
    my $wantNewSet;
    foreach (@{$query->{+Q_SOURCE}->[0]->{+Q_SOURCEPATH}}) {
	$wantNewSet = @$rs > 100 ? 1 : 0;
	if ($wantNewSet) {
	    $idx++;
	    $description = $descriptions->[$idx] = {};
	    $rs = $resultSets->[$idx] = [[undef]];
	    @condSet = $self->_analyzeCondition($query->{+Q_CONDITION}->[0]);
	}

	#process $subject - a beginning of the path
	my $subject = $self->_extractElement($_->{+Q_ELEMENT}->[0],
					     $_->{+Q_BINDING}->[0]);
	if ($subject->[0]{type} eq Q_FUNCTION) {
	    $self->_funcParams($rs,$description,undef,$_->{+Q_ELEMENT}->[0]);
	}
	#process class info (rdf:type)
	if (exists $_->{+Q_CLASS}) {
	    my $type = $self->getOptions->{Factory}->
	      newResource(RDF_NS, 'type');
	    my $class = $self->_extractElement
	      ($_->{+Q_CLASS}->[0]->{+Q_ELEMENT}->[0], 
	       $_->{+Q_CLASS}->[0]->{+Q_BINDING});
	    $self->_funcParams($rs,$description,undef, 
			       $class->[0]{elementpath})
	      if $class->[0]{type} eq Q_FUNCTION;
	    $self->_expandResult($rs, $description, 'S', $subject, 
				 [{object=>$type}], $class);
	}

	#process $element - the first property found on the path
	my $element;
	if (exists $_->{+Q_ELEMENT}->[1] ) {
	    $element = $self->_extractElement($_->{+Q_ELEMENT}->[1],
					      $_->{+Q_BINDING}->[1]);
	    $self->_funcParams($rs,$description,$subject,$_->{+Q_ELEMENT}->[1])
	      if $element->[0]{type} eq Q_FUNCTION;

	    #if the path has only one property and leads to target,process here
	    if ($_->{+Q_HASTARGET} && @{$_->{+Q_ELEMENT}} == 2) {
		my $target;
		if ($_->{+Q_TARGET}[0]{+Q_EXPRESSION}) {
		    $target = $self->_evalExpression(undef,undef,
						     $_->{+Q_TARGET}[0]);
		    $target = [{object=>$target}];
		} else {
		    $target =  $self->_extractElement
		      ($_->{+Q_TARGET}[0],undef);
		    $self->_funcParams($rs,$description,undef,
				       $_->{+Q_TARGET}->[0])
		      if $target->[0]{type} eq Q_FUNCTION;
		}
		$self->_expandResult($rs, $description, 'O', $subject, 
				     $element, $target);
	    } else {
		$self->_expandResult($rs, $description, 'O', $subject, 
				     $element);
	    }
	    
	} else {
	    $self->_singularResult($rs, $description, $subject);
	}
	$self->_checkConditions ($rs, $description, \@condSet);

	for (my $i = 2; $i < @{$_->{+Q_ELEMENT}} ; $i++) {
	    #iterate through sourcepath elements
	    #make "step" over the element

	    $element = $self->_extractElement($_->{+Q_ELEMENT}->[$i],
					      $_->{+Q_BINDING}->[$i]);
	    $self->_funcParams($rs,$description,undef,$_->{+Q_ELEMENT}->[$i])
	      if $element->[0]{type} eq Q_FUNCTION;

	    if ($_->{+Q_HASTARGET} && @{$_->{+Q_ELEMENT}} == $i+1) {
		my $target =  $self->
		  _extractElement($_->{+Q_TARGET}->[0], undef);
		
		$self->_funcParams($rs,$description,undef,
				   $_->{+Q_TARGET}->[0])
		  if $target->[0]{type} eq Q_FUNCTION;
		
		$self->_expandResult($rs, $description, 'O', undef, $element, 
				     $target);
	    } else {
		$self->_expandResult($rs,$description, 'O', undef, $element);
	    }
	    $self->_checkConditions ($rs, $description, \@condSet);
	}
    }
    return $self->_joinResults($resultSets, $descriptions);
}

sub _prepareResultSet_new {
    #get result set and it's description
    my ($self, $query, $rs, $description, $position) = @_;
    return unless $self->getOptions->{TURBO};
    warn "Entering _prepareResultSet\n" if $self->getOptions->{Debug};
    
    #position determines what's already done in SourcePath
    $position ||= {};
    #an index of path to process
    $position->{path} ||= 0;
    #was class processed?
    $position->{class} ||= 0;
    #an index of element in path to process
    $position->{element} ||= 0;
    
    #make your own copy
    my %position = %$position;
    
    my @condSet = $self->_analyzeCondition($query->{+Q_CONDITION}->[0]);
    # unless defined @condSet ;
    $self->_checkConditions ($rs, $description, \@condSet);
    
    #check position, you may be finished already 
    my $finished;
    my $path = $query->{+Q_SOURCE}[0]{+Q_SOURCEPATH}[$position{path}];
    if ($position{element} >= @{$path->{+Q_ELEMENT}}) {
	#next path if possible
	$position{path}++;
	if ($position{path} < @{$query->{+Q_SOURCE}->[0]->{+Q_SOURCEPATH}}) {
	    $position{element} = 0;
	    $position{class} = 0;
	    $path = $query->{+Q_SOURCE}[0]{+Q_SOURCEPATH}[$position{path}];
	} else {
	    $finished = 1;
	}
    }
    if ($finished) {
	$self->_formatResult($rs, $description, $query);
	warn "Leaving _prepareResultSet\n" if $self->getOptions->{Debug};
	return;
    }
    
    #process $subject - a beginning of the path
    my $subject;
    if ($position{element} == 0) {
	$subject = $self->_extractElement($path->{+Q_ELEMENT}->[0],
					  $path->{+Q_BINDING}->[0]);
	if ($subject->[0]{type} eq Q_FUNCTION) {
	    $self->_funcParams($rs,$description,undef,
			       $path->{+Q_ELEMENT}->[0]);
	}
	$position{element}++;
    } else {
	$subject = undef;
    }
    #process class info (rdf:type)
    if (exists $path->{+Q_CLASS} and !$position{class}) {
	my $type = $self->getOptions->{Factory}->
	  newResource(RDF_NS, 'type');
	my $class = $self->_extractElement
	  ($path->{+Q_CLASS}->[0]->{+Q_ELEMENT}->[0], 
	   $path->{+Q_CLASS}->[0]->{+Q_BINDING}->[0]);
	$self->_funcParams($rs,$description,undef, $class->[0]{elementpath})
	  if $class->[0]{type} eq Q_FUNCTION;
	$position{class} = 1;
	$self->_expandResult($rs, $description, 'S', $subject, 
			     [{object=>$type}], $class, \%position);
    } else {
	#process $element - the first property found on the path
	my $element;
	if (exists $path->{+Q_ELEMENT}->[$position{element}] ) {
	    $element = $self->_extractElement
	      ($path->{+Q_ELEMENT}->[$position{element}], 
	       $path->{+Q_BINDING}->[$position{element}]);
	    $self->_funcParams($rs,$description,$subject,
			       $path->{+Q_ELEMENT}->[$position{element}])
	      if $element->[0]{type} eq Q_FUNCTION;
	    $position{element}++;
	    
	    #if the path has only one property and leads to target,process here
	    if ($path->{+Q_HASTARGET} && @{$path->{+Q_ELEMENT}}
		== $position{element}) {
		my $target;
		if ($path->{+Q_TARGET}[0]{+Q_EXPRESSION}) {
		    $target = $self->_evalExpression(undef,undef,
						     $path->{+Q_TARGET}[0]);
		    $target = [{object=>$target}];
		} else {
		    $target =  $self->_extractElement
		      ($path->{+Q_TARGET}[0],undef);
		    $self->_funcParams($rs,$description,undef,
				       $path->{+Q_TARGET}->[0])
		      if $target->[0]{type} eq Q_FUNCTION;
		}
		$self->_expandResult($rs, $description, 'O', $subject, 
				     $element, $target, \%position);
	    } else {
		$self->_expandResult($rs, $description, 'O', $subject, 
				     $element, undef, \%position);
	    }
	} else {
	    $self->_singularResult($rs, $description, $subject, \%position);
	}
    }
    
    warn "Leaving _prepareResultSet\n" if $self->getOptions->{Debug};
    
    return ;
}

sub _expandResult {
    my ($self, $rs, $description, $join, $roots, 
	$elements, $targets, $position) = @_;
    my @newRS;
    my %newDescr = %$description;
    my $targets = $targets || [{object=>undef}];
    #iterate through partial result's rows
    for (my $i = 0; $i < @$rs; $i++) {
	my $subjects = $roots || [{object=>$rs->[$i][0]}];
	foreach my $root (@$subjects) {
	    next unless $self->_bindingPreCheck($rs->[$i],
						$description,$root);
	    my $pushSubject;
	    if ($roots && $root->{type} eq Q_VARIABLE) {
		$newDescr{$root->{name}} = @{$rs->[$i]};
		$pushSubject = 1;
	    } 
	    if ($roots && $root->{binding}) {
		croak "Multiple binding is not allowed near ".$root->{name}
		  if @{$root->{binding}} > 1;
		if (!($description->{$root->{binding}[0]})) {
		    $newDescr{$root->{binding}[0]} = @{$rs->[$i]};
		    $pushSubject = 1;
		}
	    }


	    foreach my $element (@$elements) {
		my $pushPredicate;
		if ($element->{type} eq Q_VARIABLE && 
		    !($description->{$element->{name}})) {
		    $newDescr{$element->{name}} = @{$rs->[$i]} + $pushSubject;
		    $pushPredicate = 1;
		}
		if (my $bnd = $element->{binding}[1]) {
		    if (!($description->{$bnd})) {
			$newDescr{$bnd} = @{$rs->[$i]} + $pushSubject; 
			$pushPredicate = 1;
		    }
		}
		my $pushObject;
		if (my $bnd = $element->{binding}[0]) {
		    if (!($description->{$bnd})) {
			$newDescr{$bnd} = @{$rs->[$i]} + $pushSubject + 
			  $pushPredicate;
			$pushObject = 1;
		    }
		}
		foreach my $target (@$targets) {
		    if ($target->{type} eq Q_VARIABLE && 
			!($description->{$target->{name}})) {
			$newDescr{$target->{name}} = @{$rs->[$i]} + 
			  $pushSubject + $pushPredicate;
			$pushObject = 1;
		    }
		    if ($target->{binding}) {
			croak "Multiple binding is not allowed near ".
			  $target->{name}
			    if @{$target->{binding}} > 1;
			my $bnd = $target->{binding}[0];
			if (!($description->{$bnd})) {
			    $newDescr{$bnd} = @{$rs->[$i]} + 
			      $pushSubject + $pushPredicate;
			    $pushObject = 1;
			}
			
		    }
		    my $found = $self->_getStmts($rs->[$i], $description, 
						 $root, $element, $target);
		    foreach my $enum (@{$found}) {
			while (my $st = $enum->getNext) {
			    next unless $self->_bindingCheck($rs->[$i], 
							     $description, 
							     $root, 
							     $st->getSubject);
			    next unless $self->_bindingCheck($rs->[$i], 
							     $description, 
							     $element, 
							     $st->getObject);
			    my @row = @{$rs->[$i]};
			    push @row, $st->getSubject if $pushSubject;
			    push @row, $st->getPredicate if $pushPredicate;
			    push @row, $st->getObject if $pushObject;
			    if ($join eq 'S') {
				@row[0] = $st->getSubject;
			    } elsif ($join eq 'O') {
				@row[0] = $st->getObject;
			    } else {
				croak "Join point not defined\n";
			    }
##########
			    if ($position) {
				my @subRS = [@row];
				my %subDescr = %newDescr;
				$self->_prepareResultSet_new
				  ($self->{_query}, \@subRS, \%subDescr, 
				   $position);
			    }
##########
			    push @newRS, \@row;
			}
			$enum->close;
		    }
		}
	    }
	    
	}
    }
    %$description = %newDescr;
    return @$rs = @newRS;
}

sub _singularResult {
    #get all nodes from the model
    my ($self, $rs, $description, $elements, $position) = @_;
    my %newDescr = %$description;
    my @newRS;
    
    my $pushElement = 0;
    my $lastIndex;
    if (defined $rs->[0]) {
	$lastIndex = @{$rs->[0]} ;
    } else {
	$lastIndex = 0;
    }
    if ($elements->[0]{type} eq Q_VARIABLE && 
	!exists $description->{$elements->[0]{name}}) {
	$pushElement = 1;
	$newDescr{$elements->[0]{name}} = $lastIndex;
    }
    if (my $bnd = $elements->[0]{binding}) {
	croak "Multiple binding is not allowed near ".$elements->[0]->{name}
	  if @{$bnd} > 1;
	    if (!($description->{$bnd->[0]})) {
		$newDescr{$bnd->[0]} = $lastIndex;
		$pushElement = 1;
	    }
    }
    for (my $i = 0; $i < @$rs; $i++) {
	my %res;
	my %lit;
	foreach my $element (@$elements) {
	    #check for conflict between bound variables and values
	    next unless $self->_bindingPreCheck($rs->[$i],
						$description,$element);
	    #return current result set if variable is already resolved
	    # - this doesn't work with binding
	    #	    return @$rs if $self->_evalVar($rs->[$i],$description,
	    #					   $element->{name}, 'RELAX');
	    
	    my $found = $self->_getStmts($rs->[$i], $description, 
					 $element, undef, undef);
	    foreach my $enum (@{$found}) {
		while (my $st = $enum->getNext) {
		    next unless $self->_bindingCheck
		      ($rs->[$i], $description,$element, $st->getSubject);
		    my @row = @{$rs->[$i]};
		    unless ($res{$st->getSubject->getURI}) {
			if ($pushElement) {
			    push @row, $st->getSubject;
			}
			##########
			if ($position) {
			    my @subRS = [@row];
			    my %subDescr = %newDescr;
			    $self->_prepareResultSet_new
			      ($self->{_query}, \@subRS, \%subDescr, 
			       $position);
			}
			##########
			$res{$st->getSubject->getURI} = 1;
			push @newRS, \@row;
		    }
		}
		$enum->close;
	    }
	    
	    $found = $self->_getStmts($rs->[$i], $description, 
				      undef, $element, undef);
	    foreach my $enum (@{$found}) {
		while (my $st = $enum->getNext) {
		    next unless $self->_bindingCheck
		      ($rs->[$i],$description,$element,$st->getPredicate);
		    my @row = @{$rs->[$i]};
		    unless ($res{$st->getPredicate->getURI}) {
			if ($pushElement) {
			    push @row, $st->getPredicate;
			}
			##########
			if ($position) {
			    my @subRS = [@row];
			    my %subDescr = %newDescr;
			    $self->_prepareResultSet_new
			      ($self->{_query}, \@subRS, \%subDescr, 
			       $position);
			}
			##########
			$res{$st->getPredicate->getURI} = 1;
			push @newRS, \@row;
		    }
		}
		$enum->close;
	    }
	    
	    
	    $found = $self->_getStmts($rs->[$i], $description, 
				      undef, undef, $element);
	    foreach my $enum (@{$found}) {
		while (my $st = $enum->getNext) {
		    next unless $self->_bindingCheck
		      ($rs->[$i],$description,$element,$st->getObject);
		    my @row = @{$rs->[$i]};
		    if ($st->getObject->isLiteral) {
			unless ($lit{$st->getObject->getValue}) {
			    if ($pushElement) {
				push @row, $st->getObject;
			    }
			    ##########
			    if ($position) {
				my @subRS = [@row];
				my %subDescr = %newDescr;
				$self->_prepareResultSet_new
				  ($self->{_query}, \@subRS, \%subDescr, 
				   $position);
			    }
			    ##########
			    $lit{$st->getObject->getValue} = 1;
			    push @newRS, \@row;
			}
		    } else {
			unless ($res{$st->getObject->getURI}) {
			    if ($pushElement) {
				push @row, $st->getObject;
			    }
			    ##########
			    if ($position) {
				my @subRS = [@row];
				my %subDescr = %newDescr;
				$self->_prepareResultSet_new
				  ($self->{_query}, \@subRS, \%subDescr, 
				   $position);
			    }
			    ##########
			    $res{$st->getObject->getURI} = 1;
			    push @newRS, \@row;
			}
		    }
		}
		$enum->close;
	    }
	}
    }
    %$description = %newDescr;
    return @$rs = @newRS;
}
sub _extractElement {
    my ($self,$node, $binding) = @_;
    my $elements = [];
    my $element = {};
    
    ($element->{type}) = keys %$node;
    if ($element->{type} eq Q_VARIABLE) {
	$element->{name} = $node->{+Q_VARIABLE}->[0]->{+Q_NAME}->[0];
	$element->{object} = undef;
	$element->{binding} = $self->_extractBinding($binding);
	push @$elements, $element;
    } elsif ($element->{type} eq Q_NODE) {
	if ($node->{+Q_NODE}->[0]->{+Q_URI}) {
	    $element->{name} = $node->{+Q_NODE}->[0]->{+Q_URI}->[0];
	    $element->{object} = $self->getOptions->{Factory}->
	      newResource($element->{name});
	} elsif (my $name = $node->{+Q_NODE}->[0]->{+Q_NAME}) {
	    if (@$name > 1) {
		my $ns = $self->getOptions->{_localNamespaces}->{$name->[0]};
		$ns = $self->getOptions->{Namespaces}->{$name->[0]}
		  unless defined $ns;
		$element->{name} = $ns.$name->[1];
	    } else {
		my $ns = $self->getOptions->{_localNamespaces}->{Default};
		$ns = $self->getOptions->{Namespaces}->{Default}
		  unless defined $ns;
		$element->{name} = $ns.$name->[0];
	    }
	    $element->{object} =  $self->getOptions->{Factory}->
	      newResource($element->{name});
	}
	$element->{binding} = $self->_extractBinding($binding);
	push @$elements, $element;
    } elsif ($element->{type} eq Q_FUNCTION) {
	$element->{name} = $node->{+Q_FUNCTION}->[0]->{+Q_NAME}->[0];
	$element->{elementpath} = $node->{+Q_FUNCTION}->[0]->
	  {+Q_ELEMENTPATH};
	$element->{binding} = $self->_extractBinding($binding);
	push @$elements, $element;
    } elsif ($element->{type} eq Q_ELEMENT) {
	foreach (@{$node->{+Q_ELEMENT}}) {
	    my $subEls = $self->_extractElement($_, $binding);
	    push @$elements , @$subEls;
	}
    } elsif ($element->{type} eq Q_SUBSTITUTION) {
	my $substName = $node->{+Q_SUBSTITUTION}->[0]->{+Q_NAME}->[0];
	$element->{object} = $self->{_subst}{$substName} || 
	  croak "Substitution not defined for $substName.\n";
	$element->{binding} = $self->_extractBinding($binding);
	$element->{type} = $element->{object}->isLiteral ? Q_LITERAL : Q_NODE;
	$element->{name} = $element->{object}->getLabel;
	push @$elements, $element;
    }
    return $elements;
}
sub _extractBinding {
    my ($self, $binding) = @_;
    my @retVal;
    return undef unless defined $binding;
    foreach (@{$binding->{+Q_VARIABLE}}) {
	push @retVal, $_->{+Q_NAME}[0];
    }
    return \@retVal
}
sub _bindingPreCheck {
    my ($self, $row, $descr, $element) = @_;
    #if element has a binding, it should conform its value
    #this doesn't apply to properties
    my $retVal = 1;
    if ($element->{binding} && $element->{binding}[0]) {
	my $bound = $self->_evalVar($row, $descr,
				    $element->{binding}[0], 'RELAX');
	if ($bound) {
	    if ($element->{type} eq Q_VARIABLE) {
		my $val = $self->_evalVar($row, $descr,
					  $element->{name}, 'RELAX');
		$retVal = 0 unless !$val ||
		  $bound->isLiteral == $val->isLiteral &&
		    $bound->getLabel eq $val->getLabel;
	    } elsif ($element->{type} eq Q_FUNCTION) {
		#do nothing here, check bindings after _getStmts
	    } else {
		my $val =$element->{object};
		$retVal = 0 unless !defined $val ||
		  $bound->isLiteral == $val->isLiteral &&
		    $bound->getLabel eq $val->getLabel;
	    }
	}
    }  
    return $retVal;
}
sub _bindingCheck {
    my ($self, $row, $descr, $element, $result) = @_;
    my $retVal = 1;
    if ($element->{binding} && $element->{binding}[0]) {
	my $bound = $self->_evalVar($row, $descr, 
				    $element->{binding}[0], 'RELAX');
	$retVal = 0 unless !$bound ||
	  $result->isLiteral==$bound->isLiteral &&
	    $result->getLabel eq $bound->getLabel;
    }
    return $retVal;
}

sub _funcParams {
    #Find variables resolved not yet in function subject and parameters
    #and resolve them.
    my ($self, $rs, $descr, $subjects, $prmNode) = @_;
    my @vars;
    if (defined $subjects) {
	foreach (@$subjects) {
	    if ($_->{type} eq Q_VARIABLE) {
		push @vars, $_->{name} unless defined $descr->{$_->{name}};
	    }
	}
    }
    $self->_findVars($prmNode, \@vars);
    foreach (@vars) {
	$self->_singularResult($rs, $descr, [{name=>$_, type=>Q_VARIABLE}])
	  unless defined $descr->{$_};
    }
    
}

sub _joinResults {
    my ($self, $resultSets, $descriptions) = @_;
    my $toJoin ;
    my $joined = $resultSets->[0];
    my $joinedDescr = $descriptions->[0];
    for (my $i = 1; $i < @$resultSets; $i++) {
	my @attachements;
	my @extensions;
	$toJoin = $joined;
	undef $joined;
	#descriptions
	my $lastIndex;
	if (defined $toJoin->[0]) {
	    $lastIndex = @{$toJoin->[0]};
	} else {
	    $lastIndex = 0;
	}
	foreach (keys %{$descriptions->[$i]}) {
	    if (exists $joinedDescr->{$_}) {
		push @attachements, [$joinedDescr->{$_},
				     $descriptions->[$i]->{$_} ];
	    } else {
		push @extensions, $descriptions->[$i]->{$_};
		$joinedDescr->{$_} = $lastIndex++;
	    }
	}

	#data
	foreach my $rowTo (@$toJoin) {
	    foreach my $rowFrom (@{$resultSets->[$i]}) {
		my $fit = 1;
		foreach (@attachements) {
		    $fit = 0 unless $rowTo->[$_->[0]]->getLabel eq 
		      $rowFrom->[$_->[1]]->getLabel;
		}
		if ($fit) {
		    my @newRow = @$rowTo;
		    foreach (@extensions) {
			push @newRow, $rowFrom->[$_];
		    }
		    push @$joined, \@newRow;
		}
	    }
	}
    }
    return ($joined, $joinedDescr);
}

sub _analyzeCondition {
    my ($self, $condition) = @_;
    #returns list of conjunctions that apply independently plus which 
    #variables are in them. Variables are sorted by name.
    #The form is: ({node=>$queryNode, vars=>[name1,name2,...]},...)
    
    my @retVal;
    return @retVal unless $condition;

    my $isConjunction = 0;
    if (exists $condition->{+Q_CONNECTION}) {
	$isConjunction = 1;
	foreach (@{$condition->{+Q_CONNECTION}}) {
	    $isConjunction = 0 if /^or$/i;
	}
	
    } 
    if ($isConjunction) {
	foreach (@{$condition->{+Q_CONDITION}}) {
	    push @retVal, $self->_analyzeCondition($_);
	}
    } elsif (exists $condition->{+Q_CONDITION} &&
	    !exists $condition->{+Q_CONNECTION}) {
	#a single condition, step into it
	push @retVal, $self->_analyzeCondition($condition->{+Q_CONDITION}[0]);
    } else {
	#a match or disjunction
	my @vars;
	croak "Condition not defined in analyzeCondition\n" unless defined $condition;
	$self->_findVars($condition , \@vars);
	push @retVal,{node=>$condition, vars=>\@vars};
    }
    return @retVal;
}

sub _checkConditions {
    my ($self, $rs, $descr, $condSet) = @_;
    #tries to apply some sub-conditions
    #condSet is got from _analyzeCondition

    my @newCondSet;
    foreach my $cond (@$condSet) {
	my $apply = 1;
	foreach (@{$cond->{vars}}) {
	    $apply = 0 unless $descr->{$_};
	    last unless $apply;
	} 
	if ($apply) {
	    $self->_applyConditions($rs, $descr, $cond->{node});
	} else {
	    push @newCondSet, $cond;
	}

    }
    #throw away applied conditions
    @$condSet = @newCondSet;
}

############################################################
# Result formatting
    
sub _formatResult {
    my ($self, $rs, $descr, $query) = @_;

    foreach my $rsRow (@$rs) {
	my $rows;
	$rows = $self->_evalRow($rsRow, $descr,$query->
				{+Q_RESULTSET}->[0]->{+Q_ELEMENTPATH});
	foreach my $row (@$rows) {
	    &{$self->{_handler}}(@$row);
	}
    }
}

sub _evalRow {
    # Apply element path expressions to a row (a set of variables) 
    # It may return one or more rows
    my ($self, $row, $descr, $elementPath) = @_;
    my $result = [[]];
    if (defined $elementPath) {
	foreach (@$elementPath) {
	    my @newResult;
	    my $values = $self->_evalPath($row, $descr, $_);
	    foreach my $rw (@$result) {
		foreach my $value (@$values) {
		    push @newResult, [@$rw, $value];
		}
		push (@newResult,[@$rw, undef]) unless @$values;
	    }
	    $result = \@newResult;
	}
    }
    return $result;
}

############################################################
# Narrowing result according to conditions
sub _applyConditions {
    my ($self, $rs, $descr, $condition) = @_;
    my @newResult;
    #my $condition = $query->{+Q_CONDITION}->[0];
    return $rs unless $condition;
    foreach my $row (@$rs) {
	if ($self->_evalCondition($row, $descr, $condition)) {
	    push @newResult, $row;
	}
    }
    @$rs = @newResult;
    return $rs;
}

sub _evalCondition {
    my ($self, $row, $descr, $condition) = @_;
    my $fit;

    if (exists $condition->{+Q_MATCH}) {
	$fit = $self->_evalMatch($row, $descr, $condition->{+Q_MATCH}->[0]);
    } else {
	for (my $i = 0; $i < @{$condition->{+Q_CONDITION}}; $i++) {
	    if (defined ( $condition->{+Q_CONNECTION}->[$i]) && 
		$condition->{+Q_CONNECTION}->[$i] =~ /^or$/i) {
		$fit  = (defined $fit ? $fit : 1) &&
		  $self->_evalCondition($row, $descr, 
				     $condition->{+Q_CONDITION}->[$i]);
		last if $fit;
		undef $fit;
	    } else {
		$fit  = (defined $fit ? $fit : 1) &&
		  $self->_evalCondition($row, $descr, 
				     $condition->{+Q_CONDITION}->[$i]);
	    }
	}
    }
    return $fit;
}

sub _evalMatch {
    my ($self, $row, $descr, $match) = @_;
    my $fit;
    my $set1 = $self->_evalPath($row, $descr, $match->{+Q_PATH}->[0]);
    if (exists $match->{+Q_PATH}->[1]) {
	my $set2 = $self->_evalPath($row, $descr, $match->{+Q_PATH}->[1]);
	foreach my $val1 (@$set1) {
	    foreach my $val2 (@$set2) {
		if (_relation($val1, $val2,$match->{+Q_RELATION}->[0] )) {
		    $fit = 1;
		    last; #in $set2
		    last; #in $set1
		}
	    }
	}
    } else {
	$fit = scalar @$set1;
    }
    return $fit || 0;
}

sub _evalPath {
    my ($self, $row, $descr, $path) = @_;
    my @values;
    
    #If the path is a literal expression, return it's value
    if (exists $path->{+Q_EXPRESSION}) {
	my $value = $self->_evalExpression($row, $descr, 
					   $path->{+Q_EXPRESSION}->[0]);
	return [$value];
    }
    
    #Otherwise evaluate resources ($roots)
    my $roots;
    my $pathAtom;
    if (exists $path->{+Q_ELEMENTS}) {
	$pathAtom = Q_ELEMENTS;
    } elsif (exists $path->{+Q_ELEMENT}) {
	$pathAtom = Q_ELEMENT;
    }
    $roots = $self->_extractElement($path->{$pathAtom}[0]);
    my $newRoots = [];
    foreach my $inst (@$roots) {
	if ($inst->{type} eq Q_VARIABLE) {
	    $inst->{object} = $self->_evalVar($row, $descr, 
					      $inst->{name});
	    $inst->{type} = Q_NODE;
	    push @$newRoots, $inst;
	} elsif ($inst->{type} eq Q_FUNCTION) {
	    my ($val) = $self->_evalFun($row, $descr,$inst->{name},
					undef, $inst->{elementpath});
	    foreach (@$val) {
		push @$newRoots, {object=>$_};
	    }
	} else {
	    push @$newRoots, $inst;
	}
	$roots = $newRoots;
    }
    if (exists $path->{+Q_CLASS}) {
	# Check class (rdf:type) 
	my $passed = 0;
	my $class = $path->{+Q_CLASS}->[0];
	my $type = $self->getOptions->{Factory}->
	  newResource(RDF_NS, 'type');
	foreach my $inst (@$roots) {
	    my $classes = $self->_extractElement($class->{$pathAtom}->[0]);
	    foreach my $class (@$classes) {
		if ($inst->{type} eq Q_VARIABLE) {
		    $inst->{object} = $self->_evalVar($row, $descr, 
						      $inst->{name});
		    $inst->{type} = Q_NODE;
		}
		my $found = $self->_getStmts($row, $descr, 
					     $inst,{object=>$type}, $class);
		foreach my $enum (@$found) {
		    while ($enum->getNext) {
			$passed = 1;
			last;
		    }
		    $enum->close;
		}
	    }
	}
	return [] unless $passed;
    }
    my $node = $path->{$pathAtom};
    my $skipFirstElement = 1;
    foreach (@$node) {
	if ($skipFirstElement) {
	    #skip first element (it's processed already)
	    $skipFirstElement = 0;
	    next;
	}
	my $newRoots = [];
	my $element = $self->_extractElement($_);
	foreach my $subj (@$roots) {
	    foreach my $pred (@$element) {
		my $found = $self->_getStmts($row, $descr, 
					     $subj,$pred,undef);
		foreach my $enum (@{$found}) {
		    while (my $st = $enum->getNext) {
			my $root = {};
			$root->{object} = $st->getObject;
			push (@$newRoots, $root);
		    }
		    $enum->close;
		}
	    }
	}
	$roots = $newRoots;
    }
    
    my %lit;
    my %res;
    foreach (@$roots) {
	if ($_->{object}->isLiteral) {
	    next if $lit{$_->{object}->getValue};
	    $lit{$_->{object}->getValue} = 1;
	} else {
	    next if $res{$_->{object}->getURI};
	    $res{$_->{object}->getURI} = 1;
	}
	push @values, $_->{object};
    }
    return \@values;
}

sub _getStmts {
    my ($self, $row, $descr, $s, $p, $o) = @_;
    #Returns an array of enumerators.
    #Example: [$enum1,$enum2,...]
    my @subjects;
    my @predicates;
    my @objects;
    my @retValEnum;
    #Evaluate variables if you can
    foreach ($s,$p,$o) {
	$_ = {object=>undef, type=>Q_NODE} unless defined $_;
	$_->{object} = $self->_evalVar($row,$descr,$_->{name},'RELAX')
	  if $_->{type} eq Q_VARIABLE;
    }
    if ($s->{type} eq Q_FUNCTION) {
	my ($val) = $self->_evalFun($row, $descr, $s->{name}, undef,
				    $s->{elementpath});
	push @subjects, @{$val};
    } else {
	push @subjects, $s->{object};
    }
    if ($o->{type} eq Q_FUNCTION) {
	my ($val) = $self->_evalFun($row, $descr, $o->{name}, undef, 
				  $o->{elementpath});
	push @objects, @{$val};
    } else {
	push @objects, $o->{object};
    }
    if ($p->{type} eq Q_FUNCTION && (defined $s->{object} || !($s->{type} eq Q_NODE))) {
	my $fakePredicate = new RDF::Core::Resource($p->{name});
	my @retValArray;
	foreach my $subject (@subjects) {
	    my ($val,$pred) = $self->_evalFun($row, $descr, $p->{name}, 
					      $subject, $p->{elementpath});
	    foreach my $object (@objects) {
		for (my $i = 0; $i < @$val; $i++) {
		    if (!defined $object || 
			($val->[$i]->isLiteral == $object->isLiteral &&
			 $val->[$i]->getLabel eq $object->getLabel)) {
			push @retValArray , new RDF::Core::Statement
			  ($subject,$pred->[$i]||$fakePredicate,$val->[$i]);
		    }
		}
	    }
	}
	push @retValEnum, new RDF::Core::Enumerator::Memory(\@retValArray)
    } else {
	if ($p->{type} eq Q_FUNCTION) {
	    my ($val) = $self->_evalFun($row, $descr, $p->{name}, undef, 
				      $p->{elementpath});
	    push @predicates, @{$val};
	} else {
	    push @predicates, $p->{object};
	}
	
	foreach my $subject (@subjects) {
	    next if defined $subject && $subject->isLiteral;
	    foreach my $predicate (@predicates) {
		next if defined $predicate && $predicate->isLiteral;
		foreach my $object (@objects) {
		    push @retValEnum, $self->getOptions->{Model}->
		      getStmts($subject, $predicate, $object);
		    warn "Getting \n\t",
		    $subject ? $subject->getLabel : 'undef',"\n\t", 
		    $predicate ? $predicate->getLabel : 'undef',"\n\t", 
		    $object ? $object->getLabel : 'undef',"\n"
		      if $self->getOptions->{Debug};
#		    warn "Got ",$self->getOptions->{Model}->
#		      countStmts($subject, $predicate, $object)," statements\n"
#			if $self->getOptions->{Debug};
		}
	    }
	}
    }

    return \@retValEnum;
}
sub _evalVar {
    my ($self, $row, $descr, $varName, $relax) = @_;

    my $retVal = $row->[$descr->{$varName}] if defined $descr->{$varName};
    croak "Variable not found: $varName\n"
      unless defined $retVal || $relax;
    return $retVal;
}

sub _evalFun {
    my ($self, $row, $descr, $name, $subject, $elementPath) = @_;
    my @retVal;
    my @predicates;
    my $params;
    my $functions = $self->getOptions->{Functions};
    $params = $self->_evalRow($row, $descr, $elementPath);
    foreach (@$params) {
	my $fun = $functions->getFunctions->{$name};
	croak "Unknown function: $name" unless $fun;
	my @ret = &{$fun}($functions,$subject,$_);
	push @retVal, @{$ret[0]};
	push @predicates, @{$ret[1]};
    }
    

    return (\@retVal, \@predicates);
}

sub _evalExpression {
    my ($self, $row, $descr, $expression) = @_;
    my $retVal;
    if (exists $expression->{+Q_LITERAL}) {
	$retVal = $self->getOptions->{Factory}->
	  newLiteral($expression->{+Q_LITERAL}->[0]);
    } elsif (exists $expression->{+Q_SUBSTITUTION}) {
	my $substName = $expression->{+Q_SUBSTITUTION}->[0]->{+Q_NAME}->[0];
	$retVal = $self->{_subst}{$substName} || 
	  croak "Substitution not defined for $substName.\n";
    } else {
	$retVal = $self->_evalExpression($row, $descr,
					 $expression->{+Q_EXPRESSION}->[0]);
	for (my $i=1; $i < @{$expression->{+Q_EXPRESSION}}; $i++) {
	    #TODO: Operator precedence may be needed if more operators
	    # are implemented
	    my $newVal = $self->_evalExpression($row, $descr, $expression->
						{+Q_EXPRESSION}->[$i]);
	    $retVal = $self->_operation ($retVal,$newVal,$expression->
				  {+Q_OPERATION}->[$i-1]);
	    
	}
	
    } 
    return $retVal;
}

############################################################
# Utils

sub _namespaces {
    my ($self, $query) = @_;
    my $namespaces = {};
    $self->getOptions()->{_localNamespaces} = $namespaces;
    return unless $query->{+Q_NAMESPACE} && $query->{+Q_NAMESPACE}[0]{+Q_NAME};

    my $query_ns =  $query->{+Q_NAMESPACE}[0];
    for (my $i = 0; $i < @{$query_ns->{+Q_NAME}}; $i++) {
	$namespaces->{$query_ns->{+Q_NAME}[$i]} = $query_ns->{+Q_URI}[$i];
    }
    $self->getOptions()->{_localNamespaces} = $namespaces;
}
sub _relation {
    #Compare two nodes in graph
    my ($lval, $rval, $rel) = @_;
    my $retVal = 0;

    return undef 
      unless defined $lval && defined $rval;

    if ($rel eq '=') {
	$retVal = 1 if $lval->isLiteral == $rval->isLiteral &&
	  $lval->getLabel eq $rval->getLabel;
    } elsif ($rel eq '!=') {
	$retVal = 1 if $lval->isLiteral != $rval->isLiteral ||
	  !($lval->getLabel eq $rval->getLabel);
    } elsif ($rel eq '<=') {
	$retVal = 1 if $lval->isLiteral && $rval->isLiteral &&
	  $lval->getLabel le $rval->getLabel;
    } elsif ($rel eq '<') {
	$retVal = 1 if $lval->isLiteral && $rval->isLiteral &&
	  $lval->getLabel lt $rval->getLabel;
    } elsif ($rel eq '>=') {
	$retVal = 1 if $lval->isLiteral && $rval->isLiteral &&
	  $lval->getLabel ge $rval->getLabel;
    } elsif ($rel eq '>') {
	$retVal = 1 if $lval->isLiteral && $rval->isLiteral &&
	  $lval->getLabel gt $rval->getLabel;
    } else {
	croak "Relation not defined: $rel\n";
    }
    return $retVal;
}

sub _operation {
    my ($self, $lval, $rval, $op) = @_;
    my $retVal;

    return undef 
      unless defined $lval && defined $rval;
    if ($op eq '|') {
	if ($lval->isLiteral && $rval->isLiteral) {
	    $retVal = $self->getOptions->{Factory}->
	      newLiteral($lval->getValue.$rval->getValue);
	}
    } else {
	croak "Operation not defined: $op\n";
    }
    return $retVal
}
sub _findVars {
    # Return variable elements found in given subtree of query
    my ($self, $node, $vars) = @_;

    if (ref $node eq 'ARRAY') {
	foreach (@$node) {
	    $self->_findVars($_, $vars) if ref $_;
	}
    } elsif (ref $node eq 'HASH') {
	if (exists $node->{+Q_VARIABLE} 
	    && $node->{+Q_VARIABLE}[0]{+Q_NAME}[0]) {
	    push @$vars, $node->{+Q_VARIABLE}[0]{+Q_NAME}[0]; 
	} else {
	    foreach (values %$node) {
		$self->_findVars($_, $vars) if ref $_;
	    }
	}
#  	if ($node->{+Q_ELEMENT}) {
#  	    for (my $i = 0; $i < @{$node->{+Q_ELEMENT}}; $i++) {
#  		my $binding;
#  		$binding = $_->{+Q_VARIABLE}->[$i]->{+Q_NAME}->[0]
#  		  if $_->{+Q_VARIABLE};
#  		my $element = $self->_extractElement($_->{+Q_ELEMENT}->[$i],
#  						     $binding);
#  		foreach (@$element) {
#  		    #add variables to result
#  		    push @$vars, $_ 
#  		      if $_->{type} eq Q_VARIABLE;
#  		    #add variable binding, if found
#  		    push @$vars, {name=>$_->{binding}, type=>Q_VARIABLE}
#  		      if $_->{binding};
#  		}
#  	    }
#  	} else {
#  	    foreach (values %$node) {
#  		$self->_findVars($_, $vars) if ref $_;
#  	    }
#  	}
    } elsif (!defined $node) {
	croak "Can't find vars in subtree - node is not defined\n";
    } else {
	croak "Can't find vars in subtree - $node is not a tree node\n";
    }
}

sub _prepareHandler {
    my ($self, $handler, $default) = @_;
    my $defaulting = 0;
    if (defined $handler) {
	$self->{_handler} = $handler;
    } else {
	$self->{_handler} = $default;
	$defaulting = 1;
    }
    return $defaulting;
}
1;
__END__

=head1 NAME

RDF::Core::Evaluator - gets a query object that RDF::Core::Query parsed and evaluates the query. 

=head1 SYNOPSIS

  my %namespaces = (Default => 'http://myApp.gingerall.org/ns#',
                    ns     => 'http://myApp.gingerall.org/ns#',
		   );
  my $evaluator = new RDF::Core::Evaluator
    (Model => $model,            #an instance of RDF::Core::Model
     Factory => $factory,        #an instance of RDF::Core::NodeFactory
     Namespaces => \%namespaces,
    );
  my $query = new RDF::Core::Query(Evaluator=> $evaluator);

=head1 DESCRIPTION

The evaluator is just to be created and passed to query object, that uses it to evaluate the query.

=head2 Interface

=over 4

=item * new(%options)

Available options are:

=over 4

=item * Model

RDF::Core::Model object that contains data to be queried.

=item * Functions

RDF::Core::Function object is a functions library.

=item * Factory

RDF::Core::NodeFactory object, that produces resource and literal objects.

=item * Namespaces

A hash containing namespace prefixes as keys and URIs as values. See more in paragraph B<Names and URIs> in RDF::Core::Query, 

=item * Row

A code reference that is called every time a result row is found. The row elements are passed as parameters of the call. They can be undefined, RDF::Core::Resource or RDF::Core::Literal value. If Row is omitted, result is returned as a reference to array of rows

=back

=back

=head1 LICENSE

This package is subject to the MPL (or the GPL alternatively).

=head1 AUTHOR

Ginger Alliance, rdf@gingerall.cz

=head1 SEE ALSO

RDF::Core::Query

=cut


