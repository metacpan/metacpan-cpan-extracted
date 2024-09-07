#=============================================================================
#
#       Module:  Term::CLI::Argument::Number::Float
#
#  Description:  Class for floating point arguments in Term::CLI
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

package Term::CLI::Argument::Number::Float 0.060000;

use 5.014;
use warnings;

use Scalar::Util 1.23 qw( looks_like_number );

use Moo 1.000001;
use namespace::clean 0.25;

extends 'Term::CLI::Argument::Number';

sub coerce_value {
    my ( $self, $arg ) = @_;
    if ( looks_like_number($arg) ) {
        return $arg + 0.0;
    }
    ## no critic (ProhibitExplicitReturnUndef)
    return undef;
}

1;

__END__

=pod

=head1 NAME

Term::CLI::Argument::Number::Float - class for floating point arguments in Term::CLI

=head1 VERSION

version 0.060000

=head1 SYNOPSIS

 use Term::CLI::Argument::Number::Float;

 my $arg = Term::CLI::Argument::Number::Float->new(
                name => 'index',
                min => -1.0,
                max => +1.0,
                inclusive => 1
           );

=head1 DESCRIPTION

Class for floating point arguments in L<Term::CLI>(3p). Extends
L<Term::CLI::Argument::Number>(3p).

=head2 Inherits from:

L<Term::CLI::Argument::Number>(3p).

=head2 Consumes:

None.

=head1 CONSTRUCTORS

See L<Term::CLI::Argument::Number>(3p).

=head1 ACCESSORS

See L<Term::CLI::Argument::Number>(3p).

=head1 METHODS

Inherited from
L<Term::CLI::Argument::Number>(3p).

Additionally:

=over

=item B<coerce_value> ( I<VALUE> )

Overloaded to check for a valid numerical value (using
L<Scalar::Util's looks_like_number|Scalar::Util/looks_like_number>).

=back

=head1 SEE ALSO

L<Scalar::Util>(3p),
L<Term::CLI::Argument::Number::Int>(3p),
L<Term::CLI::Argument::Number>(3p),
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
