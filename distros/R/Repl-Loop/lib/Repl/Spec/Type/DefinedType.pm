package Repl::Spec::Type::DefinedType;

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
    croak sprintf("Expected type 'defined' but received '<undef>'.", $arg) if !defined($arg);
    return $arg;
}

sub name
{
    return 'defined';
}

1;