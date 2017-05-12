=head1 NAME

Repl::Spec::Type::CheckedHashType - A parameter guard for hashes.

=head1 SYNOPSIS

This type guard ensures that a hash was passed containing values
of another nested type guard provided by the user. An example: a hash of integers
is ensured by creating a CheckedHashType with nested IntegerType.
The guards can be nested arbitrarily to obtain a guard for whatever complex nested type.

=head1 DESCRIPTION

=head1 Methods

=over 4

=item C<new()>

Parameters: A nested guard that will be applied to the values of the hash.

=item C<guard()>

Parameters: A single expression.
Returns: A new hash where the values are converted by the nested type guard.

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

package Repl::Spec::Type::CheckedHashType;

use strict;
use warnings;
use Carp;

# Parameter:
# - The type of the hash values.
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
    
    if(ref($arg) eq 'HASH')
    {
        my $result = {};
        my $idx = 0;
        foreach my $el (keys %$arg)
        {
            my $val;
            eval {$val = $eltyp->guard($arg->{$el})};
            croak sprintf("Expected %s but the value of element '%s' does not comply.\n%s.", $self->name(), $el, $@)if ($@);
            $result->{$el} = $val;
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
    return sprintf("HASH of %s", $eltyp->name());    
}

1;
