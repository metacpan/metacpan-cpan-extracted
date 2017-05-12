package Net::GPSD3::Return::DEVICES;
use strict;
use warnings;
use base qw{Net::GPSD3::Return::Unknown};

our $VERSION='0.12';

=head1 NAME

Net::GPSD3::Return::DEVICES - Net::GPSD3 Return DEVICES Object

=head1 SYNOPSIS

=head1 DESCRIPTION

Provides a Perl object interface to the DEVICE object returned by the GPSD daemon.

=head1 METHODS

=head2 class

Returns the object class

=head2 string

Returns the JSON string

=head2 parent

Return the parent Net::GPSD object

=head2 devices

Returns a list of device data structures.

  my @device=$devices->devices; #({},...)
  my @device=$devices->devices; #[{},...]

=cut

sub devices {
  my $self=shift;
  $self->{"devices"}=[] unless ref($self->{"devices"}) eq "ARRAY";
  return wantarray ? @{$self->{"devices"}} : $self->{"devices"};
}

=head2 Devices

Returns a list of L<Net::GPSD3::Return::DEVICES> objects.

  my @device=$devices->Devices; #(bless{},...)
  my @device=$devices->Devices; #[bless{},...]

=cut

sub Devices {
  my $self=shift;
  unless (defined $self->{"Devices"}) {
    $self->{"Devices"}=[
      map {$self->parent->constructor(%$_, string=>$self->parent->encode($_))}
        grep {ref($_) eq "HASH"} $self->devices];
  }
  return wantarray ? @{$self->{"Devices"}} : $self->{"Devices"};
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

L<Net::GPSD3>, L<Net::GPSD3::Return::Unknown>

=cut

1;
