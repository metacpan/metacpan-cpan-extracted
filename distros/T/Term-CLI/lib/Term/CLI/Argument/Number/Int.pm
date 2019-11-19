#=============================================================================
#
#       Module:  Term::CLI::Argument::Number::Int
#
#  Description:  Class for integer arguments in Term::CLI
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

package Term::CLI::Argument::Number::Int  0.051007 {

use Modern::Perl 1.20140107;
use Moo 1.000001;
use namespace::clean 0.25;

extends 'Term::CLI::Argument::Number';

sub coerce_value {
    my $val = $_[1];

    if ($val =~ /^[+-]?\d+$/) {
        return int($val);
    }
    return undef;
}

}

1;

__END__

=pod

=head1 NAME

Term::CLI::Argument::Number::Int - class for integer arguments in Term::CLI

=head1 VERSION

version 0.051007

=head1 SYNOPSIS

 use Term::CLI::Argument::Number::Int;

 my $arg = Term::CLI::Argument::Number::Int->new(
                name => 'count',
                min => 0,
                max => 100_000,
                inclusive => 1
           );

=head1 DESCRIPTION

Class for integer arguments in L<Term::CLI>(3p). Extends
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

Overloaded to check for a valid integer value.

=back

=head1 SEE ALSO

L<Term::CLI::Argument::Number::Float>(3p),
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
