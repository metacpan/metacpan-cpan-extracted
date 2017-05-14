# -*-Perl-*-
#
#  LTU.pm - A Perl module implementing linear threshold units.
#
#     Copyright (c) 1995 Tom Fawcett. All rights reserved.
#     This program is free software; you may redistribute it and/or
#     modify it under the same terms as Perl itself.
#
#  Original C code written by James Callan.
#  Rewritten for Perl from Version 2.4 by Tom Fawcett.
#  Bugs, comments, suggestions:  Tom Fawcett <fawcett@nynexst.com>
#
#  Description:
#
#  This module contains subroutines for creating, using, and destroying
#  linear threshold units (LTUs).  It offers four different training rules:
#
#  1)  The absolute correction rule (ACR), copied from Nils Nilsson's book
#      "Learning Machines:  Foundations of Trainable Pattern-Classification
#      Systems," published by McGraw-Hill in 1965.  This rule is identical
#      to the Perceptron rule.  Its advantage is that it converges quickly
#      when the training instances are linearly separable.
#  2)  The least-mean-square (LMS) rule, devised by Widrow and Hoff in 1960.
#      See the AI Handbook or Duda & Hart for information on the LMS rule.
#      The advantage of the LMS rule over absolute correction or fixed
#      increment is that it tends to minimize the mean-squared error, even
#      when the classes are not linearly separable.
#  3)  The recursive least square (RLS) rule, copied from Peter Young's book
#      "Recursive Estimation and Time-Series Analysis," published by
#      Springer-Verlag in 1984.  This rule is like the LMS rule, but far
#      superior to it.  It's faster, because each instance only needs to
#      be seen once.  It's also more accurate.
#  4)  The thermal perceptron (TACR) rule, copied from Marcus Frean's PhD
#      thesis "Learning in Single Perceptrons," published by University of
#      Edinburgh in 1990.  This rule is like the ACR rule, except that its
#      annealing capabilities enable it to handle classes that are not
#      linearly separable.
#
#  A "maybe-train" training strategy (i.e. train only when the linear
#  threshold unit misclassifies an instance) is implicit in the absolute
#  correction rule, the LMS rule and the thermal perceptron rule.  The RLS
#  rule always trains.
#
#  The training rules are most effective when attribute values are scaled
#  to a fixed range.  When values exceed 1.0, some of the rules (e.g. ACR,
#  TACR) may allow the magnitude of weights to grow without bound.  When
#  different attributes have different ranges, some of the rules (e.g. RLS)
#  give greater influence to attributes with larger ranges.  Therefore, you
#  can request automatic scaling, if you desire it, when the LTU is created.
#  If you enable scaling, your data is automatically scaled, so that its value
#  does not exceed 1.0.  Scales are computed and adjusted when necessary,
#  without any intervention from you.  
#
#  LTU's converge most quickly when the data includes both positive and
#  negative values.  Therefore, when your data is scaled, it is scaled so
#  that the midpoint of the range is 0.0.
#
#  Each time scales are adjusted, the weights in the LTU become inaccurate.
#  The scaling procedure cannot compensate for this inaccuracy.  Therefore,
#  the automatic scaling can affect the speed with which the algorithm
#  converges.  However, once the scales "settle down" (i.e. once the extreme
#  values for each attribute have been seen), the speed of convergence is not
#  affected.
#
#  Automatic scaling adversely affects the RLS rule, because the RLS rule
#  implicitly "remembers" each instance.  When scales are adjusted, the 
#  instances remembered by the LTU become noisy.  If you enable scaling with
#  the RLS rule, you should cycle through your instances several times, at
#  least until the extreme values (min/maxs) of each attribute have been seen.
#
#
##############################################################################
#  $Log: LTU.pm,v $
# Revision 2.7  1996/02/20  15:15:18  fawcett
# Fixed package confusion made in the original version.
# Now exports $LTU_MINUS, LTU_PLUS and LTU_THRESHOLD.
# Created Makefile.PL so that MakeMaker can handle installation,
# cleaning, distribution, etc.
#
#
# Revision 2.5  1995  fawcett
# Initial public offering, released as Statistics::LTU.pm.
# Based on Jamie's LTU.c version 2.4.
#
##############################################################################
package Statistics::LTU;
my($rcs) = ' $Id: LTU.pm,v 2.7 1996/02/20 15:15:18 fawcett Exp $ ' ;
require 5;
use Carp;

require Exporter;
@ISA = ('Exporter');
@EXPORT = qw($LTU_PLUS $LTU_MINUS $LTU_THRESHOLD);

($Statistics::LTU::VERSION) = $rcs =~ /Id: LTU\.pm.* ([\d\.]+) /;
die "Can't determine Statistics::LTU::VERSION from rcs string!"
    unless $Statistics::LTU::VERSION;

#  We understand LTU's dumped with 2.5 or later
my($read_LTU_files_back_to) = 2.5;


##
##  EXPORTED CONSTANTS
##

$LTU_MINUS =       -1.0;
$LTU_PLUS  =        1.0;
$LTU_THRESHOLD =     0;

##
##  PRIVATE CONSTANTS
##

my($LTU_ORIGIN_OFF) =   0;
my($LTU_ORIGIN_ON) =    1;

my($LTU_SCALING_OFF) =  0;
my($LTU_SCALING_ON) =   1;

##
##  Data Structure Definitions
##

##  Field indices for the LTU structure.
##  All index names end in "i";

my($LTU_LENGTH) = 15;		# Number of entries in an LTU

