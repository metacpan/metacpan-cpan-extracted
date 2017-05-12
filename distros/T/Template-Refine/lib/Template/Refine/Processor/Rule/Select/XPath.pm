package Template::Refine::Processor::Rule::Select::XPath;
use Moose;
use XML::LibXML::XPathContext;

with 'Template::Refine::Processor::Rule::Select::Pattern';

sub select {
    my ($self, $document) = @_;
    my $xc = XML::LibXML::XPathContext->new();
    return $xc->findnodes($self->_xpath, $document);
}

sub _xpath {
    shift->pattern;
}

1;
