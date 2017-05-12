package Perlipse::SourceParser::Visitors::Subroutine;
use base qw(Perlipse::SourceParser::Visitors::Visitor);

use strict;

use constant {
    SUPPORTED_ELEMENTS => qw(PPI::Statement::Sub),
};

sub visit
{
    my $class = shift;
    my ($element, $ast) = @_;

    my $node = $ast->createNode(element => $element);

    if ($element->forward)
    {
        $node->sourceEnd($class->utils->lastLocation($element));
    }
    elsif ($element->block)
    {
        my $finish = $element->block->finish;
        if ($finish)
        {
            $node->sourceEnd($class->utils->location($finish));
        }
        else
        {
            #print STDERR "missing closing }\n";
        }
    }
    else
    {
        # print STDERR "subroutine has no block or forward declaration";
    }

    $ast->curPkg->addStatement($node);

    return 1;
}

##

sub _supported_elements
{
    return SUPPORTED_ELEMENTS;
}

1;
