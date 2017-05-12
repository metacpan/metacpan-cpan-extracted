#
# $Id: Lorcon2.pm 31 2015-02-17 07:04:36Z gomor $
#
package Net::Lorcon2;
use strict; use warnings;

our $VERSION = '2.03';

use Class::Gomor::Array;
use base qw(Exporter DynaLoader Class::Gomor::Array);

use constant LORCON_EGENERIC => -1;
use constant LORCON_ENOTSUPP => -255;

our %EXPORT_TAGS = (
   consts => [qw(
      LORCON_EGENERIC
      LORCON_ENOTSUPP
   )],
   subs => [qw(
      lorcon_list_drivers
      lorcon_find_driver
      lorcon_get_datalink
      lorcon_create
      lorcon_get_error
      lorcon_open_inject
      lorcon_send_bytes
   )],
);

our @EXPORT = (
   @{$EXPORT_TAGS{consts}},
   @{$EXPORT_TAGS{subs}},
);

__PACKAGE__->bootstrap($VERSION);

our @AS = qw(
   driver
   interface
   _drv
   _context
);

__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildIndices;

sub new {
   my $self = shift->SUPER::new(
      driver    => "mac80211",
      interface => "wlan0",
      @_,
   );
   my $drv = lorcon_find_driver($self->driver);
   if (! $drv) {
      print STDERR "[-] new: lorcon_find_driver: failed\n";
      return;
   }
   $self->_drv($drv);
   my $context = lorcon_create($self->interface, $self->_drv);
   if (! $context) {
      print STDERR "[-] new: lorcon_create: failed\n";
      return;
   }
   $self->_context($context);
   return $self;
}

sub setInjectMode {
   my $self = shift;
   my $r = lorcon_open_inject($self->_context);
   if ($r == -1) {
      print STDERR "[-] setInjectMode: lorcon_open_inject: ".lorcon_get_error($self->_context)."\n";
      return;
   }
   return 1;
}

sub sendBytes {
   my $self = shift;
   my ($bytes) = @_;
   my $r = lorcon_send_bytes($self->_context, length($bytes), $bytes);
   if ($r < 0) {
      print STDERR "[-] sendBytes: lorcon_send_bytes: ".lorcon_get_error($self->_context)."\n";
      return;
   }
   return $r;
}

sub DESTROY {
   my $self = shift;
   if (defined($self->_context)) {
      print STDERR "DEBUG: lorcon_DESTROY\n";
      lorcon_close($self->_context);
      lorcon_free($self->_context);
   }
}

1;

__END__

=head1 NAME

Net::Lorcon2 - Raw wireless packet injection using the Lorcon2 library

=head1 SYNOPSIS

  use Net::Lorcon2 qw(:subs);

  my $if     = "wlan0";
  my $driver = "mac80211";
  my $packet = "G"x100;

  #
  # Usage in an OO-way
  #

  my $lorcon = Net::Lorcon2->new(
     interface => $if,
     driver    => $driver,
  );

  $lorcon->setInjectMode;

  my $t = $lorcon->sendBytes($packet);
  if (! $t) {
     print "[-] Unable to send bytes\n";
     exit 1;
  }

  #
  # Usage with lorcon2 library API
  #

  my $drv = lorcon_find_driver($driver);
  if (! $drv) {
     print STDERR "[-] Unable to find DRV for [$driver]\n";
     exit 1;
  }

  my $lorcon = lorcon_create($if, $drv);
  if (! $lorcon) {
    print STDERR "[-] lorcon_create failed\n";
    exit 1;
  }

  my $r = lorcon_open_inject($lorcon);
  if ($r == -1) {
    print STDERR "[-] lorcon_open_inject: ".lorcon_get_error($lorcon)."\n";
    exit 1;
  }

  my $t = lorcon_send_bytes($lorcon, length($packet), $packet);
  print "T: $t\n";

=head1 DESCRIPTION

This module enables raw 802.11 packet injection provided you have a Wi-Fi card
supported by Lorcon2.

Lorcon2 can be obtained from L<http://802.11ninja.net/svn/lorcon/>.

This version has been tested against the following revision:

L<http://802.11ninja.net/svn/lorcon/tags/lorcon2-200911-rc1>

=head1 FUNCTIONS

=over 4

=item B<lorcon_add_wepkey>

=item B<lorcon_auto_driver>

=item B<lorcon_close>

=item B<lorcon_create>

=item B<lorcon_find_driver>

=item B<lorcon_free>

=item B<lorcon_free_driver_list>

=item B<lorcon_get_capiface>

=item B<lorcon_get_channel>

=item B<lorcon_get_driver_name>

=item B<lorcon_get_error>

=item B<lorcon_get_selectable_fd>

=item B<lorcon_get_timeout>

=item B<lorcon_get_vap>

=item B<lorcon_get_version>

=item B<lorcon_inject>

=item B<lorcon_list_drivers>

=item B<lorcon_open_inject>

=item B<lorcon_open_injmon>

=item B<lorcon_open_monitor>

=item B<lorcon_send_bytes>

=item B<lorcon_set_channel>

=item B<lorcon_set_filter>

=item B<lorcon_set_timeout>

=item B<lorcon_set_vap>

=back

=head1 METHODS

=over 4

=item B<new>(device, driver) 

Constructs a new C<Net::Lorcon2> object. C<device> is the name of the device to
use for packet injection. C<driver> is the driver to use (one of the names
returned from getcardlist)

=item B<setInjectMode> ()

Sets the inject mode for the card.

=item B<sendBytes> (data)

Send raw data in the air.

=back

=head1 CONSTANTS

Load them: use Net::Lorcon2 qw(:consts);

=over 4

=item B<LORCON_EGENERIC>

=item B<LORCON_ENOTSUPP>

=back

=head1 SEE ALSO

L<lorcon2(7)>, 802.11 Wireless Networks by Matthew Gast.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret, E<lt>gomor at cpan dot orgE<gt> (current maintainer and developper of Net::Lorcon2)

David Leadbeater, E<lt>dgl at dgl dot cxE<gt> (original author)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2015 by Patrice E<lt>GomoRE<gt> Auffret

Copyright (C) 2007-2008 by David Leadbeater and Patrice E<lt>GomoRE<gt> Auffret

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
