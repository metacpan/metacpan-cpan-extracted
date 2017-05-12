# $Id: XmlLangNode.pm,v 0.1 2002/02/13 14:11:43 brendan Exp brendan $
# Syndication::NewsML::XmlLangNode.pm

$VERSION     = sprintf("%d.%02d", q$Revision: 0.1 $ =~ /(\d+)\.(\d+)/);
$VERSION_DATE= sprintf("%s", q$Date: 2002/02/13 14:11:43 $ =~ m# (.*) $# );

$DEBUG = 1;

# Syndication::NewsML::XmlLangNode -- superclass defining what to do with "xml:lang" attributes
#
package Syndication::NewsML::XmlLangNode;
use Carp;
@ISA = qw( Syndication::NewsML::Node );

sub _init {
    my ($self, $node) = @_;
}

# get xml:lang attribute (can't turn this into an AUTOLOAD because of the colon, dammit!)
sub getXmlLang {
    my ($self) = @_;
    $self->{xmlLang} = $self->{node}->getAttributeNode("xml:lang")->getValue;
}

1;
