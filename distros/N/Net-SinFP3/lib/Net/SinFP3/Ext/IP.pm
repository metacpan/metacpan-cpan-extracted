#
# $Id: IP.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Ext::IP;
use strict;
use warnings;

use base qw(Class::Gomor::Array);
__PACKAGE__->cgBuildIndices;

# This is to verify that RST packets are generated from the target with
# the same TTL as a SYN|ACK packet. We accept a difference of 3 hops, but
# if this is greater, we consider to not be the same generated TTL
# Example: SunOS 5.9 generates a TTL of 60 in a SYN|ACK from our probe,
#          but a TTL of 64 for a RST from our probe. So, $ttl = 0.
sub __analyzeIpTtl {
   my $self = shift;
   my ($p, $p2) = @_;
   return 1 if ! $p2 || ! $p2->reply;
   my $ttlSrc = $self->getResponseIpTtl($p2);
   my $ttlDst = $self->getResponseIpTtl($p);
   my $ttl = 1;
   $ttl = 0 if (($ttlSrc > $ttlDst) && ($ttlSrc - $ttlDst > 3));
   $ttl = 0 if (($ttlDst > $ttlSrc) && ($ttlDst - $ttlSrc > 3));
   return $ttl;
}

sub __analyzeIpDfBit {
   my $self = shift;
   my ($p) = @_;
   return $self->getResponseIpDfBit($p) ? '1' : '0';
}

sub __analyzeIpIdPassive {
   my $self = shift;
   my ($p) = @_;
   return $self->getResponseIpId($p) ? '1' : '0';
}

sub __analyzeIpId {
   my $self = shift;
   my ($p) = @_;
   my $reqId = $self->getProbeIpId($p);
   my $repId = $self->getResponseIpId($p);
   my $flag  = 1;
   if    ($repId == 0)        { $flag = 0 }
   elsif ($repId == $reqId)   { $flag = 2 }
   elsif ($repId == ++$reqId) { $flag = 3 } # There is no reason for that, but
                                            # anyway, we have nothing to loose
   return $flag;
}

sub _analyzeBinary {
   my $self = shift;
   my ($p, $p2) = @_;
   my $flagTtl = $self->__analyzeIpTtl($p, $p2);
   my $flagId  = $self->__analyzeIpId($p);
   my $flagDf  = $self->__analyzeIpDfBit($p);
   my $flagSeq = $self->_tcp->__analyzeTcpSeq($p);
   my $flagAck = $self->_tcp->__analyzeTcpAck($p);
   return 'B'.$flagTtl.$flagId.$flagDf.$flagSeq.$flagAck;
}

1;

__END__

=head1 NAME

Net::SinFP3::Ext::IP - methods used for handling IP headers

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
