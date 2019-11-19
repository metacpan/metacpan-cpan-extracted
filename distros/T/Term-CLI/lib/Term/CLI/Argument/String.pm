#=============================================================================
#
#       Module:  Term::CLI::Argument::String
#
#  Description:  Class for arbitrary string arguments in Term::CLI
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

package Term::CLI::Argument::String  0.051007 {

use Modern::Perl 1.20140107;

use Term::CLI::L10N;

use Types::Standard 1.000005 qw( Int );

use Moo 1.000001;
use namespace::clean 0.25;

extends 'Term::CLI::Argument';

has min_len   => ( is => 'rw', isa => Int, clearer => 1, predicate => 1 );
has max_len   => ( is => 'rw', isa => Int, clearer => 1, predicate => 1 );

sub validate {
    my ($self, $value) = @_;

    $self->set_error('');

    if (!defined $value) {
        return $self->set_error(loc('value must be defined'));
    }

    if ($self->has_min_len && length $value < $self->min_len) {
        return $self->set_error(
            loc("too short (min. length [_1])", $self->min_len)
        );
    }
    elsif ($self->has_max_len && length $value > $self->max_len) {
        return $self->set_error(
            loc("too long (max. length [_1])", $self->max_len)
        );
    }
    return $value;
}

}

1;

__END__

=pod

=head1 NAME

Term::CLI::Argument::String - class for basic string arguments in Term::CLI

=head1 VERSION

version 0.051007

=head1 SYNOPSIS

 use Term::CLI::Argument::String;

 my $arg1 = Term::CLI::Argument::String->new(
    name => 'arg1'
 );

 $arg1->validate('');      # returns ''
 $arg1->validate('a');     # returns 'a'
 $arg1->validate('abcde'); # returns 'abcde'

 my $arg2 = Term::CLI::Argument::String->new(
    name => 'arg2'
    min_length => 1,
    max_length => 4,
 );

 $arg2->validate('');      # returns undef, sets error
 $arg2->validate('a');     # returns 'a'
 $arg2->validate('abcde'); # returns undef, sets error

=head1 DESCRIPTION

Simple class for string arguments in L<Term::CLI>(3p). This is basically
the L<Term::CLI::Argument>(3p) class, but also allowing empty strings.

=head1 CLASS STRUCTURE

=head2 Inherits from:

L<Term::CLI::Argument>(3p).

=head2 Consumes:

None.

=head1 CONSTRUCTORS

See L<Term::CLI::Argument>(3p). Additional attributes are:

=over

=item B<min_len> =E<gt> I<NUM>

The minimum required length for any value.

=item B<max_len> =E<gt> I<NUM>

The maximum lenght allowed for any value.

=back

=head1 ACCESSORS

Inherited from L<Term::CLI::Argument>(3p). Additionally, the
following are defined:

=over

=item B<min_len> ( I<NUMBER> )

=item B<max_len> ( I<NUMBER> )

Minimum and maximum length for the string, resp.

=item B<has_min_len>

=item B<has_max_len>

Booleans, indicate whether C<min_len> and C<max_len> have been set,
resp.

=item B<clear_min_len>

=item B<clear_max_len>

Clear the C<min_len> and C<max_len> limits, resp.

=back

See L<Term::CLI::Argument>(3p).

=head1 METHODS

See L<Term::CLI::Argument>(3p).

=over

=item B<validate> ( I<Str> )

Overloaded from L<Term::CLI::Argument>.

Requires the I<Str> value to be defined, and have a length
that is between C<min_len> and C<max_len> (if defined).

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
