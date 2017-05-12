package Perlipse::SourceParser::Visitors::Include;
use base qw(Perlipse::SourceParser::Visitors::Visitor);

use strict;

use constant {
    SUPPORTED_ELEMENTS => qw(PPI::Statement::Include),
};

sub visit
{
    my $class = shift;
    my ($element, $ast) = @_;
    
    my $node = $ast->createNode(element => $element);
    $node->sourceEnd($class->utils->lastLocation($element));
    
    $ast->curPkg->addStatement($node);
    
    return 1;
}

## 

sub _supported_elements
{
    return SUPPORTED_ELEMENTS;
}

1;