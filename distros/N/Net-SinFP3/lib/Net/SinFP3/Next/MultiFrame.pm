#
# $Id: MultiFrame.pm,v 008243d3e89a 2018/07/21 14:54:07 gomor $
#
package Net::SinFP3::Next::MultiFrame;
use strict;
use warnings;

use base qw(Net::SinFP3::Next);
our @AA = qw(
   frameList
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsArray(\@AA);

sub new {
   my $self = shift->SUPER::new(
      frameList => [],
      @_,
   );

   return $self;
}

sub getIpSrc {
   my $self = shift;
   my ($frame) = @_;
   return 'unknown' unless defined($frame);
   my $ip = $frame->ref->{IPv4} || $frame->ref->{IPv6};
   return defined($ip) ? $ip->src : 'unknown';
}

sub getIpDst {
   my $self = shift;
   my ($frame) = @_;
   return 'unknown' unless defined($frame);
   my $ip = $frame->ref->{IPv4} || $frame->ref->{IPv6};
   return defined($ip) ? $ip->dst : 'unknown';
}

sub getTcpSrc {
   my $self = shift;
   my ($frame) = @_;
   return 'unknown' unless defined($frame);
   my $tcp = $frame->ref->{TCP};
   return defined($tcp) ? $tcp->src : 'unknown';
}

sub getTcpDst {
   my $self = shift;
   my ($frame) = @_;
   return 'unknown' unless defined($frame);
   my $tcp = $frame->ref->{TCP};
   return defined($tcp) ? $tcp->dst : 'unknown';
}

sub getTcpFlags {
   my $self = shift;
   my ($frame) = @_;
   return 'unknown' unless defined($frame);
   my $tcp = $frame->ref->{TCP};
   return defined($tcp) ? $tcp->flags : 'unknown';
}

sub print {
   my $self = shift;
   my @frames = $self->frameList;
   my $first  = $frames[0];
   if (defined($first)) {
      return "first frame [".$self->getIpSrc($first)."]:".
             $self->getTcpSrc($first)." flags: ".
             sprintf("0x%02x", $self->getTcpFlags($first));
   }
   else {
      return "No frame found";
   }
}

1;

__END__

=head1 NAME

Net::SinFP3::Next::MultiFrame - object containing an multiple frames

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
