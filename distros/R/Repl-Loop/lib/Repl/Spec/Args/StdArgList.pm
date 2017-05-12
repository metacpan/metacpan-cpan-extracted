package Repl::Spec::Args::StdArgList;

use strict;
use warnings;
use Carp;

#
# There are 3 types of parameters in a standard argument list.
# 1. Fixed and required arguments. Each with its own type.
# 2. Optional. Each argument has its own type. These cannot be of type Pair, because this might conflict with the named arguments.
#    The optional parameters can have a default value which will be used when the argument is not present.
# 3. Named (optional or required). These are pairs at the end of the command line.
#    The named parameters can have a default value.
#

sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    
    my $fixedArg = shift || die "Expected a arrayref containing fixed args.";
    my $optArg = shift || die "Expected a arrayref containing optional args.";
    my $namedArg = shift || die "Expected a arrayref containing named args.";
    
    my $self= {};
    $self->{FIXED}=$fixedArg;
    $self->{OPT}=$optArg;
    $self->{NAMED}=$namedArg;
    
    return bless $self, $class;
}


# Parameters:
# - An argument list (ref to array).
# - A context! (which is not used by the type system, but it could be by the type specs).
# Notes:
# - The context is not used directly by the argument checker, it is passed to the
#   type specs, so a type spec implementation could make use of it.
# - The argument list is expected to have the form ["cmd", arg1, ..., argn]
sub guard
{
    my $self = shift;
    
    my $args = shift || die "Argument list expected.";
    my $argslen = scalar(@$args);
    my $ctx = shift || die "Context expected";
    
    my $fixed = $self->{FIXED};
    my $opt = $self->{OPT};
    my $named = $self->{NAMED};
    
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
    
    # Test the optional args.
    foreach my $spec (@$opt)
    {
        $newargs->[$argidx] = $spec->guard($args, $argidx, $ctx);
        $argidx = $argidx + 1;        
    }
    
    # If there are still arguments left that are not pairs there are 
    # too many arguments.
    croak sprintf("Too many arguments. Expected at most %d arguments.", scalar(@$fixed) + scalar(@$opt)) if($argidx < $argslen && !(ref($args->[$argidx]) eq "Repl::Core::Pair"));
    
    # Named args.
    my $startnamed = $argslen - 1;
    while($startnamed > 0 && (ref($args->[$startnamed]) eq "Repl::Core::Pair"))
    {
        $startnamed = $startnamed - 1;
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
 
    # If we get here, we've done all the checking.   
    return $newargs;    
}

1;
