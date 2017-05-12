=head1 NAME

Repl::Spec::Type::IntegerRangeType - A parameter guard for integer ranges.

=head1 SYNOPSIS

This type guard ensures that an integer, range bound parameter was passed by the user.

=head1 DESCRIPTION

=head1 Methods

=over 4

=item C<new()>

Parameters: from and to to indicate the range.

=item C<guard()>

Parameters: A single expression.
Returns: The integer value.

=item C<name()>
         
=head1 SEE ALSO

L<Repl::Spec::Type::BooleanType>
L<Repl::Spec::Type::CheckedArrayType>
L<Repl::Spec::Type::CheckedHashType>
L<Repl::Spec::Type::InstanceType>
L<Repl::Spec::Type::IntegerRangeType>
L<Repl::Spec::Type::IntegerType>
L<Repl::Spec::Type::PatternType>
L<Repl::Spec::Type::StringEnumType>

=cut

package Repl::Spec::Type::IntegerRangeType;

use strict;
use warnings;
use Carp;

use Repl::Spec::Type::IntegerType;

our @ISA = qw(Repl::Spec::Type::IntegerType);

# Expects two integer arguments, the range of the integer.
# - from
# - to
sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    
    my $from = shift;
    my $to = shift;
    
    # Invoke super constructor.
    my $self= Repl::Spec::Type::IntegerType::new($class);
    $self->{FROM} = $from;
    $self->{TO} = $to;
    # We don't have to bless.
    return  $self;
}

sub guard
{
    my $self = shift;
    my $arg = shift;
    my $from = $self->{FROM};
    my $to  = $self->{TO};
    
    eval {$arg = $self->SUPER::guard($arg)};
    carp $@ if $@;      
    if($arg < $from || $arg > $to)
    {
        croak sprintf("Integer out of range. Expected %s but received '%s'.", $self->name(), $arg);
    }
    else
    {
        return $arg;
    }    
    croak sprintf("Expected type integer but received '%s'.", $arg);
}

sub name
{
    my $self = shift;

    my $from = $self->{FROM};
    my $to  = $self->{TO};
    
    return sprintf("integer range %d..%d", $from, $to);
}

1;
