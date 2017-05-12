#
# $Id: Client.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Output::Client;
use strict;
use warnings;

use base qw(Net::SinFP3::Output);
__PACKAGE__->cgBuildIndices;

use Net::Frame::Layer::SinFP3 qw(:consts);
use Net::Frame::Layer::SinFP3::Tlv;
use Net::Frame::Simple;

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   return $self;
}

sub take {
   return [
      'Net::SinFP3::Result::Active',
      'Net::SinFP3::Result::Passive',
      'Net::SinFP3::Result::Unknown',
      'Net::SinFP3::Result::PortError',
   ];
}

sub _runPortError {
   my $self = shift;
   my ($results) = @_;

   return $self->_runUnknown($results);
}

sub _runActive {
   my $self = shift;
   my ($results) = @_;

   my $global  = $self->global;
   my $log     = $global->log;
   my $input   = $global->input;
   my $request = $input->_request;

   my $hdr = Net::Frame::Layer::SinFP3->new(
      version => NF_SINFP3_VERSION1,
      type    => $request->ref->{SinFP3}->type,
      flags   => $request->ref->{SinFP3}->flags,
      code    => NF_SINFP3_CODE_BADTYPE,
   );

   return $self->_sendResponse($hdr);
}

sub _runUnknown {
   my $self = shift;
   my ($results) = @_;

   my $global  = $self->global;
   my $log     = $global->log;
   my $input   = $global->input;
   my $request = $input->_request;

   my $hdr = Net::Frame::Layer::SinFP3->new(
      version => NF_SINFP3_VERSION1,
      type    => NF_SINFP3_TYPE_RESPONSEPASSIVE,
      flags   => $request->ref->{SinFP3}->flags,
      code    => NF_SINFP3_CODE_SUCCESSUNKNOWN,
   );

   return $self->_sendResponse($hdr);
}

