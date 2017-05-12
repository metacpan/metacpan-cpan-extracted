package Repl::Spec::Type::WhateverType;

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
    return $arg;
}

sub name
{
    return 'whatever';
}

1;