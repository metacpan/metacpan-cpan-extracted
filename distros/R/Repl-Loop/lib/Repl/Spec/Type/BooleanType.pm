=head1 NAME

Repl::Spec::Type::BooleanType - A parameter guard for boolean values.

=head1 SYNOPSIS

This type guard ensures that a boolean parameter was passed by the user.
The guard converts truthy values to 1 and falsy values to 0.

Truthy values are "true", "ok", "on", "yes".

Falsy values are "false", "nok", "off", "no".

=head1 DESCRIPTION

=head1 Methods

=over 4

=item C<new()>

=item C<guard()>

Parameters: A single expression.
Returns: 0 or 1.

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

package Repl::Spec::Type::BooleanType;

use strict;
use warnings;
use Carp;

# No parameters.
sub new
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = {};
    return bless $self, $class;    
}

sub guard
{
    my $self = shift;
    my $arg = shift;
    
    return 1 if $arg =~ /true|yes|on|ok|1|t/i;
    return 0 if $arg =~ /false|no|off|nok|0|f/i;
    croak sprintf("Expected type boolean but received '%s'.", $arg);
}

sub name
{
    return 'boolean';
}

1;