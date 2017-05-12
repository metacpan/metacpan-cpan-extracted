#
# $Id: Server.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Input::Server;
use strict;
use warnings;

use base qw(Net::SinFP3::Input);
our @AS = qw(
   timeout
   _server
   _client
   _request
   _sel
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::SinFP3::Next::Client;

use IO::Socket::INET;
use IO::Select;
use Net::Frame::Layer::SinFP3 qw(:consts);
use Net::Frame::Layer::SinFP3::Tlv;
use Net::Frame::Simple;

sub give {
   return [
      'Net::SinFP3::Next::Client',
   ];
}

sub new {
   my $self = shift->SUPER::new(
      timeout => 5,
      @_,
   );

   my $global = $self->global;
   my $log    = $global->log;

   return $self;
}

sub init {
   my $self = shift->SUPER::init(@_) or return;

   my $global = $self->global;
   my $log = $global->log;

   my $ip = $global->targetIp || '127.0.0.1';
   my $port = $global->port || 32000;

   my $s = IO::Socket::INET->new(
      LocalAddr => $ip,
      LocalPort => $port,
      Domain => AF_INET,
      ReuseAddr => 1,
      Type => SOCK_STREAM,
      Listen => $global->jobs,
   ) or $log->fatal("Unable to start server socket");

   $s->blocking(0);
   $s->autoflush(1);

   my $sel = IO::Select->new;
   $sel->add($s);

   $log->verbose("Server listening on: [$ip]:$port");

   $self->_sel($sel);
   $self->_server($s);

   return 1;
}

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my $global = $self->global;
   my $log    = $global->log;

   my $sel    = $self->_sel;
   my $server = $self->_server;

   $log->debug("Waiting client");
   while (my @read = $sel->can_read) {
      if (my $client = $server->accept) {
         $log->verbose("Client accepted: [".$client->peerhost."]:".
                       $client->peerport);
         $self->_client($client);
         return Net::SinFP3::Next::Client->new(
            global   => $global,
            peerhost => $client->peerhost,
            peerport => $client->peerport,
         );
      }
   }

   return;
}

sub _sendResponse {
   my $self = shift;
   my ($request, $code) = @_;

   my $global = $self->global;
   my $log    = $global->log;
   my $input  = $global->input;
   my $client = $self->_client;

   my $sinfp3 = Net::Frame::Layer::SinFP3->new(
      version  => NF_SINFP3_VERSION1,
      type     => $request->type,
      flags    => $request->flags,
      code     => $code,
      tlvCount => 0,
      tlvList  => [],
   );

   my $simple = Net::Frame::Simple->new(layers => [ $sinfp3 ]);
   $log->debug($simple->print);

   my $raw = $simple->raw;
   my $r   = $client->syswrite($raw, length($raw));
   $log->debug("syswrite ret: $r");

   $client->close;
   $log->debug("Closing client connection");

   return 1;
}

sub _sendResponseBadVersion {
   my $self = shift;
   my ($request) = @_;
   return $self->_sendResponse($request, NF_SINFP3_CODE_BADVERSION);
}

sub _sendResponseBadType {
   my $self = shift;
   my ($request) = @_;
   return $self->_sendResponse($request, NF_SINFP3_CODE_BADTYPE);
}

sub _sendResponseBadTlvCount {
   my $self = shift;
   my ($request) = @_;
   return $self->_sendResponse($request, NF_SINFP3_CODE_BADTLVCOUNT);
}

sub _sendResponseBadTlv {
   my $self = shift;
   my ($request) = @_;
   return $self->_sendResponse($request, NF_SINFP3_CODE_BADTLV);
}

