package RF::LTE::EARFCN;
use strict;
use warnings;
use base qw{Package::New};
use Carp qw{croak};

our $VERSION = '0.03';

=head1 NAME

RF::LTE::EARFCN - LTE EARFCN Channel Converter to Band and Frequency

=head1 SYNOPSIS

  use RF::LTE::EARFCN;
  my $rf = RF::LTE::EARFCN->new(channel=>5110);
  say for "Channel: "              . $rf->channel,
          "Channel Type: "         . $rf->channel_type,
          "Band: "                 . $rf->band,
          "Frequency (dl): "       . $rf->fdl,
          "Frequency (ul): "       . $rf->ful,
          "Frequency Separation: " .  $rf->fs;

=head1 DESCRIPTION

This LTE EARFCN Channel to Band and Frequency Converter uses the functions and tables in sections 5.7.3 of ETSI TS 136 101 V17.6.0 (2022-08) to convert EARFCN Channel to Band (band), Frequency Downlink (fdl), Frequency Uplink (ful), and Frequency Separation (fs).

The carrier frequency in the uplink and downlink is designated by the E-UTRA Absolute Radio Frequency Channel
Number (EARFCN) in the range 0 - 262143. The relation between EARFCN and the carrier frequency in MHz for the
downlink is given by the following equation, where FDL_low and NOffs_DL are given in Table 5.7.3-1 and NDL is the
downlink EARFCN.

  FDL = FDL_low + 0.1(NDL - NOffs_DL)

The relation between EARFCN and the carrier frequency in MHz for the uplink is given by the following equation
where FUL_low and NOffs_UL are given in Table 5.7.3-1 and NUL is the uplink EARFCN.

  FUL = FUL_low + 0.1(NUL - NOffs_UL)

=head1 METHODS

=head2 new

=head1 PROPERTIES

=head2 channel

Sets and returns the EARFCN channel number.  The logic is written so that the channel number can be either the downlink or uplink channel number and the correct frequency calculation is used.

  my $rf = RF::LTE::EARFCN->new(channel=>5110);
  $rf->channel(5110);
  my $channel = $rf->channel;

=cut

sub channel {
  my $self = shift;
  if (@_) {
    $self->{'channel'} = shift;
    undef($self->{'_row'});           #clears _row
    undef($self->{'channel_type'});   #clears channel_type
    undef($self->{'channel_offset'}); #clears channel_offset
  }
  croak('Error: channel required')                unless defined $self->{'channel'};
  croak('Error: channel must be zero or greater') unless $self->{'channel'} >= 0;
  return $self->{'channel'};
}

=head2 channel_type

Returns either 'ul' or 'dl' based on whether the channel is an uplink or downlink channel number.

  my $channel_type = $rf->channel_type; #ISA String 'dl'||'ul'

=cut

sub channel_type {
  my $self = shift;
  die('Error: channel_type does not take a parameter') if @_;
  $self->_row unless $self->{'channel_type'};
  croak('Error: channel_type not defined') unless defined $self->{'channel_type'};
  croak('Error: channel_type invalid')     unless ($self->{'channel_type'} eq 'dl' or $self->{'channel_type'} eq 'ul');
  return $self->{'channel_type'};
}

=head2 channel_offset

Returns channel offset used for calculating uplink or downlink EARFCN

  my $channel_offset = $rf->channel_offset; #ISA Int

=cut

sub channel_offset {
  my $self = shift;
  die('Error: channel_offset does not take a parameter') if @_;
  $self->_row unless $self->{'channel_offset'};
  croak('Error: channel_offset not defined') unless defined $self->{'channel_offset'};
  croak('Error: channel_offset invalid')     unless $self->{'channel_offset'} >= 0;
  return $self->{'channel_offset'};
}

# From: https://www.etsi.org/deliver/etsi_ts/136100_136199/136101/17.06.00_60/ts_136101v170600p.pdf
# LTE; Evolved Universal Terrestrial Radio Access (E-UTRA);
#   User Equipment (UE) radio transmission and reception (3GPP TS 36.101 version 17.6.0 Release 17)
# Section: 5.7.3 Carrier frequency and EARFCN
# Table 5.7.3-1: E-UTRA channel numbers
#   Columns
our $BAND_TABLE_INDEX_band            = 0;
our $BAND_TABLE_INDEX_fdl_low         = 1;
our $BAND_TABLE_INDEX_noffs_dl        = 2;
our $BAND_TABLE_INDEX_range_ndl_lower = 2; #same as $BAND_TABLE_INDEX_noffs_dl
our $BAND_TABLE_INDEX_range_ndl_upper = 3;
our $BAND_TABLE_INDEX_ful_low         = 4;
our $BAND_TABLE_INDEX_noffs_ul        = 5;
our $BAND_TABLE_INDEX_range_nul_lower = 5; #same as $BAND_TABLE_INDEX_noffs_ul
our $BAND_TABLE_INDEX_range_nul_upper = 6;

