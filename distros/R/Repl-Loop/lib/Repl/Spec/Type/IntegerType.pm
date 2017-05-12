=head1 NAME

Repl::Spec::Type::IntegerRange - A parameter guard for integers.

=head1 SYNOPSIS

This type guard ensures that an integer parameter was passed by the user.

=head1 DESCRIPTION

=head1 Methods

=over 4

=item C<new()>

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

package Repl::Spec::Type::IntegerType;

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
    
    return $arg if $arg =~ /[+-]?\d+/;
    croak sprintf("Expected type integer but received '%s'.", $arg);
}

sub name
{
    return 'integer';
}

1;
