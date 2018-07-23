#
# $Id: Connect.pm,v 008243d3e89a 2018/07/21 14:54:07 gomor $
#
package Net::SinFP3::Input::Connect;
use strict;
use warnings;

use base qw(Net::SinFP3::Input);
our @AS = qw(
   data
   _dump
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::SinFP3::Next::MultiFrame;

sub give {
   return [
      'Net::SinFP3::Next::Frame',
   ];
}

sub new {
   my $self = shift->SUPER::new(
      data => "GET / HTTP/1.0\r\n\r\n",
      @_,
   );

   my $global = $self->global;
   my $log    = $global->log;

   if (! defined($global->target)) {
      $log->fatal("You must provide `target' attribute in Global object");
   }

   if (! defined($global->port)) {
      $log->fatal("You must provide `port' attribute in Global object");
   }

   my $port = $global->port;
   if ($port !~ /^[-,\d]+$/) {
      $log->fatal("Invalid port provided: [$port]");
   }

   if (! $global->targetIp) {
      $log->fatal("Invalid target IP provided: [".$global->targetIp."]");
   }

   return $self;
}

sub init {
   my $self = shift->SUPER::init(@_) or return;

   my $global = $self->global;
   my $log = $global->log;

   my $me = $global->ip;
   my $ip = $global->targetIp;
   my $port = $global->port;

   # Capture TCP SYN and SYN|ACK between source and target
   my $filter = '';
   if ($global->ipv6) {
      $filter = "(tcp and host $ip and port $port)";
   }
   else {
      $filter = "(tcp and src host $ip and src port $port)".
                " or ".
                "(tcp and dst host $ip and dst port $port)".
                " and (tcp[tcpflags] == (tcp-syn|tcp-ack) or ".
                "      tcp[tcpflags] == (tcp-syn))";
   }

   my $oDump = $global->getDumpOnline(
      filter => $filter,
      timeoutOnNext => 0,
   );
   $oDump->start;

   $self->_dump($oDump);

   return 1;
}

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my $global = $self->global;
   my $log    = $global->log;

   my $ip = $global->targetIp;
   my $port = $global->port;

   $log->info("Connecting to [$ip]:$port");

   my $s = $global->tcpConnect(ip => $ip, port => $port);
   print $s $self->data;
   close($s);

   $log->info("Success sending [".$self->data."]");

   my $oDump = $self->_dump;

   my @frames = ();
   while (my $h = $oDump->next) {
      my $frame = Net::Frame::Simple->newFromDump($h);

      # Due to some buggy pcap installs that miss ip6 filter
      if ($global->ipv6 && !$frame->ref->{IPv6}) {
         next;
      }

      push @frames, $frame;

      $self->last(1);
   }

   my $next = Net::SinFP3::Next::MultiFrame->new(
      global => $global,
      frameList => \@frames,
   );

   return $next;
}

sub post {
   my $self = shift;
   $self->_dump->stop;
   $self->_dump(undef);
   return 1;
}

1;

__END__

=head1 NAME

Net::SinFP3::Input::Connect - methods used when in TCP connect active mode

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