sub postRun {
   my $self = shift->SUPER::postRun(@_) or return;

   my $global = $self->global;
   my $log    = $global->log;

   my $client = $self->_client;
   my $server = $self->_server;

   $server->close;

   $client->blocking(0);
   $client->autoflush(1);

   my $sel = IO::Select->new;
   $sel->add($client);

   my $eof     = 0;
   my $request = '';
   my $toRead  = 1024;
   while (my @read2 = $sel->can_read($self->timeout)) {
      my $buf = '';
      my $r   = $client->sysread($buf, $toRead);
      if (! defined($r)) {
         $log->error("Client: sysread: $!");
         return;
      }
      if ($r == 0) {   # End-of-file
         $eof++;
         last;
      }

      $request .= $buf;

      #$log->debug("Client: read: [".unpack("H*", $request)."]");

      # We need the first 8 bytes to parse packet header
      my $read = length($request);
      if ($read >= 8) {
         my $hdr = substr($request, 0, 8);
         my $p   = Net::Frame::Layer::SinFP3->new(raw => $hdr)->unpack;
         #$log->debug($p->print);

         if ($p->version != NF_SINFP3_VERSION1) {
            return $self->_sendResponseBadVersion($p);
         }
         if ($p->type != NF_SINFP3_TYPE_REQUESTPASSIVE) {
            return $self->_sendResponseBadType($p);
         }
         if ($p->tlvCount != 2) {  # Frame type + frame
            return $self->_sendResponseBadTlvCount($p);
         }

         my $requestLen = $p->length + 8;

         if ($requestLen == $read) {
            $log->debug("Packet complete: read: [$read] bytes. Request [".unpack("H*", $request)."]");
            my $frame = Net::Frame::Simple->new(
               firstLayer => 'SinFP3',
               raw        => $request,
            );
            $log->debug($frame->print);

            my $layer;
            for my $tlv ($frame->ref->{SinFP3}->tlvList) {
               if ($tlv->type == NF_SINFP3_TLV_TYPE_FRAMEPROTOCOL) {
                  my $proto = unpack('C', $tlv->value);
                  if ($proto == NF_SINFP3_TLV_VALUE_ETH) {
                     $layer = 'ETH';
                  }
                  elsif ($proto == NF_SINFP3_TLV_VALUE_IPv4) {
                     $layer = 'IPv4';
                  }
                  elsif ($proto == NF_SINFP3_TLV_VALUE_IPv6) {
                     $layer = 'IPv6';
                  }
                  else {
                     return $self->_sendResponseBadTlv($p);
                  }
               }
               elsif ($layer && $tlv->type == NF_SINFP3_TLV_TYPE_FRAMEPASSIVE) {
                  # Sanity checks on provided frame
                  my $minLen = 40; # IPv4 + TCP headers
                  if ($layer eq 'IPv4') {
                     $minLen = 40;  # IPv4 + TCP headers
                  }
                  elsif ($layer eq 'IPv6') {
                     $minLen = 60;  # IPv6 + TCP headers
                  }
                  elsif ($layer eq 'ETH') {
                     $minLen = 54;  # ETH + IPv4 + TCP
                  }

                  if (length($tlv->value) < $minLen) {
                     return $self->_sendResponseBadTlv($p);
                  }

                  my $simple = Net::Frame::Simple->new(
                     firstLayer => $layer,
                     raw        => $tlv->value,
                  );
                  $log->debug($simple->print);

                  # Save request, so Output::Client can use it
                  $self->_request($frame);

                  my $next = Net::SinFP3::Next::Frame->new(
                     global => $global,
                     frame  => $simple,
                  );
                  $global->next($next);  # We change 'en live'
                  return $self;
               }
            }

            # If we are here, there was an on error on TLV
            return $self->_sendResponseBadTlv($p);
         }
         else {
            # Request not complete, need to read more
            next;
         }
      }
      else {
         # Request not complete, need to read more
         next;
      }
   }

   if ($eof) {
      $log->debug("Eof from client");
   }

   # XXX: to handle timeout
   #$log->debug("Timeout from client read");

   $log->debug("Closing client connection");
   $client->close;

   return;
}

# Father Server process has to close client socket after forking()
# So client will be able to close() socket.
sub postFork {
   my $self = shift->SUPER::postFork(@_) or return;

   my $client = $self->_client;
   $client->close;

   return 1;
}

sub post {
   my $self = shift->SUPER::post(@_) or return;

   $self->_client->close;

   return 1;
}

1;

__END__

=head1 NAME

Net::SinFP3::Input::Server - API server Input plugin

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
