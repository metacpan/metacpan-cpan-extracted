#
# $Id: Writer.pm 364 2014-11-30 11:26:27Z gomor $
#
package Net::Frame::Dump::Writer;
use strict;
use warnings;

use base qw(Net::Frame::Dump);
our @AS = qw(
   append
   _fd
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Dump qw(:consts);

sub new {
   my $self = shift->SUPER::new(
      firstLayer => 'RAW',
      append     => 0,
      overwrite  => 0,
      @_,
   );

   return $self;
}

my $mapLinks = {
   'NULL'            => NF_DUMP_LAYER_NULL(),
   'ETH'             => NF_DUMP_LAYER_ETH(),
   'PPP'             => NF_DUMP_LAYER_PPP(),
   'RAW'             => NF_DUMP_LAYER_RAW(),
   '80211'           => NF_DUMP_LAYER_80211(),
   'SLL'             => NF_DUMP_LAYER_SLL(),
   '80211::Radiotap' => NF_DUMP_LAYER_80211_RADIOTAP(),
   'ERF'             => NF_DUMP_LAYER_ERF(),
};

sub _getPcapHeader {
   my $self = shift;

   my $dlt = $mapLinks->{$self->firstLayer} or do {
      print("[-] ".__PACKAGE__.": Can't get pcap header information for ".
            "this layer type\n");
      return;
   };

   # http://wiki.wireshark.org/Development/LibpcapFileFormat
   return CORE::pack('VvvVVVV',
      0xa1b2c3d4, # magic number
      2,          # major version number
      4,          # minor version number
      0,          # GMT to local correction
      0,          # accuracy of timestamps
      1500,       # max length of captured packets, in octets
      $dlt,       # data link type
   );
}

sub _openFile {
   my $self = shift;

   my $file = $self->file;
   if (-f $self->file && $self->append) {
      open(my $fd, '>>', $file) or do {
         print("[-] ".__PACKAGE__.": open[append]: $file: $!\n");
         return;
      };
      $self->_fd($fd);
   }
   elsif (!-f $self->file || $self->overwrite) {
      my $hdr = $self->_getPcapHeader;
      open(my $fd, '>', $file) or do {
         print("[-] ".__PACKAGE__.": open[overwrite]: $file: $!\n");
         return;
      };
      my $r = syswrite($fd, $hdr, length($hdr));
      if (!defined($r)) {
         print("[-] ".__PACKAGE__.": syswrite: $file: $!\n");
         return;
      }
      $self->_fd($fd);
   }

   return 1;
}

sub start {
   my $self = shift;

   $self->isRunning(1);

   if (-f $self->file && !$self->overwrite && !$self->append) {
      print("[-] ".__PACKAGE__.": We will not overwrite a file by default. ".
            "Use `overwrite' attribute to do it or use `append' mode\n");
      return;
   }

   $self->_openFile;

   return 1;
}

sub stop {
   my $self = shift;

   if (!$self->isRunning) {
      return;
   }

   if (defined($self->_fd)) {
      close($self->_fd);
      $self->_fd(undef);
   }

   $self->isRunning(0);

   return 1;
}

sub write {
   my $self = shift;
   my ($h) = @_;

   if (!defined($self->_fd)) {
      print("[-] ".__PACKAGE__.": file @{[$self->file]} not open for ".
           "writing\n");
      return;
   }

   my $raw = $h->{raw};
   my $ts  = $h->{timestamp};
   my $len = length($raw);

   # Create record header
   my ($sec, $usec) = split('\.', $ts);
   my $recHdr = CORE::pack('VVVV',
      $sec,
      $usec,
      $len,
      $len,
   );
   my $r = syswrite($self->_fd, $recHdr.$raw, length($recHdr.$raw));
   if (!defined($r)) {
      print("[-] ".__PACKAGE__.": syswrite: @{[$self->file]}: $!\n");
      return;
   }

   return $r;
}

1;

__END__

=head1 NAME

Net::Frame::Dump::Writer - tcpdump like implementation, writer mode

=head1 SYNOPSIS

   use Net::Frame::Dump::Writer;

   my $oDump = Net::Frame::Dump::Writer->new(
      file       => 'new-file.pcap',
      firstLayer => 'ETH',
   );

   $oDump->start;

   $oDump->write({ timestamp => '10.10', raw => ('A' x 14) });

   $oDump->stop;

=head1 DESCRIPTION

This module implements a pcap file builder. You will be able to create frames, then write them in the pcap file format to a file.

=head1 ATTRIBUTES

The following are inherited attributes:

=over 4

=item B<file>

Name of the .pcap file to generate.

=item B<overwrite>

Overwrites a .pcap file that already exists. Default to not.

=item B<append>

Append new frames to an existing pcap file. Create it if does not exists yet.

=item B<firstLayer>

Stores information about the first layer type. It is used to write .pcap file header information.

=item B<isRunning>

Returns true if a call to B<start> has been done, false otherwise or if a call to B<stop> has been done.

=back

=head1 METHODS

=over 4

=item B<new>

=item B<new> (hash)

Object constructor. You can pass attributes that will overwrite default ones. See B<SYNOPSIS> for default values.

=item B<start>

When you want to start writing frames to the file, call this method.

=item B<stop>

When you want to stop writing frames to the file, call this method.

=item B<write> ({ timestamp => $value, raw => $rawFrame })

Takes a hashref as a parameter. This hashref MUST have timestamp and raw keys, with values. The raw data will be stored to the .pcap file.

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
