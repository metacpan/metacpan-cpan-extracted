#=============================================================================
#
#       Module:  Term::CLI::Argument
#
#  Description:  Generic parent class for arguments in Term::CLI
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  22/01/18
#
#   Copyright (c) 2018 Steven Bakker
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#=============================================================================

use 5.014_001;

package Term::CLI::Argument  0.051007 {

use Modern::Perl 1.20140107;
use Moo 1.000001;

use Term::CLI::L10N;

use Types::Standard 1.000005 qw( Int );

use namespace::clean 0.25;

extends 'Term::CLI::Element';

has min_occur => ( is => 'rw', isa => Int, default => sub{1});
has max_occur => ( is => 'rw', isa => Int, default => sub{1});

sub BUILD {
    my ($self, $args) = @_;
    # Allow "occur" as a shortcut for min/max setting.
    if (defined $args->{occur}) {
        $self->min_occur($args->{occur});
        $self->max_occur($args->{occur});
    }
}

sub occur {
    my $self = shift @_;
    if (@_) {
        my $min = shift @_;
        my $max = @_ ? shift @_ : $min;
        $self->min_occur($min);
        $self->max_occur($max);
    }
    return ($self->min_occur, $self->max_occur);
}

sub type {
    my $self = shift;
    my $class = ref $self;
    if ($class eq 'Term::CLI::Argument') {
        return 'GENERIC';
    }
    return $class =~ s/^Term::CLI::Argument:://r;
}

before validate => sub { $_[0]->set_error('') };

sub validate {
    my ($self, $value) = @_;

    $self->set_error('');
    if (!defined $value or $value eq '') {
        return $self->set_error(loc('value cannot be empty'));
    }
    return $value;
}

}

1;

__END__

=pod

=head1 NAME

Term::CLI::Argument - generic parent class for arguments in Term::CLI

=head1 VERSION

version 0.051007

=head1 SYNOPSIS

 use Term::CLI::Argument;

 my $arg = Term::CLI::Argument->new(name => 'varname');

=head1 DESCRIPTION

Generic parent class for arguments in L<Term::CLI>(3p).
Inherits from L<M6::CLI::Element>(3p).

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
L<min_occur|/min_occur> and L<max_occur|/max_occur> values, resp.

When called with one argument, it will set both the C<min_occur> and
C<max_occur> attributes to the given value.

=item B<type>

Return the argument "type". By default, this is the object's class name
with the C<M6::CLI::Argument::> prefix removed. Can be overloaded to
provide a different value.

=item B<validate> ( I<value> )

Check whether I<value> is a valid value for this object. Return the
(possibly normalised) value if it is, nothing (i.e. C<undef> or the
empty list, depending on call context) if it is not (and set the
L<error|/error>() attribute).

By default, this method only checks whether I<value> is defined and not
an empty string.

Sub-classes should probably override this.

=back

=head1 SEE ALSO

L<Term::CLI::Argument::String>(3p),
L<Term::CLI::Argument::Number>(3p),
L<Term::CLI::Argument::Enum>(3p),
L<Term::CLI::Argument::Filename>(3p),
L<Term::CLI::Element>(3p),
L<Term::CLI>(3p).

=head1 AUTHOR

Steven Bakker E<lt>sbakker@cpan.orgE<gt>, 2018.

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
