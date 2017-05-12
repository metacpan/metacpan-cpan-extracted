# $Id: TopicSetNode.pm,v 0.1 2002/02/13 14:11:43 brendan Exp brendan $
# Syndication::NewsML::TopicSetNode.pm

$VERSION     = sprintf("%d.%02d", q$Revision: 0.1 $ =~ /(\d+)\.(\d+)/);
$VERSION_DATE= sprintf("%s", q$Date: 2002/02/13 14:11:43 $ =~ m# (.*) $# );

$DEBUG = 1;

#
# Syndication::NewsML::TopicSetNode -- superclass defining what to do with TopicSet fields
#
package Syndication::NewsML::TopicSetNode;
use Carp;
@ISA = qw( Syndication::NewsML::Node );

sub _init {
    my ($self, $node) = @_;
    $self->{_multiElements}{TopicSet} = ZEROORMORE;
}

1;
