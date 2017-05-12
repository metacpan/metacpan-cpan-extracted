=head1 NAME

Repl::Spec::Type::InstanceType - A parameter guard that ensures instances of a specified class.

=head1 SYNOPSIS

This type guard ensures that a reference parameter was passed by the user
containing a reference to an abject belonging to a specified class. Reference types 'ARRAY' and 'HASH' can be used as well.

=head1 DESCRIPTION

=head1 Methods

=over 4

=item C<new()>

Parameters: A string denoting a class name or 'ARRAY' or 'HASH'.

=item C<guard()>

Parameters: A single expression.
Returns: The same reference. No conversions are applied.

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

package Repl::Spec::Type::InstanceType;

use strict;
use warnings;
use Carp;

use Scalar::Util qw(blessed dualvar isweak readonly refaddr reftype tainted
                        weaken isvstring looks_like_number set_prototype);

# Parameters:
# - The package name (string) or reference type (HASH, ARRAY) to which
#   the argument must belong.
sub new
{
    my $invocant = shift;
    my $classname = shift;
    
    my $class = ref($invocant) || $invocant;
    
    my $self = {CLASS=>$classname};
    return bless $self, $class;    
}

sub guard
{
    my $self = shift;
    my $arg = shift;
    
    my $classname = $self->{CLASS};
    return $arg if (blessed($arg) && UNIVERSAL::isa($arg, $classname));
    return $arg if (ref($arg) && ($classname eq ref($arg)));
    croak sprintf("Expected '%s' instance but received '%s'.", $classname, $arg);
}

sub name
{
    my $self = shift;    
    my $classname = $self->{CLASS};
    return sprintf("%s reference", $classname);    
}

1;
