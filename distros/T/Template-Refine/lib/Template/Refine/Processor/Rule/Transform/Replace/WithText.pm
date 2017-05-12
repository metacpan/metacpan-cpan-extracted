package Template::Refine::Processor::Rule::Transform::Replace::WithText;
use Moose;

extends 'Template::Refine::Processor::Rule::Transform::Replace';

sub transform {
    my ($self, $node) = @_;

    my $replacement = XML::LibXML::Text->new($self->replacement->($node));
    return $replacement if $node->isa('XML::LibXML::Text');

    my $copy = $node->cloneNode(0);
    $copy->removeChildNodes;
    $copy->addChild($replacement);
    return $copy;
}

1;
