#=============================================================================
#
#       Module:  Term::CLI::Argument::Bool
#
#  Description:  Class for "enum" arguments in Term::CLI
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

package Term::CLI::Argument::Bool  0.051007 {

use Modern::Perl 1.20140107;

use Types::Standard 1.000005 qw(
    ArrayRef
    Str
    Bool
);

use Term::CLI::L10N;

use Moo 1.000001;
use namespace::clean 0.25;

extends 'Term::CLI::Argument';

has 'true_values' => (
    is => 'rw',
    isa => ArrayRef[Str],
    default => sub { [qw( true 1 )] },
);

has 'false_values' => (
    is => 'rw',
    isa => ArrayRef[Str],
    default => sub { [qw( false 0 )] },
);

has 'ignore_case' => (
    is => 'rw',
    isa => Bool,
    default => sub { 1 },
);


sub validate {
    my $self  = shift;
    my $value = shift;

    defined $self->SUPER::validate($value) or return;

    my ($true, $false);

    if ($self->ignore_case) {
        $value = lc $value;

        $true = [ map { lc $_ } @{$self->true_values} ];
        $false = [ map { lc $_ } @{$self->false_values} ];
    }
    else {
        $true  = $self->true_values;
        $false = $self->false_values;
    }

    my @true_match = grep { rindex($_, $value, 0) == 0 } @$true;
    my @false_match = grep { rindex($_, $value, 0) == 0 } @$false;

    if (@true_match) {
        if (@false_match) {
            return $self->set_error(
                loc("ambiguous boolean value"
                    ." (matches ~[[_1]~] and ~[[_2]~])",
                    join(", ", @true_match),
                    join(", ", @false_match),
                )
            );
        }
        else {
            return 1;
        }
    }
    elsif (@false_match) {
        return 0;
    }

    return $self->set_error(loc("invalid boolean value"));
}


sub complete {
    my ($self, $value) = @_;

    my @values = ( @{$self->true_values}, @{$self->false_values} );

    if (!length $value) {
        return sort @values;
    }
    else {
        if ($self->ignore_case) {
            my @matches
                = sort
                    grep
                        { substr(lc $_, 0, length($value)) eq lc $value }
                        @values;

            return map { $value.substr($_, length($value)) } @matches;
        }
        else {
            return sort
                grep { substr($_, 0, length($value)) eq $value } @values;
        }
    }
}


}

1;

__END__

=pod

=head1 NAME

Term::CLI::Argument::Bool - class for "boolean" arguments in Term::CLI

=head1 VERSION

version 0.051007

=head1 SYNOPSIS

 use Term::CLI::Argument::Bool;

 # Case-insensitive booleans (default)
 my $arg = Term::CLI::Argument::Bool->new(
     name => 'arg1',
     ignore_case => 1, # default
 );

 $arg->validate( 'true' );  # -> returns 1
 $arg->validate( 'tRuE' );  # -> returns 1
 $arg->validate( '1' );     # -> returns 1

 $arg->validate( 'false' ); # -> returns 0
 $arg->validate( 'FaLsE' ); # -> returns 0
 $arg->validate( '0' );     # -> returns 0

 $arg->validate( 'never' ); # -> returns undef, sets error.

 # Case-sensitive booleans
 $arg = Term::CLI::Argument::Bool->new(
     name => 'arg1',
     ignore_case => 0,
 );

 $arg->validate( 'tRuE' );  # -> returns undef, sets error.
 $arg->validate( 'FaLsE' ); # -> returns undef, sets error.

 # Alternative booleans
 $arg = Term::CLI::Argument::Bool->new(
     name => 'arg1',
     true_values => ['on', 'yes'],
     false_values => ['off', 'no'],
 );

 $arg->validate( 'on' );    # -> returns 1
 $arg->validate( 'off' );   # -> returns 0

 # Abbreviation
 $arg->validate( 'y' );     # -> returns 1
 $arg->validate( 'n' );     # -> returns 0
 $arg->validate( 'o' );     # ambiguous -> returns undef, sets error.

=head1 DESCRIPTION

Class for "boolean" string arguments in L<Term::CLI>(3p).

This class inherits from
the L<Term::CLI::Argument>(3p) class.

By default, the valid strings for a boolean are:

=over

=item C<true>, C<1>

A true value.

=item C<false>, C<0>

A false value.

=back

=head2 Case-Insensitive Matching

By default, the object's L<validate()|/validate> and
L<complete()|/complete> methods ignore case, so C<FAlsE>
validates as "false", and C<TR> will have a completion of
C<TRue>.

Set the L<ignore_case|/ignore_case> flag to 0 to do
case-sensitive matching.

=head2 Abbreviations

The L<validate|/validate> method accepts abbreviations
as long as they are uniquely identifying either one or more
"true" values I<or> one or more "false" values.

For example, if you specify the following:

=over

=item B<true_values> =E<gt> [ B<"on">, B<"yes"> ]

=item B<false_values> =E<gt> [ B<"off">, B<"never">, B<"no"> ]

=back

Then the string C<o> will not validate since it matches both a "true"
value (C<on>) I<and> a "false" value (C<off>). On the other hand, the
string C<n> I<will> validate, for although it matches both C<never>
and C<no>, those values are both "false" values, so there is no ambiguity.

=head1 CLASS STRUCTURE

=head2 Inherits from:

L<Term::CLI::Argument>(3p).

=head2 Consumes:

None.

=head1 CONSTRUCTORS

=over

=item B<new> ( B<name> =E<gt> I<STRING>, ... )

See also L<Term::CLI::Argument>(3p).

Additional attributes:

=over

=item B<true_values> =E<gt> I<ArrayRef>[I<Str>]
X<true_values>

List of values that are considered to be "true". Default
is C<['true', '1']>.

=item B<false_values> =E<gt> I<ArrayRef>[I<Str>]
X<false_values>

List of values that are considered to be "false". Default
is C<['false', '0']>.

=item B<ignore_case> =E<gt> I<Bool>
X<ignore_case>

Whether or not matching should ignore case. Default is 1 (so C<True>
and C<FALSE> are valid as well).

=back

=back

=head1 ACCESSORS

See also L<Term::CLI::Argument>(3p).

=over

=item B<ignore_case> ( [ I<Bool> ] )
X<ignore_case>

Get or set the C<ignore_case> flag.

=item B<true_values> ( [ I<ArrayRef>[I<Str>] ] )
X<true_values>

Get or set the list of strings that denote a "true" value.

=item B<false_values> ( [ I<ArrayRef>[I<Str>] ] )
X<false_values>

Get or set the list of strings that denote a "false" value.

=back

=head1 METHODS

See also L<Term::CLI::Argument>(3p).

The following methods are added or overloaded:

=over

=item B<validate> ( I<Str> )

Validate I<Str> to see if it is a uniquely "true" or "false" value. Return
1 if it is a "true" value, 0 if it is a "false" value.

If the true/false validity cannot be determined, the object's C<error>
attribute is set and C<undef> is returned.

=item B<complete> ( I<Str> )

Return a list of possible completions for I<Str>. If C<ignore_case> is true,
then values like C<FA> will result in C<('FAlse')>.

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
