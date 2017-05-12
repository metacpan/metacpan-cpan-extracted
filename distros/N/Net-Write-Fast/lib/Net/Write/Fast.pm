#
# $Id: Fast.pm,v 83433f6e04ef 2016/02/04 06:28:41 gomor $
#
package Net::Write::Fast;
use strict;
use warnings;

use base qw(Exporter DynaLoader);

our $VERSION = '0.18';

__PACKAGE__->bootstrap($VERSION);

our %EXPORT_TAGS = (
   consts => [qw(
   )],
   subs => [qw(
      estimate_runtime
      runtime_as_string
   )],
   vars => [qw(
   )],
);

our @EXPORT_OK = (
   @{$EXPORT_TAGS{vars}},
   @{$EXPORT_TAGS{consts}},
   @{$EXPORT_TAGS{subs}},
);

use Time::Interval;

sub estimate_runtime {
   my ($info) = @_;

   if (! defined($info)) {
      print STDERR "[-] estimate_runtime: give HASHREF\n";
      return;
   }

   if (! exists($info->{ports})
   ||  ! exists($info->{targets})
   ||  ! exists($info->{try})
   ||  ! exists($info->{pps})) {
      print STDERR "[-] estimate_runtime: info HASHREF not complete\n";
      return;
   }

   my $nports = scalar(@{$info->{ports}});
   my $nhosts = scalar(@{$info->{targets}});
   my $try = $info->{try};
   my $pps = $info->{pps};

   my $estim = Time::Interval::parseInterval(
      seconds => $try * $nports * $nhosts / $pps,
   );

   return {
      days => $estim->{days},
      hours => $estim->{hours},
      minutes => $estim->{minutes},
      seconds => $estim->{seconds},
      nhosts => $nhosts,
   };
}

sub runtime_as_string {
   my ($info) = @_;

   if (! defined($info)) {
      print STDERR "[-] runtime_as_string: give HASHREF\n";
      return;
   }

   if (! exists($info->{days})
   ||  ! exists($info->{hours})
   ||  ! exists($info->{minutes})
   ||  ! exists($info->{seconds})
   ||  ! exists($info->{nhosts})) {
      print STDERR "[-] runtime_as_string: info HASHREF not complete\n";
      return;
   }

   my $string = sprintf(
      "Estimated runtime: %d day(s) %d hour(s) %d minute(s) %d second(s) for %d host(s)",
         $info->{days},
         $info->{hours},
         $info->{minutes},
         $info->{seconds},
         $info->{nhosts},
   );

   return $string;
}

1;

__END__

=head1 NAME

Net::Write::Fast - create and inject packets fast

=head1 SYNOPSIS

   use Net::Write::Fast;

   # Sends multiple TCP SYNs to multiple IPv4 targets
   my $r = Net::Write::Fast::l4_send_tcp_syn_multi(
      "127.0.0.1",                  # IPv4 source
      [ '127.0.0.2', '127.0.0.3' ], # IPv4 targets
      [ 25, 80, 110 ],              # TCP port targets
      200,                          # Number of packet per second
      3,                            # Number of try
      0,                            # Use IPv6
      0,                            # OPTIONAL: enable warnings flag
   );

   # Sends multiple TCP SYNs to multiple IPv6 targets
   my $r = Net::Write::Fast::l4_send_tcp_syn_multi(
      "::1",            # IPv6 source
      [ '::2', '::3' ], # IPv6 targets
      [ 25, 80, 110 ],  # TCP port targets
      200,              # Number of packet per second
      3,                # Number of try
      1,                # Use IPv6
      0,                # OPTIONAL: enable warnings flag
   );

   # Handle errors
   if ($r == 0) {
      print STDERR "ERROR: ",Net::Write::Fast::nwf_geterror(),"\n";
   }

=head1 DESCRIPTION

Sends network frames fast to the network.

=head1 ENOBUFS ERRORS

If you got some ENOBUFS errors, you will have to tune your Operating System TCP/IP stack. For Linux, you can increase buffer size using the following commands:

# Should be enough to send at 200_000 pps (~ 10 MB of bandwidth)

sysctl -w net.core.wmem_max=109051904   # 100 MB

sysctl -w net.core.wmem_default=109051904   # 100 MB

=head1 FUNCTIONS

=over 4

=item B<l4_send_tcp_syn_multi> (ip_src, ip_dst arrayref, ip_dst count, ports arrayref, ports count, packets per second, try count, use IPv6 flag)

Sends multiple TCP SYNs at layer 4 to multiple IP targets. Returns 0 in case of failure, and sets error buffer to an error message.

=item B<nwf_geterror>

Get latest error message.

=item B<estimate_runtime> { ports => ARRAYREF, targets => ARRAYREF, pps => COUNT, try => COUNT }

Returns a HASHREF with days, hours, minutes and seconds for estimated running time.

=item B<runtime_as_string> { days => COUNT, hours => COUNT, minutes => COUNT, seconds => COUNT }

Returns as string by takink the HASHREF obtained from estimate_runtime().

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2016, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
