package Repl::Cmd::SleepCmd;

use strict;
use warnings;

sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    
    my $self= {};
    return bless $self, $class;
}

sub execute
{
    my $self = shift;
    my $ctx = shift;
    my $args = shift;
    
    return if scalar(@$args) < 2;
    sleep $args->[1];
}

1;
