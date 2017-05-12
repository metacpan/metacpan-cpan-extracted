#!/usr/bin/perl
#
# @File CUI.pm
# @Author andriy
# @Created Jun 27, 2016 1:16:36 PM
#

use strict;
use warnings;
package CUI;

sub new {
    my $class = shift;;
    my $self = {
        _ID => shift,
	_preferredname => shift,
        _strength => 0,
        _pathlength => -1,
        _prevCUI => 0,
        _prevPredicate => 0,

    };
    bless $self, $class;
    return $self;
}
#returns id of cui
sub getId {
    return shift->{_ID};
}
#returns preferred name of cui
sub getPreferredName {
    return shift->{_preferredname};
}

#returns aggregate path length, -1 if vertex has not been reached
sub getPathLength(){
    return shift->{_pathlength};
}

sub getStrength(){
    return shift->{_strength};
}

#updates aggregate path length
sub setPathLength(){
    my $self = shift;
    $self->{_pathlength} = shift;
}


sub setPrevCUI(){
    my $self = shift;
    $self->{_prevCUI} = shift;
}

sub setStrength(){
    my $self = shift;
    $self->{_strength} = shift;
}

sub getPrevCUI(){
    my $self = shift;
    return $self->{_prevCUI};
}

sub setPrevPredicate{
    my $self = shift;
    $self->{_prevPredicate} = shift;
}

sub getPath{
    my $self = shift;
    my $length = $self->{_pathlength};

    my $path = $self->getPreferredName();

    while($self->getPrevCUI()){
        $path = $self->getPrevCUI()->getPreferredName() . " ".$self->{_prevPredicate}." ".$path;
        $self = $self->getPrevCUI();

    }
    return $path;
}

#test method for printing
sub _print{
    my $self = shift;
    print $self->{_ID} ." ".$self->{_preferredname}." ".$self. " ". $self->{_pathlength}."\n";
}




#checks if two cui's are equivalent i.e. have the same id's
sub equals {
    return shift-> {_ID}== shift-> {_ID};
}
1;
