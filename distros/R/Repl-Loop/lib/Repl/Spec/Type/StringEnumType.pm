=head1 NAME

Repl::Spec::Type::StringEnumType - A parameter guard for strings that can
have a value from a restricted set of string constants.

=head1 SYNOPSIS

This type guard ensures that a string parameter was passed by the user
matching a string out of a set of string constants.

=head1 DESCRIPTION

=head1 Methods

=over 4

=item C<new()>

A set of strings from which the values are choosen.

=item C<guard()>

Parameters: A single expression.
Returns: The string value.

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

package Repl::Spec::Type::StringEnumType;

use strict;
use warnings;
use Carp;

# Parameters:
# - A list of string constants.
sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    
    my @values = @_;
    
    my $self= {VALUES=>\@values};
    return bless $self, $class;
}

sub guard
{
    my $self = shift;
    my $arg = shift;    
    my $values = $self->{VALUES};
    
    foreach my $enum (@$values)
    {
        return $arg if($enum eq $arg);
    }
    croak sprintf("Expected %s but received '%s'.", $self->name(), $arg);
}

sub name
{
    my $self = shift;
    my $values = $self->{VALUES};
    
    return sprintf('enum %s', join("|", @$values));
}

1;
