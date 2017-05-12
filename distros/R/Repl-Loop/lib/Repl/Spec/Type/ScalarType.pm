package Repl::Spec::Type::ScalarType;

use strict;
use warnings;
use Carp;

# No parameters.
sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = {};
    return bless $self, $class;    
}

sub guard
{
    my $self = shift;
    my $arg = shift;
    
    return $arg if !ref($arg);
    croak sprintf("Expected type scalar but received '%s'.", $arg);
}

sub name
{
    return 'scalar';
}

1;