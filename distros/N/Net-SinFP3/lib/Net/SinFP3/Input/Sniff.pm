#
# $Id: Sniff.pm,v 008243d3e89a 2018/07/21 14:54:07 gomor $
#
package Net::SinFP3::Input::Sniff;
use strict;
use warnings;

use base qw(Net::SinFP3::Input);
our @AS = qw(
   promisc
   filter
   _dump
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::SinFP3::Next::Frame;

sub give {
   return [
      'Net::SinFP3::Next::Frame',
   ];
}

sub new {
   my $self = shift->SUPER::new(
      promisc => 1,
      @_,
   );

   return $self;
}

sub init {
   my $self = shift->SUPER::init(@_) or return;

   my $global = $self->global;
   my $log    = $global->log;

   # Default filter for passive fingerprinting
   if (! $self->filter) {
      my $filter = '';
      if ($global->ipv6) {
         $filter = 'ip6 and tcp';
      }
      else {
         $filter = 'tcp and tcp[tcpflags] == tcp-syn';
      }
      $self->filter($filter);
   }

   my $oDump = $global->getDumpOnline(
      promisc => $self->promisc,
      filter  => $self->filter,
   ) or return;
   $oDump->start or return;

   $self->_dump($oDump);

   return 1;
}

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my $global = $self->global;

   my $oDump = $self->_dump;

   while (1) {
      if (my $h = $oDump->next) {
         my $frame = Net::Frame::Simple->newFromDump($h);

         # Due to some buggy pcap installs that miss ip6 filter
         if ($global->ipv6 && !exists($frame->ref->{IPv6})) {
            next;
         }

         my $next = Net::SinFP3::Next::Frame->new(
            global => $global,
            frame  => $frame,
         );

         return $next;
      }
   }

   return;
}

1;

__END__

=head1 NAME

Net::SinFP3::Input::Sniff - sniff the network and returns Next::Frame objects

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