my($LENGTHi, 
   $SCALINGi,
   $ORIGIN_RESTRICTIONi,
   $UNUSEDi,
   $CYCLES_SINCE_WEIGHT_CHANGEi,
   # Remainder are references to vectors
   $WEIGHTi,			
   $WEIGHT_MINi,
   $WEIGHT_MAXi,
   $ATTRIB_MINi,
   $ATTRIB_MAXi,
   $ATTRIB_SCALEi,
   $ATTRIBUTEi,
   $RLS_Pi,
   $RLS_TMP_1i,
   $RLS_TMP_2i,
   ) = 
    (0 .. $LTU_LENGTH-1);

$LTU_ATTRIBUTE_MIN = -0.5;

##
##  new creates a new LTU with weights set to 0.
##
sub new {
    my($type, $nvars, $scaling) = @_;

    ##
    ##  First allocate the LTU, and fill in its basic information.
    ##

    my($self) = [ (0) x $LTU_LENGTH ];

    my($length) = $nvars + 1;

    $self->[$SCALINGi] = $scaling;
    $self->[$LENGTHi]  = $length;
    $self->[$ORIGIN_RESTRICTIONi] = $LTU_ORIGIN_OFF;

    ##
    ##  Create vectors used by all types.
    ##
    $self->[$WEIGHTi]     = [ (0.0) x $length ];
    $self->[$WEIGHT_MINi] = [ (0.0) x $length ];
    $self->[$WEIGHT_MAXi] = [ (0.0) x $length ];
    $self->[$ATTRIBUTEi]  = [ (0.0) x $length ];

    ##
    ##  Allocate scaling vectors if necessary.
    ##
    if ($scaling == $LTU_SCALING_ON) {

	## Signal need to initialize these values by setting attrib_min > max

	$self->[$ATTRIB_MINi]   = [ (1.0) x $length ];
	$self->[$ATTRIB_MAXi]   = [ (-1.0) x $length ];
	$self->[$ATTRIB_SCALEi] = [ (1.0) x $length ];

    };

    bless $self, $type;		# Bless into type
}


##
##  COPY creates a copy of itself, which it returns
##
sub copy {
    my($self) = @_;

    ##
    ##  First, create a new LTU.
    ##

    my($new) = new Statistics::LTU($self->[$LENGTHi]-1, 
		       $self->[$SCALINGi]);

    ##
    ##  Copy the basic information that all LTU's have.  (The attribute vector
    ##  isn't copied because its contents are temporary.)
    ##
    $new->[$CYCLES_SINCE_WEIGHT_CHANGEi] =
	$self->[$CYCLES_SINCE_WEIGHT_CHANGEi];
    $new->[$ORIGIN_RESTRICTIONi] = 
	$self->[$ORIGIN_RESTRICTIONi];

    $new->[$WEIGHTi] =     [@{$self->[$WEIGHTi]}];
    $new->[$WEIGHT_MINi] = [@{$self->[$WEIGHT_MINi]}];
    $new->[$WEIGHT_MAXi] = [@{$self->[$WEIGHT_MAXi]}];

    ##
    ##  Copy scaling data, if necessary.
    ##
    if ($new->[$SCALINGi] == $LTU_SCALING_ON) {
	$new->[$ATTRIB_MINi] =   $self->[$ATTRIB_MINi];
	$new->[$ATTRIB_MAXi] =   $self->[$ATTRIB_MAXi];
	$new->[$ATTRIB_SCALEi] = $self->[$ATTRIB_SCALEi];
    }

    $new;
}


##
##  LTU_DESTROY destroys an existing linear threshold unit.
#####  I don't know if this is necessary but it can't hurt
##
sub destroy {
    my($self) = @_;

    for (0 .. $LTU_LENGTH-1) {
	undef $self->[$_];
    }
    undef $self;

}


##
##  IS_CYCLING returns a boolean value which indicates whether or not the
##  LTU's weights are cycling.  If they are, further training will not produce
##  better results.  This judgement is based upon the heuristic that if the
##  weights are not cycling, then the min/max's of weights will change fairly
##  often.  The caller must specify what it thinks is "fairly often".  This is
##  done with a parameter that specifies how many times the training function
##  can adjust weights before the caller would expect at least one weight to
##  have its min/max adjusted.  Some common values for this parameter are the
##  number of attributes, or the log of the number of attributes.
##

sub is_cycling {
    my($self, $how_often_weights_must_change) = @_;

    $self->[$CYCLES_SINCE_WEIGHT_CHANGEi] > $how_often_weights_must_change;
}


##
##  PRINT describes the LTU and its weights.
##
sub print {
    my($self) = @_;

    print "The linear threshold unit is of type ", ref($self);
    print " and contains ", $self->[$LENGTHi], " weights.\n";

    printf("Origin restriction=%d.\n", 
	    $self->[$ORIGIN_RESTRICTIONi]);
    printf("Cycles since last change of a weight min/max:  %d.\n",
	    $self->[$CYCLES_SINCE_WEIGHT_CHANGEi]);

    ##
    ##  Print 8 weights to a line, just to make it easier to read.
    ##

    my($i);

    for $i (0 .. $self->[$LENGTHi]-1) {
	print $self->[$WEIGHTi]->[$i], " ";

	printf("\n") if $i%8 == 7;
    };

    print "\n";
}


