package Repl::Cmd::ExitCmd;

use strict;
use warnings;

# Parameters
# - a Repl.
sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $repl = shift;
    
    my $self= {};
    $self->{REPL} = $repl;
    return bless $self, $class;
}

sub execute
{
    my $self = shift;
    
    my $repl = $self->{REPL};
    $repl->stop();
}

1;