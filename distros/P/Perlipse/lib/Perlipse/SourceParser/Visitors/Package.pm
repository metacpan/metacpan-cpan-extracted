package Perlipse::SourceParser::Visitors::Package;
use base qw(Perlipse::SourceParser::Visitors::Visitor);

use strict;

use constant {
    SUPPORTED_ELEMENTS => qw(PPI::Statement::Package),
};

sub visit
{
    my $class = shift;
    my ($element, $ast) = @_;
    
    my $node = $ast->createNode(element => $element);
    $ast->addPkg($node);
    
    return 1;
}

## 

sub _supported_elements
{
    return SUPPORTED_ELEMENTS;
}

1;