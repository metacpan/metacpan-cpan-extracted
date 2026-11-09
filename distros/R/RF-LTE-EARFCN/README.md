# NAME

RF::LTE::EARFCN - LTE EARFCN Channel to Frequency Converter

# SYNOPSIS

    use RF::LTE::EARFCN;
    my $rf = RF::LTE::EARFCN->new(channel=>5110);
    printf "Channel: %s\n Frequency (dl): %s\n Frequency (ul): %s\n Frequency Separation: %s\n",
           $rf->channel, $rf->fdl, $rf->ful, $rf->fs;

# DESCRIPTION

This LTE EARFCN Channel to Frequency Converter uses the functions and tables in sections 5.7.3 and 5.7.4 of ETSI TS 136 101 V17.6.0 (2022-08) to convert EARFCN Channel to Frequency Downlink (fdl), Frequency Uplink (ful), and Frequency Separation (fs).

The carrier frequency in the uplink and downlink is designated by the E-UTRA Absolute Radio Frequency Channel
Number (EARFCN) in the range 0 - 262143. The relation between EARFCN and the carrier frequency in MHz for the
downlink is given by the following equation, where FDL\_low and NOffs\_DL are given in Table 5.7.3-1 and NDL is the
downlink EARFCN.

    FDL = FDL_low + 0.1(NDL - NOffs_DL)

The relation between EARFCN and the carrier frequency in MHz for the uplink is given by the following equation
where FUL\_low and NOffs\_UL are given in Table 5.7.3-1 and NUL is the uplink EARFCN.

    FUL = FUL_low + 0.1(NUL - NOffs_UL)

The relationship between frequency uplink and frequency downlink can also be calculated using table 5.7.4.

    FDL = FUL + FS
    FUL = FDL - FS

# METHODS

## new

# PROPERTIES

## channel

Sets and returns the EARFCN channel number.  The logic is written so that the channel number can be either the downlink or uplink channel number and the correct frequency calculation is used.

    my $rf = RF::LTE::EARFCN->new(channel=>5110);
    $rf->channel(5110);
    my $channel = $rf->channel;

## channel\_type

Returns either 'ul' or 'dl' based on whether the channel is an uplink or downlink channel number.

    my $channel_type = $rf->channel_type; #ISA String 'dl'||'ul'

## band, fdl\_low, noffs\_dl, range\_ndl\_lower, range\_ndl\_upper, ful\_low, noffs\_ul, range\_nul\_lower, range\_nul\_upper, band\_note2

Returns the table values directly from the table based on the channel.

    my $band = $rf->band;

## fdl

Calculates and returns the downlink carrier frequency in MHz.

    my $frequency_downlink_mhz = $rf->fdl;

The relation between EARFCN and the carrier frequency in MHz for the downlink is given by the following equation, where FDL\_low and NOffs\_DL are given in Table 5.7.3-1 and NDL is the
downlink EARFCN.

    FDL = FDL_low + 0.1(NDL - NOffs_DL)

## ful

Calculates and returns the uplink carrier frequency in MHz.

    my $frequency_uplink_mhz = $rf->ful;

The relation between EARFCN and the carrier frequency in MHz for the uplink is given by the following equation where FUL\_low and NOffs\_UL are given in Table 5.7.3-1 and NUL is the uplink EARFCN.

    FUL = FUL_low + 0.1(NUL - NOffs_UL)

Issue: Does not support Narrow Band IoT options NB1 or NB2.

## fs

Returns the TX-RX frequency separation in MHz from Table 5.7.4-1 based on the band of the channel.

    my $frequency_separation_mhz = $rf->fs;

The default E-UTRA TX channel (carrier center frequency) to RX channel (carrier center frequency) separation is
specified in Table 5.7.4-1 for the TX and RX channel bandwidths defined in Table 5.6.1-1

# SEE ALSO

[https://www.etsi.org/deliver/etsi\_ts/136100\_136199/136101/17.06.00\_60/ts\_136101v170600p.pdf](https://www.etsi.org/deliver/etsi_ts/136100_136199/136101/17.06.00_60/ts_136101v170600p.pdf)
[https://github.com/qvil/lte-earfcn-calculator](https://github.com/qvil/lte-earfcn-calculator)

# AUTHOR

Michael R. Davis

# COPYRIGHT AND LICENSE

Copyright (C) 2026 by Michael R. Davis

License: MIT
