#=============================================================================
#
#       Module:  Term::CLI::L10N::en
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  27/02/18
#
#   Copyright (c) 2018-2022 Steven Bakker; All rights reserved.
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#=============================================================================

package Term::CLI::L10N::en 0.055002;

use 5.014;
use warnings;

use parent 0.225 qw( Term::CLI::L10N );

## no critic (ProhibitPackageVars)
our %Lexicon = ( _AUTO => 1, );

1;

__END__

=pod

=head1 NAME

Term::CLI::L10N::en - English localizations for Term::CLI

=head1 VERSION

version 0.055002

=head1 SYNOPSIS

 use Term::CLI::L10N qw( loc );

 Term::CLI::L10N->set_language('en');

 say loc("invalid value"); # -> invalid value
 say Term::CLI::L10N->quant(1, 'guitar') ; # -> 1 guitar
 say Term::CLI::L10N->quant(2, 'guitar') ; # -> 2 guitars

=head1 DESCRIPTION

Provide English language strings for L<Term::CLI>(3p).

=head1 VARIABLES

=over

=item <%LEXICON>

Package variable containing the language mappings.
Contains C<_AUTO> mapped to C<1>, assuming that all
messages are written in English by default.

=back

=head1 SEE ALSO

L<Term::CLI>(3p),
L<Locale::Maketext>(3p),
L<Term::CLI::L10N>(3p).

=head1 AUTHOR

Steven Bakker E<lt>sbakker@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Steven Bakker; All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
