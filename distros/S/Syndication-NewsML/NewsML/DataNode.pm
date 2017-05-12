# $Id: DataNode.pm,v 0.1 2002/02/13 14:11:43 brendan Exp brendan $
# Syndication::NewsML::DataNode.pm

$VERSION     = sprintf("%d.%02d", q$Revision: 0.1 $ =~ /(\d+)\.(\d+)/);
$VERSION_DATE= sprintf("%s", q$Date: 2002/02/13 14:11:43 $ =~ m# (.*) $# );

$DEBUG = 1;

#
# Syndication::NewsML::DataNode -- superclass defining what to do with DataContent and Encoding fields
#
package Syndication::NewsML::DataNode;
@ISA = qw( Syndication::NewsML::Node );

sub _init {
    my ($self, $node) = @_;
    $self->{_singleElements}{Encoding} = OPTIONAL;
    $self->{_singleElements}{DataContent} = OPTIONAL;
}

1;
