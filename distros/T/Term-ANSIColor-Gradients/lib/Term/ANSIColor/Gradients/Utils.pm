package Term::ANSIColor::Gradients::Utils ;

use strict ;
use warnings ;
use Exporter 'import' ;

our $VERSION   = '0.10' ;
our @EXPORT_OK = qw(build_contrast intensity_shift) ;

# ---------------------------------------------------------------------------
# ANSI 256 color index to RGB table, built once at load time
# ---------------------------------------------------------------------------

my @CUBE = (0, 95, 135, 175, 215, 255) ;

my @SYS_RGB =
	(
	[  0,  0,  0], [128,  0,  0], [  0,128,  0], [128,128,  0],
	[  0,  0,128], [128,  0,128], [  0,128,128], [192,192,192],
	[128,128,128], [255,  0,  0], [  0,255,  0], [255,255,  0],
	[  0,  0,255], [255,  0,255], [  0,255,255], [255,255,255],
	) ;

my @ANSI_RGB ;

{
$ANSI_RGB[$_] = $SYS_RGB[$_] for 0 .. 15 ;

for my $i (16 .. 231)
	{
	my $n = $i - 16 ;
	my $r = int($n / 36) ;
	my $g = int(($n % 36) / 6) ;
	my $b = $n % 6 ;
	$ANSI_RGB[$i] = [$CUBE[$r], $CUBE[$g], $CUBE[$b]] ;
	}

for my $i (232 .. 255)
	{
	my $v = 8 + ($i - 232) * 10 ;
	$ANSI_RGB[$i] = [$v, $v, $v] ;
	}
}

# ---------------------------------------------------------------------------

sub rgb_to_hsv
{
my ($r, $g, $b) = @_ ;

$r /= 255.0 ;
$g /= 255.0 ;
$b /= 255.0 ;

my $max = $r ;
$max = $g if $g > $max ;
$max = $b if $b > $max ;

my $min = $r ;
$min = $g if $g < $min ;
$min = $b if $b < $min ;

my $delta = $max - $min ;
my $v     = $max ;
my $s     = $max > 0 ? $delta / $max : 0 ;
my $h     = 0 ;

if ($delta > 0)
	{
	if    ($max == $r) { $h = 60 * (($g - $b) / $delta) }
	elsif ($max == $g) { $h = 60 * (($b - $r) / $delta) + 120 }
	else               { $h = 60 * (($r - $g) / $delta) + 240 }

	$h += 360 if $h < 0 ;
	}

return ($h, $s, $v) ;
}

# ---------------------------------------------------------------------------

sub hsv_to_rgb
{
my ($h, $s, $v) = @_ ;

if ($s == 0)
	{
	my $c = int($v * 255 + 0.5) ;
	return ($c, $c, $c) ;
	}

$h /= 60.0 ;
my $i = int($h) ;
my $f = $h - $i ;
my $p = $v * (1 - $s) ;
my $q = $v * (1 - $s * $f) ;
my $t = $v * (1 - $s * (1 - $f)) ;

my ($r, $g, $b) ;
if    ($i == 0) { ($r, $g, $b) = ($v, $t, $p) }
elsif ($i == 1) { ($r, $g, $b) = ($q, $v, $p) }
elsif ($i == 2) { ($r, $g, $b) = ($p, $v, $t) }
elsif ($i == 3) { ($r, $g, $b) = ($p, $q, $v) }
elsif ($i == 4) { ($r, $g, $b) = ($t, $p, $v) }
else            { ($r, $g, $b) = ($v, $p, $q) }

return (int($r * 255 + 0.5), int($g * 255 + 0.5), int($b * 255 + 0.5)) ;
}

# ---------------------------------------------------------------------------

sub nearest_ansi
{
my ($tr, $tg, $tb) = @_ ;

my $best_idx  = 0 ;
my $best_dist = 1e18 ;

for my $i (0 .. 255)
	{
	my ($r, $g, $b) = @{$ANSI_RGB[$i]} ;
	my $d = ($r - $tr) ** 2 + ($g - $tg) ** 2 + ($b - $tb) ** 2 ;

	if ($d < $best_dist)
		{
		$best_dist = $d ;
		$best_idx  = $i ;
		}
	}

return $best_idx ;
}

# ---------------------------------------------------------------------------

sub build_contrast
{
my ($idx) = @_ ;

my ($r, $g, $b) = @{$ANSI_RGB[$idx]} ;
my ($h, $s, $v) = rgb_to_hsv($r, $g, $b) ;

# Greyscale: no meaningful hue, flip luminance instead
if ($s < 0.15)
	{
	my $lum  = 0.299 * $r + 0.587 * $g + 0.114 * $b ;
	my $cv   = $lum < 128 ? 1.0 : 0.0 ;
	my ($nr, $ng, $nb) = hsv_to_rgb($h, $s, $cv) ;

	return nearest_ansi($nr, $ng, $nb) ;
	}

# Chromatic: complementary hue, same saturation and value
my $ch = ($h + 180) % 360 ;
my ($nr, $ng, $nb) = hsv_to_rgb($ch, $s, $v) ;

return nearest_ansi($nr, $ng, $nb) ;
}

# ---------------------------------------------------------------------------

sub intensity_shift
{
my ($idx, $delta) = @_ ;

my ($r, $g, $b) = @{$ANSI_RGB[$idx]} ;
my ($h, $s, $v) = rgb_to_hsv($r, $g, $b) ;

$v += $delta * 0.05 ;
$v = 0 if $v < 0 ;
$v = 1 if $v > 1 ;

my ($nr, $ng, $nb) = hsv_to_rgb($h, $s, $v) ;

return nearest_ansi($nr, $ng, $nb) ;
}

1 ;

__END__

=head1 NAME

Term::ANSIColor::Gradients::Utils - color conversion and contrast utilities

=head1 SYNOPSIS

 use Term::ANSIColor::Gradients::Utils qw(build_contrast intensity_shift) ;

 my $contrast_idx  = build_contrast(196) ;   # complement of bright red
 my $darker_idx    = intensity_shift(196, -4) ;

=head1 DESCRIPTION

Internal utility module providing ANSI 256-color index conversions and the
algorithms used by the gradient data modules and CLI tool.

=head2 build_contrast($ansi_index)

Returns the ANSI 256-color index whose hue is complementary (180 degree hue
rotation) to the input color, with luminance adjusted to ensure readability.
For near-grey input (saturation < 0.15) a luminance flip is used instead.

=head2 intensity_shift($ansi_index, $delta)

Returns a new ANSI index representing the same hue and saturation as the
input but with brightness (HSV value) shifted by C<$delta * 0.05>.  Positive
values lighten, negative values darken.  Result is clamped to [0, 1] before
the nearest-ANSI search.

=head1 AUTHOR

Nadim Khemir <nadim.khemir@gmail.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself (Artistic License 2.0 or GPL 3.0).

=cut
