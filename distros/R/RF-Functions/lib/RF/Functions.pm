package RF::Functions;
use strict;
use warnings;
use POSIX qw{log10};
use base qw{Exporter};
use Math::Round qw{};

our $VERSION   = '0.04';
our @EXPORT_OK = qw(
                    db_ratio ratio2db
                    ratio_db db2ratio
                    fsl_hz_m fsl_mhz_km fsl_ghz_km fsl_mhz_mi
                    dbd_dbi dbi_dbd dbd2dbi dbi2dbd dipole_gain
                   );

=head1 NAME

RF::Functions - Perl Exporter for Radio Frequency (RF) Functions

=head1 SYNOPSIS

  use RF::Functions qw{db_ratio ratio_db};
  my $db = db_ratio(2); #~3dB

=head1 DESCRIPTION

RF::Functions is a lib for common RF function.  I plan to add additional functions as I need them.

=head1 FUNCTIONS

=head2 db_ratio, ratio2db

Returns dB given a numerical power ratio.

  my $db = db_ratio(2);   #+3dB
  my $db = db_ratio(1/2); #-3dB

=cut

sub db_ratio {10 * log10(shift())};

sub ratio2db {10 * log10(shift())};

=head2 ratio_db, db2ratio

Returns power ratio given dB.

  my $power_ratio = ratio_db(3); #2

=cut

sub ratio_db {10 ** (shift()/10)};

sub db2ratio {10 ** (shift()/10)};

=head2 dbi_dbd, dbd2dbi

Returns dBi given dBd.  Converts the given antenna gain in dBd to dBi. 

  my $eirp = dbi_dbd($erp);

=cut

sub dbi_dbd {shift() + dipole_gain()};

sub dbd2dbi {shift() + dipole_gain()};

=head2 dbd_dbi, dbi2dbd

Returns dBd given dBi. Converts the given antenna gain in dBi to dBd.

  my $erp = dbd_dbi($eirp);

=cut

sub dbd_dbi {shift() - dipole_gain()};

sub dbi2dbd {shift() - dipole_gain()};

=head2 dipole_gain

Returns the gain of a reference half-wave dipole in dBi.

  my $dipole_gain = dipole_gain(); #always 2.15 dBi

=cut

sub dipole_gain {2.15}; #FCC 10Log(1.64) ~ 2.15

=head2 fsl_hz_m, fsl_mhz_km, fsl_ghz_km, fsl_mhz_mi

Return power loss in dB given frequency and distance in the specified units of measure

  my $free_space_loss = fsl_mhz_km($mhz, $km); #returns dB

=cut

sub fsl_hz_m {
  my ($f, $d) = @_;
  return _fsl_constant($f, $d, -147.55);
}

sub fsl_mhz_km {
  my ($f, $d) = @_;
  return _fsl_constant($f, $d, 32.45);
}

sub fsl_ghz_km {
  my ($f, $d) = @_;
  return _fsl_constant($f, $d, 92.45);
}

sub fsl_mhz_mi {
  my ($f, $d) = @_;
  return _fsl_constant($f, $d, 36.58); #const = 20*log10(4*pi/c) where c = 0.18628237 mi/μs (aka mile * MHz)
}

sub _fsl_constant {
  my $freq  = shift; die("Error: Frequency must be positive number") unless $freq > 0;
  my $dist  = shift; die("Error: Distance must be non-negative number") unless $dist >= 0;
  my $const = shift or die("Error: Constant required");
  #Equvalent to 20log($freq) + 20log($dist) + $const for performance
  return Math::Round::nearest(0.001, 20 * log10($freq * $dist) + $const);
}

=head1 SEE ALSO

L<POSIX/log10>, L<Math::Round/nearest>

L<https://en.wikipedia.org/wiki/Decibel#Power_quantities>

L<https://en.wikipedia.org/wiki/Free-space_path_loss#Free-space_path_loss_in_decibels>

L<https://en.wikipedia.org/wiki/Dipole_antenna#Dipole_as_a_reference_standard>

=head1 AUTHOR

Michael R. Davis, MRDVT

=head1 COPYRIGHT AND LICENSE

MIT LICENSE

Copyright (C) 2022 by Michael R. Davis

=cut

1;
