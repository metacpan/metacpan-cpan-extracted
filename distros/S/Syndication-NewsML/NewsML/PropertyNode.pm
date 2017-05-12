# $Id: PropertyNode.pm,v 0.1 2002/02/13 14:11:43 brendan Exp brendan $
# Syndication::NewsML::PropertyNode.pm

$VERSION     = sprintf("%d.%02d", q$Revision: 0.1 $ =~ /(\d+)\.(\d+)/);
$VERSION_DATE= sprintf("%s", q$Date: 2002/02/13 14:11:43 $ =~ m# (.*) $# );

$DEBUG = 1;

# Syndication::NewsML::PropertyNode -- superclass defining what to do in elements
#                              that contain Property sub-elements
#
package Syndication::NewsML::PropertyNode;
use Carp;
@ISA = qw( Syndication::NewsML::Node );

sub _init {
    my ($self, $node) = @_;
    $self->{_multiElements}->{Property} = ZEROORMORE;
}

1;
