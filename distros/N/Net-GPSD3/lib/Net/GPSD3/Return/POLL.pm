package Net::GPSD3::Return::POLL;
use strict;
use warnings;
use base qw{Net::GPSD3::Return::Unknown::Timestamp};

our $VERSION='0.18';

=head1 NAME

Net::GPSD3::Return::POLL - Net::GPSD3 Return POLL Object

=head1 SYNOPSIS

  use Net::GPSD3;
  use Data::Dumper qw{Dumper};
  my $gpsd = Net::GPSD3->new;
  my $poll = $gpsd->poll;
  print Dumper($poll);

=head1 DESCRIPTION

Provides a Perl object interface to the POLL object returned by the GPSD daemon.

=head1 METHODS

=head2 class

Returns the object class

=head2 string

Returns the JSON string

=head2 parent

Return the parent L<Net::GPSD3> object

=head2 time

=head2 timestamp

=head2 datetime

=head2 active

=cut

sub active {shift->{"active"}};

=head2 fix, tpv

Returns the first fix from the Fixes array or undef if none.

  my $fix=$poll->fix #isa Net::GPSD3::Return::TPV or undef

Note: I will try to keep this method consistant

=cut

sub fix {shift->Fixes->[0]};
sub tpv {shift->Fixes->[0]};

=head2 Fixes

Object wrapper around JSON data

  my $fix=$poll->Fixes #isa [] of Net::GPSD3::Return::TPV objects
  my @fix=$poll->Fixes #isa () of Net::GPSD3::Return::TPV objects

Note: I'm not sure why this is an array from the protocol but do not count on this staying the same

=cut

sub Fixes {
  my $self=shift;
  $self->{"Fixes"}=[map {$self->parent->constructor(%$_, string=>$self->parent->encode($_))} $self->_fixes]
    unless defined $self->{"Fixes"};
  return wantarray ? @{$self->{"Fixes"}} : $self->{"Fixes"};
}

sub _fixes {
  my $self=shift;
  $self->{"fixes"}=delete($self->{"tpv"}) if exists $self->{"tpv"}; #RT 73489
  $self->{"fixes"}=[] unless ref($self->{"fixes"}) eq "ARRAY";
  return wantarray ? @{$self->{"fixes"}} : $self->{"fixes"};
}

=head2 sky

Returns the first object from the Skyviews array or undef if none.

  my $sky=$poll->sky #isa Net::GPSD3::Return::SKY or undef

Note: I will try to keep this method consistant

=cut

sub sky {shift->Skyviews->[0]};

=head2 Skyviews

Object wrapper around JSON data

  my $sky=$poll->Skyviews #isa [] of Net::GPSD3::Return::SKY objects
  my @sky=$poll->Skyviews #isa () of Net::GPSD3::Return::SKY objects

Note: I'm not sure why this is an array from the protocol but do not count on this staying the same

=cut

sub Skyviews {
  my $self=shift;
  $self->{"Skyviews"}=[map {$self->parent->constructor(%$_, string=>$self->parent->encode($_))} $self->_skyviews]
    unless defined $self->{"Skyviews"};
  return wantarray ? @{$self->{"Skyviews"}} : $self->{"Skyviews"};
}

sub _skyviews {
  my $self=shift;
  $self->{"skyviews"}=delete($self->{"sky"}) if exists $self->{"sky"}; #RT 73489
  $self->{"skyviews"}=[] unless ref($self->{"skyviews"}) eq "ARRAY";
  return wantarray ? @{$self->{"skyviews"}} : $self->{"skyviews"};
}

=head2 Gst

Object wrapper around JSON data

  my $gst=$poll->Gst #isa [] of Net::GPSD3::Return::GST objects
  my @gst=$poll->Gst #isa () of Net::GPSD3::Return::GST objects

Note: I'm not sure why this is an array from the protocol but do not count on this staying the same

=cut

sub Gst {
  my $self=shift;
  $self->{"Gst"}=[map {$self->parent->constructor(%$_, string=>$self->parent->encode($_))} $self->_gst]
    unless defined $self->{"Gst"};
  return wantarray ? @{$self->{"Gst"}} : $self->{"Gst"};
}

sub _gst {
  my $self=shift;
  $self->{"gst"}=[] unless ref($self->{"gst"}) eq "ARRAY";
  return wantarray ? @{$self->{"gst"}} : $self->{"gst"};
}

=head1 BUGS

Log on RT and send to gpsd-dev email list

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

L<Net::GPSD3>, L<Net::GPSD3::Return::Unknown::Timestamp>

=cut

1;