##
##  RESTORE restores a linear threshold unit from the specified file.
##
sub restore {
    my($class, $file_name) = @_;

    if (!open(FILE, "<$file_name")) {
	carp "restore: $file_name: $!\n";
	return(0);
    }

    ##
    ##  Check that the LTU is consistent with this version
    ##
    my($ltu_version);
    $ltu_version = <FILE>;
    chop($ltu_version);

    if ($ltu_version < $read_LTU_files_back_to) {
	carp "restore: $file_name written with LTU version $ltu_version.\n";
	carp "This is version $Statistics::LTU::VERSION, which only understands\n";
	carp "LTU files back to $read_LTU_files_back_to.\n";
	carp "LTU not restored!\n";
	return(0);
    }

    ## First, read the type, the number of weights, and whether or not scaling
    ##  is enabled.  Then, create a linear threshold unit.  Note that the
    ##  number of variables in the training instances is one less than the
    ##  number of weights (one weight is a constant).
    ##

    my($line);
    $line = <FILE>;
    chop($line);
    my($type, $length, $scaling, $cycles_since_weight_change, $origin) =
	split(/ /, $line);

    my($new) = $type->new($length-1, $scaling);

    $new->[$CYCLES_SINCE_WEIGHT_CHANGEi] = $cycles_since_weight_change;
    $new->[$ORIGIN_RESTRICTIONi]         = $origin;

    ##
    ##  Now, read the weights, the minimum value of the attributes, and the
    ##  maximum value of the attributes, from the file, and store them in the
    ##  linear threshold unit.

    my($new_weight) = 		$new->[$WEIGHTi];
    my($new_weight_min) = 	$new->[$WEIGHT_MINi];
    my($new_weight_max) = 	$new->[$WEIGHT_MAXi];
    my($new_attrib_min) = 	$new->[$ATTRIB_MINi];
    my($new_attrib_max) = 	$new->[$ATTRIB_MAXi];
    my($new_attrib_scale) = 	$new->[$ATTRIB_SCALEi];
    
    my($i, @fields);

    for $i (0 .. $length-1) {
	$line = <FILE>;  chop($line);

	@fields =  split(/ /, $line);

	($new_weight->[$i], $new_weight_min->[$i], $new_weight_max->[$i]) =
	    @fields;

	if ($scaling == $LTU_SCALING_ON) {
	    
	    ($new_attrib_min->[$i], $new_attrib_max->[$i]) = @fields[3,4];

	    if ($new_attrib_max->[$i] > $new_attrib_min->[$i]) {
		$new_attrib_scale->[$i] = 1.0 /
		    ($new_attrib_max->[$i] - $new_attrib_min->[$i]);
	    }
	}
    }
	
    #####  Pick up final theta value
    $line = <FILE>;  chop($line);
    $new->[$WEIGHTi]->[$length-1] = $line;

    close(FILE);
    
    $new;
}



##
##  SAVE saves the linear threshold unit in the specified file.
##  If the file can't be created for some reason, 0 is returned.  Otherwise, 1
##  is returned.
##
sub save {
    my($self, $file_name) = @_;
    my($length) = $self->[$LENGTHi];

    if (!open(FILE, ">$file_name")) {
	carp "Statistics::LTU::save: $file_name: $!";
	return(0);
    }

    ##
    ##  Stamp the file with a version number.
    ##
    print FILE $Statistics::LTU::VERSION, "\n";

    ## First, print the type, the number of weights and whether or not scaling
    ##  is enabled.  Then, print the weights, the minimum value of the
    ##  attribute, and the maximum value of the attribute.  Print 1
    ##  attribute/line, just to make it easier to read.

    print FILE join(' ', ((ref $self), 
			  $self->[$LENGTHi],
			  $self->[$SCALINGi],
			  $self->[$CYCLES_SINCE_WEIGHT_CHANGEi],
			  $self->[$ORIGIN_RESTRICTIONi]
			  )), 
			      "\n";

    my($i);
    for $i (0 .. $length-1) {

	printf FILE "%lf %lf %lf ", 
		$self->[$WEIGHTi]->[$i],
		$self->[$WEIGHT_MINi]->[$i],
		$self->[$WEIGHT_MAXi]->[$i];

	if ($self->[$SCALINGi] == $LTU_SCALING_ON) {
	    printf FILE "%lf %lf ", 
	    $self->[$ATTRIB_MINi]->[$i],
	    $self->[$ATTRIB_MAXi]->[$i];
	}

	print FILE "\n";
    }

    printf FILE "%lf\n", $self->[$WEIGHTi]->[$length-1];

    close(FILE);

    1;
}


##
##  TEST computes and returns the result of applying the linear threshold
##  unit to the instance_vector.
##

sub test {
    my($self, $instance_vector) = @_;

    my($length) =    $self->[$LENGTHi];
    my($weight) =    $self->[$WEIGHTi];
    my($attribute) = $self->[$ATTRIBUTEi];

    $self->_scale_attributes($instance_vector);

    my($result) = $weight->[$length-1];

    my($i);

    for $i (0 .. $length-2) {
	$result += $attribute->[$i] * $weight->[$i];
    }

    $result;

}



##
##  _SCALE_ATTRIBUTES translates and scales the attributes comprising an
##  instance vector.  The scaled attributes are stored in the attributes slot
##  on the LTU, so that the original instance_vector will not be changed.
##
sub _scale_attributes {
    my($self, $instance_vector) = @_;
    my($length) = $self->[$LENGTHi];

    my($attribute) =    $self->[$ATTRIBUTEi];
    my($attrib_min) =   $self->[$ATTRIB_MINi];
    my($attrib_scale) = $self->[$ATTRIB_SCALEi];

    ##
    ##  If scaling is disabled, just copy the instance attribute values into
    ##  the temporary attribute vector.  This isolates the input values from
    ##  the caller's storage and converts to double precision.  Otherwise
    ##  translate and scale the attributes.  When min=max, only one value has
    ##  been seen for the attribute.  In that case, the attribute is mapped
    ##  to the minimum value.  It is advantageous to use one of the endpoints,
    ##  instead of the midpoint 0.0, because it lets training begin.  
    ##

    my($i);

    if ($self->[$SCALINGi] == $LTU_SCALING_OFF) {

	for $i (0 .. $#$instance_vector) {
	    $attribute->[$i] = $instance_vector->[$i];
	}
    } else {

	for $i (0 .. $#$instance_vector) {
	    $attribute->[$i] = (($instance_vector->[$i] - $attrib_min->[$i]) *
				$attrib_scale->[$i]) + $LTU_ATTRIBUTE_MIN;
	}
    }

    ##
    ##  A constant attribute must be added to the end of the instance vector
    ##  in order to learn some kinds of functions (e.g. f(x)=mx+b, the function
    ##  for a line in 2D space).  The constant attribute enables the training
    ##  function to learn a weight that translates the hyperplane.  However,
    ##  it is undesirable for other kinds of functions (e.g. f(x)=mx, which is
    ##  what some preference predicates look like).  Decide what to do.
    ##

    if ($self->[$ORIGIN_RESTRICTIONi] == $LTU_ORIGIN_ON) {
	$attribute->[$length-1] = 0.0;

    } else {
	$attribute->[$length-1] = 1.0;
    }

}


