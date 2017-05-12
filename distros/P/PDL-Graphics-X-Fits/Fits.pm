package PDL::Graphics::X::Fits;

use 5.008001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.01';

#
# Simple OO fits image display built on PDL::Graphics::X
#
# 
#
# Hazen 3/05
#

use PDL;
use PDL::ImageND;
use PDL::Graphics::X;

#			
# Global variables
#				   

my $warning_message = "PDL::Graphics::X::Fits";

# hard coded display defaults

my $BORDER_WIDTH = 75;
my $BORDER_COLOR = [0, 1, 0];
my $LABEL_COLOR = [0, 1, 0];
my $MINOR_TICK_LEN = 4;
my $MAJOR_TICK_LEN = 7;
my $TICK_COLOR = [0, 1, 0];
my $WINDOW_BACKGROUND_COLOR = [0, 0, 0];

# hash for parameters associated with displaying the fits image

my %fits_params = (
	FITS_X => 100,
	FITS_Y => 100,
	MIN => undef,
	MAX => undef,
	RESCALE_X => 1.0,
	RESCALE_Y => 1.0,
	RGB => 0,
	WIN_MAX_X => 100,
	WIN_MAX_Y => 100,
	X_LABEL => 'X',
	X_MAX => 0,
	X_MIN => 0,
	X_UNIT => 'arb',
	Y_LABEL => 'Y',
	Y_MAX => 0,
	Y_MIN => 0,
	Y_UNIT => 'arb',
);

# default window options, these are just passed through to PDL::Graphics::X

my %default_options = (
	CTAB => undef,
	MIN => undef,
	MAX => undef,
	RGB => 0,
	WIN_TITLE => "X::FITS",
);

#			
# Private sub-routines
#				   

# parse options hashes

sub _parseOptions {
	my $input_options = shift;
	my $default_options = shift;

	while ( my($temp_key, $temp_value) = each %{$input_options} ) {
		if (exists $default_options->{$temp_key}) {
			$default_options->{$temp_key} = $temp_value;
		} else {
			print "$warning_message, no such option : $temp_key\n";
		}
	}
}

# given a number, figure out how many digits it is away from zero.

sub _digitsToZero{
	my $num = shift;
	my $sign = shift;

	$num = abs($num);
	my $num_d = 1;
	my $sign_d = 1;
	if($num>0.0){
		my $temp = log($num);
		if($temp < 0) { 
			$sign_d = -1;
		}
		$num_d = abs($temp)/log(10);
	}
	$num_d = ceil($num_d);
	return ($num_d, $sign_d);
}

# figure out the maximum number of digits & direction from zero of two numbers

sub _numDigits {
	my $min = shift;
	my $max = shift;

	my ($num_d_min, $sign_d_min) = _digitsToZero($min);
	my ($num_d_max, $sign_d_max) = _digitsToZero($max);

	my $num_d = $num_d_min;
	my $sign_d = $sign_d_min;
	if($num_d_max > $num_d_min){ 
		$num_d = $num_d_max; 
		$sign_d = $sign_d_max;
	}

	return ($num_d, $sign_d);
}
	
# convert number to string

sub _makeLabel {
	my $num = shift;
	my $min = shift;
	my $max = shift;
	
	my $range = $max - $min;
	my ($num_d, $sign_d) = _digitsToZero($range);
	my $text;
	if($sign_d > 0){
		my $format = "%.f";
		if($num_d < 2){
			$format = "%.1f";
		}
		$text = sprintf($format, $num);		
	} else {
		my $format = "%." . ($num_d+1) . "f";
		$text = sprintf($format, $num);
	}
	
	return $text;
}

# adjust the axis size and exponent based on the number of
# digits and sign needed to represent the axis

sub _adjustAxis{
	my $max = shift;
	my $min = shift;

	my $exp = "";

	my($digits, $sign) = _numDigits($max, $min);
	if($sign > 0){
		if($digits > 2){
			$max = $max/(10.0 ** ($digits - 1));
			$min = $min/(10.0 ** ($digits - 1));
			$exp = " x10^" . ($digits - 1);
		}
	} else {
		if($digits > 1){
			$max = $max * (10.0 ** ($digits - 1));
			$min = $min * (10.0 ** ($digits - 1));
			$exp = " x10^-" . ($digits - 1);
		}
	}
	return($max, $min, $exp);
}

