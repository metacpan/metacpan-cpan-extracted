#=============================================================================
#
#       Module:  Term::CLI::Element
#
#  Description:  Generic parent class for elements in Term::CLI
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

package Term::CLI::Element  0.051007 {

use Modern::Perl 1.20140107;
use Term::CLI::ReadLine;

use Types::Standard 1.000005 qw( Str );

use Moo 1.000001;
use namespace::clean 0.25;

extends 'Term::CLI::Base';

sub complete { return () }

}

1;

__END__

=pod

=head1 NAME

Term::CLI::Element - generic parent class for elements in Term::CLI

=head1 VERSION

version 0.051007

=head1 SYNOPSIS

 use Term::CLI::Element;

 my $arg = Term::CLI::Element->new(name => 'varname');

=head1 DESCRIPTION

Generic parent class for command line elements in L<Term::CLI>(3p).
This is used by L<Term::CLI::Command>(3p) and L<Term::CLI::Argument>(3p)
to provide basic, shared functionality.

This class inherits from L<Term::CLI::Base>(3p) to provide the
C<error>, C<term>, and C<set_error> methods.

=head1 CLASS STRUCTURE

=head2 Inherits from:

L<Term::CLI::Base>(3p).

=head2 Consumes:

None.

=head1 CONSTRUCTORS

=over

=item B<new> ( B<name> =E<gt> I<VARNAME> ... )
X<new>

Create a new Term::CLI::Element object and return a reference to it.

The B<name> attribute is required.

=back

=head1 METHODS

The C<Term::CLI::Element> inherits from accessors
and methods from L<Term::CLI::Base>(3p).

In addition, it defines:

=over

=item B<complete> ( I<STR> )

Return a list of strings that are possible completions for I<value>.
By default, this method returns an empty list.

Sub-classes should probably override this.

=back

=head1 SEE ALSO

L<Term::CLI>(3p),
L<Term::CLI::Argument>(3p),
L<Term::CLI::Base>(3p),
L<Term::CLI::Command>(3p),
L<Term::CLI::ReadLine>(3p).

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
