#!/usr/bin/perl
#
# @File Predicate.pm
# @Author Andriy Mulyar
# @Created Jun 27, 2016 1:17:38 PM
#

use strict;
use warnings;
package Predicate;

#A predicate will be treated as an edge on the graph. This object takes 4
# parameters
#Source CUI
#Predicate Type (ie. ISA, TREATS, CAUSES, etc)
#Destination CUI
#Edge Weight
#
sub new {
    my $class = shift;
    my $self = {
        _source => shift,
	_predicate => shift,
        _destination => shift,
        _weight => shift,

    };
    bless $self, $class;
    return $self;
}

#returns source vertex
sub getSource{
    return shift->{_source}
}

#returns predicate name
sub getPredicate{
    return shift->{_predicate};
}

#returns destination vertex
sub getDestination{
    return shift->{_destination}
}

#returns weight associated with the edge
sub getWeight{
    return shift->{_weight};
}

#test print
sub _print{
    my $self = shift;
    print $self->{_source}->getPreferredName()." ". $self->{_predicate} ." ".$self->{_destination}->getPreferredName()." ".$self->{_weight}."\n";
    #print "$self->{_source} $self->{_predicate} $self->{_destination}";
}
1;
