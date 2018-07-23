#
# $Id: Pcap.pm,v 008243d3e89a 2018/07/21 14:54:07 gomor $
#
package Net::SinFP3::Output::Pcap;
use strict;
use warnings;

use base qw(Net::SinFP3::Output);
our @AS = qw(
   anonymize
   append
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::IPv4 qw(:consts);
use Net::Frame::Layer::IPv6 qw(:consts);

sub take {
   return [
      'Net::SinFP3::Result::Passive',
      'Net::SinFP3::Result::Active',
      'Net::SinFP3::Result::Frame',
      'Net::SinFP3::Result::MultiFrame',
   ];
}

sub new {
   my $self = shift->SUPER::new(
      anonymize => 0,
      append    => 0,
      @_,
   );

   return $self;
}

sub _ipv4 {
   my $self = shift;
   my ($frames) = @_;

   my @new = ();
   my $src;
   for my $f (@$frames) {
      next unless defined($f);
      if ($f->ref->{IPv4}) {
         if ($self->anonymize) {
            $src ||= $f->ref->{IPv4}->src;  # Takes src IP from first frame
            $f->ref->{TCP}->checksum(666);
            $f->ref->{IPv4}->checksum(666);
            if ($f->ref->{IPv4}->src eq $src) {
               $f->ref->{IPv4}->src('127.0.0.1');
               $f->ref->{IPv4}->dst('127.0.0.2');
            }
            else {
               $f->ref->{IPv4}->src('127.0.0.2');
               $f->ref->{IPv4}->dst('127.0.0.1');
            }
         }
         my $new = Net::Frame::Simple->new(layers => [
            Net::Frame::Layer::ETH->new,
            $f->ref->{IPv4},
            $f->ref->{TCP},
         ]);
         $new->pack;
         push @new, $new;
      }
   }

   return \@new;
}

sub _ipv6 {
   my $self = shift;
   my ($frames) = @_;

   my @new = ();
   my $src;
   for my $f (@$frames) {
      next unless defined($f);
      if ($f->ref->{IPv6}) {
         if ($self->anonymize) {
            $src ||= $f->ref->{IPv6}->src;  # Takes src IP from first frame
            $f->ref->{TCP}->checksum(666);
            if ($f->ref->{IPv6}->src eq $src) {
               $f->ref->{IPv6}->src('::1');
               $f->ref->{IPv6}->dst('::2');
            }
            else {
               $f->ref->{IPv6}->src('::2');
               $f->ref->{IPv6}->dst('::1');
            }
         }
         my $new = Net::Frame::Simple->new(layers => [
            Net::Frame::Layer::ETH->new(
               type => NF_ETH_TYPE_IPv6,
            ),
            $f->ref->{IPv6},
            $f->ref->{TCP},
         ]);
         $new->pack;
         push @new, $new;
      }
   }

   return \@new;
}

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my $global  = $self->global;
   my $log     = $global->log;
   my $mode    = $global->mode;
   my $input   = $global->input;
   my $next    = $global->next;
   my @results = $global->result;

   # We do not output a pcap file if the port is in error
   if ($results[0] =~ /Net::SinFP3::Result::PortError/) {
      $log->info("Port is in error, skipping");
      return 1;
   }

   # We do not output a pcap file in Input::SynScan with fingerprint
   if (ref($input) =~ /Net::SinFP3::Input::SynScan/ && $input->fingerprint) {
      $log->info("No pcap saving while -synscan-fingerprint option in use");
      return 1;
   }

   # Gather frames for active mode
   my $frames  = [];
   my $refMode = ref($mode);
   my $refNext = ref($next);
   if ($refMode =~ /^Net::SinFP3::Mode::Active$/) {
      if ($mode->p1) {
         push @$frames, $mode->p1;
         push @$frames, $mode->p1->reply if $mode->p1->reply;
      }
      if ($mode->p2) {
         push @$frames, $mode->p2;
         push @$frames, $mode->p2->reply if $mode->p2->reply;
      }
      if ($mode->p3) {
         push @$frames, $mode->p3;
         push @$frames, $mode->p3->reply if $mode->p3->reply;
      }
   }
   # Gather frame for passive mode
   elsif ($refNext =~ /^Net::SinFP3::Next::Frame$/) {
      push @$frames, $next->frame;
   }
   # Gather frames when multiple Next objects are used
   elsif ($refNext =~ /^Net::SinFP3::Next::MultiFrame$/) {
      for my $f ($next->frameList) {
         push @$frames, $f;
      }
   }
   else {
      $log->warning("Don't know what to do with this object: [$refMode]");
      return;
   }

   # Rewrite frames to add an ETH layer
   # And anonymize them if asked by user
   $frames = $global->ipv6 ? $self->_ipv6($frames) : $self->_ipv4($frames);

   my $file;
   if ($refMode =~ /^Net::SinFP3::Mode::Active$/) {
      if ($global->ipv6) {
         $file = $self->anonymize ? 'sinfp6-::1-'.$next->port.'.pcap'
                                  : 'sinfp6-'.$next->ip.'-'.$next->port.'.pcap';
      }
      else {
         $file = $self->anonymize ? 'sinfp4-127.0.0.1-'.$next->port.'.pcap'
                                  : 'sinfp4-'.$next->ip.'-'.$next->port.'.pcap';
      }
   }
   else {
      $file = $global->ipv6 ? 'sinfp6-output.pcap' : 'sinfp4-output.pcap';
   }

   my %args = (
      append => $self->append,
   );
   if (!$self->append) {
      $args{overwrite} = 1;
   }
   my $out = $global->getDumpWriter(
      file       => $file,
      firstLayer => 'ETH',
      %args,
   ) or return;
   $out->start or return;

   for my $f (@$frames) {
      next unless defined($f);
      $out->write({ timestamp => $f->timestamp, raw => $f->raw });
   }

   $out->stop;

   if ($refMode =~ /^Net::SinFP3::Mode::Active$/) {
      print "File [$file] generation done.\n";
      print "Please send it to GomoR[at]metabrik.org if you think this is ".
            "not the\n";
      print "good identification, or if it is new signature.\n";
      print "In this last case, please specify `uname -a' (or equivalent) ".
            "from\n";
      print "the target host.\n";
   }

   return 1;
}

1;

__END__

=head1 NAME

Net::SinFP3::Output::Pcap - writes frames to a pcap file

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
