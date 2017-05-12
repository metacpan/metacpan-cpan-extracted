package Statistics::MaxEntropy;

##---------------------------------------------------------------------------##
##  Author:
##      Hugo WL ter Doest       terdoest@cs.utwente.nl
##  Description:
##      Object-oriented implementation of
##      Generalised Iterative Scaling algorithm, 
##	Improved Iterative Scaling algorithm, and
##      Feature Induction algorithm
##      for inducing maximum entropy probability distributions
##  Keywords:
##      Maximum Entropy Modeling
##      Kullback-Leibler Divergence
##      Exponential models
##
##---------------------------------------------------------------------------##
##  Copyright (C) 1998, 1999 Hugo WL ter Doest terdoest@cs.utwente.nl
##
##  This library is free software; you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 2 of the License, or
##  (at your option) any later version.
##
##  This library  is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU Library General Public 
##  License along with this program; if not, write to the Free Software
##  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
##---------------------------------------------------------------------------##


##---------------------------------------------------------------------------##
##	Globals
##---------------------------------------------------------------------------##
use vars qw($VERSION
	    @ISA
	    @EXPORT
	    $VECTOR_PACKAGE

	    $debug
	    $SAMPLE_size
	    $NEWTON_max_it
	    $KL_max_it
	    $KL_min
	    $NEWTON_min
	    $cntrl_c_pressed
	    $cntrl_backslash_pressed
	    );


##---------------------------------------------------------------------------##
##	Require libraries
##---------------------------------------------------------------------------##
use strict;
use diagnostics -verbose;
use Statistics::SparseVector;
$VECTOR_PACKAGE = "Statistics::SparseVector";
use POSIX;
use Carp;
use Data::Dumper;
require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw($KL_min
	     $NEWTON_min
	     $debug
	     $nr_add
	     $KL_max_it
	     $NEWTON_max_it
	     $SAMPLE_size
	     );

$VERSION = '1.0';


# default values for some configurable parameters
$NEWTON_max_it = 20;
$NEWTON_min = 0.001;
$KL_max_it = 100;
$KL_min = 0.001;
$debug = 0;
$SAMPLE_size = 250; # the size of MC samples
# binary or integer feature functions

# for catching interrupts
$cntrl_c_pressed = 0;
$cntrl_backslash_pressed = 0;
$SIG{INT} = \&catch_cntrl_c;
$SIG{QUIT} = \&catch_cntrl_backslash;


# checks floats
sub is_float {
    my($f) = @_;

    return ($f =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);
}


# interrrupt routine for control c
sub catch_cntrl_c {
    my($signame) = shift;

    $cntrl_c_pressed = 1;
    die "<CONTROL-C> pressed\n";
}


# interrrupt routine for control \ (originally core-dump request)
sub catch_cntrl_backslash {
    my($signame) = shift;

    $cntrl_backslash_pressed = 1;
}


# creates a new event space
# depending on the $arg parameter samples it or reads it from a file
sub new {
    my($this, $vectype, $filename) = @_;

    # for calling $self->new($someth):
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    $self->{SCALER} = "gis"; # default
    $self->{SAMPLING} = "corpus"; # default
    $self->{NR_CLASSES} = 0;
    $self->{NR_EVENTS} = 0;
    $self->{NR_FEATURES} = 0;
    $self->{VECTYPE} = $vectype;
    if ($filename) { # hey a filename
	$self->read($filename);
    }
    $self->{FEATURE_IGNORE} = $VECTOR_PACKAGE->new($self->{NR_FEATURES});
    return($self);
}


# decides how to sample, "enum", "mc", or "corpus"
sub sample {
    my($self) = @_;

    my($sample);

    if ($self->{SAMPLING} eq "mc") {
	$sample = $self->new();
	$sample->{VECTYPE} = "binary";
	$sample->{SCALER} = $self->{SCALER};
	$sample->{NR_FEATURES} = $self->{NR_FEATURES};
	# refer to the parameters of $self
	$sample->{PARAMETERS} = $self->{PARAMETERS};
	$sample->{NEED_CORRECTION_FEATURE} = 1;
	$sample->{CORRECTION_PARAMETER} = $self->{CORRECTION_PARAMETER};
	$sample->{E_REF} = $self->{E_REF};
	$sample->{THIS_IS_A_SAMPLE} = 1;
	$sample->mc($self);
	$sample->{CLASSES_CHANGED} = 1;
	$sample->prepare_model();
    }
    elsif ($self->{SAMPLING} eq "enum") {
 	$sample = $self->new();
 	$sample->{SCALER} = $self->{SCALER};
 	$sample->{SAMPLING} = "enum";
 	$sample->{NR_FEATURES} = $self->{NR_FEATURES};
 	$sample->{PARAMETERS} = $self->{PARAMETERS};
 	$sample->{NEED_CORRECTION_FEATURE} = 1;
 	$sample->{CORRECTION_PARAMETER} = $self->{CORRECTION_PARAMETER};
 	$sample->{E_REF} = $self->{E_REF};
 	$sample->{THIS_IS_A_SAMPLE} = 1;
	$sample->{M} = $self->{NR_FEATURES};
    }
    else { # "corpus"
	$sample = $self;
    }
    $sample->prepare_sample();
    return($sample);
}


# makes sure that when prepare_model is called, everything is recomputed
sub clear {
    my($self) = @_;
    
    undef $self->{PARAMETERS_INITIALISED};
    $self->{PARAMETERS_CHANGED} = 1;
    $self->{CLASSES_CHANGED} = 1;
}



sub DESTROY {
    my($self) = @_;
    
    if ($cntrl_c_pressed) {
	$self->dump();
    }
}


