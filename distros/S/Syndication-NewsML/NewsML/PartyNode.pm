# $Id: PartyNode.pm,v 0.1 2002/02/13 14:11:43 brendan Exp brendan $
# Syndication::NewsML::PartyNode.pm

$VERSION     = sprintf("%d.%02d", q$Revision: 0.1 $ =~ /(\d+)\.(\d+)/);
$VERSION_DATE= sprintf("%s", q$Date: 2002/02/13 14:11:43 $ =~ m# (.*) $# );

$DEBUG = 1;

# Syndication::NewsML::PartyNode -- superclass defining what to do in elements
#                           that contain Party sub-elements

package Syndication::NewsML::PartyNode;
use Carp;
@ISA = qw ( Syndication::NewsML::CommentNode ); # %party entity can have comment as well

sub _init {
    my ($self, $node) = @_;
    $self->{_multiElements}{Party} = ONEORMORE;
}

1;
