package Net::GPSD3::Return::Unknown::Timestamp;
use strict;
use warnings;
use base qw{Net::GPSD3::Return::Unknown};
use DateTime::Format::W3CDTF;
use DateTime;

our $VERSION='0.18';

=head1 NAME

Net::GPSD3::Return::Unknown::Timestamp - Net::GPSD3 Return Base Class with Timestamp

=head1 SYNOPSIS

  package XXX;
  use base qw{Net::GPSD3::Return::Unknown::Timestamp};

=head1 DESCRIPTION

Provides a time, timestamp and datetime methods to a GPSD3 Return object.

=head1 METHODS

=head2 time

Seconds since the Unix epoch, UTC.  The value may have a fractional part of up to .01sec precision.

Note: In 2.96 (protocol 3.4) the TPV->time format changed from unix epoch to W3C, but this method attempts to hide that change from the user.

Since the POSIX standard for the Unix epoch does not use leap seconds but GPS system does I do not recommend that you use this method for time display or storage.  This method is purely here for backwards compatibility.

=cut

sub time {
  my $self=shift;
  #protocol < 3.4
  $self->timestamp unless defined $self->{"_time"};
  $self->{"_time"}=$self->datetime->hires_epoch unless defined $self->{"_time"};
  return $self->{"_time"};
}

=head2 timestamp

W3C formated timestamp value either directly from the protocol >= 3.4 or calculated < 3.4.  The value may have a fractional part of up to .01sec precision.

Note: I expect that in protocol 3.5 the value will be passed directly as TPV->timestamp

=cut

sub timestamp {
  my $self=shift;
  unless (defined $self->{"_timestamp"}) {
    my $qr=qr/\A\d{4}\-\d{2}\-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d*)?Z\Z/;
    if (defined($self->{"timestamp"}) and $self->{"timestamp"} =~ $qr) {
      #protocol 3.5 (expected)
      $self->{"_timestamp"}=$self->{"timestamp"}
    } elsif (defined($self->{"time"}) and $self->{"time"} =~ $qr) {
      #protocol 3.4
      $self->{"_timestamp"}=$self->{"time"};
    } elsif (defined($self->{"time"}) and $self->{"time"} =~ m/^\d{1,}(?:\.\d*)?$/) {
      #protocol < 3.4
      $self->{"_time"}=$self->{"time"} unless defined $self->{"_time"};
      $self->{"_timestamp"}=$self->datetime->strftime(q{%FT%T.%2NZ}); #%2N truncates should round DateTime 0.66
    } else {
      die("Error: Either TPV->timestamp or TPV->time must be defined.");
    }
  }
  return $self->{"_timestamp"};
}

=head2 datetime

Returns a L<DateTime> object

=cut

sub datetime {
  my $self=shift;
  unless (defined($self->{"datetime"})) {
    my $timestamp=$self->{"_timestamp"} ||
                  $self->{"timestamp"}  || #protocol >= 3.5 (expected)
                  undef;
    if (defined $timestamp) {
      $self->{"datetime"}=DateTime::Format::W3CDTF->new->parse_datetime($timestamp);
      $self->{"_time"}=$self->datetime->hires_epoch unless defined $self->{"_time"};
    } elsif (defined $self->{"_time"}) {
      $self->{"datetime"}=DateTime->from_epoch(epoch=>$self->{"_time"}, time_zone=>"UTC");
    } elsif ($self->timestamp) { #infinate loop potential
      $self->{"datetime"}=DateTime::Format::W3CDTF->new->parse_datetime($self->timestamp);
    } else {
      die("Error: Either TPV->timestamp or TPV->time must be defined.");
    }
  }
  return $self->{"datetime"};
}

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

L<Net::GPSD3>, L<Net::GPSD3::Return::Unknown>, L<DateTime::Format::W3CDTF>, L<DateTime>

=cut

1;
