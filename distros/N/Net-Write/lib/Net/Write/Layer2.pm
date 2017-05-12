#
# $Id: Layer2.pm 2005 2015-01-23 06:56:13Z gomor $
#
package Net::Write::Layer2;
use strict;
use warnings;

use base qw(Net::Write::Layer);
__PACKAGE__->cgBuildIndices;

no strict 'vars';

use Net::Pcap;

sub new {
   my $self = shift->SUPER::new(
      @_,
   ) or return;

   if (! $self->[$__dev]) {
      print STDERR "[-] @{[(caller(0))[3]]}: you must pass `dev' parameter\n";
      return;
   }

   return $self;
}

sub open {
   my $self = shift;

   my $err;
   my $pd = Net::Pcap::open_live(
      $self->[$__dev],
      0,
      0,
      1000,
      \$err,
   );
   unless ($pd) {
      print STDERR "[-] @{[(caller(0))[3]]}: Net::Pcap::open_live: ".
                   "@{[$self->dev]}: $err\n";
      return;
   }

   $self->[$___io] = $pd;

   return 1;
}

sub send {
   my $self = shift;
   my ($raw) = @_;

   while (1) {
      if (Net::Pcap::sendpacket($self->[$___io], $raw) < 0) {
         if ($!{ENOBUFS}) {
            $self->cgDebugPrint(2, "ENOBUFS, sleeping for 1 second");
            sleep 1;
            next;
         }
         elsif ($!{EHOSTDOWN}) {
            $self->cgDebugPrint(2, "host is down");
            last;
         }
         print STDERR "[!] @{[(caller(0))[3]]}: ".
                      Net::Pcap::geterr($self->[$___io])."\n";
         return;
      }
      last;
   }

   return 1;
}

sub close {
   my $self = shift;
   if ($self->[$___io]) {
      Net::Pcap::close($self->[$___io]);
      $self->[$___io] = undef;
   }
}

1;

__END__

=head1 NAME

Net::Write::Layer2 - object for a link layer (layer 2) descriptor

=head1 SYNOPSIS

   use Net::Write::Layer2;

   my $desc = Net::Write::Layer2->new(
      dev => 'eth0',
   );

   $desc->open;
   $desc->send('G'x666);
   $desc->close;

=head1 DESCRIPTION

This is the class for creating a layer 2 descriptor.

=head1 ATTRIBUTES

=over 4

=item B<dev>

The string specifying network interface to use.

Under Unix-like systems, this is in this format: \w+\d+ (example: eth0).

Under Windows systems, this is more complex; example:
\Device\NPF_{0749A9BC-C665-4C55-A4A7-34AC2FBAB70F}

=back

=head1 METHODS

=over 4

=item B<new>

Object constructor. You MUST pass a valid B<dev> attribute. There is no default value. Returns undef on error.

=item B<open>

Open the interface. Returns undef on error.

=item B<send> (scalar)

Send raw data to the network.

=item B<close>

Close the descriptor.

=back

=head1 CAVEATS

Writing junk to loopback interface on BSD systems will not work.

=head1 SEE ALSO

L<Net::Write::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