##
##  MAINTAIN_SCALING_FACTORS checks that the specified instance falls within
##  the min-max ranges of the specified LTU.  If it does, nothing changes.
##  If it does not, the min-max ranges and the scaling factors are adjusted
##  to accomodate this new instance.
##
sub maintain_scaling_factors {
    my($self, $instance_vector) = @_;

    ##
    ##  If scaling is disabled, don't do anything.
    ##
    return if $self->[$SCALINGi] == $LTU_SCALING_OFF;

    my($length) = $self->[$LENGTHi];
    my($attrib_min) =   $self->[$ATTRIB_MINi];
    my($attrib_max) =   $self->[$ATTRIB_MAXi];
    my($attrib_scale) = $self->[$ATTRIB_SCALEi];

    my($i);
    for $i (0 .. $length-2) {
	if ($attrib_min->[$i] > $attrib_max->[$i]) {

	    ##
	    ##  Initialization.
	    ##
	    $attrib_min->[$i] = $attrib_max->[$i] = 
		$instance_vector->[$i];

	} elsif ($instance_vector->[$i] > $attrib_max->[$i]) {

	    $attrib_max->[$i] = $instance_vector->[$i];
	    $attrib_scale->[$i] =
		1.0 / ($attrib_max->[$i] - $attrib_min->[$i]);

	} elsif ($instance_vector->[$i] < $self->[$ATTRIB_MINi]->[$i]) {

	    $attrib_min->[$i] = $instance_vector->[$i];
	    $attrib_scale->[$i] =
		1.0 / ($attrib_max->[$i] - $attrib_min->[$i]);
	}
    }
}

##
##   SET_ORIGIN_RESTRICTION
##
sub set_origin_restriction {
    my($self, $value) = @_;

    if (($value == $LTU_ORIGIN_OFF) or ($value == $LTU_ORIGIN_ON)) {
	$self->[$ORIGIN_RESTRICTIONi] = $value;
    } else {
	carp "$value is an unacceptable value for the origin restriction\n";
    }
}


##
##   LTU_WEIGHTS returns a ref to copy of the LTU weights.
##
sub weights {
    my($self) = @_;
    
    [@{$self->[$WEIGHTi]}];
}


##
##  UPDATE_WEIGHT_MIN_MAX updates an LTU's weight min/max's and its
##  cycles_since_weight_change field.  Although it is simple, it is
##  implemented as a separate routine because each training routine
##  should perform this function before returning the LTU to the caller.
##
sub update_weight_min_max {
    my($self) = @_;

    my($boundary_changed) = 0;
    
    my($weight)     = $self->[$WEIGHTi];
    my($weight_max) = $self->[$WEIGHT_MAXi];
    my($weight_min) = $self->[$WEIGHT_MINi];

    my($i);
    for $i (0 .. $self->[$LENGTHi]-2) {

	if ($weight_max->[$i] < $weight->[$i]) {
	    $weight_max->[$i] = $weight->[$i];
	    $boundary_changed = 1;

	} elsif ($weight_min->[$i] > $weight->[$i]) {
	    $weight_min->[$i] = $weight->[$i];
	    $boundary_changed = 1;
	}
    }    
	
    if ($boundary_changed) {
	$self->[$CYCLES_SINCE_WEIGHT_CHANGEi] = 0;
    } else {
	$self->[$CYCLES_SINCE_WEIGHT_CHANGEi]++;
    }
}



##
##  $LTU->correctly_classifies($instance, $value) 
##  Returns 1 iff $instance is on the same side of Statistics::LTU::THRESHOLD
##  as $value is.
##
sub correctly_classifies {
    my($self, $instance, $desired_value) = @_;

    my($actual_value) = $self->test($instance);
    
    ((($actual_value   < $LTU_THRESHOLD) and
      ($desired_value  < $LTU_THRESHOLD)) or
     (($actual_value  >= $LTU_THRESHOLD) and
      ($desired_value >= $LTU_THRESHOLD)));
}

##
##  ltu->eval_on_set(examples)
##
##  Evaluates an LTU on a set of example, returning 4 integers:
##  True negatives, false positives, false negatives and true positives.
##
##  Argument is a ref to a list of examples.
##  Each example is a ref to an array of [Vector, Value].
##  Each Vector is a feature vector.
##
##  Example:
##     @Results = $LTU->eval_on_set([[[1,4,-2],1], [[1,-2,2],-1]]);
##     ($TN, $FP, $FN, $TP) = @Results;
##
sub eval_on_set {
    my($self, $Examples) = @_;

    my($TN, $FP, $FN, $TP) = (0,0,0,0);
    my($example, $Instance, $DesiredValue, $ActualValue);

    foreach $example (@{$Examples}) {
	($Instance, $DesiredValue) = @{$example};
	my($ActualValue) = $self->test($Instance);
	if ($ActualValue >= $LTU_THRESHOLD) {
	    if ($DesiredValue >= $LTU_THRESHOLD) {
		$TP++;
	    } else {
		$FP++;
	    }
	} elsif ($DesiredValue >= $LTU_THRESHOLD) {
	    $FN++;
	} else {
	    $TN++;
	}
    }

    ($TN, $FP, $FN, $TP);
}



