package Repl::Spec::Args::VarArgList;

use strict;
use warnings;
use Carp;

# Parameters:
# - Array ref of fixed args.
# - A single var arg.
# - Min nr. occurences (can be -1 if not checked.)
# - Max nr. occurences (can be -1 if unlimited.)
# - Array ref of named args.
sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    
    my $fixedArg = shift || die "Expected a arrayref containing fixed args.";
    my $varArg = shift || die "Expected a single var arg.";
    my $min = shift;
    my $max = shift;
    my $namedArg = shift || die "Expected a arrayref containing named args.";
    
    my $self= {};
    $self->{FIXED}=$fixedArg;
    $self->{VAR}=$varArg;
    $self->{MIN} = $min;
    $self->{MAX} = $max;    
    $self->{NAMED}=$namedArg;
    
    return bless $self, $class;
}

# Parameters:
# - An argument list (ref to array).
# - A context!
# Notes:
# - The context is not used directly by the argument checker, it is passed to the
#   type specs, so a type spec implementation could make use of it.
# - The argument list is expected to have the form ["cmd", arg1, ..., argn]
# - The result list contains
#    * First the fixt args.
#    * !!! Secondly the named args. Otherwise it would be impossible to
#      differentiate from the varargs.
#    * Finally the var args.
sub guard
{
    my $self = shift;    
    my $args = shift || die "Argument list expected.";
    my $argslen = scalar(@$args);
    my $ctx = shift || die "Context expected";
    
    my $fixed = $self->{FIXED};
    my $var = $self->{VAR};
    my $min = $self->{MIN};
    my $max = $self->{MAX};
    my $named = $self->{NAMED};
    
    # We look for all pairs at the end of the argument list. We will only
    # consider these trailing pairs.
    my $startnamed = $argslen - 1;
    while ($startnamed > 0 && (ref($args->[$startnamed]) eq "Repl::Core::Pair"))
    {
        $startnamed = $startnamed - 1;
    }
    my $nrvar = $startnamed - scalar(@$fixed);
    $nrvar = 0 if $nrvar < 0;                
    croak sprintf("Too few arguments of type '%s'. Expected at least %d and received %d.", $var->specname(), $min, $nrvar) if($min >= 0 && $nrvar < $min);        
    croak sprintf("Too many arguments of type '%s'. Expected at most %d and received %d.", $var->specname(), $max, $nrvar) if($max >= 0 && $nrvar > $max);
    
    my $newargs = [];
    $newargs->[0] = $args->[0];
    
    # Argidx will be used for the different parameter types.
    my $argidx = 1;
    
    # Test the fixed args.
    croak sprintf("Too few arguments. Expected at least %d arguments but received %d.", scalar(@$fixed),  ($argslen - 1)) if ((scalar($args) - 1) < scalar(@$fixed));    
    my $i = 0;
    while ($i < scalar(@$fixed))
    {
        $newargs->[$argidx] = $fixed->[$i]->guard($args, $argidx, $ctx);
        $i = $i + 1;
        $argidx = $argidx + 1;
    }
        
    # Now we can resolve the named arguments within this range.
    foreach my $spec (@$named)
    {
        $newargs->[$argidx] = $spec->guard($args, $startnamed, $ctx);
        $argidx = $argidx + 1;
    }    
    # Finally we go looking for spurious named parameters that were not specified ...
    my $j = $startnamed;
    while ($j < $argslen)
    {
        if(ref($args->[$j]) eq "Repl::Core::Pair")
        {
            my $pair = $args->[$j];
            my $left = $pair->getLeft();
            my $right = $pair->getRight();
            my $found = 0;
            
            foreach my $namedpar (@$named)
            {
                if($namedpar->name() eq $left)
                {
                    $found = 1;
                    next;
                }                
            }            
            croak sprintf("Found an unexpected named argument '%s'.", $left) if ! $found;            
        }
        $j = $j + 1;
    }
    
    # Check the var ones.
    # Start looking after the fixed args, provide the expected index.
    my $m = 0;
    my $startvar = scalar(@$fixed)  + 1;
    while($m < $nrvar) 
    {
        $newargs->[$argidx] = $var->guard($args, $startvar + $m, $ctx);
        $m = $m + 1;
        $argidx = $argidx + 1;
    }
 
    # If we get here, we've done all the checking.   
    return $newargs;    
}

1;
