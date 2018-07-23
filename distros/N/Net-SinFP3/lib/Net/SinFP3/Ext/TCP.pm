#
# $Id: TCP.pm,v 008243d3e89a 2018/07/21 14:54:07 gomor $
#
package Net::SinFP3::Ext::TCP;
use strict;
use warnings;

use base qw(Class::Gomor::Array);
our @AS = qw(
   global
   next
   _src
   _seq
   _ack
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Layer qw(:subs);
use Net::Frame::Layer::TCP qw(:consts);

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   my $src = $self->_getInitial16bits;
   my $seq = $self->_getInitial32bits;
   my $ack = $self->_getInitial32bits;

   $self->_src($src);
   $self->_seq($seq);
   $self->_ack($ack);

   return $self;
}

sub _getInitial16bits {
   my $self = shift;
   my $i16 = getRandom16bitsInt() - 3;
   $i16 += 1025 unless $i16 > 1024;
   return $i16;
}

sub _getInitial32bits {
   my $self = shift;
   my $i32 = getRandom32bitsInt() - 3;
   $i32 += 666 unless $i32 > 0;
   return $i32;
}

sub _getP1Tcp {
   my $self = shift;
   return Net::Frame::Layer::TCP->new(
      src     => $self->_src,
      seq     => $self->_seq,
      ack     => $self->_ack,
      dst     => $self->next->port,
      x2      => 0,
      flags   => NF_TCP_FLAGS_SYN,
      win     => 5840,
      options =>
         "\x02\x04\x05\xb4".
         "",
   );
}

sub _getP2Tcp {
   my $self = shift;
   return Net::Frame::Layer::TCP->new(
      src     => $self->_src + 1,
      seq     => $self->_seq + 1,
      ack     => $self->_ack + 1,
      dst     => $self->next->port,
      x2      => 0,
      flags   => NF_TCP_FLAGS_SYN,
      win     => 5840,
      options =>
         "\x02\x04\x05\xb4".
         "\x08\x0a\x44\x45".
         "\x41\x44\x00\x00".
         "\x00\x00\x03\x03".
         "\x01\x04\x02\x00".
         "",
   );
}

sub _getP3Tcp {
   my $self = shift;
   return Net::Frame::Layer::TCP->new(
      src   => $self->_src + 2,
      seq   => $self->_seq + 2,
      ack   => $self->_ack + 2,
      dst   => $self->next->port,
      x2    => 0,
      flags => NF_TCP_FLAGS_SYN | NF_TCP_FLAGS_ACK,
      win   => 5840,
   );
}

sub __analyzeTcpSeq {
   my $self = shift;
   my ($p) = @_;
   my $reqAck = $p->ref->{TCP}->ack;
   my $repSeq = $p->reply->ref->{TCP}->seq;
   my $flag   = 1;
   if    ($repSeq == 0        ) { $flag = 0 }
   elsif ($repSeq == $reqAck  ) { $flag = 2 }
   elsif ($repSeq == ++$reqAck) { $flag = 3 }
   return $flag;
}

sub __analyzeTcpAck {
   my $self = shift;
   my ($p) = @_;
   my $reqSeq = $p->ref->{TCP}->seq;
   my $repAck = $p->reply->ref->{TCP}->ack;
   my $flag   = 1;
   if    ($repAck == 0        ) { $flag = 0 }
   elsif ($repAck == $reqSeq  ) { $flag = 2 }
   elsif ($repAck == ++$reqSeq) { $flag = 3 }
   return $flag;
}

sub _analyzeTcpFlags {
   my $self = shift;
   my ($p) = @_;
   return sprintf("F0x%02x", $p->reply->ref->{TCP}->flags);
}

sub _analyzeTcpWindow {
   my $self = shift;
   my ($p) = @_;
   return 'W'.$p->reply->ref->{TCP}->win;
}

sub _analyzeTcpOptions {
   my $self = shift;
   my ($p) = @_;
   # Rewrite timestamp values, if > 0 overwrite with ffff,
   # for each timestamp. Same with WScale value
   my $mss;
   my $wscale;
   my $opts;
   if ($opts = unpack('H*', $p->reply->ref->{TCP}->options)) {
      if ($opts =~ /080a(........)(........)/) {
         if ($1 && $1 !~ /44454144|00000000/) {
            $opts =~ s/(080a)........(........)/$1ffffffff$2/;
         }
         if ($2 && $2 !~ /44454144|00000000/) {
            $opts =~ s/(080a........)......../$1ffffffff/;
         }
      }
      # Move MSS value in its own field
      if ($opts =~ /0204(....)/) {
         if ($1) {
            $mss = sprintf("%d", hex($1));
            $opts =~ s/0204..../0204ffff/;
         }
      }
      # Move WScale value in its own field
      if ($opts =~ /0303(..)/) {
         if ($1) {
            $wscale = sprintf("%d", hex($1));
            $opts =~ s/0303../0303ff/;
         }
      }
   }
   $opts .= unpack('H*', $p->reply->ref->{TCP}->payload)
      if $p->reply->ref->{TCP}->payload;

   $opts      = '0' unless $opts;
   $mss       = '0' unless $mss;
   $wscale    = '0' unless $wscale;
   my $optLen = $opts ? length($opts) / 2 : 0;
   return [ 'O'.$opts, 'M'.$mss, 'S'.$wscale, 'L'.$optLen ];
}

1;

__END__

=head1 NAME

Net::SinFP3::Ext::TCP - methods used for handling TCP headers

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