###
###  Specific LTU types built upon LTU.
###  1.  The absolute correction rule.

package Statistics::LTU::ACR;
@Statistics::LTU::ACR::ISA = qw( Statistics::LTU );
use Statistics::LTU;

##
##  ACR::TRAIN trains the specified linear threshold unit on a particular
##  instance_vector.  It returns 1 if the linear threshold unit already
##  classified the instance_vector correctly, otherwise it returns 0.
##  The training rule is taken from Nilsson's "Learning Machines" book.
##

sub train { 
    my($self, $instance_vector, $desired_value) = @_;
    my($length) = $self->[$LENGTHi];

    ##
    ##  Only train the linear threshold unit if it does not classify correctly.
    ##

    my($actual_value) = $self->test($instance_vector);

    die "\$Statistics::LTU::LTU_THRESHOLD undefined in ACR" unless defined($Statistics::LTU::LTU_THRESHOLD);

    return(1) if ((($actual_value   < $Statistics::LTU::LTU_THRESHOLD) && 
		   ($desired_value  < $Statistics::LTU::LTU_THRESHOLD)) ||
		  (($actual_value  >= $Statistics::LTU::LTU_THRESHOLD) && 
		   ($desired_value >= $Statistics::LTU::LTU_THRESHOLD)));

    ## The scale factor can only be changed when the weights are being
    ##  changed, because a change to the scale factor invalidates the current
    ##  set of weights.

    $self->maintain_scaling_factors($instance_vector);
    $self->_scale_attributes($instance_vector);

    ##
    ##  Decide how much to adjust the weights by.  The absolute correction rule
    ##  (which provides the fastest learning) requires the dot product of the
    ##  instance vector, so do that first.
    ##
    
    my($dot_product) = 0;
   
    foreach (@{$self->[$ATTRIBUTEi]}) {
	$dot_product += $_ * $_;
    }

    my($delta) = $dot_product==0 ? .1 
	: 1.0 + (int(abs($actual_value) / $dot_product));
    $delta = -$delta   if $desired_value < $Statistics::LTU::LTU_THRESHOLD;

    ##
    ##  Now, adjust the weights.  The last weight is handled differently, 
    ##  because it is always applied to the constant 1.
    ##

    my($weight) =    $self->[$WEIGHTi];
    my($attribute) = $self->[$ATTRIBUTEi];

    my($i);
    for $i (0 .. $length-1) {
	$weight->[$i] += $delta * $attribute->[$i];
    }
    $self->update_weight_min_max;

    0;
}



###
###  Recursive Least Squares linear threshold units
###
package Statistics::LTU::RLS;
use Statistics::LTU;
use Carp;

@Statistics::LTU::RLS::Inherit::ISA = @Statistics::LTU::RLS::ISA = 
    qw( Statistics::LTU );

sub new {
    my($type, $nvars, $scaling) = @_;

    #  I don't know how to get inheritance to work automatically here
    my($self) = new Statistics::LTU($nvars, $scaling);

    my($length) = $nvars + 1;

    ##
    ##  Allocate temporary space for the RLS rule.
    ##

    my($p) =               [ (0.0) x ($length * $length) ];
    $self->[$RLS_Pi] =     $p;
    $self->[$RLS_TMP_1i] = [ (0.0) x $length ];
    $self->[$RLS_TMP_2i] = [ (0.0) x $length ];

    ##  [Used to be rls_init_p]
    ##  Initialize the p matrix to an arbitrarily large value along the
    ##  diagonal, and zero everywhere else.  Suggested in the algorithm, p 27.
    ##
    ##  Young says that "large diagonal elements [for the p matrix] (say 10^6
    ##  in general) will yield convergence and performance comensurate with the
    ##  stage-wise solution of the same problem" (p 27).  I have found that
    ##  values larger than 10^6 sometimes converge to more accurate weights;
    ##  however, values that are too large (e.g. 2.0 * 10^15) produce less
    ##  accurate weights.  The value defined below is intended to be as large
    ##  as is possible without adversely affecting performance.  It was
    ##  determined empirically.
    ##

    my($DIAGONAL_VALUE) = 10.0e+6;

    my($i, $j);
    for $i (0 .. $length-1) {

	$p->[$i * $length + $i] = $DIAGONAL_VALUE;

	for $j ($i+1 .. $length-1) {

	    $p->[$i * $length + $j] = 0.0;
	    $p->[$j * $length + $i] = 0.0;
	}
    }

    bless $self;
}



sub copy {
    my($self) = @_;

    my($new) = $self->Statistics::LTU::RLS::Inherit::copy($self);

    ##
    ##  Copy the RLS data.  (The tmp_1 and tmp_2 vectors
    ##  aren't copied because their contents are temporary.)
    ##

    $new->[$RLS_Pi] = [@{$self->[$RLS_Pi]}];

    bless $new;
}

##
##  TRAIN trains the specified linear threshold unit on a particular
##  instance_vector.  The training rule is taken from Young's "Recursive
##  Estimation and Time-Series Analysis" book, pp26-27.
##  Return value is undefined.

sub train {
    my($self, $instance_vector, $desired_value) = @_;

    ##
    ##  First, translate and scale the attributes.  The scale factor can only
    ##  be changed when the weights are being changed, because a change to the
    ##  scale factor invalidates the current set of weights.
    ##

    $self->maintain_scaling_factors($instance_vector);
    $self->_scale_attributes($instance_vector);

    ##
    ##  Now, update the weights.  This is done in two parts, 
    ##  updating the P matrix and A vector, respectively.
    ##
    $self->rls_update_p;
    $self->rls_update_a($desired_value);

    $self->update_weight_min_max;
    undef;
}