our $BAND_TABLE = [
                   [1  , 2110  ,     0,   599,  1920  ,  18000,  18599],
                   [2  , 1930  ,   600,  1199,  1850  ,  18600,  19199],
                   [3  , 1805  ,  1200,  1949,  1710  ,  19200,  19949],
                   [4  , 2110  ,  1950,  2399,  1710  ,  19950,  20399],
                   [5  ,  869  ,  2400,  2649,   824  ,  20400,  20649],
                   [6  ,  875  ,  2650,  2749,   830  ,  20650,  20749],
                   [7  , 2620  ,  2750,  3449,  2500  ,  20750,  21449],
                   [8  ,  925  ,  3450,  3799,   880  ,  21450,  21799],
                   [9  , 1844.9,  3800,  4149,  1749.9,  21800,  22149],
                   [10 , 2110  ,  4150,  4749,  1710  ,  22150,  22749],
                   [11 , 1475.9,  4750,  4949,  1427.9,  22750,  22949],
                   [12 ,  729  ,  5010,  5179,   699  ,  23010,  23179],
                   [13 ,  746  ,  5180,  5279,   777  ,  23180,  23279],
                   [14 ,  758  ,  5280,  5379,   788  ,  23280,  23379],
                   [17 ,  734  ,  5730,  5849,   704  ,  23730,  23849],
                   [18 ,  860  ,  5850,  5999,   815  ,  23850,  23999],
                   [19 ,  875  ,  6000,  6149,   830  ,  24000,  24149],
                   [20 ,  791  ,  6150,  6449,   832  ,  24150,  24449],
                   [21 , 1495.9,  6450,  6599,  1447.9,  24450,  24599],
                   [22 , 3510  ,  6600,  7399,  3410  ,  24600,  25399],
                   [23 , 2180  ,  7500,  7699,  2000  ,  25500,  25699],
                   [24 , 1525  ,  7700,  8039,  1626.5,  25700,  26039], #Band 24 has optional offset -120.5 MHz (see test case to support)
                   [25 , 1930  ,  8040,  8689,  1850  ,  26040,  26689],
                   [26 ,  859  ,  8690,  9039,   814  ,  26690,  27039],
                   [27 ,  852  ,  9040,  9209,   807  ,  27040,  27209],
                   [28 ,  758  ,  9210,  9659,   703  ,  27210,  27659],
                   [29 ,  717  ,  9660,  9769],
                   [30 , 2350  ,  9770,  9869,  2305  ,  27660,  27759],
                   [31 ,  462.5,  9870,  9919,   452.5,  27760,  27809],
                   [32 , 1452  ,  9920, 10359],
                   [33 , 1900  , 36000, 36199,  1900  ,  36000,  36199],
                   [34 , 2010  , 36200, 36349,  2010  ,  36200,  36349],
                   [35 , 1850  , 36350, 36949,  1850  ,  36350,  36949],
                   [36 , 1930  , 36950, 37549,  1930  ,  36950,  37549],
                   [37 , 1910  , 37550, 37749,  1910  ,  37550,  37749],
                   [38 , 2570  , 37750, 38249,  2570  ,  37750,  38249],
                   [39 , 1880  , 38250, 38649,  1880  ,  38250,  38649],
                   [40 , 2300  , 38650, 39649,  2300  ,  38650,  39649],
                   [41 , 2496  , 39650, 41589,  2496  ,  39650,  41589],
                   [42 , 3400  , 41590, 43589,  3400  ,  41590,  43589],
                   [43 , 3600  , 43590, 45589,  3600  ,  43590,  45589],
                   [44 ,  703  , 45590, 46589,   703  ,  45590,  46589],
                   [45 , 1447  , 46590, 46789,  1447  ,  46590,  46789],
                   [46 , 5150  , 46790, 54539,  5150  ,  46790,  54539],
                   [47 , 5855  , 54540, 55239,  5855  ,  54540,  55239],
                   [48 , 3550  , 55240, 56739,  3550  ,  55240,  56739],
                   [49 , 3550  , 56740, 58239,  3550  ,  56740,  58239],
                   [50 , 1432  , 58240, 59089,  1432  ,  58240,  59089],
                   [51 , 1427  , 59090, 59139,  1427  ,  59090,  59139],
                   [52 , 3300  , 59140, 60139,  3300  ,  59140,  60139],
                   [53 , 2483.5, 60140, 60254,  2483.5,  60140,  60254],
                   [65 , 2110  , 65536, 66435,  1920  , 131072, 131971],
                   [66 , 2110  , 66436, 67335,  1710  , 131972, 132671],
                   [67 ,  738  , 67336, 67535],
                   [68 ,  753  , 67536, 67835,   698  , 132672, 132971],
                   [69 , 2570  , 67836, 68335],
                   [70 , 1995  , 68336, 68585,  1695  , 132972, 133121], #Band 70 has optional offset 295 MHz (TODO)
                   [71 ,  617  , 68586, 68935,   663  , 133122, 133471],
                   [72 ,  461  , 68936, 68985,   451  , 133472, 133521],
                   [73 ,  460  , 68986, 69035,   450  , 133522, 133571],
                   [74 , 1475  , 69036, 69465,  1427  , 133572, 134001],
                   [75 , 1432  , 69466, 70315],
                   [76 , 1427  , 70316, 70365],
                   [85 ,  728  , 70366, 70545,   698  , 134002, 134181],
                   [87 ,  420  , 70546, 70595,   410  , 134182, 134231],
                   [88 ,  422  , 70596, 70645,   412  , 134232, 134281],
                   [103,  757  , 70646, 70655,   787  , 134282, 134291],
                  ];

