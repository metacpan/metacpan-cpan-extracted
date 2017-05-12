=head1 NAME

Repl::Spec::Type::CheckedArrayType - A parameter guard for arrays.

=head1 SYNOPSIS

This type guard ensures that an array was passed containing elements
of another nested type guard provided by the user. An example: a list of integers
is ensured by creating a CheckedArrayType with nested IntegerType.
The guards can be nested arbitrarily to obtain a guard for whatever complex nested type.

=head1 DESCRIPTION

=head1 Methods

=over 4

=item C<new()>

Parameters: A nested guard that will be applied to the elements of the array.

=item C<guard()>

Parameters: A single expression.
Returns: A new array where the elements are converted by the nested type guard.

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

package Repl::Spec::Type::CheckedArrayType;

use strict;
use warnings;
use Carp;

# Parameters:
# - The type of the array elements.
sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    
    my $eltyp = shift;      
    
    my $self= {TYPE=>$eltyp};
    return bless $self, $class;
}

sub guard
{
    my $self = shift;
    my $arg = shift;
    
    my $eltyp = $self->{TYPE};
    
    if(ref($arg) eq 'ARRAY')
    {
        my $result = [];
        my $idx = 0;
        foreach my $el (@$arg)
        {
            my $val;
            eval {$val = $eltyp->guard($el)};
            croak sprintf("Expected %s but the value nr. %d does not comply.\n%s.", $self->name(), $idx, $@)if ($@);
            push(@$result, $val);
            $idx = $idx + 1;            
        }
        return $result;
    }
    else
    {
        croak sprintf("Expected %s but received '%s'.", $self->name(), $arg);
    }    
}

sub name
{
    my $self = shift;
    my $eltyp = $self->{TYPE};
    return sprintf("ARRAY of %s", $eltyp->name());    
}

1;
