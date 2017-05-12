package SOAP::DateTime;
use strict;
use Date::Manip;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.02;
	@ISA         = qw (Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw (ConvertDate);
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}


=head1 NAME

SOAP::DateTime - Support for converting dates to C<xsd:dateTime> format

=head1 SYNOPSIS

  use SOAP::DateTime;
  my $soap_datetime = ConvertDate($arbitrary_date);

=head1 DESCRIPTION

C<SOAP::DateTime> converts dates into the format required by the 
C<xsd:dateTime> type.

=head1 USAGE

See the synopsis for an example. Date parsing is handled with C<Date::Manip>,
so the date format used as input is ridiculously flexible.

=head1 BUGS

None known.

=head1 SUPPORT

Contact the author for support.

=head1 AUTHOR

	Joe McMahon
	CPAN ID: MCMAHON
	mcmahon@ibiblio.org
	http://a.galaxy.far.far.away/modules

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1), Date::Manip(1).

=head2 ConvertDate($date)

Accepts the date (in any C<Date::Manip>-supported format) and returns a date
in the format I<YYYY>-I<MM>-I<DD>TI<HH>:I<MM>:I<SS>; so, for example, 
December 14 1984 12:14:37 would be 1984-12-14T12:14:37.

=cut

sub ConvertDate {
  my $date = shift;
  die "No date supplied\n" unless $date;
  my $parsed = ParseDate($date);
  die "Unparseable date\n" unless $parsed;
  UnixDate($parsed,"%Y-%m-%dT%H:%M:%S");
}

1; #this line is important and will help the module return a true value
__END__