##
##  RLS_UPDATE_P implements equation II(1) on p26.  This is the first half of
##  the RLS algorithm.
##
##  The terminology matches what is in the book.  The algorithm computes
##  new values for array p at time k, based upon the vector x at time k and
##  the array p at time k-1.
##
##  The temporary arrays pkm1_xk and xkT_pkm1 are provided by the caller, to
##  eliminate the overhead of creating and destroying temporary arrays.
##

sub rls_update_p {
    my($self) = @_;

    my($p) =        $self->[$RLS_Pi];
    my($length) =   $self->[$LENGTHi];
    my($xk) =       $self->[$ATTRIBUTEi];
    my($pkm1_xk) =  $self->[$RLS_TMP_1i];
    my($xkT_pkm1) = $self->[$RLS_TMP_2i];

    my($i, $j);

    ##
    ##  Multiply pkm1 (the array p at time k-1) by xk (x at time k).
    ##

    for ($i=0; $i<$length; $i++) {
	$pkm1_xk->[$i] = 0.0;

	for ($j=0; $j<$length; $j++) {
	    $pkm1_xk->[$i] += $p->[$i * $length + $j] * $xk->[$j];
	}
    }

    ##
    ##  Get the scalar value [1 + xkT_pkm1_xk] ^ -1.  Call it scalar_value.
    ##  This can't be done until after pkm1_xk has been computed.
    ##
    my($scalar_value) = 1.0;

    for ($i=0; $i<$length; $i++) {
	$scalar_value += $pkm1_xk->[$i] * $xk->[$i];
    }

    $scalar_value = 1.0 / $scalar_value;

    ##
    ##  Fold the scalar_value into pkm1_xk.  This is more efficient than doing
    ##  it later, because pkm1_xk is an nx1 array and later arrays will be nxn.
    ##

    for $i (0 .. $length-1) {
	$pkm1_xk->[$i] *= $scalar_value;
    }

    ##
    ##  Multiply xkT (x at time k, transposed) by pkm1 (the array p 
    ##  at time k-1).
    ##

    for $i (0 .. $length-1) {
	$xkT_pkm1->[$i] = 0.0;

	for $j (0 .. $length-1) {
	    $xkT_pkm1->[$i] += $xk->[$j] * $p->[$j * $length + $i];
	}
    }

    ##
    ##  Multiply pkm1_xk by xkT_pkm1.  The result is used to update p, so it
    ##  does not need to be stored explicitly.
    ##

    for $i (0 .. $length-1) {
	for $j (0 .. $length-1) {
	    $p->[$i * $length + $j] -= $pkm1_xk->[$i] * $xkT_pkm1->[$j];
	}
    }
}

##
##  RLS_UPDATE_A implements equation II(2) on p26.  This is the second half of
##  the RLS algorithm.
##
sub rls_update_a {
    my($self, $yk) = @_;

    my($a) = 		$self->[$WEIGHTi];
    my($p) = 		$self->[$RLS_Pi];
    my($length) = 	$self->[$LENGTHi];
    my($xk) = 		$self->[$ATTRIBUTEi];
    
    ##
    ##  Multiply xkT (x at time k, transposed) by akm1 (a at time k-1).  The
    ##  result is a scalar value.  Subtract yk (y at time k).
    ##

    my($scalar_value) = 0.0 - $yk;
    my($i, $j);

    for ($i=0 ; $i<$length ; $i++) {
	$scalar_value += $xk->[$i] * $a->[$i];
    }

    ##
    ##  Multiply pk (p at time k) by xk (x at time k).  This is what the
    ##  algorithm calls Kk.  Matrix Kk is used to update a, so it does not
    ##  need to be stored explicitly.
    ##

    my($sum_of_products);

    for $i (0 .. $length-1) {

	$sum_of_products = 0.0;

	for $j (0 .. $length-1) {

	    $sum_of_products += $p->[$i * $length + $j] * $xk->[$j];
	}

	$a->[$i] -= $sum_of_products * $scalar_value;
    }
}


##
##  RESTORE restores a linear threshold unit from the specified file.
##

