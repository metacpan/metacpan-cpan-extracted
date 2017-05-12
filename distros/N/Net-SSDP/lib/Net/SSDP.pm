use strict;
use warnings;

package Net::SSDP;

use Glib;
use parent qw/DynaLoader/;

our $VERSION = '0.02';

sub dl_load_flags { 0x01 }

__PACKAGE__->bootstrap($VERSION);

1;

__END__

=head1 NAME

Net::SSDP - Simple Service Discovery Protocol implementation

=head1 SYNOPSIS

  use Glib;
  use Net::SSDP;

  my $mainloop = Glib::MainLoop->new;
  my $client = Net::SSDP::Client->new($mainloop->get_context);

  my $browser = Net::SSDP::ResourceBrowser->new($client);

  $browser->signal_connect('resource-available' => sub {
      my ($browser, $usn, $locations) = @_;
      print "Resource $usn became available";
  });

  $browser->signal_connect('resource-unavailable' => sub {
      my ($browser, $usn) = @_;
      print "Resource $usn became unavailable";
  });

  $browser->set_active(1);

  $mainloop->run;

=head1 DESCRIPTION

This module is an implementation of the Simple Service Discovery Protocol
(SSDP). It allows network clients to discover and announce network services.
SSDP is the basis of Universal Plug and Play (UPnP).

=head1 SEE ALSO

L<Net::SSDP::Client>

L<Net::SSDP::ResourceBrowser>

L<Net::SSDP::ResourceGroup>

=head1 AUTHOR

Florian Ragwitz E<lt>rafl@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009  Florian Ragwitz

This is free software, licensed under:

  The GNU Lesser General Public License Version 2.1, February 1999

=cut
