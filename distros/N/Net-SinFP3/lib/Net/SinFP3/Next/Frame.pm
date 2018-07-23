#
# $Id: Frame.pm,v 008243d3e89a 2018/07/21 14:54:07 gomor $
#
package Net::SinFP3::Next::Frame;
use strict;
use warnings;

use base qw(Net::SinFP3::Next);
our @AS = qw(
   frame
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   return $self;
}

sub getIpSrc {
   my $self = shift;
   return 'unknown' unless defined($self->frame);
   my $ip = $self->frame->ref->{IPv4} || $self->frame->ref->{IPv6};
   return defined($ip) ? $ip->src : 'unknown';
}

sub getIpDst {
   my $self = shift;
   return 'unknown' unless defined($self->frame);
   my $ip = $self->frame->ref->{IPv4} || $self->frame->ref->{IPv6};
   return defined($ip) ? $ip->dst : 'unknown';
}

sub getTcpSrc {
   my $self = shift;
   return 'unknown' unless defined($self->frame);
   my $tcp = $self->frame->ref->{TCP};
   return defined($tcp) ? $tcp->src : 'unknown';
}

sub getTcpDst {
   my $self = shift;
   return 'unknown' unless defined($self->frame);
   my $tcp = $self->frame->ref->{TCP};
   return defined($tcp) ? $tcp->dst : 'unknown';
}

sub getTcpFlags {
   my $self = shift;
   return 'unknown' unless defined($self->frame);
   my $tcp = $self->frame->ref->{TCP};
   return defined($tcp) ? $tcp->flags : 'unknown';
}

sub print {
   my $self = shift;
   return "[".$self->getIpSrc."]:".$self->getTcpSrc." flags: ".
          sprintf("0x%02x", $self->getTcpFlags);
}

1;

__END__

=head1 NAME

Net::SinFP3::Next::Frame - object describing a frame

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
