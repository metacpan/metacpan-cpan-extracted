package Repl::Cmd::DumpCmd;

use strict;
use warnings;
use Data::Dumper;

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
    
    print "\n";
    print Dumper($expr);
    print "\n";
}

1;
