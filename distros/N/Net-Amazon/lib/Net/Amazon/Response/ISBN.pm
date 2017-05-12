######################################################################
package Net::Amazon::Response::ISBN;
######################################################################
use warnings;
use strict;
use base qw(Net::Amazon::Response);

use Net::Amazon::Property;

##################################################
sub new {
##################################################
    my($class, %options) = @_;

    my $self = $class->SUPER::new(%options);

    bless $self, $class;   # reconsecrate
}

##################################################
sub as_string {
##################################################
    my($self) = @_;

    my($property) = $self->properties;
    return $property->as_string();
}

##################################################
sub properties {
##################################################
    my($self) = @_;

    my $property = Net::Amazon::Property::factory(
        xmlref => $self->{xmlref}->{Items}->[0]);

    return ($property);
}

1;