sub restore {
  my($class, $file_name) = @_;
  
  if (!open(FILE, "<$file_name")) {
    carp("restore: $file_name: $!\n");
    return(0);
  }
  
  ##
  ##  Check that the LTU is consistent with this version.
  ##
  my($ltu_version);
  $ltu_version = <FILE>;
  chop($ltu_version);
  
  if ($ltu_version < $read_LTU_files_back_to) {
    carp "restore: $file_name written with LTU version $ltu_version.\n";
    carp "This is version $Statistics::LTU::VERSION, which only understands\n";
    carp "LTU files back to version $read_LTU_files_back_to\n";
    carp "LTU not restored!\n";
    return(0);
  }
  
  ## First, read the type, the number of weights, and whether or not scaling
  ##  is enabled.  Then, create a linear threshold unit.  Note that the
  ##  number of variables in the training instances is one less than the
  ##  number of weights (one weight is a constant).
  ##
  
  my($line);
  $line = <FILE>;
  chop($line);
  my($type, $length, $scaling, $cycles_since_weight_change, $origin) =
      split(/ /, $line);
  
  my($new) = $type->new($length-1, $scaling);
  
  $new->[$CYCLES_SINCE_WEIGHT_CHANGEi] = $cycles_since_weight_change;
  $new->[$ORIGIN_RESTRICTIONi]         = $origin;
  
  ##
  ##  Now, read the weights, the minimum value of the attributes, and the
  ##  maximum value of the attributes, from the file, and store them in the
  ##  linear threshold unit.
  
  my($new_weight) = 		$new->[$WEIGHTi];
  my($new_weight_min) = 	$new->[$WEIGHT_MINi];
  my($new_weight_max) = 	$new->[$WEIGHT_MAXi];
  my($new_attrib_min) = 	$new->[$ATTRIB_MINi];
  my($new_attrib_max) = 	$new->[$ATTRIB_MAXi];
  my($new_attrib_scale) = 	$new->[$ATTRIB_SCALEi];
  
  my($i, @fields);
  
  for $i (0 .. $length-1) {
    $line = <FILE>;  chop($line);
    
    @fields =  split(/ /, $line);
    
    ($new_weight->[$i], $new_weight_min->[$i], $new_weight_max->[$i]) =
	@fields;
    
    if ($scaling == $LTU_SCALING_ON) {
      
      ($new_attrib_min->[$i], $new_attrib_max->[$i]) = @fields[3,4];
      
      if ($new_attrib_max->[$i] > $new_attrib_min->[$i]) {
	$new_attrib_scale->[$i] = 1.0 /
	    ($new_attrib_max->[$i] - $new_attrib_min->[$i]);
      }
    }
  }
  
  #####  Pick up final theta value
  $line = <FILE>;  chop($line);
  $new->[$WEIGHTi]->[$length-1] = $line;
  
  ##
  ##  Read information specific to RLS LTU's.
  ##
  
  $line = <FILE>; chop($line);
  $new->[$RLS_Pi] = [(split(/ /, $line))];
  
  close(FILE);
  
  $new;
}



##
##  SAVE saves the linear threshold unit in the specified file.
##  If the file can't be created for some reason, 0 is returned.  Otherwise, 1
##  is returned.
##

sub save {
    my($self, $file_name) = @_;
    my($length) = $self->[$LENGTHi];

    if (!open(FILE, ">$file_name")) {
	carp("Statistics::LTU::save: $file_name: $!");
	return(0);
    }

    ##
    ##  Stamp the file with a version number.
    ##
    print FILE $Statistics::LTU::VERSION, "\n";

    ## First, print the type, the number of weights and whether or not scaling
    ##  is enabled.  Then, print the weights, the minimum value of the
    ##  attribute, and the maximum value of the attribute.  Print 1
    ##  attribute/line, just to make it easier to read.

    print FILE join(' ', ((ref $self),
			  $self->[$LENGTHi],
			  $self->[$SCALINGi],
			  $self->[$CYCLES_SINCE_WEIGHT_CHANGEi],
			  $self->[$ORIGIN_RESTRICTIONi]
			  )), 
			      "\n";

    my($i);
    for $i (0 .. $length-1) {

	printf FILE "%lf %lf %lf ", 
		$self->[$WEIGHTi]->[$i],
		$self->[$WEIGHT_MINi]->[$i],
	$self->[$WEIGHT_MAXi]->[$i];

	if ($self->[$SCALINGi] == $LTU_SCALING_ON) {
	    printf FILE "%lf %lf ",
		    $self->[$ATTRIB_MINi]->[$i],
	    $self->[$ATTRIB_MAXi]->[$i];
	}

	print FILE "\n";
    }

    printf FILE "%lf\n", $self->[$WEIGHTi]->[$length-1];

    ##
    ##  Write out information specific to RLS LTU's.
    ##

    print FILE join(' ', @{$self->[$RLS_Pi]}), "\n";
    
    close(FILE);

    1;
}




package Statistics::LTU::LMS;
use Statistics::LTU;

@Statistics::LTU::LMS::ISA = qw( Statistics::LTU );

##
##  TRAIN trains the specified linear threshold unit on a particular
##  instance_vector.  It returns 1 if the linear threshold unit already
##  classified the instance_vector correctly, otherwise it returns 0.
##  The training rule is the least-mean-square (LMS) rule, devised by
##  Widrow and Hoff in 1960.  The advantage of the LMS rule over absolute
##  correction or fixed increment is that it tends to minimize the
##  mean-squared error, even when the classes are not linearly separable.
##  See the AI Handbook or Duda & Hart for more information.
##

sub train {
    my($self, $instance_vector, $desired_value, $rho) = @_;

    my($length) =    $self->[$LENGTHi];
    my($weight) =    $self->[$WEIGHTi];
    my($attribute) = $self->[$ATTRIBUTEi];
    ##
    ##  Make sure that rho makes sense.  If it doesn't, default to 0.2.  This
    ##  number was chosen empirically, on the basis of limited experimentation.
    ##

    $rho = 0.2 if !defined($rho) or $rho <= 0.0;

    ##
    ##  Only train the linear threshold unit if it does not classify correctly.
    ##

    my($actual_value) = $self->test($instance_vector);

    return(1) if ((($actual_value   < $Statistics::LTU::LTU_THRESHOLD) && 
		   ($desired_value  < $Statistics::LTU::LTU_THRESHOLD)) ||
		  (($actual_value  >= $Statistics::LTU::LTU_THRESHOLD) && 
		   ($desired_value >= $Statistics::LTU::LTU_THRESHOLD)));

    ## The scale factor can only be changed when the weights are being
    ##  changed, because a change to the scale factor invalidates the current
    ##  set of weights.

    $self->maintain_scaling_factors($instance_vector);
    $self->_scale_attributes($instance_vector);

    ##
    ##  Decide how much to adjust the weights by.  If the actual_value is 0,
    ##  then the least-mean square rule won't change the weights (it multiplies
    ##  by 0).  Therefore, use the fixed-increment rule (which is slower, but
    ##  also guaranteed to converge, if convergence is possible) when the
    ##  actual value is 0.  As far as I know, this modification of the LMS rule
    ##  is original (and harmless).
    ##

    my($delta) = 
	($actual_value == 0.0) ?  
	    $rho * $desired_value
		:  $rho * (- $actual_value);

    ##
    ##  Now, adjust the weights.  The last weight is handled differently, 
    ##  because it is always applied to the constant 1.
    ##

    my($i);
    for $i (0 .. $length-1) {
	$weight->[$i] += $delta * $attribute->[$i];
    }
    $self->update_weight_min_max;

    0;

}


