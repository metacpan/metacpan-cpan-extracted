#
# $Id: Online.pm 364 2014-11-30 11:26:27Z gomor $
#
package Net::Frame::Dump::Online;
use strict;
use warnings;

use base qw(Net::Frame::Dump);
our @AS = qw(
   dev
   timeoutOnNext
   timeout
   promisc
   snaplen
   unlinkOnStop
   onRecv
   onRecvCount
   onRecvData
   _pid
   _sName
   _sDataAwaiting
   _firstTime
   _son
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

BEGIN {
   my $osname = {
      cygwin  => [ \&_checkWin32, ],
      MSWin32 => [ \&_checkWin32, ],
   };

   *_check = $osname->{$^O}->[0] || \&_checkOther;
}

use Net::Frame::Dump qw(:consts);

use Net::Pcap;
use Time::HiRes qw(gettimeofday);
use Storable qw(lock_store lock_retrieve);
use Net::Frame::Layer qw(:subs);

sub _checkWin32 { return 1; }

sub _checkOther {
   if ($>) {
      die("[-]: Net::Frame::Dump::Online: Must be EUID 0 (or equivalent) ".
          "to open a device for live capture\n");
   }
   return 1;
}

sub new {
   my $self = shift->SUPER::new(
      timeoutOnNext  => 3,
      timeout        => 0,
      promisc        => 0,
      snaplen        => 1514,
      unlinkOnStop   => 1,
      onRecvCount    => -1,
      _sDataAwaiting => 0,
      @_,
   );

   if (!defined($self->_sName)) {
      my $int = getRandom32bitsInt();
      $self->_sName("netframe-tmp-$$.$int.storable");
   }

   $SIG{INT} = sub {
      return unless $self->isFather;
      $self->_clean;
   };
   $SIG{TERM} = sub {
      return unless $self->isFather;
      $self->_clean;
   };

   if (!defined($self->dev)) {
      print("[-] ".__PACKAGE__.": You MUST pass `dev' attribute\n");
      return;
   }

   return $self;
}

sub _sStore {
   lock_store(\$_[1], $_[0]->_sName) or do {
      print("[-] ".__PACKAGE__.": lock_store: @{[$_[0]->_sName]}: $!\n");
      return;
   };
   return 1;
}
sub _sRetrieve {
   ${lock_retrieve(shift->_sName)};
}

sub _sWaitFile {
   my $self = shift;
   my $startTime = gettimeofday();
   my $thisTime  = $startTime;
   while (! -f $self->_sName) {
      if ($thisTime - $startTime > 10) {
         print("[-] ".__PACKAGE__.": too long for file creation: ".
              $self->_sName."\n");
         return;
      }
      $thisTime = gettimeofday();
   }
   return 1;
}

sub _sWaitFileSize {
   my $self = shift;

   $self->_sWaitFile;

   my $startTime = gettimeofday();
   my $thisTime  = $startTime;
   while (! ((stat($self->_sName))[7] > 0)) {
      if ($thisTime - $startTime > 10) {
         $self->_clean;
         print("[-] ".__PACKAGE__.": too long for file creation2: ".
               $self->_sName."\n");
         return;
      }
      $thisTime = gettimeofday();
   }
   return 1;
}

sub _startOnRecv {
   my $self = shift;

   my $err;
   my $pd = Net::Pcap::open_live(
      $self->dev,
      $self->snaplen,
      $self->promisc,
      1000,
      \$err,
   );
   unless ($pd) {
      print("[-] ".__PACKAGE__.": open_live: $err\n");
      return;
   }
   $self->_pcapd($pd);

   my $net  = 0;
   my $mask = 0;
   Net::Pcap::lookupnet($self->dev, \$net, \$mask, \$err);
   if ($err) {
      print("[!] ".__PACKAGE__.": lookupnet: $err\n");
   }

   my $fcode;
   if (Net::Pcap::compile($pd, \$fcode, $self->filter, 0, $mask) < 0) {
      print("[-] ".__PACKAGE__.": compile: ". Net::Pcap::geterr($pd). "\n");
      return;
   }

   if (Net::Pcap::setfilter($pd, $fcode) < 0) {
      print("[-] ".__PACKAGE__.": setfilter: ". Net::Pcap::geterr($pd). "\n");
      return;
   }

   $self->getFirstLayer;

   # Setup onRecv enforced code, to make it simpler for user
   my $callback = sub {
      my ($userData, $hdr, $pkt) = @_;
      my $h = {
         raw        => $pkt,
         timestamp  => $hdr->{tv_sec}.'.'.sprintf("%06d", $hdr->{tv_usec}),
         firstLayer => $self->firstLayer,
      };
      &{$self->onRecv}($h, $userData);
   };

   {
      # We have to access onRecvData ARRAY indice to pass a ref
      no strict 'vars';

      Net::Pcap::loop(
         $pd, $self->onRecvCount, $callback, $self->[$__onRecvData],
      );
   }
}

sub start {
   my $self = shift;

   _check() or return;

   $self->isRunning(1);

   if (-f $self->file && !$self->overwrite) {
      print("[-] ".__PACKAGE__."We will not overwrite a file by default. ".
            "Use `overwrite' attribute to do it.\n");
      return;
   }

   if ($self->onRecv) {
      $self->_startOnRecv;
   }
   else {
      $self->_sStore(0);
      $self->_sWaitFileSize;
      $self->_startTcpdump;
      $self->_openFile;
   }

   return 1;
}

sub _clean {
   my $self = shift;
   if ($self->unlinkOnStop && $self->file && -f $self->file) {
      unlink($self->file);
      $self->cgDebugPrint(1, "@{[$self->file]} removed");
   }
   if ($self->_sName && -f $self->_sName) {
      unlink($self->_sName);
   }
   return 1;
}

sub stop {
   my $self = shift;

   if (!$self->isRunning || $self->isSon) {
      return;
   }

   if ($self->onRecv && $self->_pcapd) {
      Net::Pcap::breakloop($self->_pcapd);
      Net::Pcap::close($self->_pcapd);
   }
   else {
      $self->_killTcpdump;
      Net::Pcap::breakloop($self->_pcapd);
      Net::Pcap::close($self->_pcapd);
   }

   $self->isRunning(0);
   $self->_pcapd(undef);

   $self->_clean;

   return 1;
}

sub getStats {
   my $self = shift;

   if (!defined($self->_pcapd)) {
      print("[-] ".__PACKAGE__.": unable to get stats, no pcap descriptor ".
           "opened.\n");
      return;
   }

   my %stats;
   Net::Pcap::stats($self->_pcapd, \%stats);
   return \%stats;
}

sub isFather { ! shift->_son }
sub isSon    {   shift->_son }

sub _sonPrintStats {
   my $self = shift;

   my $stats = $self->getStats;
   $self->cgDebugPrint(1, 'Frames received  : '.$stats->{ps_recv});
   $self->cgDebugPrint(1, 'Frames dropped   : '.$stats->{ps_drop});
   $self->cgDebugPrint(1, 'Frames if dropped: '.$stats->{ps_ifdrop});
   return;
}

sub _startTcpdump {
   my $self = shift;

   my $err;
   my $pd = Net::Pcap::open_live(
      $self->dev,
      $self->snaplen,
      $self->promisc,
      1000,
      \$err,
   );
   unless ($pd) {
      print("[-] ".__PACKAGE__.": open_live: $err\n");
      return;
   }

   my $net  = 0;
   my $mask = 0;
   Net::Pcap::lookupnet($self->dev, \$net, \$mask, \$err);
   if ($err) {
      print("[!] ".__PACKAGE__.": lookupnet: $err\n");
   }

   my $fcode;
   if (Net::Pcap::compile($pd, \$fcode, $self->filter, 0, $mask) < 0) {
      print("[-] ".__PACKAGE__.": compile: ". Net::Pcap::geterr($pd). "\n");
      return;
   }

   if (Net::Pcap::setfilter($pd, $fcode) < 0) {
      print("[-] ".__PACKAGE__.": setfilter: ". Net::Pcap::geterr($pd). "\n");
      return;
   }

   my $p = Net::Pcap::dump_open($pd, $self->file);
   unless ($p) {
      print("[-] ".__PACKAGE__.": dump_open: ". Net::Pcap::geterr($pd). "\n");
      return;
   }
   Net::Pcap::dump_flush($p);

   my $pid = fork();
   die("[-] ".__PACKAGE__.": fork: $!\n") unless defined $pid;
   if ($pid) {   # Parent
      $self->_son(0);
      $self->_pid($pid);
      $SIG{CHLD} = 'IGNORE';
      return 1;
   }
   else {   # Son
      $self->_son(1);
      $self->_pcapd($pd);
      $SIG{HUP} = sub { $self->_sonPrintStats };
      $self->cgDebugPrint(1, "dev:    [@{[$self->dev]}]\n".
                             "file:   [@{[$self->file]}]\n".
                             "filter: [@{[$self->filter]}]");
      Net::Pcap::loop($pd, -1, \&_tcpdumpCallback, [ $p, $self ]);
      Net::Pcap::close($pd);
      exit(0);
   }
}

sub _tcpdumpCallback {
   my ($data, $hdr, $pkt) = @_;
   my $p    = $data->[0];
   my $self = $data->[1];

   Net::Pcap::dump($p, $hdr, $pkt);
   Net::Pcap::dump_flush($p);

   my $n = $self->_sRetrieve;
   $self->_sStore(++$n);
}

sub _killTcpdump {
   my $self = shift;
   return if $self->isSon;
   kill('KILL', $self->_pid);
   $self->_pid(undef);
}

sub _openFile {
   my $self = shift;

   my $err;
   my $pcapd = Net::Pcap::open_offline($self->file, \$err);
   if (!defined($pcapd)) {
      print("[-] ".__PACKAGE__.": Net::Pcap::open_offline: ".
           "@{[$self->file]}: $err\n");
      return;
   }
   $self->_pcapd($pcapd);

   return $self->getFirstLayer;
}

sub _getNextAwaitingFrame {
   my $self = shift;
   my $last = $self->_sDataAwaiting;
   my $new  = $self->_sRetrieve;

   # Return if nothing new is awaiting
   return if ($new <= $last);

   $self->_sDataAwaiting($self->_sDataAwaiting + 1);
   return $self->SUPER::next;
}

sub _nextTimeoutHandle {
   my $self = shift;

   # Handle timeout
   my $thisTime = gettimeofday();
   if ($self->timeoutOnNext && !$self->_firstTime) {
      $self->_firstTime($thisTime);
   }

   if ($self->timeoutOnNext && $self->_firstTime) {
      if (($thisTime - $self->_firstTime) > $self->timeoutOnNext) {
         $self->timeout(1);
         $self->_firstTime(0);
         $self->cgDebugPrint(1, "Timeout occured");
         return;
      }
   }

   return 1;
}

sub _nextTimeoutReset { shift->_firstTime(0) }

sub timeoutReset { shift->timeout(0) }

sub next {
   my $self = shift;

   $self->_nextTimeoutHandle or return;

   my $frame = $self->_getNextAwaitingFrame;
   $self->_nextTimeoutReset if $frame;

   return $frame;
}

1;

__END__

=head1 NAME

Net::Frame::Dump::Online - tcpdump like implementation, online mode

=head1 SYNOPSIS

   use Net::Frame::Dump::Online;

   #
   # Simply create a Dump object
   #
   my $oDump = Net::Frame::Dump::Online->new(
      dev => 'eth0',
   );

   $oDump->start;

   # Gather frames
   while (1) {
      if (my $f = $oDump->next) {
         my $raw            = $f->{raw};
         my $firstLayerType = $f->{firstLayer};
         my $timestamp      = $f->{timestamp};
      }
   }

   $oDump->stop;

   #
   # Create a Dump object, using on-event loop
   #
   sub callOnRecv {
      my ($h, $data) = @_;
      print "Data: $data\n";
      my $oSimple = Net::Frame::Simple->newFromDump($h);
      print $oSimple->print."\n";
   }

   my $oDumpEvent = Net::Frame::Dump::Online->new(
      dev         => 'eth0',
      onRecv      => \&callOnRecv,
      onRecvCount => 1,
      onRecvData  => 'test',
   );

   # Will block here, until $onRecvCount packets read, or a stop() call has 
   # been performed.
   $oDumpEvent->start;

   #
   # Default parameters on creation
   #
   my $oDumpDefault = Net::Frame::Dump::Online->new(
      dev            => undef,
      timeoutOnNext  => 3,
      timeout        => 0,
      promisc        => 0,
      unlinkOnStop   => 1,
      file           => "netframe-tmp-$$.$int.pcap",
      filter         => '',
      overwrite      => 0,
      isRunning      => 0,
      keepTimestamp  => 0,
      onRecvCount    => -1,
      frames         => [],
   );

=head1 DESCRIPTION

This module implements a tcpdump-like program, for live capture from networks.

=head1 ATTRIBUTES

=over 4

=item B<dev>

The network interface to listen on. No default value.

=item B<timeoutOnNext>

Each time you call B<next> method, an internal counter is updated. This counter tells you if you have not received any data since B<timeoutOnNext> seconds. When a timeout occure, B<timeout> is set to true.

=item B<timeout>

When B<timeoutOnNext> seconds has been reached, this variable is set to true, and never reset. See B<timeoutReset> if you want to reset it.

=item B<snaplen>

If you want to capture a different snaplen, set it a number. Default to 1514.

=item B<promisc>

By default, interface is not put into promiscuous mode, set this parameter to true if you want it.

=item B<unlinkOnStop>

When you call B<stop> method, the generated .pcap file is removed, unless you set this parameter to a false value.

=item B<onRecv>

If you place a reference to a sub in this attribute, it will be called each time a packet is received on the interface. See B<SYNOPSIS> for an example usage.

=item B<onRecvData>

This parameter will store additional data to be passed to B<onRecv> callback.

=item B<onRecvCount>

By default, it is set to read forever packets that reach your network interface. Set it to a positive value to read only B<onRecvCount> frames.

=back

The following are inherited attributes:

=over 4

=item B<file>

Name of the generated .pcap file. See B<SYNOPSIS> for the default name.

=item B<filter>

Pcap filter to use. Default to no filter.

=item B<overwrite>

Overwrites a .pcap file that already exists. Default to not.

=item B<firstLayer>

Stores information about the first layer type contained on read frame. This attribute is filled only after a call to B<start> method.

=item B<isRunning>

Returns true if a call to B<start> has been done, false otherwise or if a call to B<stop> has been done.

=item B<keepTimestamp>

Sometimes, when frames are captured and saved to a .pcap file, timestamps sucks. That is, you send a frame, and receive the reply, but your request appear to have been sent after the reply. So, to correct that, you can use B<Net::Frame::Dump> own timestamping system. The default is 0. Set it manually to 1 if you need original .pcap frames timestamps.

=back

=head1 METHODS

=over 4

=item B<new>

=item B<new> (hash)

Object constructor. You can pass attributes that will overwrite default ones. See B<SYNOPSIS> for default values.

=item B<start>

When you want to start reading frames from network, call this method.

=item B<stop>

When you want to stop reading frames from network, call this method.

=item B<next>

Returns the next captured frame; undef if none awaiting. Each time this method is called, a comparison is done to see if no frame has been captured during B<timeoutOnNext> number of seconds. If so, B<timeout> attribute is set to 1 to reflect the pending timeout.

=item B<store> (B<Net::Frame::Simple> object)

This method will store internally, sorted, the B<Net::Frame::Simple> object passed as a single parameter. B<getKey> methods, implemented in various B<Net::Frame::Layer> objects will be used to efficiently retrieve (via B<getKeyReverse> method) frames.

Basically, it is used to make B<recv> method (from B<Net::Frame::Simple>) to retrieve quickly the reply frame for a request frame.

=item B<getFramesFor> (B<Net::Frame::Simple> object)

This will return an array of possible reply frames for the specified B<Net::Frame::Simple> object. For example, reply frames for a UDP probe will be all the frames which have the same source port and destination port as the request.

=item B<flush>

Will flush stored frames, the one which have been stored via B<store> method.

=item B<timeoutReset>

Reset the internal timeout state (B<timeout> attribute).

=item B<getStats>

Tries to get packet statistics on an open descriptor. It returns a reference to a hash that has to following fields: B<ps_recv>, B<ps_drop>, B<ps_ifdrop>.

=item B<isFather>

=item B<isSon>

These methods will tell you if your current process is respectively the father, or son process of B<Net::Frame::Dump::Online> object.

=back

=head1 SEE ALSO

L<Net::Frame::Dump>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
