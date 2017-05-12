# Psychrometry.pm
# Calculate psychrometric measures in moist air
package Physics::Psychrometry;

use 5.008007;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Physics::Psychrometry ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.2';

# based on http://www.bae.uky.edu/gates/psych/PTM/dbrh2al.c
#The dry-bulb temperature (C)       =? 24.6
#The relative humidity (%)          =? 68
#The air pressure (kPa)             =? 102
# e is 2.104209
#The dewpoint temperature (C)       = 18.324036
#The wet-bulb temperature (C)       = 20.326262
#The humidity ratio                 = 0.013101
#The enthalpy (kJ/kg)               = 58.095979
#The vapor pressure (kPa)           = 2.104209
#The degree of saturation (%)       = 67.325951
#The saturated vapor pressure (kPa) = 3.094426
#The specific air volume (m3/kg)    = 0.855627
#The density of moist air (kg/m^3)  = 1.184046
#The saturated humidity ratio       = 0.019460
#The specific humidity (ratio)      = 0.012932
#The absolute humidity (kg/m3)      = 0.015312

my $C14	= 6.54;
my $C15	= 14.526;
my $C16	= 0.7389;
my $C17	= 0.09486;
my $C18	= 0.4569;

sub dbdp2wb
{
    my ($db, $dp, $p) = @_;

    my $i = 0;
    my $e = t2es($dp);
    my $w = e2w($e, $p);
    my $wb1 = $dp;
    my $wb2 = $db;
    my $twb = $wb1 + ($wb2 - $wb1) / 2;
    while ((($wb2 - $wb1) > 0.001) && ($i < 1000)) 
    {
	my $tw = dbwb2w($db, $twb, $p);
	if($tw > $w) 
	{		# /* overestimate the wetblb temperature */
	    $wb2 = $twb; #		/* the wb should be between wb1,twb */
	    $twb = $wb1 + ($wb2 - $wb1) / 2;
	}
	else 
	{		#	/* underestimate the wb */
	    $wb1 = $twb;
	    $twb = $wb1 + ($wb2 - $wb1) / 2;
	} 
    }
    my $wb = $twb;
    return $wb;
}

sub dbw2h
{
    my ($db, $w) = @_;
    return 1.006 * $db + $w * (2501.0 + 1.805 * $db);
}

sub e2w
{
    my ($e, $p) = @_;
    
    return 0.62198 * $e / ($p - $e);
}

sub dbwb2w
{
    my ($db, $wb, $p) = @_;

    
    my $estar = t2es($wb);
    my $wstar = e2w($estar, $p);
    my $t1 = (2501 - 2.381 * $wb) * $wstar -($db - $wb);
    my $t2 = 2501 + 1.805 * $db - 4.186 * $wb;
    return $t1 / $t2;
}

sub dbrh2e
{
    my ($db, $rh) = @_;

    return t2es($db) * $rh;
}

sub rhws2ds
{
    my ($rh, $ws) = @_;

    return $rh / (1 + (1 - $rh) * $ws / 0.62198);
}

sub t2es
{
    my ($t) = @_;

    $t += 273.15;
    if($t > 273.15)
    {
	return exp(-5800.2206 / $t + 1.3914993 - .048640239 * $t + (.41764768e-4) * pow($t, 2.0) - (.14452093e-7) * pow($t, 3.0) + 6.5459673 * log($t)) / 1000.0;
    }
    else
    {
      return exp(-5674.5359 / $t + 6.3925247 - (.9677843e-2) * $t + (.62215701e-6) * pow($t, 2.0) + (.20747825e-8) * pow($t, 3.0) - (.9484024e-12) * pow($t, 4.0) + 4.1635019 * log($t)) / 1000.0;
  }
}

sub e2dp
{
    my ($e) = @_;

    my $af = log($e);
    my $s1 = pow($af, 2.0);
    my $s2 = pow($af, 3.0);
    my $s3 = pow($e, 0.1984);
    my $t1 = $C14 + $C15 * $af + $C16 * $s1 + $C17 * $s2 + $C18 * $s3;
    my $t2 = 6.09 + 12.608 * $af + 0.4959 * $s1;
    return $t1 > 0 ? $t1 : $t2;
}

sub pow
{
    my ($n, $p) = @_;

    return $n ** $p;
}

