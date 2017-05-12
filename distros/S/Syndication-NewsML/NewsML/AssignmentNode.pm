# $Id: AssignmentNode.pm,v 0.1 2002/02/13 14:11:43 brendan Exp brendan $
# Syndication::NewsML::AssignmentNode.pm

$VERSION     = sprintf("%d.%02d", q$Revision: 0.1 $ =~ /(\d+)\.(\d+)/);
$VERSION_DATE= sprintf("%s", q$Date: 2002/02/13 14:11:43 $ =~ m# (.*) $# );

$DEBUG = 1;

# Syndication::NewsML::AssignmentNode -- superclass defining what to do in elements
#                                that contain assignment attributes
#
package Syndication::NewsML::AssignmentNode;
use Carp;
@ISA = qw( Syndication::NewsML::Node );

sub _init {
    my ($self, $node) = @_;
    $self->{_attributes}->{AssignedBy} = IMPLIED;
    $self->{_attributes}->{Importance} = IMPLIED;
    $self->{_attributes}->{Confidence} = IMPLIED;
    $self->{_attributes}->{HowPresent} = IMPLIED;
    $self->{_attributes}->{DateAndTime} = IMPLIED;
    $self->{_multiElements}->{Comment} = ZEROORMORE;
}

1;
