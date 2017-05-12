=head1 NAME

Repl::Spec::Type::PatternType - A parameter guard for strings matching a regular expression.

=head1 SYNOPSIS

This type guard ensures that a string parameter was passed by the user
matching a specified regular expression.

=head1 DESCRIPTION

=head1 Methods

=over 4

=item C<new()>

A regular expression to which the values must conform.

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

package Repl::Spec::Type::PatternType;

use strict;
use warnings;
use Carp;

# Parameter:
# - A string representing a regexp (don't include the '/').
sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $description = shift;
    my $pattern = shift;
    
    my $self= {DESCRIPTION=>$description, PATTERN=>$pattern};
    return bless $self, $class;
}

sub guard
{
    my $self = shift;
    my $arg = shift;
    my $pattern = $self->{PATTERN};
    my $description = $self->{DESCRIPTION};
    
    return $arg if $arg =~ /$pattern/;
    croak sprintf("Expected '%s' but received '%s'.",$self->name(), $arg);
}

sub name
{
    my $self = shift;
    my $pattern = $self->{PATTERN};
    my $description = $self->{DESCRIPTION};
    
    return sprintf("%s matching /%s/",$description, $pattern);
}

1;