# compute a reasonable number of ticks & sub-ticks for the plot
#
# this is a perl version of the PLplot function pldtik, see src/pdltik.c
#
# Copyright information for the original PLplot function is as follows :
#
#  Copyright (C) 2004  Alan W. Irwin
#
#  This file is part of PLplot.
#
#   PLplot is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Library Public License as published
#   by the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   PLplot is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Library General Public License for more details.
#
#   You should have received a copy of the GNU Library General Public License
#   along with PLplot; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#

sub _numticks {
	my $range = shift;
	my $axis_size = shift;

	# Magnitude of min/max difference to get tick spacing

	my $t1 = log(abs($range))/log(10);
    my $np = floor($t1);
    $t1 = $t1 - $np;

	# Get tick spacing

	my $t2;
	my $ns;
    if ($t1 > 0.7781512503) {
		$t2 = 2.0;
		$ns = 4;
    }
    elsif ($t1 > 0.4771212549) {
		$t2 = 1.0;
		$ns = 5;
    }
    elsif ($t1 > 0.1760912591) {
		$t2 = 5.0;
		$ns = 5;
		$np = $np - 1;
    }
    else {
		$t2 = 2.0;
		$ns = 4;
		$np = $np - 1;
    }

	# Now compute reasonable tick spacing

	my $tick = $t2 * (10.0**$np);
    my $nsubt = abs($ns);

	# adjust for very small / very large images
	
	if($axis_size < 300){
		$tick = 2*$tick;
	}

	if($axis_size > 900){
		$tick = 0.5*$tick;
	}
	
    return($tick, $nsubt);
}

# draw the image as a bitmap in the window with appropriate scale, etc...

sub _displayFits {
	my $self = shift;
	
	my $off_x = $BORDER_WIDTH;
	my $off_y = $BORDER_WIDTH;
	my $width  = $self->{Params}->{"FITS_X"} * $self->{Params}->{"RESCALE_X"};
	my $height = $self->{Params}->{"FITS_Y"} * $self->{Params}->{"RESCALE_Y"};
	my $min = $self->{Params}->{"MIN"};
	my $max = $self->{Params}->{"MAX"};
	my $to_display = rebin($self->{Fits}, $width, $height);
	if($self->{Params}->{"RGB"}){
		$to_display = $to_display->slice(":," . ($height-1) . ":0,0:2");
	} else {
		$to_display = $to_display->slice(":," . ($height-1) . ":0");
	}
	
	$self->{X_win}->imag($to_display, {DEST_X => $off_x, DEST_Y => $off_y, DEST_W => $width, DEST_H => $height, MIN => $min, MAX => $max});
}

# draw border around bitmap & hash marks & text & axis labels