sub _runPassive {
   my $self = shift;
   my ($results) = @_;

   my $global  = $self->global;
   my $log     = $global->log;
   my $input   = $global->input;
   my $request = $input->_request;

   my $hdr = Net::Frame::Layer::SinFP3->new(
      version => NF_SINFP3_VERSION1,
      type    => NF_SINFP3_TYPE_RESPONSEPASSIVE,
      flags   => $request->ref->{SinFP3}->flags,
      code    => NF_SINFP3_CODE_SUCCESSRESULT,
   );

   my $flags   = $hdr->flags;
   my @tlvList = ();
   for my $r (@$results) {
      if ($flags & NF_SINFP3_FLAG_TRUSTED || $flags == NF_SINFP3_FLAG_FULL) {
         push @tlvList, Net::Frame::Layer::SinFP3::Tlv->new(
            type  => NF_SINFP3_TLV_TYPE_TRUSTED,
            value => pack('C', $r->trusted),
         );
      }
      if ($flags & NF_SINFP3_FLAG_IPVERSION || $flags == NF_SINFP3_FLAG_FULL) {
         push @tlvList, Net::Frame::Layer::SinFP3::Tlv->new(
            type  => NF_SINFP3_TLV_TYPE_IPVERSION,
            value => pack('C', $r->ipVersion eq 'IPv4' ? 4 : 6),
         );
      }
      if ($flags & NF_SINFP3_FLAG_SYSTEMCLASS || $flags == NF_SINFP3_FLAG_FULL) {
         push @tlvList, Net::Frame::Layer::SinFP3::Tlv->new(
            type  => NF_SINFP3_TLV_TYPE_SYSTEMCLASS,
            value => $r->systemClass,
         );
      }
      if ($flags & NF_SINFP3_FLAG_VENDOR || $flags == NF_SINFP3_FLAG_FULL) {
         push @tlvList, Net::Frame::Layer::SinFP3::Tlv->new(
            type  => NF_SINFP3_TLV_TYPE_VENDOR,
            value => $r->vendor,
         );
      }
      if ($flags & NF_SINFP3_FLAG_OS || $flags == NF_SINFP3_FLAG_FULL) {
         push @tlvList, Net::Frame::Layer::SinFP3::Tlv->new(
            type  => NF_SINFP3_TLV_TYPE_OS,
            value => $r->os,
         );
      }
      if ($flags & NF_SINFP3_FLAG_OSVERSION || $flags == NF_SINFP3_FLAG_FULL) {
         push @tlvList, Net::Frame::Layer::SinFP3::Tlv->new(
            type  => NF_SINFP3_TLV_TYPE_OSVERSION,
            value => $r->osVersion,
         );
      }
      if ($flags & NF_SINFP3_FLAG_OSVERSIONFAMILY || $flags == NF_SINFP3_FLAG_FULL) {
         push @tlvList, Net::Frame::Layer::SinFP3::Tlv->new(
            type  => NF_SINFP3_TLV_TYPE_OSVERSIONFAMILY,
            value => $r->osVersionFamily,
         );
      }
      if ($flags & NF_SINFP3_FLAG_MATCHTYPE || $flags == NF_SINFP3_FLAG_FULL) {
         push @tlvList, Net::Frame::Layer::SinFP3::Tlv->new(
            type  => NF_SINFP3_TLV_TYPE_MATCHTYPE,
            value => $r->matchType,
         );
      }
      if ($flags & NF_SINFP3_FLAG_MATCHMASK || $flags == NF_SINFP3_FLAG_FULL) {
         push @tlvList, Net::Frame::Layer::SinFP3::Tlv->new(
            type  => NF_SINFP3_TLV_TYPE_MATCHMASK,
            value => $r->matchMask,
         );
      }
      if ($flags & NF_SINFP3_FLAG_MATCHSCORE || $flags == NF_SINFP3_FLAG_FULL) {
         push @tlvList, Net::Frame::Layer::SinFP3::Tlv->new(
            type  => NF_SINFP3_TLV_TYPE_MATCHSCORE,
            value => pack('C', $r->matchScore),
         );
      }
      #if ($flags & NF_SINFP3_FLAG_P1SIG || $flags == NF_SINFP3_FLAG_FULL) {
      #}
      if ($flags & NF_SINFP3_FLAG_P2SIG || $flags == NF_SINFP3_FLAG_FULL) {
         push @tlvList, Net::Frame::Layer::SinFP3::Tlv->new(
            type  => NF_SINFP3_TLV_TYPE_P2SIG,
            value => $r->sp->print,
         );
      }
      #if ($flags & NF_SINFP3_FLAG_P3SIG || $flags == NF_SINFP3_FLAG_FULL) {
      #}
   }

   $hdr->tlvList(\@tlvList);

   return $self->_sendResponse($hdr);
}

sub _sendResponse {
   my $self = shift;
   my ($response) = @_;

   my $global = $self->global;
   my $log    = $global->log;
   my $input  = $global->input;

   my $simple = Net::Frame::Simple->new(
      layers => [ $response, ],
   );
   $log->debug("Response: ".$simple->print);

   my $client = $input->_client;
   $log->debug("Client: $client");

   my $raw = $simple->raw;
   my $r   = $client->syswrite($raw, length($raw));
   $log->debug("syswrite ret: $r");

   $client->close;
   $log->debug("Closing client connection");

   return 1;
}

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my $global  = $self->global;
   my $log     = $global->log;
   my $input   = $global->input;
   my @results = $global->result;

   if ($input !~ /Net::SinFP3::Input::Server/) {
      $log->fatal("You can't use Output::Client without Input::Server");
   }

   my $ref = ref($results[0]);
   if ($ref =~ /^Net::SinFP3::Result::Unknown$/) {
      return $self->_runUnknown(\@results);
   }
   elsif ($ref =~ /^Net::SinFP3::Result::PortError$/) {
      return $self->_runPortError(\@results);
   }
   elsif ($ref =~ /^Net::SinFP3::Result::Active$/) {
      $self->_runActive(\@results);
   }
   elsif ($ref =~ /^Net::SinFP3::Result::Passive$/) {
      $self->_runPassive(\@results);
   }
   else {
      $log->warning("Don't know what to do with this result object ".
                    "with type: [$ref]");
   }

   return 1;
}

1;

__END__

=head1 NAME

Net::SinFP3::Output::Client - output results to a SinFP3 client

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