package Statistics::LTU::TACR;
use Statistics::LTU;

@Statistics::LTU::TACR::ISA = qw( Statistics::LTU );

##
##  TRAIN trains the specified linear threshold unit on a particular
##  instance_vector.  It returns 1 if the linear threshold unit already
##  classified the instance_vector correctly, otherwise it returns 0.
##  The training rule is the Thermal Absolute Correction Rule, taken from
##  Frean's "Learning in Single Perceptrons" dissertation.
##

sub train {
    my($self, $instance_vector, $desired_value, $temp, $rate) = @_;

    my($length) = $self->[$LENGTHi];

    ##
    ##  Only train the linear threshold unit if it does not classify correctly.
    ##

    my($actual_value) = $self->test($instance_vector);

    return(1) if ((($actual_value   < $Statistics::LTU::LTU_THRESHOLD) && 
		   ($desired_value  < $Statistics::LTU::LTU_THRESHOLD)) ||
		  (($actual_value  >= $Statistics::LTU::LTU_THRESHOLD) && 
		   ($desired_value >= $Statistics::LTU::LTU_THRESHOLD)));

    ##
    ##  If either temp or rate is 0, then no weight adjustment takes place.
    ##  This shouldn't occur, but if it does, handle it easily and quickly.
    ##  Note that not handling it allows a divide by zero later.
    ##

    return(0) if ($temp <= 0) or ($rate <= 0);

    ##
    ##  The scale factor can only be changed when the weights are being 
    ##  changed, because a change to the scale factor invalidates the current 
    ##  set of weights.
    ##
    
    $self->maintain_scaling_factors($instance_vector);
    $self->_scale_attributes($instance_vector);

    ##
    ##  Decide how much to adjust the weights by.  The absolute correction rule
    ##  (which provides the fastest learning) requires the dot product of the
    ##  instance vector, so do that first.
    ##
    my($attribute) = $self->[$ATTRIBUTEi];
    my($dot_product) = 0.0;
    my($i);
    
    for $i (0 .. $length-1) {
	$dot_product += ($attribute->[$i] * $attribute->[$i]);
    }
    my($delta) = 1.0 + int(abs($actual_value) / $dot_product);

    $delta = -$delta if $desired_value < $Statistics::LTU::LTU_THRESHOLD;

    ##
    ##  This is the thermal part of the rule.  
    ##
    $delta *= $rate * exp((- abs($actual_value) / $temp));

    ##
    ##  Now, adjust the weights.  The last weight is handled differently, 
    ##  because it is always applied to the constant 1.
    ##

    my($weight) = $self->[$WEIGHTi];

    for $i (0 .. $length-1) {
	$weight->[$i] += ($delta * $attribute->[$i]);
    }
    $self->update_weight_min_max;

    0;
}



{ package main; eval join('',<DATA>) || die $@ unless caller(); }

1;##### End of LTU.pm
__END__


#
#  Test code
#
package main;
use Statistics::LTU;

srand;

@LTUs = (new Statistics::LTU::ACR(2, 1),
	 new Statistics::LTU::RLS(2, 1),
	 new Statistics::LTU::TACR(2, 1),
	 new Statistics::LTU::LMS(2, 1)
	 );

#  Create examples
my($x, $y, $class);
for (1 .. 20) {
    $x = rand;  $y = rand;
    $class = (($x-.5) > $y) ? 1 : -1;
    push(@::Examples, [[$x,$y],$class]);
}

my($ltu, $save_name, $ltu_restored, $ltu_copied, $tolerance);

$tolerance = 0.0001;

my(@OtherArgs);
my($temp, $rate, $rho);
$temp = 0.1;
$rate = 0.01;
$rho = 0.1;


foreach $ltu (@::LTUs) {

    $ltu->set_origin_restriction(0);

    if (ref($ltu) =~ /TACR/) {
	@OtherArgs = ($temp, $rate);
    } elsif (ref($ltu) =~ /LMS/) {
	@OtherArgs = ($rho);
    } else {
	@OtherArgs = ();
    }

    my($example);

    foreach $example (@::Examples) {
	$ltu->maintain_scaling_factors($example->[0]);
    }

    for (1 .. 10) {
	print "\n\nITERATION $_\n";

	foreach $example (@::Examples) {
	    $ltu->train($example->[0], $example->[1], @OtherArgs);
	}
	$ltu->print;
    }

    $save_name = ref($ltu) . ".saved";
    $ltu->save($save_name);
    
    $ltu_restored = $ltu->restore($save_name);
    $ltu_copied   = $ltu->copy;
    
    foreach $example (@::Examples) {
	if (abs($ltu->test($example->[0]) - $ltu_restored->test($example->[0]))
	    > $tolerance) {
	    warn "Original and restored LTUs disagree!";
	    $ltu->print;
	    $ltu_restored->print;
	    die "SAVE/RESTORE TEST FAILED!";
	    }

	if (abs($ltu->test($example->[0]) - $ltu_copied->test($example->[0]))
	    > $tolerance) {
	    warn "Original and copied LTUs disagree!";
	    $ltu->print;
	    $ltu_copied->print;
	    die "COPY TEST FAILED!";
	}
    }
    $ltu->destroy;
    $ltu_restored->destroy;
    $ltu_copied->destroy;
}

print "Tests passed\n";

1;