sub _drawAxes {
	my $self = shift;

	my $width  = $self->{Params}->{"FITS_X"} * $self->{Params}->{"RESCALE_X"};
	my $height = $self->{Params}->{"FITS_Y"} * $self->{Params}->{"RESCALE_Y"};
	
	# draw a border around the image
	
	my $x1 = $BORDER_WIDTH - 1;
	my $x2 = $x1 + $width + 1;
	my $y1 = $BORDER_WIDTH - 1;
	my $y2 = $y1 + $height + 1;
	$self->{X_win}->rect($x1, $y1, $x2, $y2, {LINEWIDTH => 1, LINESTYLE => 0, COLOR => $BORDER_COLOR});
	
	# calculate the range & the number of ticks
	# if the range is very large or very small, we adjust & add
	# the exponent to the axis label

	my $x_exp = "";	
	my $x_max = $self->{Params}->{"X_MAX"};
	my $x_min = $self->{Params}->{"X_MIN"};
	($x_max, $x_min, $x_exp) = _adjustAxis($x_max, $x_min);
	my $x_range = $x_max - $x_min;
	my ($x_ticks, $n_x_sub_ticks) = _numticks($x_range, $width);

	my $y_exp = "";	
	my $y_max = $self->{Params}->{"Y_MAX"};
	my $y_min = $self->{Params}->{"Y_MIN"};
	($y_max, $y_min, $y_exp) = _adjustAxis($y_max, $y_min);
	my $y_range = $y_max - $y_min;
	my ($y_ticks, $n_y_sub_ticks) = _numticks($y_range, $width);

	# draw x ticks & tick labels
	
	my $cur_x = floor($x_min/($x_ticks/$n_x_sub_ticks));
	while($cur_x < $x_max){
		my $x = (($cur_x - $x_min)/$x_range) * $width + $BORDER_WIDTH;
		if($x > $BORDER_WIDTH){
			my $tick_len = $MINOR_TICK_LEN;
			if((abs($cur_x - $x_ticks * rint($cur_x/$x_ticks))) < (0.1 * $x_ticks)) {
				$tick_len = $MAJOR_TICK_LEN;
				my $label = _makeLabel($cur_x, $x_min, $x_max);
				my $l_len = length($label);
				$self->{X_win}->text($label, $x - 4.0*$l_len, $y2 + 14, 0.0, {CHARSIZE => 14, COLOR => $LABEL_COLOR});
			}
			my $xvs = pdl($x, $x);
			my $yvs = pdl($y1, $y1+$tick_len);
			$self->{X_win}->line($xvs, $yvs, {LINEWIDTH => 1, LINESTYLE => 0, COLOR => $TICK_COLOR});
			$xvs = pdl($x, $x);
			$yvs = pdl($y2, $y2-$tick_len);
			$self->{X_win}->line($xvs, $yvs, {LINEWIDTH => 1, LINESTYLE => 0, COLOR => $TICK_COLOR});
		}
		$cur_x += ($x_ticks/$n_x_sub_ticks);
	}

	# draw y ticks & tick labels
	
	my $cur_y = floor($y_min/($y_ticks/$n_y_sub_ticks));
	while($cur_y < $y_max){
		my $y = $height - (($cur_y - $y_min)/$y_range) * $height + $BORDER_WIDTH;
		if($y < ($BORDER_WIDTH + $height)){
			my $tick_len = $MINOR_TICK_LEN;
			if((abs($cur_y - $y_ticks * rint($cur_y/$y_ticks))) < (0.1 * $y_ticks)) {
				$tick_len = $MAJOR_TICK_LEN;
				my $label = _makeLabel($cur_y, $y_min, $y_max);
				my $l_len = length($label);
				$self->{X_win}->text($label, $x1 - 8.0*$l_len - 4, $y + 5, 0.0, {CHARSIZE => 14, COLOR => $LABEL_COLOR});
			}
			my $xvs = pdl($x1, $x1+$tick_len);
			my $yvs = pdl($y, $y);
			$self->{X_win}->line($xvs, $yvs, {LINEWIDTH => 1, LINESTYLE => 0, COLOR => $TICK_COLOR});
			$xvs = pdl($x2, $x2-$tick_len);
			$yvs = pdl($y, $y);
			$self->{X_win}->line($xvs, $yvs, {LINEWIDTH => 1, LINESTYLE => 0, COLOR => $TICK_COLOR});
		}
		$cur_y += ($y_ticks/$n_y_sub_ticks);
	}
	
	# draw axis labels

	my $label = $self->{Params}->{"X_LABEL"} . " (" . $self->{Params}->{"X_UNIT"} . ")" . $x_exp;
	my $l_len = length($label);
	$self->{X_win}->text($label, -5.0*$l_len + 0.5*(2.0*$BORDER_WIDTH + $width), $y2 + 0.5*$BORDER_WIDTH + 6, 0.0, {CHARSIZE => 18, COLOR => $LABEL_COLOR});
	
	$label = $self->{Params}->{"Y_LABEL"} . " (" . $self->{Params}->{"Y_UNIT"} . ")" . $y_exp;
	$l_len = length($label);
	$self->{X_win}->text($label, $x1 - 0.8*$BORDER_WIDTH - 4, -5.0*$l_len + 0.5*(2.0*$BORDER_WIDTH + $width), -90.0, {CHARSIZE => 18, COLOR => $LABEL_COLOR});

}

# handles making a "pretty" string for wedge labels

sub _wedgeLabel {
	my $num = shift;

	my $label;
	if(($num < 9999)&&($num > 0.01)){
		if($num > 1) { $label = sprintf("%d", $num); }
		elsif($num > 0.1) { $label = sprintf("%.2f", $num); }
		else { $label = sprintf("%.3f", $num); }
	} elsif ($num == 0.0) {
		 $label = "0.0";
	} else {
		$label = sprintf("%.1e", $num);
	}
	
	return $label;
}

# draw a color "wedge" & associated text

