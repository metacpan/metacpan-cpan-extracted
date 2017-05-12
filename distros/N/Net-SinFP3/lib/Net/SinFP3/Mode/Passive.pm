#
# $Id: Passive.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Mode::Passive;
use strict;
use warnings;

use base qw(Net::SinFP3::Mode);
our @AS = qw(
   sp
   flags
   frame
   _tcp
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::SinFP3::Ext::SP;
use Net::SinFP3::Ext::TCP;

use Net::Frame::Layer::TCP qw(:consts);

sub take {
   return [
      'Net::SinFP3::Next::Frame',
      'Net::SinFP3::Next::Passive',
   ];
}

sub new {
   my $self = shift->SUPER::new(
      sp => Net::SinFP3::Ext::SP->new,
      @_,
   );

   $self->_tcp(Net::SinFP3::Ext::TCP->new);

   return $self;
}

# In passive mode, the P2 probe is not our own, so timestamp is not
# built as we want. We rewrite it to be able to match.
sub _rewriteTcpOptions {
   my $self = shift;

   my $sp = $self->sp;
   #print "[*] DEBUG: ".$sp->O."\n";
   if ($sp->O =~ m/^(.*080a)(.{8})(.{8})(.*)/) {
      my $head = $1;
      my $a    = $2;
      my $b    = $3;
      my $tail = $4;
      #print "[*] DEBUG: toks: 1[$1] 2[$2] 3[$3] 4[$4]\n";
      # Some systems put timestamp values to 00. We keep it for 
      # fingerprint matching
      if ($a !~ /00000000/ && $a !~ /44454144/) {
         $a = "........";
      }
      if ($b !~ /00000000/ && $b !~ /44454144/) {
         $b = "........";
      }
      $sp->O($head.$a.$b.$tail);
      #print "[*] DEBUG: toks: 1[$head] a[$a] b[$b] 4[$tail]\n";
      #print "[*] DEBUG: rewriteTcpOptions: [@{[$sp->O]}]\n";
   }

   return 1;
}

sub _getSPSignature {
   my $self = shift;
   my ($p) = @_;

   my $f = $self->_tcp->_analyzeTcpFlags($p);
   my $w = $self->_tcp->_analyzeTcpWindow($p);
   my $o = $self->_tcp->_analyzeTcpOptions($p);

   return Net::SinFP3::Ext::SP->new(
      F => $f,
      W => $w,
      O => $o->[0],
      M => $o->[1],
      S => $o->[2],
      L => $o->[3],
   );
}

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my $global = $self->global;
   my $log    = $global->log;
   my $next   = $global->next;

   my $ref = ref($next);
   if ($ref =~ /^Net::SinFP3::Next::Frame$/) {
      my $frame = $next->frame;
      my $flags = $frame->ref->{TCP}->flags;
      # We only finger SYN frames :) (0x02: SYN)
      if ($flags != 0x02) {
         # Do nothing with such frame
         return;
      }

      # XXX: off. Now we use a passive signature for SYN and active for SYN+ACK
      # SYN will be handled by SignatureP table signatures
      # SYN+ACK will be handled by Signature table signatures
      #$self->_updateFrame($frame);

      # This is a hack to make it looks like in active mode
      $frame->reply($frame);
      $self->frame($frame->reply);

      $self->sp($self->_getSPSignature($frame));

      # Specific for passive mode
      $self->_rewriteTcpOptions;
   }
   elsif ($ref =~ /^Net::SinFP3::Next::Passive$/) {
      $self->sp($next->sp);
   }
   else {
      $log->warning("Don't know what to do with this Next object: [$ref]");
      return;
   }

   return 1;
}

1;

__END__

=head1 NAME

Net::SinFP3::Mode::Passive - methods used when in passive mode

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
