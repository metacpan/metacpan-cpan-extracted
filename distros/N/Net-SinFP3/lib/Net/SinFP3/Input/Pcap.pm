#
# $Id: Pcap.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Input::Pcap;
use strict;
use warnings;

use base qw(Net::SinFP3::Input);
our @AS = qw(
   count
   filter
   file
   _files
   _dump
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::SinFP3::Next::Frame;
use Net::SinFP3::Next::MultiFrame;

sub give {
   return [
      'Net::SinFP3::Next::Frame',
      'Net::SinFP3::Next::MultiFrame',
   ];
}

sub new {
   my $self = shift->SUPER::new(
      count => 0,
      @_,
   );

   my $global = $self->global;
   my $log    = $global->log;

   if (!defined($self->file)) {
      $log->fatal("You must provide file attribute");
   }

   # If user did not provide its own pcap filter
   if (!defined($self->filter)) {
      my $filter = $global->ipv6 ? '(ip6 and tcp)' : '(ip and tcp)';
      $self->filter($filter);
   }

   return $self;
}

sub _getDump {
   my $self = shift;
   my ($file) = @_;

   my $global = $self->global;

   my $oDump = $global->getDumpOffline(
      file   => $file,
      filter => $self->filter,
   ) or return;

   return $oDump;
}

sub init {
   my $self = shift->SUPER::init(@_) or return;

   my $files = $self->global->expandFiles(files => $self->file);
   $self->_files($files);

   return 1;
}

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my $global = $self->global;
   my $log    = $global->log;

   my $oDump;
   if (!defined($self->_dump)) {
      # Get next file
      my $list = $self->_files;
      my $file = shift @$list;
      $self->_files($list);

      $log->info("Get frames from pcap file [$file]");

      $oDump = $self->_getDump($file) or return;
      $oDump->start or return;
      $self->_dump($oDump);
   }
   else {
      $oDump = $self->_dump;
   }

   my @frames = ();
   my $read   = 0;
   my $count  = $self->count;
   while (my $h = $oDump->next) {
      my $frame = Net::Frame::Simple->newFromDump($h);
      $read++;

      # Due to some buggy pcap installs that miss ip6 filter
      if ($global->ipv6 && !$frame->ref->{IPv6}) {
         next;
      }

      push @frames, $frame;

      # If user specified a count number, we return this number of frames
      if ($count) {
         if (@frames == $count) {
            $log->debug("Returning $count frames");
            my $next = Net::SinFP3::Next::MultiFrame->new(
               global    => $global,
               frameList => \@frames,
            );
            return $next;
         }
      }
      else {
          return Net::SinFP3::Next::Frame->new(
             global => $global,
             frame  => $frame,
          );
      }
   }

   # If we are here, we are done with this file (next returned undef)
   $oDump->stop;
   $self->_dump(undef);

   # Last if no more files in array
   if (@{$self->_files} == 0) {
      $self->last(1);
   }

   # Else we will return all frames available in pcap file
   if ($count) {
      $log->debug("Returning ".@frames." frames (all available frames)");
      return Net::SinFP3::Next::MultiFrame->new(
         global    => $global,
         frameList => \@frames,
      );
   }

   return;
}

1;

__END__

=head1 NAME

Net::SinFP3::Input::Pcap - get input objects from a pcap file

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
