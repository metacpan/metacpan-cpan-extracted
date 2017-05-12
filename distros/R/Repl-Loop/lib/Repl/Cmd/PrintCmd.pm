package Repl::Cmd::PrintCmd;

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
    my $expr = shift;
    
    my @values = @$expr;
    print join(" ", @values[1..$#values]) if $#values >= 1;
    print "\n";
}

1;
