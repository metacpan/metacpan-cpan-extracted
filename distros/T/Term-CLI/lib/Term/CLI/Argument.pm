#=============================================================================
#
#       Module:  Term::CLI::Argument
#
#  Description:  Generic parent class for arguments in Term::CLI
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  22/01/18
#
#   Copyright (c) 2018-2022 Steven Bakker
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#=============================================================================

package Term::CLI::Argument 0.059000;

use 5.014;
use warnings;

use Moo 1.000001;

use Term::CLI::L10N qw( loc );

use Types::Standard 1.000005 qw( Int );

use namespace::clean 0.25;

extends 'Term::CLI::Element';

has min_occur => ( is => 'rw', isa => Int, default => sub {1} );
has max_occur => ( is => 'rw', isa => Int, default => sub {1} );

sub BUILD {
    my ( $self, $args ) = @_;

    # Allow "occur" as a shortcut for min/max setting.
    if ( defined $args->{occur} ) {
        $self->min_occur( $args->{occur} );
        $self->max_occur( $args->{occur} );
    }
    return;
}

sub occur {
    my ( $self, @args ) = @_;
    if (@args) {
        my $min = shift @args;
        my $max = @args ? shift @args : $min;
        $self->min_occur($min);
        $self->max_occur($max);
    }
    return ( $self->min_occur, $self->max_occur );
}

sub type {
    my ($self) = @_;
    my $class = ref $self;
    if ( $class eq 'Term::CLI::Argument' ) {
        return 'GENERIC';
    }
    return $class =~ s/\A Term::CLI::Argument:://rxms;
}

before validate => sub {
    my ($self) = @_;
    $self->clear_error;
};

sub validate {
    my ( $self, $value, $state ) = @_;

    if ( not defined $value or $value eq q{} ) {
        return $self->set_error( loc('value cannot be empty') );
    }
    return $value;
}

1;

__END__

=pod

=head1 NAME

Term::CLI::Argument - generic parent class for arguments in Term::CLI

=head1 VERSION

version 0.059000

=head1 SYNOPSIS

 use Term::CLI::Argument;

 my $arg = Term::CLI::Argument->new(name => 'varname');

=head1 DESCRIPTION

Generic parent class for arguments in L<Term::CLI>(3p).
Inherits from L<Term::CLI::Element>(3p).

=head1 CLASS STRUCTURE

=head2 Inherits from:

L<Term::CLI::Element>(3p).

=head2 Consumes:

None.

=head1 CONSTRUCTORS

=over

=item B<new> ( B<name> =E<gt> I<VARNAME> ... )
X<new>

Create a new Term::CLI::Argument object and return a reference to it.

The B<name> attribute is required.

Other possible attributes are:

=over

=item B<min_occur> =E<gt> I<INT>

The minimal number of times the argument must occur.
A negative or zero value means there is no minimum.

The default is C<1>.

=item B<max_occur> =E<gt> I<INT>

The maximum number of times the argument may occur.
A negative or zero value means there is no maximum.

The default is C<1>.

=item B<occur> =E<gt> I<INT>

A shortcut to setting C<min_occur> and C<max_occur>
to the same value. Specifying this will override
any C<min_occur> or C<max_occur> attributes.

=back

=back

=head1 METHODS

=head2 Accessors

Accessors are inherited from L<Term::CLI::Element>(3p).

Additionally, there are the following:

=over

=item B<min_occur> ( [ I<INT> ] )

Get or set the C<min_occur> attribute.

=item B<max_occur> ( [ I<INT> ] )

Get or set the C<max_occur> attribute.

=back

=head2 Other

=over

=item B<occur> ( [ I<INT> [, I<INT> ] ] )

When called with no arguments, returns two-element list containing the
L<min_occur|/min_occur> and L<max_occur|/max_occur> values, respectively.

When called with one argument, it will set both the C<min_occur> and
C<max_occur> attributes to the given value.

=item B<type>

Return the argument "type". By default, this is the object's class name
with the C<Term::CLI::Argument::> prefix removed. Can be overloaded to
provide a different value.

=item B<validate> ( I<TEXT>, I<STATE> )

Check whether I<TEXT> is a valid value for this object. Return the
(possibly normalised) value if it is valid. Otherwise, return nothing
(i.e. C<undef> or the empty list, depending on call context) and set the
L<error|/error>() attribute).

By default, this method only checks whether I<value> is defined and not
an empty string.

Sub-classes should probably override this.

The C<validate> function can be made context-aware by inspecting the
I<STATE> parameter, a HashRef containing the same key/value pairs
as in the arguments to the
L<command callback|Term::CLI::Role::CommandSet|/callback>
function (see also
L<Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet>):

    STATE = {
        status       => Int,
        error        => Str,
        options      => HashRef,
        arguments    => ArrayRef[Value],
        command_line => Str,
        command_path => ArrayRef[InstanceOf['Term::CLI::Command']],
    }

The C<arguments> array holds the argument values (scalars) that were parsed up
until now (not including the current argument value).

The C<command_path> array holds the L<Term::CLI::Command|Term::CLI::Command>
objects that were parsed up until now. This means that the command to which
this argument applies can be accessed with:

    CURRENT_COMMAND = STATE->{command_path}->[-1];

The C<command_line> is the full string as it was passed from
L<readline|Term::CLI/readline>.

=over 6

=item B<NOTE:>

Care should be taken to not modify the values in the I<STATE> HashRef.
Modifications may result in unexpected behaviour.

=back

=back

=head1 BUNDLED SUB-CLASSES

The L<Term::CLI|Term::CLI>(3p) distribution comes bundled with a number of
arugment classes.

=over

=item L<Term::CLI::Argument::Bool>

Parse, complete, and validate boolean arguments.

=item L<Term::CLI::Argument::Enum>

Parse, complete, and validate "enum"-like arguments (pre-defined lists of words).

=item L<Term::CLI::Argument::Filename>

Parse, complete, and validate file/path names.

=item L<Term::CLI::Argument::Number>

Parse and validate numbers.

=item L<Term::CLI::Argument::String>

Parse and validate generic strings.

=item L<Term::CLI::Argument::TypeTiny>

Parse and validate L<Type::Tiny>(3p) arguments.

=back


=head1 SEE ALSO

L<Term::CLI>(3p),
L<Term::CLI::Argument::Enum>(3p),
L<Term::CLI::Argument::Filename>(3p),
L<Term::CLI::Argument::Number>(3p),
L<Term::CLI::Argument::String>(3p),
L<Term::CLI::Argument::TypeTiny>(3p),
L<Term::CLI::Element>(3p).

=head1 AUTHOR

Steven Bakker E<lt>sbakker@cpan.orgE<gt>, 2018-2022.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Steven Bakker

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=begin __PODCOVERAGE

=head1 THIS SECTION SHOULD BE HIDDEN

This section is meant for methods that should not be considered
for coverage. This typically includes things like BUILD and DEMOLISH from
Moo/Moose. It is possible to skip these when using the Pod::Coverage class
(using C<also_private>), but this is not an option when running C<cover>
from the command line.

The simplest trick is to add a hidden section with an item list containing
these methods.

=over

=item BUILD

=item DEMOLISH

=back

=end __PODCOVERAGE

=cut
