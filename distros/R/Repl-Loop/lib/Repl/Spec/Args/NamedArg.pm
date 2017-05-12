package Repl::Spec::Args::NamedArg;

use strict;
use warnings;
use Carp;

# Parameters:
# - Name of the parameter.
# - Type spec.
# - Default value.
# - Optional flag.
sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    
    my $paramName = shift || die "Parameter name expected.";
    my $typeSpec = shift || die "Type spec expected.";
    my $value = shift;
    my $optional = shift;
    
    my $specName = sprintf("%s=%s", $paramName, $typeSpec->name());
        
    my $self = {};
    $self->{PARAMNAME} = $paramName;
    $self->{TYPESPEC} = $typeSpec;
    $self->{VALUE} = $value;
    $self->{OPTIONAL} = $optional;
    $self->{SPECNAME} = $specName;
    
    return bless $self, $class;
}

sub specname()
{
    my $self = shift;
    return $self->{SPECNAME};
}

# Parameters:
# - An argument list (ref to array).
# - a position.
# - A context!
sub guard
{
    my $self = shift;
    my $args = shift || die "Argument list expected.";
    my $pos = shift;
    my $ctx = shift || die "Context expected";
    
    my $i = $pos;
    my $argslen = scalar(@$args);
    while ($i < $argslen)
    {
        if(ref($args->[$i]) eq "Repl::Core::Pair")
        {
            my $pair = $args->[$i];
            my $pairname = $pair->getLeft();
            my $pairvalue = $pair->getRight();
            
            if($pairname eq $self->{PARAMNAME})
            {
                my $type = $self->{TYPESPEC};
                return $type->guard($pairvalue);
            }
        }        
        $i = $i + 1;
    }
    
    if($self->{OPTIONAL})
    {
        my $type = $self->{TYPESPEC};
        return $type->guard($self->{VALUE}) if $self->{VALUE};
        return $self->{VALUE};
    }
    else
    {
        croak sprintf("Missing named argument '%s'.", $self->{PARAMNAME});        
    }    
}

sub name
{
    my $self = shift;
    return $self->{PARAMNAME};
}

1;
