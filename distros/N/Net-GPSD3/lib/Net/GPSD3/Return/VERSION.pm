package Net::GPSD3::Return::VERSION;
use strict;
use warnings;
use base qw{Net::GPSD3::Return::Unknown};

our $VERSION='0.14';

=head1 NAME

Net::GPSD3::Return::VERSION - Net::GPSD3 Return VERSION Object

=head1 SYNOPSIS

  use Net::GPSD3;
  my $gpsd=Net::GPSD3->new;
  $gpsd->poll; #Sets VERSION and DEVICES in cache
  my $v=$gpsd->cache->VERSION;
  printf "Class: %s\nRelease: %s\nRevision: %s\nProtocol: %s\n", 
         $v->class,
         $v->release,
         $v->revision,
         $v->protocol;

Returns something like this.

  Class: VERSION
  Release: 2.96~dev
  Revision: 2011-03-17T02:51:23
  Protocol: 3.4

=head1 DESCRIPTION

Provides a Perl object interface to the VERSION object returned by the GPSD daemon.

=head1 METHODS

=head2 class

Returns the object class

=head2 string

Returns the JSON string

=head2 parent

Return the parent L<Net::GPSD3> object

=head2 release

=cut

sub release {shift->{"release"}};

=head2 rev, revision

=cut

*revision=\&rev;

sub rev {shift->{"rev"}};

=head2 proto, protocol

=cut

*protocol=\&proto;

sub proto {
  my $self=shift;
  return join(".", $self->proto_major, $self->proto_minor);
}

=head2 proto_major

=cut

sub proto_major {shift->{"proto_major"}};

=head2 proto_minor

=cut

sub proto_minor {shift->{"proto_minor"}};

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