# reads an events file, dies in case of inconsistent lines
# syntax first line: <name> <tab> <name> <tab> ..... <newline>
# syntax other lines, binary functions: <freq> <bitvector> <newline>
# syntax other lines, integer functions: <freq> <intvector> <newline>
# an intvector is a space separated list of integers
sub read {
    my($self, $file) = @_;

    my($features,
       $feature_names,
       @cols);

    $feature_names = "";
    open(EVENTS, $file) ||
	$self->die("Could not open $file\n");
    print "Opened $file\n";

    # read the names of the features, skip comment
    # note that feature name are in reverse order now 
    do {
	$feature_names = <EVENTS>;
    } until ($feature_names !~ /\#.*/);
    chomp $feature_names;
    $self->{FEATURE_NAMES} = [split(/\t/, $feature_names)];
    $self->{NR_FEATURES} = $#{$self->{FEATURE_NAMES}} + 1;

    # read the bitvectors
    while (<EVENTS>) {
	if (!/\#.*/) { # skip comments
	    chomp;

	    if (/\s*(\d+)\s+(.+)/) {
		$self->{FREQ}[$self->{NR_CLASSES}] = $1;
		$features = $2;
	    }
	    if ($self->{FREQ} == 0) {
		$self->die("Class $self->{NR_CLASSES} has zero probability\n");
	    }
	    $self->{NR_EVENTS} += $self->{FREQ}[$self->{NR_CLASSES}];
	    $self->{CLASSES}[$self->{NR_CLASSES}] = 
		$VECTOR_PACKAGE->new_vec($self->{NR_FEATURES}, 
					 $features, $self->{VECTYPE});
	    $self->{NR_CLASSES}++;
	}
    }
    close(EVENTS);

    print "Read $self->{NR_EVENTS} events, $self->{NR_CLASSES} classes, " . 
	"and $self->{NR_FEATURES} features\n";
    print "Closed $file\n";

    $self->{FILENAME} = $file;
    $self->{CLASSES_CHANGED} = 1;
    $self->{PARAMETERS_CHANGED} = 1;
}


# reads an initial distribution
# syntax: one parameter per line
sub read_parameters {
    my($self, $file) = @_;

    my($i);

    $i = 0;
    open(DISTR,$file) ||
	$self->die("Could not open $file\n");
    print "Opened $file\n";

    while (<DISTR>) {
	if (!/\#.*/) {
	    chomp;
	    $self->{PARAMETERS}[$i++] = $_;
	}
    }

    close(DISTR);
    if ($i != $self->{NR_FEATURES}) {
	$self->die("Initial distribution file corrupt\n");
    }
    print "Read $i parameters; closed $file\n";
    $self->{PARAMETERS_CHANGED} = 1;
}


# writes the the current parameters
# syntax: <parameter> <newline>
sub write_parameters {
    my($self, $file) = @_;

    my($i);

    open(DISTR,">$file") ||
	$self->die("Could not open $file\n");
    print "Opened $file\n";

    for ($i = 0; $i < $self->{NR_FEATURES}; $i++) {
	if ($self->{FEATURE_IGNORE}->bit_test($i)) {
	    print DISTR "IGNORED\n";
	}
	else {
	    print DISTR "$self->{PARAMETERS}[$i]\n";
	}
    }

    close(DISTR);
    print "Closed $file\n";
}


# writes the the current features with their parameters
# syntax first line: <$nr_features> <newline>
# syntax last line: <bitmask> <newline>
# syntax other lines: <name> <parameter> <newline>
sub write_parameters_with_names {
    my($self, $file) = @_;

    my($x,
       $bitmask);

    open(DISTR,">$file") ||
	$self->die("Could not open $file\n");
    print "Opened $file\n";

    # preamble
    print DISTR "$self->{NR_FEATURES}\n";
    print DISTR "$self->{SCALER}\n";
    if ($self->{SCALER} eq "gis") {
	print DISTR "$self->{M}\n";
	print DISTR "$self->{CORRECTION_PARAMETER}\n";
    }

    # print feature names with parameters
    # in the meanwhile build the bitmask
    $bitmask = "";
    for ($x = 0; $x < $self->{NR_FEATURES}; $x++) {
	print DISTR "$self->{FEATURE_NAMES}[$x]\t$self->{PARAMETERS}[$x]\n";
	if ($self->{FEATURE_IGNORE}->bit_test($x)) {
	    $bitmask = "0" . $bitmask;
	}
	else {
	    $bitmask = "1" . $bitmask;
	}
    }
    print DISTR "$bitmask\n";

    close(DISTR);
    print "Closed $file\n";
}


# generate random parameters
sub random_parameters {
    my($self) = @_;

    my($f);

    srand();
    for ($f = 0; $f < $self->{NR_FEATURES}; $f++) {
	$self->{PARAMETERS}[$f] = rand() + 1;
    }
    if ($self->{SCALER} eq "gis") {
	$self->{CORRECTION_PARAMETER} = rand();
    }
    $self->{PARAMETERS_CHANGED} = 1;
}


# sets parameters to $val
sub set_parameters_to {
    my($self, $val) = @_;

    my($f);

    for ($f = 0; $f < $self->{NR_FEATURES}; $f++) {
	$self->{PARAMETERS}[$f] = $val;
    }
    if ($self->{SCALER} eq "gis") {
	$self->{CORRECTION_PARAMETER} = $val;
    }
    $self->{PARAMETERS_CHANGED} = 1;
}


# initialise if !$self->{PARAMETERS_INITIALISED}; subsequent calls 
# of scale (by fi) should not re-initialise parameters
sub init_parameters {
    my($self) = @_;

    if (!$self->{PARAMETERS_INITIALISED}) {
	if ($self->{SAMPLING} eq "mc") {
	    # otherwise bits will be flipped with prob 1.
	    $self->random_parameters();
	}
	else {
	    if ($self->{SCALER} eq "gis") {
		$self->set_parameters_to(0);
	    }
	    else {
		$self->set_parameters_to(0);
	    }
	}
	$self->{PARAMETERS_INITIALISED} = 1;
    }
}


# make sure \tilde{p} << q_0
# constant feature functions are forbidden: that is why
# we check whether for all features \sum_x f(x) > 0
# and \sum_x f(x) != $corpus_size
sub check {
    my($self) = @_;

    my ($x);

    for ($x = 0; $x < $self->{NR_CLASSES}; $x++) {
	if ($self->{CLASS_EXP_WEIGHTS}[$x] == 0) {
	    print "Initial distribution not ok; class $x\n";
	    print $self->{CLASS_EXP_WEIGHTS}[$x], "\t", $self->{CLASSES}[$x]->to_Bin(' '),"\n";
	}
    }
}


# writes events to a file 
# usefull in case new features have been added
# syntax: same as input events file
sub write {
    my($self, $file) = @_;

    my($x, $f);

    # prologue
    open(EVENTS,">$file") ||
	$self->die("Could not open $file\n");
    print "Opened $file\n";

    # write a line with the feature names
    print EVENTS join("\t", @{$self->{FEATURE_NAMES}}), "\n";
    # write the events themselves
    for ($x = 0; $x < $self->{NR_CLASSES}; $x++) {
	print EVENTS $self->{FREQ}[$x],"\t";
	print EVENTS $self->{CLASSES}[$x]->to_Bin(' '), "\n";
    }

    # close the file and tell you did that
    close EVENTS;
    print "Wrote $self->{NR_EVENTS} events, $self->{NR_CLASSES} classes, " . 
	"and $self->{NR_FEATURES} features\n";
    print "Closed $file\n";
}


# reads a dump, and evaluates it into an object
sub undump {
    my($class, $file) = @_;

    my($x,
       $VAR1);

    # open, slurp, and close file
    open(UNDUMP, "$file") ||
	croak "Could not open $file\n";
    print "Opened $file\n";
    undef $/;
    $x = <UNDUMP>;
    $/ = "\n";
    close(UNDUMP);

    # and undump
    eval $x;
    print "Undumped $VAR1->{NR_EVENTS} events, $VAR1->{NR_CLASSES} classes, " . 
	"and $VAR1->{NR_FEATURES} features\n";
    print "Closed $file\n";
    return($VAR1);
}


# makes dump of the event space using Data::Dumper
sub dump {
    my($self, $file) = @_;

    my(@bitvecs,
       $dump,
       %features,
       $f);

    if (!$file) {
	$file = POSIX::tmpnam();
    }
    open(DUMP, ">$file") ||
	croak "Could not open $file\n";
    print "Opened $file\n";

    # build something that we can sort
    # ONLY FOR CORPUS!
    if (!$self->{THIS_IS_A_SAMPLE} && $self->{PARAMETERS}) {
    for ($f = 0; $f < $self->{NR_FEATURES}; $f++) {
        $features{$self->{FEATURE_NAMES}[$f]} = 
	    $self->{PARAMETERS}[$f];
    }
    if ($self->{NEED_CORRECTION_FEATURE} && ($self->{SCALER} eq "gis")) {
        $features{"correction$self->{M}"} = 
	    $self->{CORRECTION_PARAMETER};
    }
    # and print it into $self
    $self->{FEATURE_SORTED} = join(' > ',
				   sort {
				       if ($features{$b} == $features{$a}) {
					   return($b cmp $a)} 
				       else {
					   return ($features{$b} <=> $features{$a})
					   }
				   }
				   keys(%features));
    }

    $dump = Data::Dumper->new([$self]);
    print DUMP $dump->Dump();
    print "Dumped $self->{NR_EVENTS} events, $self->{NR_CLASSES} classes, " . 
	"and $self->{NR_FEATURES} features\n";

    close(DUMP);
    print "Closed $file\n";
}


# $msg is logged, the time is logged, a dump is created, and the
# program dies with $msg
sub die {
    my($self, $msg) = @_;

    $self->log_msg($msg);
    $self->log_msg(time());
    $self->dump();
    croak $msg;
}


# prints a msg to STDOUT, and appends it to $self->{LOG}
# so an emergency dump will contain some history information
sub log_msg {
    my($self, $x) = @_;

    $self->{LOG} .= $x;
    print $x;
}


# computes f_# for alle events; results in @sample_nr_feats_on
# computes %$sample_m_feats_on; a HOL from m 
sub active_features {
    my($self) = @_;

    my($i,
       $j,
       $sum);

    if ($self->{CLASSES_CHANGED}) {
	# check for constant features
	for ($i = 0; $i < $self->{NR_FEATURES}; $i++) {
	    $sum = 0;
	    for ($j = 0; $j < $self->{NR_CLASSES}; $j++) {
		$sum += $self->{CLASSES}[$j]->bit_test($i);
	    }
	    if (!$sum || ($sum == $self->{NR_CLASSES})) {
		print "Feature ", $i + 1, " is constant ($sum), and will be ignored\n";
		$self->{FEATURE_IGNORE}->Bit_On($i);
	    }
	}
	# M is needed for both gis and iis
	# NEED_CORRECTION_FEATURE is for gis only
	$self->{M} = 0;
	$self->{NEED_CORRECTION_FEATURE} = 0;
	for ($i = 0; $i < $self->{NR_CLASSES}; $i++) {
	    if ($self->{CLASSES}[$i]->Norm() > $self->{M}) {
		# higher nr_features_active found
		$self->{M} = $self->{CLASSES}[$i]->Norm();
		$self->{NEED_CORRECTION_FEATURE} = 1;
	    }
	}
	if ($debug) {
	    print "M = $self->{M}\n";
	}
	# set up a hash from m to classes HOL; and the correction_feature
	# CORRECTION_FEATURE FOR gis
	undef $self->{M_FEATURES_ACTIVE};
	for ($i = 0; $i < $self->{NR_CLASSES}; $i++) {
	    if ($self->{SCALER} eq "gis") {
		$self->{CORRECTION_FEATURE}[$i] = 
		    $self->{M} - $self->{CLASSES}[$i]->Norm();
	    }
	}
	if ($debug) {
	    print "M = $self->{M}\n";
	}
	# observed feature expectations
	if (!$self->{THIS_IS_A_SAMPLE}) {
	    $self->E_reference();
	}
	undef $self->{CLASSES_CHANGED};
    }
}


# compute the class probabilities according to the parameters
sub prepare_model {
    my($self) = @_;

    my ($x,
	$f);

    $self->active_features();
    if ($self->{PARAMETERS_CHANGED}) {
	$self->{Z} = 0;
	for ($x = 0; $x < $self->{NR_CLASSES}; $x++) {
	    $self->{CLASS_LOG_WEIGHTS}[$x] = 0;
	    for $f ($self->{CLASSES}[$x]->indices()) {
		$self->{CLASS_LOG_WEIGHTS}[$x] += $self->{PARAMETERS}[$f] * 
						  $self->{CLASSES}[$x]->weight($f);
		if ($f >= $self->{NR_FEATURES}) {
		    print "alarm: wrong index: $f\n";
		}
	    }
	    if ($self->{NEED_CORRECTION_FEATURE} && ($self->{SCALER} eq "gis")) {
		$self->{CLASS_LOG_WEIGHTS}[$x] += $self->{CORRECTION_FEATURE}[$x] * 
		    $self->{CORRECTION_PARAMETER};
	    }
	    $self->{CLASS_EXP_WEIGHTS}[$x] = exp($self->{CLASS_LOG_WEIGHTS}[$x]);
	    $self->{Z} += $self->{CLASS_EXP_WEIGHTS}[$x];
	}
	print "prepare_model: \$Z is not a number: $self->{Z}\n"
		unless is_float($self->{Z});

	if (!$self->{THIS_IS_A_SAMPLE}) {
	    $self->entropies();
	}
	$self->check();
	undef $self->{PARAMETERS_CHANGED};
    }
}


sub prepare_sample {
    my($self) = @_;

    # expectations
    if ($self->{SCALER} eq "gis") {
	$self->E_loglinear();
    }
    else {
	# A_{mj}
	$self->A();
    }
}


# feature expectations for the MaxEnt distribution
sub E_loglinear {
    my($self) = @_;

    my($x,
       $f,
       $vec,
       $weight,
       $Z);

    undef $self->{E_LOGLIN};
    if ($self->{SAMPLING} eq "enum") {
	$vec = $VECTOR_PACKAGE->new($self->{NR_FEATURES});
	$self->{Z} = 0;
	for ($x = 0; $x < 2 ** $self->{NR_FEATURES}; $x++) {
	    $weight = $self->weight($vec);
	    for $f ($vec->indices()) {
		$self->{E_LOGLIN}[$f] += $weight * $vec->weight($f);
	    }
	    $self->{E_LOGLIN}[$self->{NR_FEATURES}] += $weight *
		($self->{M} - $vec->Norm());
	    $self->{Z} += $weight;
	    $vec->increment();
	}
	for $f (0..$self->{NR_FEATURES}) {
	    $self->{E_LOGLIN}[$f] /= $self->{Z};
	}
    }
    else { # either corpus or mc sample
	for ($x = 0; $x < $self->{NR_CLASSES}; $x++) {
	    for $f ($self->{CLASSES}[$x]->indices()) {
		$self->{E_LOGLIN}[$f] += $self->{CLASS_EXP_WEIGHTS}[$x] *
					 $self->{CLASSES}[$x]->weight($f);
	    }
	    if ($self->{NEED_CORRECTION_FEATURE}) {
		$self->{E_LOGLIN}[$self->{NR_FEATURES}] +=
		    $self->{CLASS_EXP_WEIGHTS}[$x] *
			($self->{M} - $self->{CLASSES}[$x]->Norm());
	    }
	}
	for $f (0..$self->{NR_FEATURES}) {
	    $self->{E_LOGLIN}[$f] /= $self->{Z};
	}
    }
}


# observed feature expectations
sub E_reference {
    my($self) = @_;

    my($x,
       $f,
       @sum);

    for ($x = 0; $x < $self->{NR_CLASSES}; $x++) {
	for $f ($self->{CLASSES}[$x]->indices()) {
	    $sum[$f] += $self->{FREQ}[$x] * $self->{CLASSES}[$x]->weight($f);
	}
	if ($self->{SCALER} eq "gis") {
	    $sum[$self->{NR_FEATURES}] += $self->{CORRECTION_FEATURE}[$x] * 
		$self->{FREQ}[$x];
	}
    }
    for $f (0..$self->{NR_FEATURES}) {
	if ($sum[$f]) {
	    $self->{E_REF}[$f] = $sum[$f] / $self->{NR_EVENTS};
	}
    }
}


# compute several entropies
sub entropies {
    my($self) = @_;

    my ($i, 
	$w,
	$log_w,
	$w_ref,
	$log_w_ref);

    $self->{H_p} = 0;
    $self->{H_cross} = 0;
    $self->{H_p_ref} = 0;
    $self->{KL} = 0;
    for ($i = 0; $i < $self->{NR_CLASSES}; $i++) {
	$w = $self->{CLASS_EXP_WEIGHTS}[$i];
	# we don't know whether $p > 0
	$log_w = $self->{CLASS_LOG_WEIGHTS}[$i];
	$w_ref = $self->{FREQ}[$i];
	# we know that $p_ref > 0
	$log_w_ref = log($w_ref);
	# update the sums
	$self->{H_p} -= $w * $log_w;
	$self->{H_cross} -= $w_ref * $log_w;
	$self->{KL} += $w_ref * ($log_w_ref - $log_w);
	$self->{H_p_ref} -= $w_ref * $log_w_ref;
	if ($w == 0) {
	    $self->log_msg("entropies: skipping event $i (p^n($i) = 0)\n");
	}
    }
    # normalise
    $self->{H_p} = $self->{H_p} / $self->{Z} + log($self->{Z});
    $self->{H_cross} = $self->{H_cross} / $self->{NR_EVENTS} + log($self->{Z});
    $self->{KL} = $self->{KL} / $self->{NR_EVENTS} - log($self->{NR_EVENTS}) +
	log($self->{Z});
    $self->{H_p_ref} = $self->{H_p_ref} / $self->{NR_EVENTS} + log($self->{NR_EVENTS});
    $self->{L} = -$self->{H_cross};
}


# unnormalised p(x,y)
# $x is required, $y is optional
# $x->Size()+$y->Size() == $self->{NR_FEATURES}
sub weight {
    my($self, $x, $y) = @_;

    my ($f, 
	$sum,
	$norm);

    $sum = 0;
    for $f ($x->indices()) {
	if (!$self->{FEATURE_IGNORE}->bit_test($f)) {
	    $sum += $self->{PARAMETERS}[$f] * $x->weight($f);
	    if ($debug) {
		print "Current weight: $sum, current feature: $f\n";
	    }
	}
    }
    $norm = $x->Norm();
    # if $y is defined, 
    # then $x->Size()+$y->Size() == $self->{NR_FEATURES} should hold:
    if (defined($y) && (($x->Size() + $y->Size()) == $self->{NR_FEATURES})) {
 	for $f ($y->indices()) {
 	    if (!$self->{FEATURE_IGNORE}->bit_test($f + $x->Size())) {
 		$sum += $self->{PARAMETERS}[$f + $x->Size()] * 
 		        $y->weight($f);
		if ($debug) {
		    print "Current weight: $sum, current feature: $f\n";
		}
 	    }
 	}
 	$norm += $y->Norm();
    }
    if ($self->{NEED_CORRECTION_FEATURE} && ($self->{SCALER} eq "gis")) {
	$sum += ($self->{M} - $norm) * $self->{CORRECTION_PARAMETER};
    }
    return(exp($sum));
}


# computes the `a' coefficients of 
# \sum_{m=0}^{M} a_{m,j}^{(n)} e^{\alpha^{(n)}_j m}
# according to the current distribution
sub A {
    my($self) = @_;

    my($f,
       $m,
       $x,
       $weight,
       $vec,
       $class);

    undef $self->{A};
    undef $self->{C};
    if ($self->{SAMPLING} eq "enum") {
	undef $self->{Z};
	$vec = $VECTOR_PACKAGE->new($self->{NR_FEATURES});
	for ($x = 0; $x < 2 ** $self->{NR_FEATURES}; $x++) {
	    $weight = $self->weight($vec);
	    for $f ($vec->indices()) {
		$self->{A}{$vec->Norm()}{$f} += $weight * $vec->weight($f);
		$self->{C}{$vec->Norm()}{$f} += $vec->weight($f);
	    }
	    $self->{Z} += $weight;
	    print "Z = $self->{Z}" unless is_float($self->{Z});
	    $vec->increment();
	}
    }
    else { # mc or corpus
	for ($class = 0; $class < $self->{NR_CLASSES}; $class++) {
	    for  $f ($self->{CLASSES}[$class]->indices()) {
		$self->{A}{$self->{CLASSES}[$class]->Norm()}{$f} += 
		    $self->{CLASS_EXP_WEIGHTS}[$class] * 
		    $self->{CLASSES}[$class]->weight($f);
		$self->{C}{$self->{CLASSES}[$class]->Norm()}{$f} +=
		    $self->{CLASSES}[$class]->weight($f);
	    }
	}
    }
}


#
# Monte Carlo sampling with the Metropolis update
#

# returns heads up with probability $load 
sub loaded_die {
    my($load) = @_;

    (rand() <= $load) ? 1 : 0;
}


# samples from the probability distribution of $other to create $self
# we use the so-called Metropolis update R = h(new)/h(old)
# Metropolis algorithm \cite{neal:probabilistic}
sub mc {
    my($self, $other, $type) = @_;

    my($R,
       $weight,
       $state,
       $old_weight,
       $k,
       %events
       );

    srand();
    # take some class from the sample space as initial state
    $state = $VECTOR_PACKAGE->new($self->{NR_FEATURES});
    # make sure there are no constant features!
    $state->Fill();
    $events{$state->to_Bin(' ')}++;
    $state->Empty();
    $weight = 0;
    # iterate
    $k = 0;

    do {
	$old_weight = $weight;
	if ($state->bit_flip($k)) {
	    $weight += $self->{PARAMETERS}[$k];
	}
	else {
	    $weight -= $self->{PARAMETERS}[$k];
	}
	$R = exp($weight - $old_weight);
	if (!loaded_die(1 < $R ? 1 : $R)) { # stay at the old state
	    $state->bit_flip($k);
	    $weight = $old_weight;
	}
	else { # add state
	    $events{$state->to_Bin(' ')}++;
	}
	if ($debug) {
	    print $state->to_Bin(' '),"\t",scalar(keys(%events)),"\t$R\n";
	}
	# next component
	$k = ($k + 1) % $self->{NR_FEATURES};
    } until ((scalar(keys(%events)) == $SAMPLE_size) ||
	(scalar(keys(%events)) == 2 ** $self->{NR_FEATURES}));

    for (keys(%events)) {
	push @{$self->{CLASSES}},
	 $VECTOR_PACKAGE->new_vec($self->{NR_FEATURES}, $_, $self->{VECTYPE});
    }
    $self->{NR_CLASSES} = scalar(keys(%events)) - 1;

    $self->{CLASSES_CHANGED} = 1;
    $self->{PARAMETERS_CHANGED} = 1;
}


#
# IIS
#

# Newton estimation according to (Abney 1997), Appendix B
sub C_func {
    my($self, $j, $x) = @_;

    my($m,
       $s0,
       $s1,
       $a_x_m);

    $s0 = - $self->{NR_EVENTS} * $self->{E_REF}[$j];
    $s1 = 0;
    for ($m = 1; $m <= $self->{M}; $m++) {
	if ($self->{"C"}{$m}{$j}) {
	    $a_x_m = $self->{"C"}{$m}{$j} * exp($x * $m);
	    $s0 += $a_x_m;
	    $s1 += $m * $a_x_m;
	}
    }
    print "sum_func not a number: $s0\n"
	unless is_float($s0);
    print "sum_deriv not a number: $s1\n"
	unless is_float($s1);

    if ($s1 == 0) {
	return(0);
    }
    else {
	return($s0 / $s1);
    }
}


# Newton estimation according to (Della Pietra et al. 1997)
sub A_func {
    my($self, $j, $x) = @_;

    my($m,
       $sum_func,
       $sum_deriv,
       $a_x_m);

    $sum_func = -$self->{E_REF}[$j] * $self->{Z};
    $sum_deriv = 0;
    for ($m = 1; $m <= $self->{M}; $m++) {
	if ($self->{"A"}{$m}{$j}) {
	    $a_x_m = $self->{"A"}{$m}{$j} * exp($x * $m);
	    $sum_func += $a_x_m;
	    $sum_deriv += $m * $a_x_m;
	}
    }
    if ($sum_deriv == 0) {
	return(0);
    }
    else {
	return($sum_func / $sum_deriv);
    }
}


# solves \alpha from 
# \sum_{m=0}^{M} a_{m,j}^{(n)} e^{\alpha^{(n)}_j m}=0
sub iis_estimate_with_newton {
    my($self, $i) = @_;

    my($x,
       $old_x,
       $deriv_res,
       $func_res,
       $k);

    # $x  = log(0)
    $x = 0;
    $k = 0;

    # do newton's method
    do {
	# save old x
	$old_x = $x;
	# compute new x
	if ($self->{SAMPLING} eq "enum") {
	    # (DDL 1997)
	    $x -= $self->A_func($i, $x);
	}
	else {
	    # sample -> (Abney 1997)
	    $x -= $self->A_func($i, $x);
	}
    } until ((abs($x - $old_x) <= $NEWTON_min) ||
	     ($k++ > $NEWTON_max_it));
    if ($debug) {
	print "Estimated gamma_$i with Newton's method: $x\n";
    }
    return($x);
}


# updates parameter $i
sub gamma {
    my($self, $sample) = @_;

    my($f);

    for $f (0..$self->{NR_FEATURES} - 1) {
	if (!$self->{FEATURE_IGNORE}->bit_test($f)) {
	    if ($self->{SCALER} eq "gis") {
		$self->{PARAMETERS}[$f] +=
		    log($self->{E_REF}[$f] / $sample->{E_LOGLIN}[$f]) / $sample->{M};
	    }
	    else {
		$self->{PARAMETERS}[$f] +=
		    $sample->iis_estimate_with_newton($f);
	    }
	}
    }

    if (($self->{SCALER} eq "gis") && ($self->{NEED_CORRECTION_FEATURE})) {
	$self->{CORRECTION_PARAMETER} +=
	    log($self->{E_REF}[$self->{NR_FEATURES}] / 
		$sample->{E_LOGLIN}[$self->{NR_FEATURES}]) / $self->{M};
    }
}


# the iterative scaling algorithms
sub scale {
    my($self, $sampling, $scaler) = @_;

    my($k,
       $i,
       $kl,
       $old_kl,
       $diff,
       $sample,
       $old_correction_parameter,
       @old_parameters);

    if ($sampling) {
	$self->{SAMPLING} = $sampling;
    }
    if ($scaler) {
	$self->{SCALER} = $scaler;
    }
    if (($self->{SAMPLING} eq "enum") && ($self->{VECTYPE} eq "integer")) {
	$self->die("Cannot enumerate integer vectors\n");
    }
    if (($self->{SAMPLING} eq "mc") && ($self->{VECTYPE} eq "integer")) {
	$self->die("Cannot sample from integer vector space\n");
    }

    $self->init_parameters();
    $self->prepare_model();
    $self->log_msg("scale($self->{SCALER}, $self->{SAMPLING}, $self->{VECTYPE}): H(p_ref)=$self->{H_p_ref}\nit.\tD(p_ref||p)\t\tH(p)\t\t\tL(p_ref,p)\t\ttime\n0\t$self->{KL}\t$self->{H_p}\t$self->{L}\t" . time() . "\n");
    $k = 0;
    $kl = 1e99;
    do {
	# store parameters for reverting if converging stops
	@old_parameters = @{$self->{PARAMETERS}};
	$old_correction_parameter = $self->{CORRECTION_PARAMETER};
	if ($sample) {
	    $sample->DESTROY();
	}
	$sample = $self->sample();
	$self->gamma($sample);
	$self->{PARAMETERS_CHANGED} = 1;
	$self->prepare_model();
	$diff = $kl - $self->{KL};
	$kl = $self->{KL};

	$k++;
	$self->log_msg("$k\t$self->{KL}\t$self->{H_p}\t$self->{L}\t" . time() . "\n");
	if ($debug) {
	    $self->check();
	}
	if ($diff < 0) {
	    $self->log_msg("Scaling is not converging (anymore); will revert parameters!\n");
	    # restore old parameters
	    $self->{PARAMETERS} = \@old_parameters;
	    $self->{CORRECTION_PARAMETER} = $old_correction_parameter;
	    $self->{PARAMETERS_CHANGED} = 1;
	    $self->prepare_model();
	}
	if ($cntrl_backslash_pressed) { 
	    $self->dump();
	    $cntrl_backslash_pressed = 0;
	}
    } until ($diff <= $KL_min || ($k > $KL_max_it) || ($diff < 0));
}


#
# Field Induction Algorithm
#

# add feature $g to $self
sub add_candidate {
    my($self, $candidates, $g) = @_;

    my($i);

    $self->{NR_FEATURES}++;
    for ($i = 0; $i < $self->{NR_CLASSES}; $i++) {
	$self->{CLASSES}[$i]->insert_column($g,
					    $candidates->{CANDIDATES}[$i]->weight($g));
    }
    if ($self->{SCALER} eq "gis") {
	$self->{PARAMETERS}[$self->{NR_FEATURES} - 1] = 1;
    }
    else {
	$self->{PARAMETERS}[$self->{NR_FEATURES} - 1] = $candidates->{ALPHA}[$g];
    }
    push @{$self->{FEATURE_NAMES}}, $candidates->{CANDIDATE_NAMES}[$g];
    $self->{PARAMETERS_CHANGED} = 1;
    $self->{CLASSES_CHANGED} = 1;
    $self->prepare_model();
}


# remove the last column
sub remove_candidate {
    my($self) = @_;

    my($i);

    for ($i = 0; $i < $self->{NR_CLASSES}; $i++) {
	# substitute offset $g length 1 by nothing
	$self->{CLASSES}[$i]->delete_column($self->{NR_FEATURES}-1);
    }
    pop @{$self->{PARAMETERS}};
    pop @{$self->{FEATURE_NAMES}};
    $self->{NR_FEATURES}--;
    $self->{PARAMETERS_CHANGED} = 1;
    $self->{CLASSES_CHANGED} = 1;
    $self->prepare_model();
}


# checks for $event, if not there adds it, otherwise increases its {FREQ}
sub add_event {
    my($self, $event) = @_;

    my($i,
       $found);

    $found = 0;
    for ($i = 0; $i < $self->{NR_CLASSES}; $i++) {
	$found = ($event->Compare($self->{CLASSES}[$i]) == 0);
	if ($found) {
	    $self->{FREQ}[$i]++;
	    last;
	}
    }
    if (!$found) {
	$self->{CLASSES}[$self->{NR_CLASSES}] = $event;
	$self->{FREQ}[$self->{NR_CLASSES}] = 1;
	$self->{NR_CLASSES}++;
    }
    $self->{NR_EVENTS}++;
}


# computes the gain for all $candidates
sub gain {
    my($self, $candidates) = @_;

    my($c,
       $x,
       $kl,
       $below,
       $above,
       $sum_p_ref,
       $sum_p);

    $candidates->{MAX_GAIN} = 0;
    $candidates->{BEST_CAND} = 0;
    for ($c = 0; $c < $candidates->{NR_CANDIDATES}; $c++) {
	if (!$candidates->{ADDED}{$c}) {
	    $sum_p_ref = 0;
	    $sum_p = 0;
	    for ($x = 0; $x < $self->{NR_CLASSES}; $x++) {
		if ($candidates->{CANDIDATES}[$x]->bit_test($c)) {
		    $sum_p += $self->{CLASS_EXP_WEIGHTS}[$x];
		    $sum_p_ref += $self->{FREQ}[$x];
		}
	    }
	    $sum_p /= $self->{Z};
	    $sum_p_ref /= $self->{NR_EVENTS};
	    $above = $sum_p_ref * (1 - $sum_p);
	    $below = $sum_p * (1 - $sum_p_ref);
	    if ($above * $below > 0) {
		$candidates->{ALPHA}[$c] = log($above / $below);
	    }
	    else {
		$self->die("Cannot take log of negative/zero value: $above / $below\n");
	    }
	    # temporarily add feature to classes and compute $gain
	    $kl = $self->{KL};
	    $self->add_candidate($candidates, $c);
	    $candidates->{GAIN}[$c] = $kl - $self->{KL};
	    $self->log_msg("G($c, $candidates->{ALPHA}[$c]) = $candidates->{GAIN}[$c]\n");
	    if (($candidates->{MAX_GAIN} <= $candidates->{GAIN}[$c])) {
		$candidates->{MAX_GAIN} = $candidates->{GAIN}[$c];
		$candidates->{BEST_CAND} = $c;
	    }
	    # remove the feature
	    $self->remove_candidate();
	}
    }
}


# adds the $n best candidates
sub fi {
    my($self, $scaler, $candidates, $n, $sample) = @_;

    my ($i,
	$kl);

    $self->log_msg("fi($scaler, $sample, $n, $self->{VECTYPE})\n");
    if ($scaler) {
	$self->{SCALER} = $scaler;
    }
    if ($sample) {
	$self->{SAMPLING} = $sample;
    }

    if ($self->{NR_CLASSES} != $candidates->{NR_CLASSES}) {
	$self->die("Candidates have the wrong number of events\n");
    }
    $self->scale();
    $kl = $self->{KL};
    $n = ($n > $candidates->{NR_CANDIDATES}) ? $candidates->{NR_CANDIDATES} : $n;
    for ($i = 0; $i < $n; $i++) {
	$self->gain($candidates);
	$self->add_candidate($candidates, $candidates->{BEST_CAND});
	$candidates->{ADDED}{$candidates->{BEST_CAND}} = 1;
	$self->log_msg("Adding candidate $candidates->{BEST_CAND}\n");
	$self->scale();
	$self->log_msg("Actual gain: " . ($self->{KL} - $kl) . "\n");
	$kl = $self->{KL};
    }
    return(1);
}


#
# Routines for classification, only binary features!
#

# context features are 0 .. $n-1
# $x is a vector, $sampling 
sub classify {
    my($self, $x) = @_;

    my($y,
       $sum,
       $i,
       $weight,
       $best_class,
       $best_weight);

    $self->log_msg("classify(" . $x->to_Bin('') . ")\n");
    $sum = 0;
    # use every possible completion of $x to compute $sum
    # allocate a class vector
    $y = $VECTOR_PACKAGE->new($self->{NR_FEATURES} - $x->Size());
    $best_weight = 0;
    # for every possible $y
    for ($i = 0; $i < 2 ** $y->Size(); $i++) {
	# compute p(x,y) which proportional to p(y|x) (I hope)
	$weight = $self->weight($x, $y);
	if ($weight > $best_weight) {
	    $best_class = $y;
	    $best_weight = $weight;
	    if ($debug) {
		print "$i\t", $y->to_Bin(''), "\t$weight\n";
	    }
	}
	$y->increment();
    }
    return($best_class, $best_weight);
}


1;

__END__


# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

MaxEntropy - Perl5 module for Maximum Entropy Modeling and Feature Induction

=head1 SYNOPSIS

  use Statistics::MaxEntropy;

  # debugging messages; default 0
  $Statistics::MaxEntropy::debug = 0;

  # maximum number of iterations for IIS; default 100
  $Statistics::MaxEntropy::NEWTON_max_it = 100;

  # minimal distance between new and old x for Newton's method; 
  # default 0.001
  $Statistics::MaxEntropy::NEWTON_min = 0.001;

  # maximum number of iterations for Newton's method; default 100
  $Statistics::MaxEntropy::KL_max_it = 100;

  # minimal distance between new and old x; default 0.001
  $Statistics::MaxEntropy::KL_min = 0.001;

  # the size of Monte Carlo samples; default 1000
  $Statistics::MaxEntropy::SAMPLE_size = 1000;

  # creation of a new event space from an events file
  $events = Statistics::MaxEntropy::new($vectype, $file);

  # Generalised Iterative Scaling, "corpus" means no sampling
  $events->scale("corpus", "gis");

  # Improved Iterative Scaling, "mc" means Monte Carlo sampling
  $events->scale("mc", "iis");

  # Feature Induction algorithm, also see Statistics::Candidates POD
  $candidates = Statistics::Candidates->new($candidates_file);
  $events->fi("iis", $candidates, $nr_to_add, "mc");

  # writing new events, candidates, and parameters files
  $events->write($some_other_file);
  $events->write_parameters($file);
  $events->write_parameters_with_names($file);

  # dump/undump the event space to/from a file
  $events->dump($file);
  $events->undump($file);


=head1 DESCRIPTION

This module is an implementation of the Generalised and Improved
Iterative Scaling (GIS, IIS) algorithms and the Feature Induction (FI)
algorithm as defined in (B<Darroch and Ratcliff 1972>) and (B<Della
Pietra et al. 1997>). The purpose of the scaling algorithms is to find
the maximum entropy distribution given a set of events and
(optionally) an initial distribution. Also a set of candidate features
may be specified; then the FI algorithm may be applied to find and add
the candidate feature(s) that give the largest `gain' in terms of
Kullback Leibler divergence when it is added to the current set of
features.

Events are specified in terms of a set of feature functions
(properties) f_1...f_k that map each event to {0,1} or to the natural
numbers: an event is a string of bits. In addition, the frequency of
each event is given. We assume the event space to have a probability
distribution that can be described by

=begin roff

    p(x) = 1/Z e^{sum_i alpha_i f_i(x)}

=end roff

=begin text

    p(x) = 1/Z e^{sum_i alpha_i f_i(x)}

=end text

=begin latex

\begin{equation*}
    p(x) = \frac{1}{Z} \exp[\sum_i \alpha_i f_i(x)]
\end{equation*}
where $Z$ is a normalisation factor given by
\begin{equation*}
    Z = \sum_x \exp[\sum_i \alpha_i f_i(x)]
\end{equation*}

=end latex

=begin roff

where Z is a normalisation factor. The purpose of the IIS algorithm is
the find alpha_1..alpha_k such that D(p~||p), defined by

    D(p~||p) = 
       sum_x p~ . log(p~(x) / p(x)),

is minimal under the condition that p~[f_i] = p[f_i], for all i.

=end roff

=begin latex

The purpose of the scaling algorithms IIS GIS is
the find $\alpha_1..\alpha_k$ such that $D(\tilde{p}||p)$, defined by
\begin{equation*}
    D(\tilde{p}||p) = 
       \sum_x \tilde{p} \log (\frac{\tilde{p}(x)}{p(x)}),
\end{equation*}
is minimal under the condition that for all $i$
$\tilde{p}[f_i]=p[f_i]$.

=end latex

If you have a Perl earlier than 5.005, then you need C<Data::Dumper>
module by Gurusamy Sarathy. It can be obtained from CPAN just like
this module.


=head2 CONFIGURATION VARIABLES

=over 4

=item C<$Statistics::MaxEntropy::debug>

If set to C<1>, lots of debug information, and intermediate results will be
output. Default: C<0>

=item C<$Statistics::MaxEntropy::NEWTON_max_it>

Sets the maximum number of iterations in Newton's method. Newton's
method is applied to find the new parameters \alpha_i of the features
C<f_i>. Default: C<100>.

=item C<$Statistics::MaxEntropy::NEWTON_min>

Sets the minimum difference between x' and x in Newton's method (used for
computing parameter updates in IIS); if either the maximum number of
iterations is reached or the difference between x' and x is small enough,
the iteration is stopped. Default: C<0.001>. Sometimes features have
Infinity or -Infinity as a solution; these features are excluded from future
iterations.

=item C<$Statistics::MaxEntropy::KL_max_it>

Sets the maximum number of iterations applied in the IIS
algorithm. Default: C<100>.

=item C<$Statistics::MaxEntropy::KL_min>

Sets the minimum difference between KL divergences of two
distributions in the IIS algorithm; if either the maximum number of
iterations is reached or the difference between the divergences is
enough, the iteration is stopped. Default: C<0.001>.

=item C<$Statistics::MaxEntropy::SAMPLE_size>

Determines the number of (unique) events a sample should contain. Only
makes sense if for sampling "mc" is selected (see below). Its default
is C<1000>.

=back


=head2 METHODS

=over 4

=item C<new>

 $vectype = "binary"; # or "integer"
 $events = Statistics::MaxEntropy::new($vectype, $events_file);

A new event space is created, and the events are read from
C<$file>. The events file is not required. The syntax of events files
is described in L<FILE SYNTAX>. The C<$vectype> parameter specifies
how nonzero feature values should be interpreted as binary values or
not.

=item C<write>

 $events->write($file);

Writes the events to a file. Its syntax is described in 
L<FILE SYNTAX>.

=item C<scale>

 $events->scale($sample, $scaler);

If C<$scaler> equals C<"gis">, the Generalised Iterative Scaling algorithm
(B<Darroch and Ratcliff 1972>) is applied on the event space; C<$scaler>
equals C<"iis">, the Improved Iterative Scaling Algorithm (B<Della Pietra et
al. 1997>) is used. If C<$sample> is C<"corpus">, there is no sampling done
to re-estimate the parameters (the events previously read are considered a
good sample); if it equals C<"mc"> Monte Carlo (Metropolis-Hastings)
sampling is performed to obtain a random sample; if C<$sample> is C<"enum">
the complete event space is enumerated.

=item C<fi>

 fi($scaler, $candidates, $nr_to_add, $sampling);

Calls the Feature Induction algorithm. The parameter C<$nr_to_add> is for
the number of candidates it should add. If this number is greater than the
number of candidates, all candidates are added. Meaningfull values for
C<$scaler> are C<"gis"> and C<"iis">; default is C<"gis"> (see previous
item). C<$sampling> should be one of C<"corpus">, C<"mc">, C<"enum">.
C<$candidates> should be in the C<Statistics::Candidates> class:

 $candidates = Statistics::Candidates->new($file);

See L<Statistics::Candidates>.

=item C<write_parameters>

 $events->write_parameters($file);

=item C<write_parameters_with_names>

 $events->write_parameters_with_names($file);

=item C<dump>

 $events->dump($file);

C<$events> is written to C<$file> using C<Data::Dumper>.

=item C<undump>

 $events = Statistics::MaxEntropy->undump($file);

The contents of file C<$file> is read and eval'ed into C<$events>.

=back


=head1 FILE SYNTAX

Lines that start with a C<#> and empty lines are ignored.

Below we give the syntax of in and output files.


=head2 EVENTS FILE (input/output)

Syntax of the event file (C<n> features, and C<m> events); the following
holds for features:

=over 4

=item *

each line is an event; 

=item *

each column represents a feature function; the co-domain of a feature
function is N;

=item *

constant features (i.e. columns that are completely 0 or 1) are
forbidden;

=item *

2 or more events should be specified (this is in fact a consequence of
the previous requirement;

=back

The frequency of each event precedes the feature columns. Features are
indexed from right to left. Each C<f_ij> and each C<freq_i> is
an integer:

    name_1 <tab> name_2 ... name_n-1 <tab> name_n <cr>
    freq_1 <white> f_11 <white> f12 ... f_1n-1 <white> f_1n <cr>
      .                          .
      .                          .
      .                          .
    freq_i <white> f_i1 <white> fi2 ... f_in-1 <white> f_in <cr>
      .                          .
      .                          .
      .                          .
    freq_m <white> f_m1 <white> fm2 ... f_mn-1 <white> f_mn

(C<m> events, C<n> features) The feature names are separated by tabs,
not white space. The line containing the feature names will be split
on tabs; this implies that (non-tab) white space may be part of the
feature names. The distinction between binary and integer feature
functions is a matter of interpretation. If vector type C<"binary"> is
used, nonzero values are interpreted as 1.


=head2 PARAMETERS FILE (input/output)

Syntax of the initial parameters file; one parameter per line:

    par_1 <cr>
     .
     .
     .
    par_i <cr>
     .
     .
     .
    par_n

The syntax of the output distribution is the same. The alternative
procedure for saving parameters to a file
C<write_parameters_with_names> writes files that have the following
syntax

    n <cr>
    name_1 <tab> par_1 <cr>
     .
     .
     .
    name_i <tab> par_i <cr>
     .
     .
     .
    name_n <tab> par_n <cr>
    bitmask

where bitmask can be used to tell other programs what features to use
in computing probabilities. Features that were ignored during scaling
or because they are constant functions, receive a C<0> bit.


=head2 DUMP FILE (input/output)

A dump file contains the event space (which is a hash blessed into
class C<Statistics::MaxEntropy>) as a Perl expression that can be
evaluated with eval.


=head1 BUGS

It's slow.


=head1 SEE ALSO

L<perl(1)>, L<Statistics::Candidates>, L<Statistics::SparseVector>,
L<POSIX>, L<Carp>.


=head1 DIAGNOSTICS

The module dies with an appropriate message if

=over 4

=item *

it cannot open a specified events file;

=item *

if you specified a constant feature function (in the events file or
the candidates file);

=item *

If the events file, candidates file, or the parameters file is not
consistent. Possible causes are (a.o.): 

=over 4

=item *

insufficient or too many features for some event; 

=item *

inconsistent candidate lines;

=item *

insufficient, or to many event lines in the candidates file.

=back

=item *

it is tried to do feature induction with integer feature functions.

=back

The module captures C<SIGQUIT> and C<SIGINT>. On a C<SIGINT>
(typically <CONTROL-C> it will dump the current event space(s) and
die. If a C<SIGQUIT> (<CONTROL-BACKSLASH>) occurs it dumps the current
event space as soon as possible after the first iteration it finishes.


=head1 REFERENCES

=over 4

=item (Abney 1997)

Steven P. Abney, Stochastic Attribute Value Grammar, Computational
Linguistics 23(4).

=item (Darroch and Ratcliff 1972) 

J. Darroch and D. Ratcliff, Generalised Iterative Scaling for
log-linear models, Ann. Math. Statist., 43, 1470-1480, 1972.

=item (Jaynes 1983)

E.T. Jaynes, Papers on probability, statistics, and statistical
physics. Ed.: R.D. Rosenkrantz. Kluwer Academic Publishers, 1983.

=item (Jaynes 1997) 

E.T. Jaynes, Probability theory: the logic of science, 1997,
unpublished manuscript.
C<URL:http://omega.math.albany.edu:8008/JaynesBook.html>

=item (Della Pietra et al. 1997) 

Stephen Della Pietra, Vincent Della Pietra, and John Lafferty,
Inducing features of random fields, In: Transactions Pattern Analysis
and Machine Intelligence, 19(4), April 1997.

=back


=head1 VERSION

Version 1.0.


=head1 AUTHOR

=begin roff

Hugo WL ter Doest, terdoest@cs.utwente.nl

=end roff

=begin text

Hugo WL ter Doest, terdoest@cs.utwente.nl

=end text

=begin latex

Hugo WL ter Doest, \texttt{terdoest\symbol{'100}cs.utwente.nl}

=end latex


=head1 COPYRIGHT

=begin roff

Copyright (C) 1998, 1999 Hugo WL ter Doest, terdoest@cs.utwente.nl
Univ. of Twente, Dept. of Comp. Sc., Parlevink Research, Enschede,
The Netherlands.

=end roff

=begin latex

\copyright 1998, 1999 Hugo WL ter Doest,
\texttt{terdoest\symbol{'100}cs.utwente.nl} Univ. of Twente, Dept. of
Comp. Sc., Parlevink Research, Enschede, The Netherlands.

=end latex

C<Statistics::MaxEntropy> comes with ABSOLUTELY NO WARRANTY and may be copied
only under the terms of the GNU Library General Public License (version 2, or
later), which may be found in the distribution.

=cut
