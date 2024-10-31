#
# $Id: Splitsubnet.pm,v 462dcd9243b5 2024/10/31 09:09:10 gomor $
#
package OPP::Proc::Splitsubnet;
use strict;
use warnings;

use base qw(OPP::Proc);
__PACKAGE__->cgBuildIndices;

our $VERSION = '1.00';

use Regexp::IPv4;
use Regexp::IPv6;
use Net::IPv4Addr qw(ipv4_broadcast);
use Socket qw(inet_aton inet_ntoa);
my $ipv4_re = qr/^${Regexp::IPv4::IPv4_re}$/;
my $ipv6_re = qr/^${Regexp::IPv6::IPv6_re}$/;

#
# | splitsubnet
# | splitsubnet subnetfield
#
sub process {
   my $self = shift;
   my ($input) = @_;

   my $options = $self->options;
   my $field = $options->{0} || 'subnet';

   my $values = $self->value($input, $field);
   unless ($values) {  # No field by that name, don't touch
      $self->output->add($input);
      return 1;
   }

   if (@$values > 1) {  # Don't handle that, don't touch
      $self->output->add($input);
      return 1;
   }

   my $v = $values->[0];
   my ($subnet, $cidr) = $v =~ m{^([^/]+)/(\d+)$};
   unless ($subnet =~ $ipv4_re) {  # IPv6 not handled yet, don't touch
      $self->output->add($input);
      return 1;
   }
   unless ($cidr < 16) {  # Mask is ok, don't touch
      $self->output->add($input);
      return 1;
   }

   # Mask is < 16, we split into multiple docs:
   my $count = 2 ** (32 - $cidr);
   my $chunks = $count / 65536;  # Chunk by X number of /16
   my $this_subnet = $subnet.'/16';
   for (1..$chunks) {
      my $clone = $self->clone($input);
      $self->set($clone, $field, $this_subnet);
      $self->output->add($clone);
      # Prepare for next round:
      my $last = ipv4_broadcast($this_subnet);
      my $last_int = CORE::unpack('N', inet_aton($last)) + 1;
      $this_subnet = inet_ntoa(pack('N', $last_int)).'/16';
   }

   return 1;
}

1;

__END__

=head1 NAME

OPP::Proc::Splitsubnet - splitsubnet processor

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024, ONYPHE SAS

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
