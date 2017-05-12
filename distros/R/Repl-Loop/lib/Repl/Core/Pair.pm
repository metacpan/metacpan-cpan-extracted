package Repl::Core::Pair;

# Pragma's.
use strict;

# Uses.
use Carp;

sub new
{
    my $invocant = shift;
    my %args = (@_);
    my $class = ref($invocant) || $invocant;
    
    # Initialize the token instance.
    my $self = {};
    $self->{LEFT} = $args{LEFT} || confess "A pair needs an lvalue.";
    $self->{RIGHT} = $args{RIGHT} || confess "A pair needs an rvalue.";
    
    return bless($self, $class);
}

sub getLeft
{
    my $self = shift;
    return $self->{LEFT};
}

sub getRight
{
    my $self = shift;
    return $self->{RIGHT};
}


1;
