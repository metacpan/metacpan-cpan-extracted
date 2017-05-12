package Repl::Spec::Args::OptionalArg;

use strict;
use warnings;
use Carp;

# Parameters:
# - A typespec.
# - A default value.
sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    
    my $typespec = shift || die "Expected a type spec.";
    my $value = shift || die "Expected a default value.";
    
    my $specname = sprintf("opt: %s", $typespec->name());
    
    my $self= {};
    $self->{TYPESPEC} = $typespec;
    $self->{VALUE} = $value;
    $self->{SPECNAME} = $specname;
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
    
    return $self->{VALUE} if($pos < 0 || $pos >= scalar(@$args));
    return $self->{VALUE} if(ref($args->[$pos]) eq "Repl::Core::Pair");
    
    my $typespec = $self->{TYPESPEC};
    my $result;
    eval {$result = $typespec->guard($args->[$pos], $ctx)};
    croak sprintf("The optional argument at position %d: %s", $pos, $@) if $@;
    return $result;    
}
             
1;
