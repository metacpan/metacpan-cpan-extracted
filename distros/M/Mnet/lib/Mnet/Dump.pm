package Mnet::Dump;

# purpose: functions to Data::Dumper used internally by other Mnet modules

# required modules
use warnings;
use strict;
use Mnet;
use Data::Dumper;



sub line {

# $out = Mnet::Dump::line($val)
# purpose: returns single line sorted Data::Dumper output for input value
# $value: input variable to dump, can be a scalar, hash, array, reference, etc
# $out: output Data::Dumper line, examples: undef, "value", [ list ], { etc }

    # read input value, dump it as a sorted single Data::Dumper line
    my $val = shift;
    my $out = Data::Dumper->new([$val])->Indent(0)->Sortkeys(1)->Useqq(1)->Dump;
    $out =~ s/(^\$VAR1 = |;\n*$)//g;
    return $out;
}


# normal end of package
1;