sub _row {
  my $self    = shift;
  my $channel = $self->channel;
  if (@_) {
    $self->{'_row'}           = undef;
    $self->{'channel_type'}   = undef;
    $self->{'channel_offset'} = undef;
  }
  unless ($self->{'_row'}) {
    my $found;
    foreach my $row (@$BAND_TABLE) {
      if ($row->[$BAND_TABLE_INDEX_range_ndl_lower] <= $channel and $channel <= $row->[$BAND_TABLE_INDEX_range_ndl_upper]) {
        $found                    = $row;
        $self->{'channel_type'}   = 'dl';
        $self->{'channel_offset'} = $channel - $row->[$BAND_TABLE_INDEX_noffs_dl];
      }
      last if $found;
      if (defined($row->[$BAND_TABLE_INDEX_noffs_ul]) and $row->[$BAND_TABLE_INDEX_range_nul_lower] <= $channel and $channel <= $row->[$BAND_TABLE_INDEX_range_nul_upper]) {
        $found                    = $row;
        $self->{'channel_type'}   = 'ul';
        $self->{'channel_offset'} = $channel - $row->[$BAND_TABLE_INDEX_noffs_ul];
      }
      last if $found;
    }
    die(qq{Error: table entry not found for channel "$channel"}) unless $found;
    $self->{'_row'} = $found;
  }
  return $self->{'_row'};
}

=head2 band, fdl_low, noffs_dl, range_ndl_lower, range_ndl_upper, ful_low, noffs_ul, range_nul_lower, range_nul_upper

Returns the table values directly from the table based on the channel.

  my $band = $rf->band;

=cut

sub band            {shift->_row->[$BAND_TABLE_INDEX_band]};
sub fdl_low         {shift->_row->[$BAND_TABLE_INDEX_fdl_low]};
sub noffs_dl        {shift->_row->[$BAND_TABLE_INDEX_noffs_dl]};
sub range_ndl_lower {shift->_row->[$BAND_TABLE_INDEX_range_ndl_lower]};
sub range_ndl_upper {shift->_row->[$BAND_TABLE_INDEX_range_ndl_upper]};
sub ful_low         {shift->_row->[$BAND_TABLE_INDEX_ful_low]};
sub noffs_ul        {shift->_row->[$BAND_TABLE_INDEX_noffs_ul]};
sub range_nul_lower {shift->_row->[$BAND_TABLE_INDEX_range_nul_lower]};
sub range_nul_upper {shift->_row->[$BAND_TABLE_INDEX_range_nul_upper]};

=head2 fdl

Calculates and returns the downlink carrier frequency in MHz.

  my $frequency_downlink_mhz = $rf->fdl;

The relation between EARFCN and the carrier frequency in MHz for the downlink is given by the following equation, where FDL_low and NOffs_DL are given in Table 5.7.3-1 and NDL is the downlink EARFCN.

  FDL = FDL_low + 0.1(NDL - NOffs_DL)

=cut

sub fdl {
  my $self = shift;
  return $self->fdl_low + 0.1 * ($self->channel_offset);
}

=head2 ful

Calculates and returns the uplink carrier frequency in MHz.

  my $frequency_uplink_mhz = $rf->ful;

The relation between EARFCN and the carrier frequency in MHz for the uplink is given by the following equation where FUL_low and NOffs_UL are given in Table 5.7.3-1 and NUL is the uplink EARFCN.

  FUL = FUL_low + 0.1(NUL - NOffs_UL)

Returns undef for bands that are restricted to E-UTRA operation when carrier aggregation is configured.

=cut

sub ful {
  my $self = shift;
  return defined($self->ful_low) ? $self->ful_low + 0.1 * ($self->channel_offset) : undef;
}

=head2 fs

Calculates the TX-RX frequency separation in MHz from Table 5.7.3-1 based on the difference between FDL_low and FUL_low.

  my $frequency_separation_mhz = $rf->fs;

Returns undef for bands that are restricted to E-UTRA operation when carrier aggregation is configured.

=cut

sub fs {
  my $self = shift;
  return defined($self->ful_low) ? $self->fdl_low - $self->ful_low : undef;
}

=head1 SEE ALSO

L<https://www.etsi.org/deliver/etsi_ts/136100_136199/136101/17.06.00_60/ts_136101v170600p.pdf>
L<https://github.com/qvil/lte-earfcn-calculator>

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Michael R. Davis

License: MIT

=cut

1;