sub dbw2v
{
    my ($db, $w, $p) = @_;

    $db += 273.15;
    return (287.055 * $db * ( 1 + 1.6078 * $w)) / ($p * 1000.0);
}

sub wv2da
{
    my ($w, $v) = @_;

    return (1 + $w) / $v;
}

sub es2ws
{
    my ($es, $p) = @_;

    return e2w($es, $p);
}

sub w2q
{
    my ($w) = @_;

    return $w / (1 + $w);
}

sub wv2X
{
    my ($w, $v) = @_;

    return $w / $v;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Physics::Psychrometry - Perl extension for calculating Psychrometric 
 measures for moist air

=head1 SYNOPSIS

  use Physics::Psychrometry;
  my $db = 24.6; # C
  my $rh = 0.68; # RH 0.0 to 1.0
  my $p = 102;   # kPa

  my $e = Physics::Psychrometry::dbrh2e($db, $rh);
  my $dp = Physics::Psychrometry::e2dp($e);
  my $wb = Physics::Psychrometry::dbdp2wb($db, $dp, $p);
  my $w = Physics::Psychrometry::e2w($e, $p);
  my $h = Physics::Psychrometry::dbw2h($db, $w);
  my $es = Physics::Psychrometry::t2es($db);
  my $v = Physics::Psychrometry::dbw2v($db, $w, $p);
  my $ws = Physics::Psychrometry::es2ws($es, $p);
  my $ds = Physics::Psychrometry::rhws2ds($rh, $ws);
  my $da = Physics::Psychrometry::wv2da($w, $v);
  my $q = Physics::Psychrometry::w2q($w);
  my $x = Physics::Psychrometry::wv2X($w, $v);


=head1 DESCRIPTION

Calculates a variety of Psychrometric values for moist air
Blah blah blah.

=head2 EXPORT

None by default.

=head1 METHODS

=head2 dbrh2e

Convert dry bulb (C) and Relative Humidity (0.0 to 1.0) to vapor pressure (kPa)

    my $e = Physics::Psychrometry::dbrh2e($db, $rh);

=head2 e2dp

Convert vapor pressure (kPa) to Dewpoint (C)

    my $dp = Physics::Psychrometry::e2dp($e);

=head2 dbdp2wb

Convert dry bulb (C), Dewpoint (C) and airpressure (kPa) to wet bulb (C)

    my $wb = Physics::Psychrometry::dbdp2wb($db, $dp, $p);

=head2 e2w

Convert vapor pressure (kPa) and airpressure (kPa) to humidity ratio 

    my $w = Physics::Psychrometry::e2w($e, $p);

=head2 dbw2h

Convert dry bulb (C) and humidity ratio to enthalpy (kJ/kg)   

    my $h = Physics::Psychrometry::dbw2h($db, $w);

=head2 t2es

Convert dry bulb (C) to saturated vapor pressure (kPa)

    my $es = Physics::Psychrometry::t2es($db);

=head2 dbw2v

Convert dry bulb (C) and humidity ratio to specific air volume (m3/kg)

    my $v = Physics::Psychrometry::dbw2v($db, $w, $p);

=head2 es2ws

Convert saturated vapor pressure (kPa) to saturated humidity ratio 

    my $ws = Physics::Psychrometry::es2ws($es, $p);

=head2 rhws2ds

Convert Relative Humidity (0.0 to 1.0) and saturated humidity ratio to degree of saturation (0.0 to 1.0)

    my $ds = Physics::Psychrometry::rhws2ds($rh, $ws);

=head2 wv2da

Convert humidity ratio and specific air volume (m3/kg) to density of moist air (kg/m^3)

    my $da = Physics::Psychrometry::wv2da($w, $v);

=head2 w2q

Convert humidity ratio to specific humidity (ratio)

    my $q = Physics::Psychrometry::w2q($w);

=head2 wv2X

Convert humidity ratio and specific air volume (m3/kg) to absolute humidity (kg/m3)

    my $x = Physics::Psychrometry::wv2X($w, $v);


=head1 SEE ALSO

Based on http://www.bae.uky.edu/gates/psych/PTM/dbrh2al.c

=head1 AUTHOR

Mike McCauley, E<lt>mikem@airspayce.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Mike McCauley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
