package Repl::Spec::Type::NumberType;

use strict;
use warnings;
use Carp;

# No arguments required.
sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    
    my $self= {};
    return bless $self, $class;
}

sub guard
{
    my $self = shift;
    my $arg = shift;
    
    my $test = $arg;
    eval {
        local $SIG{__WARN__} = sub {die $_[0]}; # Turn warnings into exceptions.
        $test += 0;
    };
    croak sprintf("Expected type number but received '%s'.", $arg) if $@;
    return $arg;    
}

sub name
{
    return 'number';
}

1;
