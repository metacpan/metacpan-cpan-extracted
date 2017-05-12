package PerlMongers::Warszawa;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use warnings;
use strict;
require Exporter;
#======================================================================
$VERSION = '0.1';
@ISA = qw(Exporter);
@EXPORT_OK = qw(Perl_Mongers);
#======================================================================
sub info {
	system('perldoc', __PACKAGE__);
}
#======================================================================
1;


=head1 NAME

PerlMongers::Warszawa.pm


=head1 SYNOPSIS

	use PerlMongers::Warszawa qw(info);
	
	info();

=head1 DESCRIPTION

Oficjalne zgromadzenie Perl Mongers w Warszawie zrzeszające programistów języków dynamicznych (głównie oczywiście Perl), fanatyków i mistyków Wielbłąda, a także wszystkich, którzy chcą zdobywać doświadczenie, rozwijać się oraz dobrze bawić.

=head1 SUBROUTINES/METHODS

=over 4

=item B<info( )>

Wyświatla tę jakże użyteczną informację :-)

=back

=head1 DEPENDENCIES

=over 4

=item Perl :P

=item Exporter

=back


=head1 INCOMPATIBILITIES

Brak.

=head1 BUGS AND LIMITATIONS

Też brak. Naprawdę!

=head1 SEE ALSO

http://warszawa.pm.org

=head1 AUTHOR

Strzelecki Łukasz <strzelec@rswsystems.com>

=head1 LICENCE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