sub _drawWedge {
	my $self = shift;

	my $width  = $self->{Params}->{"FITS_X"} * $self->{Params}->{"RESCALE_X"};
	my $height = $self->{Params}->{"FITS_Y"} * $self->{Params}->{"RESCALE_Y"};
	
	my $wedge = 255 - yvals(zeroes(20,256));
	if($height < 256){
		$wedge = rebin($wedge, 20, $height);
	}
	
	my $x1 = $width + 1.5 * $BORDER_WIDTH - 10;
	my $x2 = $x1 + 20;
	my $y1 = $BORDER_WIDTH + 0.5 * $height - 0.5 * $wedge->dim(1);
	my $y2 = $y1 + $wedge->dim(1);

	$self->{X_win}->imag($wedge, {DEST_X => $x1, DEST_Y => $y1});
	$self->{X_win}->rect($x1-1, $y1-1, $x2, $y2, {LINEWIDTH => 1, LINESTYLE => 0, COLOR => $BORDER_COLOR});

	my $label = _wedgeLabel($self->{Params}->{"MIN"});
	my $l_len = length($label);
	$self->{X_win}->text($label, $x1 - 4.0*$l_len + 10, $y2 + 15, 0.0, {CHARSIZE => 14, COLOR => $LABEL_COLOR});

	$label = _wedgeLabel($self->{Params}->{"MAX"});
	$l_len = length($label);
	$self->{X_win}->text($label, $x1 - 4.0*$l_len + 10, $y1 - 4, 0.0, {CHARSIZE => 14, COLOR => $LABEL_COLOR});	
}

#				   
# Object Methods  
#				   

# creates a new fits window object

sub new {
	my $self = shift;
	my $fits = shift;
	my $opt = shift;

	my %fits_p = %fits_params;
	my %wopt = %default_options;
	if(defined($opt)){ _parseOptions($opt, \%wopt); }

	if(defined($fits)){
		if($fits->hdr->{NAXIS} > 1){
			my $X_win = PDL::Graphics::X->new({WIN_TITLE => $wopt{"WIN_TITLE"}, SIZE_X => 100, SIZE_Y => 100, BACK_COLOR => $WINDOW_BACKGROUND_COLOR});
			if(defined($X_win)){
			
				# size window appropriately
				
				my ($max_x, $max_y) = ($X_win->winsize())[2,3];
				my $fits_x = $fits->hdr->{NAXIS1};
				my $fits_y = $fits->hdr->{NAXIS2};
				my $re_scale = 1.0;
				while(($fits_x * $re_scale) > ($max_x - 2*$BORDER_WIDTH)) { $re_scale = 0.6 * $re_scale; }
				while(($fits_y * $re_scale) > ($max_y - 2*$BORDER_WIDTH)) { $re_scale = 0.6 * $re_scale; }
				$X_win->resize(($fits_x * $re_scale + 2*$BORDER_WIDTH), ($fits_y * $re_scale + 2*$BORDER_WIDTH));

				# read the parameters from the fits image into the parameters hash
				
				$fits_p{"FITS_X"} = $fits_x;
				$fits_p{"FITS_Y"} = $fits_y;
				$fits_p{"MIN"} = $wopt{"MIN"};
				$fits_p{"MAX"} = $wopt{"MAX"};
				unless(defined($fits_p{"MIN"})){ $fits_p{"MIN"} = (minmax($fits))[0]; }				
				unless(defined($fits_p{"MAX"})){ $fits_p{"MAX"} = (minmax($fits))[1]; }
				$fits_p{"RESCALE_X"} = $re_scale;
				$fits_p{"RESCALE_Y"} = $re_scale;
				$fits_p{"WIN_MAX_X"} = $max_x;
				$fits_p{"WIN_MAX_Y"} = $max_y;
				
				if(defined($fits->hdr->{CTYPE1})) { $fits_p{"X_LABEL"} = $fits->hdr->{CTYPE1}; }
				if(defined($fits->hdr->{CUNIT1})) { $fits_p{"X_UNIT"} = $fits->hdr->{CUNIT1}; }
				if(defined($fits->hdr->{CTYPE2})) { $fits_p{"Y_LABEL"} = $fits->hdr->{CTYPE2}; }
				if(defined($fits->hdr->{CUNIT2})) { $fits_p{"Y_UNIT"} = $fits->hdr->{CUNIT2}; }

				my $x_delt = 1.0;
				my $y_delt = 1.0;
				if(defined($fits->hdr->{CDELT1})) { $x_delt = $fits->hdr->{CDELT1}; }
				if(defined($fits->hdr->{CDELT2})) { $y_delt = $fits->hdr->{CDELT2}; }
				my $x_zero = 0.0;
				my $y_zero = 0.0;				
				if(defined($fits->hdr->{CRPIX1})) { $x_zero = $fits->hdr->{CRPIX1}; }
				if(defined($fits->hdr->{CRPIX2})) { $y_zero = $fits->hdr->{CRPIX2}; }
				$fits_p{"X_MAX"} = $x_delt * ($fits_x - $x_zero);
				$fits_p{"X_MIN"} = $x_delt * (      0 - $x_zero);
				$fits_p{"Y_MAX"} = $y_delt * ($fits_y - $y_zero);
				$fits_p{"Y_MIN"} = $y_delt * (      0 - $y_zero);
				
				if($wopt{"RGB"}) { 
					if($fits->dim(2) == 3) {
						$fits_p{"RGB"} = 1;
					} else {
						print "$warning_message, attempt to display non-RGB image as RGB\n";
					}
				}
				my $param = {X_win => $X_win, Fits => $fits, Params => \%fits_p};
				$self = bless($param, $self);
				
				if(defined($wopt{"CTAB"})){
					$X_win->ctab($wopt{"CTAB"});
				}
				_displayFits($self);
				_drawAxes($self);
				unless($fits_p{"RGB"}) { _drawWedge($self); }
				return $self;
			} else {
				print "$warning_message, X initialize failed\n";
			}
		} else {
			print "$warning_message, 1 or 0 dimensional FITS display is not supported\n";
		}
	} else {
		print "$warning_message, FITS image is undefined\n";
	}
	return undef;
}

