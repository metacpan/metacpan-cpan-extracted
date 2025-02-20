# NAME

RF::Functions - Perl Exporter for Radio Frequency (RF) Functions

# SYNOPSIS

    use RF::Functions qw{db_ratio ratio_db};
    my $db = db_ratio(2); #~3dB

# DESCRIPTION

RF::Functions is a lib for common RF function.  I plan to add additional functions as I need them.

# FUNCTIONS

## db\_ratio, ratio2db

Returns dB given a numerical power ratio.

    my $db = db_ratio(2);   #+3dB
    my $db = db_ratio(1/2); #-3dB

## ratio\_db, db2ratio

Returns power ratio given dB.

    my $power_ratio = ratio_db(3); #2

## dbi\_dbd, dbd2dbi

Returns dBi given dBd.  Converts the given antenna gain in dBd to dBi. 

    my $eirp = dbi_dbd($erp);

## dbd\_dbi, dbi2dbd

Returns dBd given dBi. Converts the given antenna gain in dBi to dBd.

    my $erp = dbd_dbi($eirp);

## dipole\_gain

Returns the gain of a reference half-wave dipole in dBi.

    my $dipole_gain = dipole_gain(); #always 2.15 dBi

## fsl\_hz\_m, fsl\_mhz\_km, fsl\_ghz\_km, fsl\_mhz\_mi

Return power loss in dB given frequency and distance in the specified units of measure

    my $free_space_loss = fsl_mhz_km($mhz, $km); #returns dB

# SEE ALSO

["log10" in POSIX](https://metacpan.org/pod/POSIX#log10), ["nearest" in Math::Round](https://metacpan.org/pod/Math::Round#nearest)

[https://en.wikipedia.org/wiki/Decibel#Power\_quantities](https://en.wikipedia.org/wiki/Decibel#Power_quantities)

[https://en.wikipedia.org/wiki/Free-space\_path\_loss#Free-space\_path\_loss\_in\_decibels](https://en.wikipedia.org/wiki/Free-space_path_loss#Free-space_path_loss_in_decibels)

[https://en.wikipedia.org/wiki/Dipole\_antenna#Dipole\_as\_a\_reference\_standard](https://en.wikipedia.org/wiki/Dipole_antenna#Dipole_as_a_reference_standard)

# AUTHOR

Michael R. Davis, MRDVT

# COPYRIGHT AND LICENSE

MIT LICENSE

Copyright (C) 2023 by Michael R. Davis
