#=============================================================================
#
#       Module:  Term::CLI::Argument::Number
#
#  Description:  Base class for numerical arguments in Term::CLI
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

package Term::CLI::Argument::Number  0.051007 {

use Modern::Perl 1.20140107;
use Term::CLI::L10N;

use Moo 1.000001;
use namespace::clean 0.25;

extends 'Term::CLI::Argument';

has min => ( is => 'rw', clearer => 1, predicate => 1 );
has max => ( is => 'rw', clearer => 1, predicate => 1 );
has inclusive => ( is => 'rw', default => sub {1} );

sub coerce_value {
    die "coerce_value() has not been overloaded";
}

sub validate {
    my ($self, $value) = @_;

    if (!defined $value || length($value) == 0) {
        return $self->set_error(loc('not a valid number'));
    }

    my $num = $self->coerce_value($value);

    if (!defined $num) {
        return $self->set_error(loc('not a valid number'));
    }

    if ($self->inclusive) {
        if ($self->has_min && $num < $self->min) {
            return $self->set_error(loc('too small'));
        }
        elsif ($self->has_max && $num > $self->max) {
            return $self->set_error(loc('too large'));
        }
    }
    else {
        if ($self->has_min && $num <= $self->min) {
            return $self->set_error(loc('too small'));
        }
        elsif ($self->has_max && $num >= $self->max) {
            return $self->set_error(loc('too large'));
        }
    }
    return $num;
}

}

1;

__END__

=pod

=head1 NAME

Term::CLI::Argument::Number - base class for numerical arguments in Term::CLI

=head1 VERSION

version 0.051007

=head1 SYNOPSIS

 use Term::CLI::Argument::Number;

 my $arg = Term::CLI::Argument::Number->new(
                name => 'arg1',
                min => 1
                max => 2
                inclusive => 1
           );

=head1 DESCRIPTION

Base class for numerical arguments in L<Term::CLI>(3p). This class cannot
be used directly, but should be extended by sub-classes.

=head1 CLASS STRUCTURE

=head2 Inherits from:

L<Term::CLI::Argument>(3p).

=head2 Consumes:

None.

=head1 CONSTRUCTORS

=over

=item B<new> ( B<name> =E<gt> I<VARNAME>, ... )
X<new>

Create a new Term::CLI::Argument::Number object and return a reference
to it.

The B<name> attribute is required.

Other attributes that are recognised:

=over

=item B<min> =E<gt> I<NUM>

The minimum valid value (by default an I<inclusive> boundary,
but see L<inclusive|/inclusive> below.

=item B<max> =E<gt> I<NUM>

The maximum valid value (by default an I<inclusive> boundary,
but see L<inclusive|/inclusive> below.

=item B<inclusive> =E<gt> I<BOOLEAN>

Default is 1 (true). Indicates whether minimum/maximum boundaries
are inclusive or exclusive.

=back

=back

=head1 ACCESSORS

Inherited from L<Term::CLI::Argument>(3p). Additionally, the
following are defined:

=over

=item B<min> ( I<NUMBER> )

=item B<max> ( I<NUMBER> )

Lower and upper boundaries, resp.

=item B<inclusive> ( I<BOOL> )

Boolean indicating whether the boundaries are inclusive.

=item B<has_min>

=item B<has_max>

Booleans, indicate whether C<min> and C<max> have been set, resp.

=item B<clear_min>

=item B<clear_max>

Clear the C<min> and C<max> limits, resp.

=back

=head1 METHODS

Inherited from L<Term::CLI::Argument>(3p).

Additionally:

=over

=item B<validate> ( I<VALUE> )

The L<validate|Term::CLI::Argument/validate> method uses the
L<coerce_value|/coerce_value> method to convert I<VALUE> to
a suitable number and then checks any boundaries.

=item B<coerce_value> ( I<VALUE> )

This method I<must> be overridden by sub-classes.

It will be called with a single argument (the I<VALUE>) and is
supposed to return the converted number. If the number is not
valid, it should return C<undef>.

=back

=head1 SEE ALSO

L<Term::CLI::Argument>(3p),
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

=cut
