package Repl::Core::Lambda;

use strict;
use warnings;

# Parameters:
# - A parameter list (array of parameter names).
# - The body expression.
# - The lexical context.
sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    
    my $self= {};
    $self->{PARAMS} = shift;
    $self->{EXPR} = shift;
    $self->{CTX} = shift;
    return bless $self, $class;
}

sub getExpr
{
    my $self = shift;
    return $self->{EXPR};
}

sub createContext
{
    my $self = shift;
    my @args = (@_);
    my $params = $self->{PARAMS};
    my $lexicalctx = $self->{CTX};
    
    die "ERROR: Wrong number of arguments." if scalar(@args) != scalar(@$params);
    my $callctx = new Repl::Core::BasicContext();
    my $i = 0;
    foreach my $param (@$params)
    {
        $callctx->defBinding($param, $args[$i]);
        $i = $i + 1;
    }
    return new Repl::Core::CompositeContext($callctx, $lexicalctx);    
}

1;