# returns mouse coordinates in the picture coordinate system

sub cursor {
	my $self = shift;

	my $width  = $self->{Params}->{"FITS_X"} * $self->{Params}->{"RESCALE_X"};
	my $height = $self->{Params}->{"FITS_Y"} * $self->{Params}->{"RESCALE_Y"};
	my $x_range = $self->{Params}->{"X_MAX"} - $self->{Params}->{"X_MIN"};
	my $y_range = $self->{Params}->{"Y_MAX"} - $self->{Params}->{"Y_MIN"};

	while(1){
		my($x, $y) = $self->{X_win}->cursor();
		if(defined($x)){
			if(($x > ($BORDER_WIDTH-1))&&($x < ($width+$BORDER_WIDTH-1))){
				if(($y > ($BORDER_WIDTH-1))&&($y < ($width+$BORDER_WIDTH-1))){
					$x = (($x - $BORDER_WIDTH)/$width) * $x_range + $self->{Params}->{"X_MIN"};
					$y = (1.0 - (($y - $BORDER_WIDTH)/$height)) * $y_range + $self->{Params}->{"Y_MIN"};
					return ($x, $y);
				}
			}
		} else {
			print "$warning_message, unable to get mouse coordinates\n";
			return (0,0);
		}
	}
}

# catch object destroy for any clean-up

sub DESTROY {
	my $self = shift;
}

1;
__END__

=head1 NAME

PDL::Graphics::X::Fits - OO X Windows fits image display

=head1 SYNOPSIS

  use PDL;
  use PDL::Graphics::LUT;
  use PDL::Graphics::X::Fits;

  my $fits = rfits("PDL-2.4.1/m51.fits");
  my $win1 = PDL::Graphics::X::Fits->new($fits, {WIN_TITLE => "In Color", CTAB => cat(lut_data("idl5"))});
  my ($x, $y) = $win1->cursor();

=head1 DESCRIPTION

A OO X Windows fits image display module built on PDL::Graphics::X. This module draws fits image with appropriately labeled axises & tick marks, similar to those drawn by PGPLOT. Once the image has been displayed, the cursor method will return the location of the next mouse click in image coordinates.

Options recognized

       CTAB - color table to use when displaying the image (greyscale is default)
        MIN - minimum value to display (image minimum is default)
        MAX - maximum value to display (image maximum is default)
        RGB - set to 1 to display a RGB fits (expects the image to be in the form (x, y, RGB))
  WIN_TITLE - a title for the window (default is "X::FITS")

=head2 EXPORT

None by default.

=head1 SEE ALSO

PDL::Graphics::X

=head1 KNOWN ISSUES

Since PDL::Graphics::X doesn't handle rotated text very well, the y-axis label looks pretty ugly.

=head1 BUGS

...

=head1 AUTHOR

Hazen Babcock, hbabcockos1 at mac.com

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Hazen Babcock

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
