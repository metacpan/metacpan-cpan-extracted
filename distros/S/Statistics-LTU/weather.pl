#!/usr/local/bin/perl
# -*-Perl-*-
# weather.perl -- Tom Fawcett  Tue Jan  2 1996
#
# Description:
#
#       Simple test/demo program for Statistics/LTU.pm.
#
#       Example set is a very simple illustration domain taken from
#       Quinlan's article on decision trees:
#
# @ARTICLE{Quinlan86,
#   author    = "J.R. Quinlan",
#   year      = "1986",
#   title     = "Induction of Decision Trees",
#   journal   = "Machine Learning",
#   volume    = "1",
#   pages     = "81--106",
#   publisher = "Kluwer Academic Publishers, Boston"
#        }


#
require 5;
use Statistics::LTU;

print "LTU version is $Statistics::LTU::VERSION\n";
print "\$LTU_PLUS = $LTU_PLUS, \$LTU_MINUS = $LTU_MINUS\n";

#  Individual features to be used
@Features = ("sunny", "overcast", "rain",# clouds
	     "hot", "mild", "cool",      # temperature
	     "humid", "normal", "dry",   # humidity
	     "windy", "calm"	         # wind
	     );

$N_FEATURES = $#Features + 1;

#  The raw examples, taken from Quinlan's paper.
#  Note that for simplicity we just represent the features
#  as a string.
@Quinlan_Examples = (
	     ["sunny		hot	humid	calm",	"n"],
	     ["sunny		hot	humid 	windy","n"],
	     ["overcast 	hot	humid 	calm", "y"],
	     ["rain 		mild	humid	calm",	"y"],
	     ["rain 		cool	normal	calm",	"y"],
	     ["rain		cool	normal	windy","n"],
	     ["overcast		cool	normal	windy","y"],
	     ["sunny		mild	humid	calm",	"n"],
	     ["sunny		cool	normal	calm",	"y"],
	     ["rain		mild	normal	calm",	"y"],
	     ["sunny		mild	normal	windy","y"],
	     ["overcast		mild	humid	windy","y"],
	     ["overcast		hot	normal	calm",	"y"],
	     ["rain		mild	humid	windy","y"]
	     );


#  Create the example set.  Format of @Examples is
#  ( [[...feature vector...], class], [[...feature vector...], class], ...)
#

@Examples = ();

foreach $example (@Quinlan_Examples) {
    ($feature_string, $class) = @{$example};

    @Values = (0) x $N_FEATURES;
    for $i (0 .. $#Features) {
	$feature = $Features[$i];
	$Values[$i] = 1	if $feature_string =~ /$feature/i;
    }

    push(@Examples, [\@Values, 
		     ($class eq "y" ? $LTU_PLUS : $LTU_MINUS)]
	);
}

#  Create the LTU.  Enable automatic feature scaling.
$ltu = new Statistics::LTU::ACR($N_FEATURES, 1);

#  This is the main loop that trains and tests the LTU.

for $iter (1 .. 10) {

    #  Train the LTU
    for $example (@Examples) {
	($features_ref, $class) = @{$example};
	$ltu->train($features_ref, $class);
    }

    #  Test the LTU.  We really don't need to do this separately from 
    #  the eval_on_set since we could figure out accuracy from the
    #  stats eval_on_set returns.
    #
    $correct = 0;
    for $example (@Examples) {
	($features_ref, $class) = @{$example};
	if ($ltu->correctly_classifies($features_ref, $class)) {
	    $correct++;
	}
    }

    ($TN, $FP, $FN, $TP) = $ltu->eval_on_set(\@Examples);

    print "\nIteration $iter.  LTU accuracy is ";
    print $correct / ($#Examples + 1), "\n";
    print "True negs=$TN, False pos=$FP, False negs=$FN, True pos=$TP\n";

    $ltu->print;
}

##### End of weather.perl
