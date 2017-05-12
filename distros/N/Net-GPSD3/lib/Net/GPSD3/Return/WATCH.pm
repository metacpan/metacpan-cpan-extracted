package Net::GPSD3::Return::WATCH;
use strict;
use warnings;
use base qw{Net::GPSD3::Return::Unknown};

our $VERSION='0.14';

=head1 NAME

Net::GPSD3::Return::WATCH - Net::GPSD3 Return WATCH Object

=head1 SYNOPSIS

=head1 DESCRIPTION

Provides a Perl object interface to the WATCH object returned by the GPSD daemon.

=head1 METHODS

=head2 class

Returns the object class

=head2 string

Returns the JSON string

=head2 parent

Return the parent L<Net::GPSD3> object

=head2 enabled

=cut

sub enabled {
  my $self=shift;
  return $self->{"enable"} || $self->{"enabled"}; #reverse once we move to the new protocol expected 3.5
}


=head2 enable (deprecated)

=cut

sub enable {shift->enabled(@_)}; #bad protocol name

=head2 json

=cut

sub json {shift->{"json"}};

=head2 nmea

=cut

sub nmea {shift->{"nmea"}};

=head2 raw

=cut

sub raw {shift->{"raw"}};

=head2 scaled

=cut

sub scaled {shift->{"scaled"}};

=head2 timing

=cut

sub timing {shift->{"timing"}};

=head1 BUGS

Log on RT and Send to gpsd-dev email list

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

Try gpsd-dev email list

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  STOP, LLC
  domain=>michaelrdavis,tld=>com,account=>perl
  http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<Net::GPSD3>, L<Net::GPSD3::Return::Unknown>

=cut

1;
