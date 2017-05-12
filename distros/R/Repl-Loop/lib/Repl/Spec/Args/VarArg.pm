package Repl::Spec::Args::VarArg;

use strict;
use warnings;
use Carp;

# Parameters:
# - A type spec.
sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $typespec = shift || die "TypeSpec expected.";
    
    my $self= {};
    $self->{TYPESPEC} = $typespec;
    $self->{SPECNAME} = "var: " . $typespec->name();
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
    my $pos = shift || die "Position expected.";
    my $ctx = shift || die "Context expected";
    
    croak sprintf("Var argument at position %d: argument not present or type Pair found.", $pos) if($pos < 0 || $pos >= scalar(@$args));
    my $typespec = $self->{TYPESPEC};
    my $result;
    eval {$result = $typespec->guard($args->[$pos], $ctx)};
    croak sprintf("Var argument at position %d: %s", $pos, $@) if $@;
    return $result;    
}

1;
