#
# $Id: NTP.pm 49 2012-11-19 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::NTP;
use strict; use warnings;

our $VERSION = '1.02';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_NTP_ADJ
      NF_NTP_LI_NOWARN
      NF_NTP_LI_61
      NF_NTP_LI_59
      NF_NTP_LI_ALARM
      NF_NTP_MODE_RSVD
      NF_NTP_MODE_SYMACTIVE
      NF_NTP_MODE_SYMPASSIVE
      NF_NTP_MODE_CLIENT
      NF_NTP_MODE_SERVER
      NF_NTP_MODE_BROADCAST
      NF_NTP_MODE_NTPCONTROL
      NF_NTP_MODE_PRIVATE
      NF_NTP_STRATUM_UNSPEC
      NF_NTP_STRATUM_PRIMARY
      NF_NTP_STRATUM_UNSYNC
      NF_NTP_REFID_GOES
      NF_NTP_REFID_GPS
      NF_NTP_REFID_GAL
      NF_NTP_REFID_PPS
      NF_NTP_REFID_IRIG
      NF_NTP_REFID_WWVB
      NF_NTP_REFID_DCF
      NF_NTP_REFID_HBG
      NF_NTP_REFID_MSF
      NF_NTP_REFID_JJY
      NF_NTP_REFID_LORC
      NF_NTP_REFID_TDF
      NF_NTP_REFID_CHU
      NF_NTP_REFID_WWV
      NF_NTP_REFID_WWVH
      NF_NTP_REFID_NIST
      NF_NTP_REFID_ACTS
      NF_NTP_REFID_USNO
      NF_NTP_REFID_PTB
      NF_NTP_KoD_ACST
      NF_NTP_KoD_AUTH
      NF_NTP_KoD_AUTO
      NF_NTP_KoD_BCST
      NF_NTP_KoD_CRYP
      NF_NTP_KoD_DENY
      NF_NTP_KoD_DROP
      NF_NTP_KoD_RSTR
      NF_NTP_KoD_INIT
      NF_NTP_KoD_MCST
      NF_NTP_KoD_NKEY
      NF_NTP_KoD_RATE
      NF_NTP_KoD_RMOT
      NF_NTP_KoD_STEP
   )],
   subs => [qw(
      ntpTimestamp
      ntp2date
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
   @{$EXPORT_TAGS{subs}},
);

use constant NF_NTP_ADJ             => 2208988800;
use constant NF_NTP_LI_NOWARN       => 0;
use constant NF_NTP_LI_61           => 1;
use constant NF_NTP_LI_59           => 2;
use constant NF_NTP_LI_ALARM        => 3;
use constant NF_NTP_MODE_RSVD       => 0;
use constant NF_NTP_MODE_SYMACTIVE  => 1;
use constant NF_NTP_MODE_SYMPASSIVE => 2;
use constant NF_NTP_MODE_CLIENT     => 3;
use constant NF_NTP_MODE_SERVER     => 4;
use constant NF_NTP_MODE_BROADCAST  => 5;
use constant NF_NTP_MODE_NTPCONTROL => 6;
use constant NF_NTP_MODE_PRIVATE    => 7;
use constant NF_NTP_STRATUM_UNSPEC  => 0;
use constant NF_NTP_STRATUM_PRIMARY => 1;
use constant NF_NTP_STRATUM_UNSYNC  => 16;
use constant NF_NTP_REFID_GOES      => 0x474f4553;
use constant NF_NTP_REFID_GPS       => 0x47505300;
use constant NF_NTP_REFID_GAL       => 0x47414c00;
use constant NF_NTP_REFID_PPS       => 0x50505300;
use constant NF_NTP_REFID_IRIG      => 0x49524947;
use constant NF_NTP_REFID_WWVB      => 0x57575642;
use constant NF_NTP_REFID_DCF       => 0x44434600;
use constant NF_NTP_REFID_HBG       => 0x48424700;
use constant NF_NTP_REFID_MSF       => 0x4d534600;
use constant NF_NTP_REFID_JJY       => 0x4a4a5900;
use constant NF_NTP_REFID_LORC      => 0x4c4f5243;
use constant NF_NTP_REFID_TDF       => 0x54444600;
use constant NF_NTP_REFID_CHU       => 0x43485500;
use constant NF_NTP_REFID_WWV       => 0x57575600;
use constant NF_NTP_REFID_WWVH      => 0x57575648;
use constant NF_NTP_REFID_NIST      => 0x4e495354;
use constant NF_NTP_REFID_ACTS      => 0x41435453;
use constant NF_NTP_REFID_USNO      => 0x55534e4f;
use constant NF_NTP_REFID_PTB       => 0x50544200;
use constant NF_NTP_KoD_ACST        => 0x41435354;
use constant NF_NTP_KoD_AUTH        => 0x41555448;
use constant NF_NTP_KoD_AUTO        => 0x4155544f;
use constant NF_NTP_KoD_BCST        => 0x42435354;
use constant NF_NTP_KoD_CRYP        => 0x43525950;
use constant NF_NTP_KoD_DENY        => 0x44454e59;
use constant NF_NTP_KoD_DROP        => 0x44524f50;
use constant NF_NTP_KoD_RSTR        => 0x52535452;
use constant NF_NTP_KoD_INIT        => 0x494e4954;
use constant NF_NTP_KoD_MCST        => 0x4d435354;
use constant NF_NTP_KoD_NKEY        => 0x4e4b4559;
use constant NF_NTP_KoD_RATE        => 0x52415445;
use constant NF_NTP_KoD_RMOT        => 0x524d4f54;
use constant NF_NTP_KoD_STEP        => 0x53544550;

our @AS = qw(
   leap
   version
   mode
   stratum
   poll
   precision
   rootDelay
   rootDisp
   refId
   refTime
   refTime_frac
   org
   org_frac
   rec
   rec_frac
   xmt
   xmt_frac
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';

use Bit::Vector;
use Time::HiRes qw (time);

$Net::Frame::Layer::UDP::Next->{123} = "NTP";

sub new {

   shift->SUPER::new(
      leap         => NF_NTP_LI_NOWARN,
      version      => 3,
      mode         => NF_NTP_MODE_CLIENT,
      stratum      => NF_NTP_STRATUM_UNSPEC,
      poll         => 0,
      precision    => 0,
      rootDelay    => 0,
      rootDisp     => 0,
      refId        => 0,
      refTime      => 0,
      refTime_frac => 0,
      org          => 0,
      org_frac     => 0,
      rec          => 0,
      rec_frac     => 0,
      xmt          => ntpTimestamp(time),
      xmt_frac     => 0,
      @_,
   );
}

sub getLength { 48 }

sub pack {
   my $self = shift;

   my $leap    = Bit::Vector->new_Dec(2, $self->leap);
   my $version = Bit::Vector->new_Dec(3, $self->version);
   my $mode    = Bit::Vector->new_Dec(3, $self->mode);
   my $bvlist  = $leap->Concat_List($version, $mode);

   my $raw = $self->SUPER::pack('CCCC N11',
      $bvlist->to_Dec,
      $self->stratum,
      $self->poll,
      $self->precision,
      $self->rootDelay,
      $self->rootDisp,
      $self->refId,
      $self->refTime,
      $self->refTime_frac,
      $self->org,
      $self->org_frac,
      $self->rec,
      $self->rec_frac,
      $self->xmt,
      $self->xmt_frac,
   ) or return;

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($bv, $stratum, $poll, $precision,
       $rootDelay, $rootDisp, 
       $refId,
       $refTime, $refTime_frac,
       $org, $org_frac,
       $rec, $rec_frac,
       $xmt, $xmt_frac,
       $payload) =
      $self->SUPER::unpack('CCCC N N H8 N8 a*', $self->raw)
         or return;

   my $bvlist = Bit::Vector->new_Dec(8, $bv);
   $self->leap   ($bvlist->Chunk_Read(2,6));
   $self->version($bvlist->Chunk_Read(3,3));
   $self->mode   ($bvlist->Chunk_Read(3,0));

   $self->stratum($stratum);
   $self->poll($poll);
   $self->precision($precision);
   $self->rootDelay($rootDelay);
   $self->rootDisp($rootDisp);
   $self->refId(_unpack_refid($stratum, $refId));
   $self->refTime($refTime);
   $self->refTime_frac($refTime_frac);
   $self->org($org);
   $self->org_frac($org_frac);
   $self->rec($rec);
   $self->rec_frac($rec_frac);
   $self->xmt($xmt);
   $self->xmt_frac($xmt_frac);

   $self->payload($payload);

   return $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   # Needed?
   if ($self->payload) {
      return 'NTP';
   }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $refTime_frac = _bin2frac(_dec2bin($self->refTime_frac));
   my $org_frac = _bin2frac(_dec2bin($self->org_frac));
   my $rec_frac = _bin2frac(_dec2bin($self->rec_frac));
   my $xmt_frac = _bin2frac(_dec2bin($self->xmt_frac));

   my $l = $self->layer;
   my $buf = sprintf
      "$l: leap:%d  version:%d  mode:%d  stratum:%d\n".
      "$l: poll:%d  precision:%d\n".
      "$l: rootDelay:%d  rootDisp:%d  refId:%s\n".
      "$l: refTime:%d   refTime_frac:%s\n".
#      "$l:   [%s%s]\n".
      "$l: org:%d  org_frac:%s\n".
#      "$l:   [%s%s]\n".
      "$l: rec:%d  rec_frac:%s\n".
#      "$l:   [%s%s]\n".
      "$l: xmt:%d  xmt_frac:%s\n",
#      "$l:   [%s%s]",
         $self->leap, $self->version, $self->mode, $self->stratum,
         $self->poll, $self->precision,
         $self->rootDelay, $self->rootDisp, $self->refId,
         $self->refTime, $self->refTime_frac,
#         _getTime($self->refTime + $refTime_frac - NF_NTP_ADJ), substr($refTime_frac, 1),
         $self->org, $self->org_frac, 
#         _getTime($self->org + $org_frac - NF_NTP_ADJ), substr($org_frac, 1),
         $self->rec, $self->rec_frac, 
#         _getTime($self->rec + $rec_frac - NF_NTP_ADJ), substr($rec_frac, 1),
         $self->xmt, $self->xmt_frac;
#         _getTime($self->xmt + $xmt_frac - NF_NTP_ADJ), substr($xmt_frac, 1);

   return $buf;
}

####

sub ntp2date {
   my ($time, $frac) = @_;
   my $adj_frac = _bin2frac(_dec2bin($frac));
   my $ts = _getTime($time + $adj_frac - NF_NTP_ADJ) . substr($adj_frac, 1) . " UTC";
   return $ts
}

sub ntpTimestamp {
   return int(shift() + NF_NTP_ADJ);
}

sub _unpack_refid {
    my $stratum = shift;
    my $raw_id  = shift;
    if ($stratum < 2) {
        return CORE::unpack("A4", CORE::pack("H8", $raw_id));
    }
    return sprintf("%d.%d.%d.%d", CORE::unpack("C4", CORE::pack("H8", $raw_id)));
}

sub _dec2bin {
    my $str = CORE::unpack("B32", CORE::pack("N", shift));
    return $str;
}

sub _frac2bin {
    my $bin  = '';
    my $frac = shift;
    while (length($bin) < 32) {
        $bin = $bin . int($frac * 2);
        $frac = ($frac * 2) - (int($frac * 2));
    }
    return $bin;
}

sub _bin2frac {
    my @bin = split '', shift;
    my $frac = 0;
    while (@bin) {
        $frac = ($frac + pop @bin) / 2;
    }
    return $frac;
}

sub _getTime {
   my @time = gmtime(shift);
   my @month = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
   my $ts =
        $month[ $time[4] ] . " "
      . ( ( $time[3] < 10 ) ? ( " " . $time[3] ) : $time[3] ) . " "
      . (1900 + $time[5]) . " "
      . ( ( $time[2] < 10 ) ? ( "0" . $time[2] ) : $time[2] ) . ":"
      . ( ( $time[1] < 10 ) ? ( "0" . $time[1] ) : $time[1] ) . ":"
      . ( ( $time[0] < 10 ) ? ( "0" . $time[0] ) : $time[0] );

   return $ts
}

1;

__END__

=head1 NAME

Net::Frame::Layer::NTP - NTP layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::NTP qw(:consts);

   my $layer = Net::Frame::Layer::NTP->new(
      leap         => NF_NTP_LI_NOWARN,
      version      => 3,
      mode         => NF_NTP_MODE_CLIENT,
      stratum      => NF_NTP_STRATUM_UNSPEC,
      poll         => 0,
      precision    => 0,
      rootDelay    => 0,
      rootDisp     => 0,
      refId        => 0,
      refTime      => 0,
      refTime_frac => 0,
      org          => 0,
      org_frac     => 0,
      rec          => 0,
      rec_frac     => 0,
      xmt          => ntpTimestamp(time),
      xmt_frac     => 0,
   );

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::NTP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the NTP layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc1305.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<leap>

NTP Leap Indicator.  See B<CONSTANTS> for more information.

=item B<version>

NTP version.

=item B<mode>

NTP mode.  See B<CONSTANTS> for more information.

=item B<stratum>

NTP stratum.  See B<CONSTANTS> for more information.

=item B<poll>

Maximum poll interval between messages in seconds to the nearest power of two.

=item B<precision>

Precision of the local clock in seconds to the nearest power of two.

=item B<rootDelay>

Total roundtrip delay to the primary reference source, in seconds with the fraction point between bits 15 and 16.

=item B<rootDisp>

Maximum error relative to the primary reference source in seconds with the fraction point between bits 15 and 16.

=item B<refId>

In the case of stratum 2 or greater, this is the IPv4 address of the primary reference host.  In the case of stratum 0 or 1, this is a four byte, left-justified, zero padded ASCII string.

=item B<ref>

=item B<ref_frac>

The local time at which the local clock was last set or corrected and the fractional part.

=item B<org>

=item B<org_frac>

The local time when the client sent the request and the fractional part.

=item B<rec>

=item B<rec_frac>

The local time when the request was received by the server and the fractional part.

=item B<xmt>

=item B<xmt_frac>

The local time when the reply was sent from the server and the fractional part.

=back

The following are inherited attributes. See B<Net::Frame::Layer> for more information.

=over 4

=item B<raw>

=item B<payload>

=item B<nextLayer>

=back

=head1 METHODS

=over 4

=item B<new>

=item B<new> (hash)

Object constructor. You can pass attributes that will overwrite default ones. See B<SYNOPSIS> for default values.

=back

The following are inherited methods. Some of them may be overriden in this layer, and some others may not be meaningful in this layer. See B<Net::Frame::Layer> for more information.

=over 4

=item B<layer>

=item B<computeLengths>

=item B<pack>

=item B<unpack>

=item B<encapsulate>

=item B<getLength>

=item B<getPayloadLength>

=item B<print>

=item B<dump>

=back

=head1 USEFUL SUBROUTINES

Load them: use Net::Frame::Layer::NTP qw(:subs);

=over 4

=item B<ntpTimestamp> (time)

Create an NTP-adjusted timestamp.

=item B<ntp2date> (time, frac)

Provided the NTP time and fracional timestamps, returns a human-readable time string.

=back

=head1 CONSTANTS

Load them: use Net::Frame::Layer::NTP qw(:consts);

=over 4

=item B<NF_NTP_ADJ>

NTP adjustment (2208988800).

=item B<NF_NTP_LI_NOWARN>

=item B<NF_NTP_LI_61>

=item B<NF_NTP_LI_59>

=item B<NF_NTP_LI_ALARM>

NTP leap indicators.

=item B<NF_NTP_MODE_RSVD>

=item B<NF_NTP_MODE_SYMACTIVE>

=item B<NF_NTP_MODE_SYMPASSIVE>

=item B<NF_NTP_MODE_CLIENT>

=item B<NF_NTP_MODE_SERVER>

=item B<NF_NTP_MODE_BROADCAST>

=item B<NF_NTP_MODE_NTPCONTROL>

=item B<NF_NTP_MODE_PRIVATE>

NTP modes.

=item B<NF_NTP_STRATUM_UNSPEC>

=item B<NF_NTP_STRATUM_PRIMARY>

=item B<NF_NTP_STRATUM_UNSYNC>

NTP stratums.

=item B<NF_NTP_REFID_GOES>

=item B<NF_NTP_REFID_GPS>

=item B<NF_NTP_REFID_GAL>

=item B<NF_NTP_REFID_PPS>

=item B<NF_NTP_REFID_IRIG>

=item B<NF_NTP_REFID_WWVB>

=item B<NF_NTP_REFID_DCF>

=item B<NF_NTP_REFID_HBG>

=item B<NF_NTP_REFID_MSF>

=item B<NF_NTP_REFID_JJY>

=item B<NF_NTP_REFID_LORC>

=item B<NF_NTP_REFID_TDF>

=item B<NF_NTP_REFID_CHU>

=item B<NF_NTP_REFID_WWV>

=item B<NF_NTP_REFID_WWVH>

=item B<NF_NTP_REFID_NIST>

=item B<NF_NTP_REFID_ACTS>

=item B<NF_NTP_REFID_USNO>

=item B<NF_NTP_REFID_PTB>

NTP reference ID codes.

=item B<NF_NTP_KoD_ACST>

=item B<NF_NTP_KoD_AUTH>

=item B<NF_NTP_KoD_AUTO>

=item B<NF_NTP_KoD_BCST>

=item B<NF_NTP_KoD_CRYP>

=item B<NF_NTP_KoD_DENY>

=item B<NF_NTP_KoD_DROP>

=item B<NF_NTP_KoD_RSTR>

=item B<NF_NTP_KoD_INIT>

=item B<NF_NTP_KoD_MCST>

=item B<NF_NTP_KoD_NKEY>

=item B<NF_NTP_KoD_RATE>

=item B<NF_NTP_KoD_RMOT>

=item B<NF_NTP_KoD_STEP>

NTP kiss codes.

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2016, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
