package Mnet::Dump;

# purpose: functions to Data::Dumper used internally by other Mnet modules

# required modules
use warnings;
use strict;
use Data::Dumper;



sub line {

# $line = Mnet::Dump::line($value)
# purpose: returns single line sorted Data::Dumper output for input value
# $value: input variable to dump, can be a scalar, hash, array, reference, etc
# $line: output Data::Dumper line, examples: undef, "value", [ list ], { etc }

    # read input value, dump it as a sorted single Data::Dumper line
    my $value = shift;
    my $value_dumper = Data::Dumper->new([$value]);
    $value_dumper->Indent(0);
    $value_dumper->Sortkeys(1);
    $value_dumper->Useqq(1);
    my $value_dump = $value_dumper->Dump;
    $value_dump =~ s/(^\$VAR1 = |;\n*$)//g;
    return $value_dump;
}


# normal end of package
1;

