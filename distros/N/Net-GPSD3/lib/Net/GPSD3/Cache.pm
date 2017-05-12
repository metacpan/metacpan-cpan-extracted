package Net::GPSD3::Cache;
use strict;
use warnings;
use base qw{Net::GPSD3::Base};

our $VERSION='0.12';

=head1 NAME

Net::GPSD3::Cache - Net::GPSD3 caching object

=head1 SYNOPSIS

  use Net::GPSD3;
  my $cache=Net::GPSD3->cache; #isa Net::GPSD3::Cache
  $cache->add($obj);           #obj isa Net::GPSD3::Return::XXX 

=head1 DESCRIPTION

=head1 METHODS

=head2 add

Adds an object to the cache.

=cut

sub add {
  my $self=shift;
  my $obj=shift;
  if ($obj->can("class") and $self->can($obj->class)) {
    $self->{$obj->class}=$obj; 
  }
  return $self;
}

=head2 TPV

Returns the last L<Net::GPSD3::Return::TPV> object reported by gpsd.

=cut

sub TPV {shift->{"TPV"}};

=head2 SKY

Returns the last L<Net::GPSD3::Return::SKY> object reported by gpsd.

=cut

sub SKY {shift->{"SKY"}};

=head2 DEVICES

Returns the last L<Net::GPSD3::Return::DEVICES> object reported by gpsd.

=cut

sub DEVICES {shift->{"DEVICES"}};

=head2 VERSION

Returns the last L<Net::GPSD3::Return::VERSION> object reported by gpsd.

=cut

sub VERSION {shift->{"VERSION"}};

=head2 ERROR

Returns the last L<Net::GPSD3::Return::ERROR> object reported by gpsd.

=cut

sub ERROR {shift->{"ERROR"}};

=head2 WATCH

Returns the last L<Net::GPSD3::Return::WATCH> object reported by gpsd.

=cut

sub WATCH {shift->{"WATCH"}};

=head2 SUBFRAME

Returns the last L<Net::GPSD3::Return::SUBFRAME> object reported by gpsd.

=cut

sub SUBFRAME {shift->{"SUBFRAME"}};

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

L<Net::GPSD3>

=cut

1;
