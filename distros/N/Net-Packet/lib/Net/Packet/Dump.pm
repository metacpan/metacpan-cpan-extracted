#
# $Id: Dump.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::Dump;
use strict;
use warnings;
use Carp;

require Class::Gomor::Array;
our @ISA = qw(Class::Gomor::Array);

use Net::Packet::Env qw($Env);
require Net::Packet::Frame;
use Net::Packet::Utils qw(getRandom32bitsInt);
use Net::Packet::Consts qw(:dump :layer);

use Net::Pcap;
use Time::HiRes qw(gettimeofday);
use Storable qw(lock_store lock_retrieve);

our @AS = qw(
   dev
   env
   file
   filter
   overwrite
   timeoutOnNext
   timeout
   promisc
   link
   nextFrame
   isRunning
   unlinkOnClean
   noStore
   noLayerWipe
   mode
   keepTimestamp
   snaplen
   _pid
   _pcapd
   _dumper
   _stats
   _firstTime
   _sName
   _sDataAwaiting
);
our @AA = qw(
   frames
);
our @AO = qw(
   framesSorted
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray(\@AA);

no strict 'vars';

BEGIN {
   my $osname = {
      cygwin  => \&_killTcpdumpWin32,
      MSWin32 => \&_killTcpdumpWin32,
   };

   *_killTcpdump = $osname->{$^O} || \&_killTcpdumpOther;
}

sub new {
   my $self = shift->SUPER::new(
      dev        => $Env->dev,
      env        => $Env,
      file       => "netpacket-tmp-$$.@{[getRandom32bitsInt()]}.pcap",
      filter     => '',
      overwrite  => 0,
      timeout    => 0,
      promisc    => 0,
      timeoutOnNext  => 3,
      isRunning      => 0,
      unlinkOnClean  => 1,
      noStore        => 0,
      noLayerWipe    => 0,
      framesSorted   => {},
      frames         => [],
      mode           => NP_DUMP_MODE_ONLINE,
      keepTimestamp  => 0,
      snaplen        => 1514,
      _sDataAwaiting => 0,
      _sName         => "netpacket-tmp-$$.@{[getRandom32bitsInt()]}.storable",
      @_,
   );

   unless ($self->[$__file]) {
      confess("You MUST set `file' attribute\n");
   }

   $Env->dump($self) unless $Env->noDumpAutoSet;

   $self;
}

sub isModeOnline  { shift->[$__mode] eq NP_DUMP_MODE_ONLINE  }
sub isModeOffline { shift->[$__mode] eq NP_DUMP_MODE_OFFLINE }
sub isModeWriter  { shift->[$__mode] eq NP_DUMP_MODE_WRITER  }

sub start {
   my $self = shift;

   $self->cgDebugPrint(1, 'will run in mode: '.$self->mode);

   $self->[$__isRunning] = 1;

   if ($self->isModeOnline) {
      if (-f $self->[$__file] && ! $self->[$__overwrite]) {
         croak("We will not overwrite a file by default. Use `overwrite' ".
               "attribute to do it\n");
      }
      $self->_sStore(0);
      $self->_waitFileSize($self->[$___sName]);
      $self->_startTcpdump;
      $self->_openFileOffline;
   }
   elsif ($self->isModeOffline) {
      if (! -f $self->[$__file]) {
         croak("File does not exists: ".$self->[$__file]."\n");
      }
      $self->_openFileOffline;
      $self->_setFilter;
   }
   elsif ($self->isModeWriter) {
      if (-f $self->[$__file] && ! $self->[$__overwrite]) {
         croak("We will not overwrite a file by default. Use `overwrite' ".
               "attribute to do it\n");
      }
      $self->_openFileWriter;
   }

   1;
}

sub stop {
   my $self = shift;

   return unless $self->[$__isRunning];
   return if     $self->isSon;

   if ($self->isModeOnline) {
      $self->_killTcpdump;
      $self->[$___pid] = undef;
      if ($self->[$___sName] && -f $self->[$___sName]) {
         unlink($self->[$___sName]);
      }
   }
   elsif ($self->isModeWriter) {
      Net::Pcap::dump_close($self->[$___dumper]);
   }
   elsif ($self->isModeOffline) {
      # Nothing to do here
   }

   Net::Pcap::close($self->[$___pcapd]);
   $self->[$__isRunning] = 0;

   1;
}

sub isFather { shift->[$___pid] ? 1 : 0 }
sub isSon    { shift->[$___pid] ? 0 : 1 }

sub _sStore {
   lock_store(\$_[1], $_[0]->[$___sName])
      or carp("@{[(caller(0))[3]]}: lock_store: @{[$_[0]->[$___sName]]}: $!\n");
}
sub _sRetrieve { ${lock_retrieve(shift->[$___sName])} }

sub _sonPrintStats {
   my $self = shift;

   my $stats = $self->getStats;
   Net::Pcap::breakloop($self->[$___pcapd]);
   Net::Pcap::close($self->[$___pcapd]);

   $self->cgDebugPrint(1, 'Frames received  : '.$stats->{ps_recv});
   $self->cgDebugPrint(1, 'Frames dropped   : '.$stats->{ps_drop});
   $self->cgDebugPrint(1, 'Frames if dropped: '.$stats->{ps_ifdrop});
   exit(0);
}

sub _waitFile {
   my $self = shift;
   my ($file) = @_;
   my $startTime = gettimeofday();
   my $thisTime  = $startTime;
   while (! -f $file) {
      if ($thisTime - $startTime > 10) {
         croak("@{[(caller(0))[3]]}: too long for file creation: $file\n")
      }
      $thisTime = gettimeofday();
   }
}

sub _waitFileSize {
   my $self = shift;
   my ($file) = @_;

   $self->_waitFile($file);

   my $startTime = gettimeofday();
   my $thisTime  = $startTime;
   while (! ((stat($file))[7] > 0)) {
      if ($thisTime - $startTime > 10) {
         $self->clean;
         croak("@{[(caller(0))[3]]}: too long for file creation2: $file\n")
      }
      $thisTime = gettimeofday();
   }
}

sub _startTcpdump {
   my $self = shift;

   my $err;
   my $pd = Net::Pcap::open_live(
      $self->[$__dev],
      $self->[$__snaplen],
      $self->[$__promisc],
      1000,
      \$err,
   );
   unless ($pd) {
      croak("@{[(caller(0))[3]]}: open_live: $err\n");
   }

   my $net  = 0;
   my $mask = 0;
   Net::Pcap::lookupnet($self->[$__dev], \$net, \$mask, \$err);
   if ($err) {
      carp("@{[(caller(0))[3]]}: lookupnet: $err\n");
   }

   my $fcode;
   if (Net::Pcap::compile($pd, \$fcode, $self->[$__filter], 0, $mask) < 0) {
      croak("@{[(caller(0))[3]]}: compile: ". Net::Pcap::geterr($pd). "\n");
   }

   if (Net::Pcap::setfilter($pd, $fcode) < 0) {
      croak("@{[(caller(0))[3]]}: setfilter: ". Net::Pcap::geterr($pd). "\n");
   }

   my $p = Net::Pcap::dump_open($pd, $self->[$__file]);
   unless ($p) {
      croak("@{[(caller(0))[3]]}: dump_open: ". Net::Pcap::geterr($pd). "\n");
   }
   Net::Pcap::dump_flush($p);

   $SIG{CHLD} = 'IGNORE';

   my $pid = fork();
   croak("@{[(caller(0))[3]]}: fork: $!\n") unless defined $pid;
   if ($pid) {
      $self->[$___pid] = $pid;
      return 1;
   }
   else {
      $self->[$___pcapd] = $pd;
      $SIG{INT}  = sub { $self->_sonPrintStats };
      $SIG{TERM} = sub { $self->_sonPrintStats };
      $self->cgDebugPrint(1, "dev:    [@{[$self->[$__dev]]}]\n".
                             "file:   [@{[$self->[$__file]]}]\n".
                             "filter: [@{[$self->[$__filter]]}]");
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

sub _killTcpdumpWin32 {
   my $self = shift;
   return unless $self->[$___pid];
   kill('KILL', $self->[$___pid]);
}

sub _killTcpdumpOther {
   my $self = shift;
   return unless $self->[$___pid];
   kill('TERM', $self->[$___pid]);
}

sub clean {
   my $self = shift;

   if ($self->isModeOnline) {
      if ($self->[$__unlinkOnClean]
      &&  $self->[$__file] && -f $self->[$__file]) {
         unlink($self->[$__file]);
         $self->cgDebugPrint(1, "@{[$self->[$__file]]} removed");
      }
   }

   if ($self->[$___sName] && -f $self->[$___sName]) {
      unlink($self->[$___sName]);
   }

   1;
}

sub getStats {
   my $self = shift;

   unless ($self->[$___pcapd]) {
      carp("@{[(caller(0))[3]]}: unable to get stats, no pcap descriptor ".
           "opened\n");
      return undef;
   }
   
   my %stats;
   Net::Pcap::stats($self->[$___pcapd], \%stats);
   $self->[$___stats] = \%stats;
   \%stats;
}

sub flush {
   my $self = shift;
   $self->[$__frames]       = [];
   $self->[$__framesSorted] = {};
}

sub _setFilter {
   my $self = shift;
   my $str = $self->[$__filter];

   return unless $str;

   my ($net, $mask, $err);
   Net::Pcap::lookupnet($self->[$__dev], \$net, \$mask, \$err);
   if ($err) {
      croak("@{[(caller(0))[3]]}: Net::Pcap::lookupnet: @{[$self->[$__dev]]}: ".
            "$err\n");
   }

   my $filter;
   Net::Pcap::compile($self->[$___pcapd], \$filter, $str, 0,
                      $mask);
   unless ($filter) {
      croak("@{[(caller(0))[3]]}: Net::Pcap::compile: error\n");
   }

   Net::Pcap::setfilter($self->[$___pcapd], $filter);
}

sub _openFileOffline {
   my $self = shift;

   my $err;
   $self->[$___pcapd] = Net::Pcap::open_offline($self->[$__file], \$err);
   unless ($self->[$___pcapd]) {
      croak("@{[(caller(0))[3]]}: Net::Pcap::open_offline: ".
            "@{[$self->[$__file]]}: $err\n");
   }

   $self->[$__link] = Net::Pcap::datalink($self->[$___pcapd]);
}

sub _getPcapHeader {
   my $self = shift;
   # 24 bytes header of a DLT_RAW pcap file
   "\xd4\xc3\xb2\xa1\x02\x00\x04\x00\x00\x00\x00\x00".
   "\x00\x00\x00\x00\xdc\x05\x00\x00\x0c\x00\x00\x00";
}

sub _openFileWriter {
   my $self = shift;
   my $file = $self->[$__file];

   my $hdr = $self->_getPcapHeader;
   open(my $fh, '>', $file)
      or croak("@{[(caller(0))[3]]}: open: $file: $!\n");
   syswrite($fh, $hdr, length($hdr));
   close($fh);

   my $err;
   my $pcapd = Net::Pcap::open_offline($file, \$err);
   unless ($pcapd) {
      croak("@{[(caller(0))[3]]}: Net::Pcap::open_offline: ".
            "$file: $err\n");
   }
   $self->[$___pcapd] = $pcapd;

   $self->[$___dumper] = Net::Pcap::dump_open($pcapd, $file);
   unless ($self->[$___dumper]) {
      croak("@{[(caller(0))[3]]}: Net::Pcap::dump_open: ".
            Net::Pcap::geterr($pcapd)."\n");
   }

   1;
}

sub _addToFramesSorted {
   my $self = shift;
   my ($frame) = @_;
   if (! $self->[$__env]->doFrameReturnList) {
      $self->framesSorted($frame);
      push @{$self->[$__frames]}, $frame;
   }
   else {
      for my $f (@$frame) {
         $self->framesSorted($f);
         push @{$self->[$__frames]}, $f;
      }
   }
}

sub _getTimestamp {
   my $self = shift;
   my ($hdr) = @_;
   $hdr->{tv_sec}.'.'.sprintf("%06d", $hdr->{tv_usec});
}

sub _setTimestamp {
   my $self = shift;
   my @time = Time::HiRes::gettimeofday();
   $time[0].'.'.sprintf("%06d", $time[1]);
}

my $mapLinks = {
   NP_DUMP_LINK_NULL()   => NP_LAYER_NULL(),
   NP_DUMP_LINK_EN10MB() => NP_LAYER_ETH(),
   NP_DUMP_LINK_RAW()    => NP_LAYER_RAW(),
   NP_DUMP_LINK_SLL()    => NP_LAYER_SLL(),
   NP_DUMP_LINK_PPP()    => NP_LAYER_PPP(),
};

sub _pcapNext {
   my $self = shift;

   my %hdr;
   if (my $raw = Net::Pcap::next($self->[$___pcapd], \%hdr)) {
      my $ts = $self->[$__keepTimestamp] ? $self->_getTimestamp(\%hdr)
                                         : $self->_setTimestamp;
      my $frame = Net::Packet::Frame->new(
         env         => $self->env,
         raw         => $raw,
         timestamp   => $ts,
         encapsulate => $mapLinks->{$self->[$__link]} || NP_LAYER_UNKNOWN,
      ) or return undef;

      $self->_addToFramesSorted($frame) unless $self->[$__noStore];
      return $frame;
   }

   undef;
}

sub _getNextAwaitingFrameOffline {
   my $self = shift;
   $self->_pcapNext;
}

sub _getNextAwaitingFrameOnline {
   my $self = shift;
   my $last = $self->[$___sDataAwaiting];
   my $new  = $self->_sRetrieve;

   # Return if nothing new is awaiting
   return undef if ($new <= $last);

   $self->[$___sDataAwaiting]++;
   $self->_pcapNext;
}

sub _getNextAwaitingFrame {
   my $self = shift;
   $self->isModeOnline ? $self->_getNextAwaitingFrameOnline
                       : $self->_getNextAwaitingFrameOffline;
}

# XXX: need more work
#sub _getNextAwaitingFrames {
   #my $self = shift;
   #my $last = $self->[$___sDataAwaiting];
   #my $new  = $self->_sRetrieve;
   #my $diff = $new - $last;
   #return [] if $diff <= 0; # Nothing awaiting
   #$self->[$___sDataAwaiting] += $diff;
   #my $frames = [];
   #while ($diff--) {
      #push @$frames, $self->_pcapNext;
   #}
   #$frames;
#}

sub _nextTimeoutHandle {
   my $self = shift;

   # Handle timeout
   my $thisTime = gettimeofday()      if     $self->[$__timeoutOnNext];
   $self->[$___firstTime] = $thisTime unless $self->[$___firstTime];

   if ($self->[$__timeoutOnNext] && $self->[$___firstTime]) {
      if (($thisTime - $self->[$___firstTime]) > $self->[$__timeoutOnNext]) {
         $self->[$__timeout]    = 1;
         $self->[$___firstTime] = 0;
         $self->cgDebugPrint(1, "Timeout occured");
         return undef;
      }
   }
   1;
}

sub _nextTimeoutReset { shift->[$___firstTime] = 0 }

sub next {
   my $self = shift;

   unless ($self->[$__isRunning]) {
      croak("You MUST call start() method before using next() method\n");
   }

   $self->_nextTimeoutHandle or return undef;

   my $frame = $self->_getNextAwaitingFrame;
   $self->_nextTimeoutReset if $frame;

   $frame ? do { $self->[$__nextFrame] = $frame } : undef;
}

sub nextAll { my $self = shift; while ($self->next) {} }

sub write {
   my $self = shift;
   my ($frame) = @_;

   unless ($self->isModeWriter) {
      croak("Dump is not in writer mode\n");
   }

   # Rebuild the frame without possible layer 2
   my $new;
   $new .= $frame->l3->raw if $frame->l3;
   $new .= $frame->l4->raw if $frame->l4;
   $new .= $frame->l7->raw if $frame->l7;

   # Create pcap header
   my ($sec, $usec) = split('\.', $frame->timestamp);
   my $hdr = {
      len     => length($new),
      caplen  => length($new),
      tv_sec  => $sec,
      tv_usec => $usec,
   };

   Net::Pcap::pcap_dump($self->[$___dumper], $hdr, $new);
   Net::Pcap::dump_flush($self->[$___dumper]);
}

# XXX: broken for now
#sub nextAll {
   #my $self = shift;
   #$self->_nextTimeoutHandle or return [];

   #my $frames = $self->_getNextAwaitingFrames;
   #$self->_nextTimeoutReset if @$frames;
   #$frames;
#}

sub timeoutReset { shift->[$__timeout] = 0 }

sub framesFor {
   my $self = shift;
   my ($f) = @_;

   my $l2Key = ($f->l2 && $f->l2->getKeyReverse($f)) || 'all';
   my $l3Key = ($f->l3 && $f->l3->getKeyReverse($f)) || 'all';
   my $l4Key = ($f->l4 && $f->l4->getKeyReverse($f)) || 'all';
   my $aref = $self->[$__framesSorted]->{$l2Key}{$l3Key}{$l4Key};

   $aref ? @$aref : ();
}

#
# Other accessors
#

sub framesSorted {
   my $self = shift;
   my ($f) = @_;

   if ($f) {
      # Wipe headers, since if not, framesFor() will not be able to find them.
      # Because if you create a Frame from L3, no headers are set for L2, but 
      # the Dump will have them and store them into the l2Key.
      if ($self->env->desc && ! $self->[$__noLayerWipe]) {
         $f->l2(undef) if ref($self->env->desc) =~ /L3|L4/;
         $f->l3(undef) if ref($self->env->desc) =~ /L4/;
      }

      my $l2Key = ($f->l2 && $f->l2->getKey($f)) || 'all';
      my $l3Key = ($f->l3 && $f->l3->getKey($f)) || 'all';
      my $l4Key = ($f->l4 && $f->l4->getKey($f)) || 'all';
      push @{$self->[$__framesSorted]->{$l2Key}{$l3Key}{$l4Key}}, $f;

      # We store a second time for ICMP messages
      if ($f->isIcmp) {
         my $l3Key = ($f->l3 && $f->l3->is.':'.$f->l3->dst) || 'all';
         push @{$self->[$__framesSorted]->{$l2Key}{$l3Key}{$l4Key}}, $f;
      }
   }

   $self->[$__framesSorted];
}

1;

__END__

=head1 NAME

Net::Packet::Dump - a tcpdump-like object providing frame capturing and more

=head1 SYNOPSIS

   require Net::Packet::Dump;
   use Net::Packet::Consts qw(:dump);

   #
   # Example live capture (sniffer like)
   #

   # Instanciate object
   my $dump = Net::Packet::Dump->new(
      mode          => NP_DUMP_MODE_ONLINE,
      file          => 'live.pcap',
      filter        => 'tcp',
      promisc       => 1,
      snaplen       => 1514,
      noStore       => 1,
      keepTimestamp => 1,
      unlinkOnClean => 0,
      overwrite     => 1,
   );
   # Start capture
   $dump->start;

   while (1) {
      if (my $frame = $dump->next) {
         print $frame->l2->print, "\n" if $frame->l2;
         print $frame->l3->print, "\n" if $frame->l3;
         print $frame->l4->print, "\n" if $frame->l4;
         print $frame->l7->print, "\n" if $frame->l7;
      }
   }

   # Cleanup
   $dump->stop;
   $dump->clean;

   #
   # Example offline analysis
   #

   my $dump2 = Net::Packet::Dump->new(
      mode          => NP_DUMP_MODE_OFFLINE,
      file          => 'existant-file.pcap',
      unlinkOnClean => 0,
   );

   # Analyze the .pcap file, build an array of Net::Packet::Frame's
   $dump2->start;
   $dump2->nextAll;

   # Browses captured frames
   for ($dump2->frames) {
      # Do what you want
      print $_->l2->print, "\n" if $_->l2;
      print $_->l3->print, "\n" if $_->l3;
      print $_->l4->print, "\n" if $_->l4;
      print $_->l7->print, "\n" if $_->l7;
   }

   # Cleanup
   $dump2->stop;
   $dump2->clean;

   #
   # Example writing mode
   #

   my $dump3 = Net::Packet::Dump->new(
      mode      => NP_DUMP_MODE_WRITER,
      file      => 'write.pcap',
      overwrite => 1,
   );

   $dump3->start;

   # Build or capture some frames here
   my $frame = Net::Packet::Frame->new;

   # Write them
   $dump3->write($frame);

   # Cleanup
   $dump3->stop;
   $dump3->clean;

=head1 DESCRIPTION

This module is the capturing part of Net::Packet framework. It is basically a tcpdump process. When a capture starts, the tcpdump process is forked, and saves all traffic to a .pcap file. The parent process can call B<next> or B<nextAll> to convert captured frames from .pcap file to B<Net::Packet::Frame>s.

Then, you can call B<recv> method on your sent frames to see if a corresponding reply is waiting in the B<frames> array attribute of B<Net::Packet::Dump>.

By default, if you use this module to analyze frames you've sent (very likely ;)), and you've sent those frames at layer 4 (using B<Net::Packet::DescL4>) (for example), lower layers will be wiped on storing in B<frames> array. This behaviour can be disabled by using B<noLayerWipe> attribute.

Since B<Net::Packet> 3.00, it is also possible to create complete .pcap files, thanks to the writer mode (see B<SYNOPSIS>).

=head1 ATTRIBUTES

=over 4

=item B<dev>

By default, this attribute is set to B<dev> found in default B<$Env> object. You can overwrite it by specifying another one in B<new> constructor.

=item B<env>

Stores a B<Net::Packet::Env> object. It is used in B<start> method, for example. The default is to use the global B<$Env> object created when using B<Net::Packet::Env>.

=item B<file>

Where to save captured frames. By default, a random name file is chosen, named like `netpacket-tmp-$$.@{[getRandom32bitsInt()]}.pcap'.

=item B<filter>

A pcap filter to restrain what to capture. It also works in offline mode, to analyze only what you want, and not all traffic. Default to capture all traffic. WARNING: every time a packet passes this filter, and the B<next> method is called, the internal counter used by b<timeoutOnNext> is reset. So the B<timeout> attribute can only be used if you know exactly that the filter will only catch what you want and not perturbating traffic.

=item B<overwrite>

If the B<file> exists, setting this to 1 will overwrite it. Default to not overwrite it.

=item B<timeoutOnNext>

Each time B<next> method is called, an internal counter is incremented if no frame has been captured. When a frame is captured (that is, a frame passed the pcap filter), the B<timeout> attribute is reset to 0. When the counter reaches the value of B<timeoutOnNext>, the B<timeout> attribute is set to 1, meaning no frames have been captured during the specified amount of time. Default to 3 seconds.

=item B<timeout>

Is auto set to 1 when a timeout has occured. It is not reset to 0 automatically, you need to do it yourself.

=item B<promisc>

If you want to capture in promiscuous mode, set it to 1. Default to 0.

=item B<snaplen>

If you want to capture a different snaplen, set it a number. Default to 1514.

=item B<link>

This attribute tells which datalink type is used for .pcap files.

=item B<nextFrame>

This one stores a pointer to the latest received frame after a call to B<next> method. If a B<next> call is done, and no frame is received, this attribute is set to undef.

=item B<isRunning>

When the capturing process is running (B<start> has been called), this is set to 1. So, when B<start> method has been called, it is set to 1, and when B<stop> method is called, set to 0.

=item B<unlinkOnClean>

When the B<clean> method is called, and this attribute is set to 1, the B<file> is deleted from disk. Set it to 0 to avoid this behaviour. BEWARE: default to 1.

=item B<noStore>

If you set this attribute to 1, frames will not be stored in B<frames> array. It is used in sniffer-like programs, in order to avoid memory exhaustion by keeping all captured B<Net::Packet::Frame> into memory. Default is to store frames.

=item B<noLayerWipe>

As explained in DESCRIPTION, if you send packets at layer 4, layer 2 and 3 are not keeped when stored in B<frames>. The same is true when sending at layer 3 (layer 2 is not kept). Default to wipe those layers. WARNING: if you set it to 1, and you need the B<recv> method from B<Net::Packet::Frame>, it will fail. In fact, this is a speed improvements, that is in order to find matching frame for your request, they are stored in a hash, using layer as keys (B<getKey> and B<getKeyReverse> are used to get keys from each layer. So, if you do not wipe layers, a key will be used to store the frame, but another will be used to search for it, and no match will be found. This is a current limitation I'm working on to remove.

=item B<mode>

When you crate a B<Net::Packet::Dump>, you have 3 possible modes : online, offline and writer. You need to load constants from B<Net::Packet::Consts> to have access to that (see B<SYNOPSIS>). The three constants are:

NP_DUMP_MODE_ONLINE

NP_DUMP_MODE_OFFLINE

NP_DUMP_MODE_WRITER

Default behaviour is to use online mode.

=item B<keepTimestamp>

Sometimes, when frames are captured and saved to a .pcap file, timestamps sucks. That is, you send a frame, and receive the reply, but your request appear to have been sent after the reply. So, to correct that, you can use B<Net::Packet> framework own timestamping system. The default is 0. Set it manually to 1 if you need original .pcap frames timestamps.

=item B<frames> [is an arrayref]

Stores all analyzed frames found in a pcap file in this arrayref.

=item B<framesSorted> [is an hashref]

Stores all analyzed frames found in a pcap file in this hashref, using keys to store and search related frames request/replies.

=back

=head1 METHODS

=over 4

=item B<new>

Object contructor. Default values for attributes:

dev:             $Env->dev

env:             $Env

file:            "netpacket-tmp-$$.@{[getRandom32bitsInt()]}.pcap"

filter:          ''

overwrite:       0

timeout:         0

promisc:         0

snaplen:         1514

timeoutOnNext:   3

isRunning:       0

unlinkOnClean:   1

noStore:         0

noLayerWipe:     0

mode:            NP_DUMP_MODE_ONLINE

keepTimestamp:   0

=item B<isModeOnline>

=item B<isModeOffline>

=item B<isModeWriter>

Returns 1 if B<Net::Packet::Dump> object is respectively set to online, offline or writer mode. 0 otherwise.

=item B<start>

You MUST manually call this method to start frame capture, whatever mode you are in. In online mode, it will fork a tcpdump-like process to save captured frames to a .pcap file. It will not overwrite an existing file by default, use B<overwrite> attribute for that. In offline mode, it will only provide analyzing methods. In writer mode, it will only provide writing methods for frames. It will set B<isRunning> attribute to 1 when called.

=item B<stop>

You MUST manually call this method to stop the process. In online mode, it will not remove the generated .pcap file, you MUST call B<clean> method. In offline mode, it will to nothing. In writer mode, it will call B<Net::Pcap::dump_close> method. Then, it will set B<isRunning> attribute to 0.

=item B<isFather>

=item B<isSon>

These methods will tell you if your current process is respectively the father, or son process of B<Net::Packet::Dump> object.

=item B<clean>

You MUST call this method manually. It will never be called by B<Net::Packet> framework. This method will remove the generated .pcap file in online mode if the B<unlinkOnClean> attribute is set to 1. In other modes, it will do nothing.

=item B<getStats>

Tries to get packet statistics on an open descriptor. It returns a reference to a hash that has to following fields: B<ps_recv>, B<ps_drop>, B<ps_ifdrop>.

=item B<flush>

Will removed all analyzed frames from B<frames> array and B<framesSorted> hash. Use it with caution, because B<recv> from B<Net::Packet::Frame> relies on those.

=item B<next>

Returns the next captured frame; undef if none found in .pcap file. In all cases, B<nextFrame> attribute is set (either to the captured frame or undef). Each time this method is run, a comparison is done to see if no frame has been captured during B<timeoutOnNext> amount of seconds. If so, B<timeout> attribute is set to 1 to reflect the pending timeout. When a frame is received, it is stored in B<frames> arrayref, and in B<framesSorted> hashref, used to quickly B<recv> it (see B<Net::Packet::Frame>), and internal counter for time elapsed since last received packet is reset.

=item B<nextAll>

Calls B<next> method until it returns undef (meaning no new frame waiting to be analyzed from pcap file).

=item B<write> (scalar)

In writer mode, this method takes a B<Net::Packet::Frame> as a parameter, and writes it to the .pcap file. Works only in writer mode.

=item B<timeoutReset>

Used to reset manually the B<timeout> attribute. This is a helper method.

=item B<framesFor> (scalar)

You pass a B<Net::Packet::Frame> has parameter, and it returns an array of all frames relating to the connection. For example, when you send a TCP SYN packet, this method will return TCP packets relating to the used source/destination IP, source/destination port, and also related ICMP packets.

=item B<framesSorted> (scalar)

Method mostly used internally to store in a hashref a captured frame. This is used to retrieve it quickly on B<recv> call.

=back

=head1 CONSTANTS

=over 4

=item B<NP_DUMP_LINK_NULL>

=item B<NP_DUMP_LINK_EN10MB>

=item B<NP_DUMP_LINK_RAW>

=item B<NP_DUMP_LINK_SLL>

Constants for first layers within the pcap file.

=item B<NP_DUMP_MODE_OFFLINE>

=item B<NP_DUMP_MODE_ONLINE>

=item B<NP_DUMP_MODE_WRITER>

Constants to set the dump mode.

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 RELATED MODULES

L<NetPacket>, L<Net::RawIP>, L<Net::RawSock>

=cut
