# ======================================================================
# Project:             Web Counter Parser
# Project Leader:      Peter Wise
# Module component:    Parse::WebCounter
# ----------------------------------------------------------------------
# Module name:         Parse::WebCounter
# Module state:        First Release
# Module notes:        Parses Image counters
#
# Module filename:     Parse::WebCounter.pm
# ----------------------------------------------------------------------
# Version  Author      Date       Comment
# ~~~~~~~~ ~~~~~~~~~~~ ~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 0.01     P.J.Wise    08/10/2004 Initial Version
# 0.02     P.J.Wise    18/12/2006 First Release to CPAN
#
# ----------------------------------------------------------------------
# CVS:
#    ID:        $Id: WebCounter.pm,v 1.13 2006/12/19 20:42:27 peter Exp $
#
# ----------------------------------------------------------------------
# Notes:
# ~~~~~~
# Module parses web counter images using GD and supplies the numeric
# value represented by the image. Useful if you have a cron keeping
# track of the number of hits you are getting per day and you don't
# have real logs to go by. You will need copies of the images
# representing the individual digits, or a strip of all of them for
# it to compare to as the module is not very bright it does a simple
# image comparison as apposed to any sophisticated image analysis
# (This is not designed, nor intended to be a Captcha solver).
# You will need to have GD compiled with support for the image format
# that your counters are displayed in. (Usually gif)
# ======================================================================
package Parse::WebCounter;

use 5.008;
use strict;
use warnings;

use GD;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use Parse::WebCounter ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( readImage readDigit
        
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
        
);



use vars qw($VERSION);

$VERSION = '0.02';


#-------------------------------------------------------------------------------
# Parse::WebCounter::new()
#-------------------------------------------------------------------------------
# Purpose:
# Constructor
#-------------------------------------------------------------------------------
# Parameters:
# takes a Hash or hashref of module parameters recognises the following
# options
#    Name         Default     Notes
#    DIGITWIDTH   15          Width of individual digit
#    DIGITHEIGHT  20          Height of individual digit
#    STRIPORDER   1234567890  Order of digits in the image strip (if used)
#    MODE         STRIP       Use image strip or "DIGITS"
#    TYPE         gif         File type of images
#    PATTERN      a           Pattern dir
#    UNKOWNCHAR   char        Character to use if digit not matched
#
# (Image file loaded = PATTERN/STRIP.TYPE or PATTER/0.TYPE -> 9.TYPE)
# -----------------------------------------------------------------------------
# Returns:
# ObjectRef     Self
#
#-------------------------------------------------------------------------------
sub new{
	my $proto = shift;
	my @args = @_;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self,$class);

	#Defaults...
	$self->{DIGITWIDTH} = 15;
	$self->{DIGITHEIGHT}= 20;
	$self->{STRIPORDER} = "1234567890";
	$self->{MODE}       = "STRIP";
	$self->{TYPE}       = "gif";
	$self->{PATTERN}    = "a";
	$self->{UNKNOWNCHAR}= "_";

	my $rprops;
	if (ref($args[0]) eq 'HASH'){
		my $rtgash = %{$args[0]};
		$rprops = $self->_cap_hash($args[0]);
	}else{
		$rprops = $self->_cap_hash({ @args });
	}
	foreach my $k (qw(DIGITWIDTH DIGITHEIGHT STRIPORDER TYPE PATTERN UNKNOWNCHAR)){
		if (exists($rprops->{$k})){
			$self->{$k} = $rprops->{$k};
		}
	}
	#need to be special with MODE
	if (exists($rprops->{MODE})){
		$rprops->{MODE} =~ tr/a-z/A-Z/;
		if ($rprops->{MODE} ne "STRIP" && $rprops->{MODE} ne "DIGITS"){
			warn "Invalid mode " . $rprops->{MODE} . " using default\n";
		}else{
			$self->{MODE} = $rprops->{MODE};
		}
	}


	$self->_init();
	
	return $self;
}

#-------------------------------------------------------------------------------
# Parse::WebCounter::_init()
#-------------------------------------------------------------------------------
# Purpose:
# Internal function to initialise the class data (loads image strip data)
#-------------------------------------------------------------------------------
# Parameters:
# None - pulls data from class object and $ENV
#
#-------------------------------------------------------------------------------
# Returns:
# Nothing
#
#-------------------------------------------------------------------------------
sub _init{
	my $self = shift;

	if ($self->{MODE} eq "STRIP"){
		$self->_loadStripImage();
	}else{
		$self->_loadDigitImages();
	}
}



#-------------------------------------------------------------------------------
# Parse::WebCounter::_cap_hash(<hash>)
#-------------------------------------------------------------------------------
# Purpose:
# automagically convert the hash it is given into capitalised keys so users
# of the module can pass any capitalisation they like as module options
#-------------------------------------------------------------------------------
# Parameters:
# HashRef
#
#-------------------------------------------------------------------------------
# Returns:
# HashRef  all the keys CAPITALISED
#
#-------------------------------------------------------------------------------
sub _cap_hash {
	my $self = shift;
	my $rhash = shift;
	my %hash = map {
		my $k = $_;
		my $v = $rhash->{$k};
		$k =~ tr/a-z/A-Z/;
		$k => $v;
	} keys(%{$rhash});
	return \%hash;
}

#-------------------------------------------------------------------------------
# Parse::WebCounter::_loadStripImage()
#-------------------------------------------------------------------------------
# Purpose:
# Loads the images required for matching from a single strip of digits in 
# one image and breaks it up into individual ones.
#-------------------------------------------------------------------------------
# Parameters: None, but uses following class data
# digitwidth   int     The width of the digits in the strip
# digitheight  int     The height of the digits in the strip
# strip order  string  the "order" of the digits ie "1234567890"
# type         string  The "type" of image, essentially the extension
# pattern      string  the pattern directory to load from relative to current
#-------------------------------------------------------------------------------
# Returns:
# Nothing, But stores the image data in the class.
#
#-------------------------------------------------------------------------------
sub _loadStripImage{
	my $self = shift;
	my %reference_images;
	my $filename = $self->{PATTERN} . "/strip." . $self->{TYPE};
	my $imagestrip = GD::Image->new($filename);
	my $left = 0;
	my @striporder = split('',$self->{STRIPORDER});
	foreach my $number (@striporder){
		my $digit = GD::Image->new($self->{DIGITWIDTH},
					   $self->{DIGITHEIGHT});
		$digit->copy($imagestrip,0,0,$left,0,$self->{DIGITWIDTH}
						    ,$self->{DIGITHEIGHT});
		$left += $self->{DIGITWIDTH};
		$reference_images{$number} = $digit;
	}
	$self->{REFIMAGES} = \%reference_images;
}

#-------------------------------------------------------------------------------
# Parse::WebCounter::_loadDigitImages()
#-------------------------------------------------------------------------------
# Purpose:
# Loads the images required for matching from separate digit files
# 
#-------------------------------------------------------------------------------
# Parameters: None, but uses following class data
# digitwidth   int     The width of the digits in the strip
# digitheight  int     The height of the digits in the strip
# strip order  string  the "order" of the digits ie "1234567890"
# type         string  The "type" of image, essentially the extension
# pattern      string  the pattern directory to load from relative to current
# 
#-------------------------------------------------------------------------------
# Returns:
# Nothing, But stores the image data in the class.
#
#-------------------------------------------------------------------------------
sub _loadDigitImages{
	my $self = shift;
	my %reference_images;
	my @striporder = split('',$self->{STRIPORDER});
	foreach my $number (@striporder){
		$reference_images{$number} = GD::Image->new( $self->{PATTERN} . "/" . $number . "." . $self->{TYPE});
	}

	$self->{REFIMAGES} = \%reference_images;

}

#-------------------------------------------------------------------------------
# Parse::WebCounter::readImage(image[,xoffset[,yoffset]])
#-------------------------------------------------------------------------------
# Purpose:
# Reads the given image to determine the value of all the digits within
# 
#-------------------------------------------------------------------------------
# Parameters: 
# image        gdimage  The image object to evaluate
# xoffset      int      Offset value to use (in case image has a border)
# yoffset      int      Offset value
#
# Values from classdata used
# digitwidth   int     The width of the digits in the strip
# digitheight  int     The height of the digits in the strip
# 
#-------------------------------------------------------------------------------
# Returns:
# The parsed value of the image.
#
#-------------------------------------------------------------------------------
sub readImage{
	my $self = shift;
	my $image = shift;
	my $xoffset = shift || 0;
	my $yoffset = shift || 0;
	my ($width,$height) = $image->getBounds();
	my $return = "";
	for (my $i = $xoffset; $i < $width ; $i += $self->{DIGITWIDTH}){
		my $digit = GD::Image->new($self->{DIGITWIDTH}, 
					   $self->{DIGITHEIGHT});
		$digit->copy($image,0,0,$i,$yoffset,
			     $self->{DIGITWIDTH},
			     $self->{DIGITHEIGHT});
		$return .= $self->readDigit($digit);
	}
	return $return;

}


#-------------------------------------------------------------------------------
# Parse::WebCounter::readDigit(image)
#-------------------------------------------------------------------------------
# Purpose:
# Reads the given image digit to determine the value
# 
#-------------------------------------------------------------------------------
# Parameters: 
# image        gdimage  The image object to evaluate
#
# Values from classdata used
# REFIMAGES	hashref	 The stored reference images for comparison
# UNKNOWNCHAR	char     The character to return for an unmatched digit ('_')
# 
#-------------------------------------------------------------------------------
# Returns:
# The parsed value of the digit, or the UNKNOWNCHAR if the digit could not
# be matched.
#
#-------------------------------------------------------------------------------
sub readDigit{
	my $self = shift;
	my $image = shift;
	foreach my $number (keys(%{$self->{REFIMAGES}})){
		if ($image->compare($self->{REFIMAGES}->{$number}) == 0){
			return $number;
		}
	}
	return $self->{UNKNOWNCHAR};
}

1;

__END__

=head1 NAME

Parse::WebCounter - Read the integer value of a web counter image

=head1 SYNOPSIS

    use Parse::WebCounter;

    my $cp = new Parse::WebCounter();
    my $imagetocheck = GD::Image->new("webcounterimage.gif");
    my $value = $cp->readImage($imagetocheck);
    print "Counter value is: $value\n";

=head1 ABSTRACT

Parse::WebCounter - Read the integer value of a web counter image

=head1 DESCRIPTION

This module parses web counter images using GD and supplies the numeric
value represented by the image. Useful if you have a cron keeping
track of the number of hits you are getting per day and you do not
have real logs to go by. You will need copies of the images
representing the individual digits, or a strip of all of them for
it to compare to as the module is not very bright it does a simple
image comparison as apposed to any sophisticated image analysis
(This is not designed, nor intended to be a Captcha solver).

=head2 PACKAGE METHODS

new Parse::WebCounter

new Parse::WebCounter([<Class options>])

Creates and returns a new C<Parse::WebCounter> object.

It can be created with the following class options that override the 
class defaults. They are listed here with their default options.

=over 5

=item C<< DIGITWIDTH => 15 >>

The width of the individual digit items.

=item C<< DIGITHEIGHT => 20 >>

The height of the individual digit items.

=item C<< STRIPORDER => '1234567890' >>

The order of the individual digits within a reference image strip.

=item C<< MODE => 'STRIP' >>

There are two choices for this, C<STRIP> and C<DIGITS>. If strip is used
then the module will attempt to load and break down a image strip of 
reference images (left to right, not top to bottom) named I<strip.gif>. If
the digits option is given then the module will instead look for
individual digit images named I<0.gif> to I<9.gif>

=item C<< TYPE => 'gif' >>

The image format to use. Most webcounters use gif format so that is
the default value. Essentially it will be loading filename.C< I<TYPE> >

=item C<< PATTERN => 'a' >>

The 'pattern' to use. The module will look under this directory name for 
the I<strip.gif> or I<0.gif>-I<9.gif> files. Allowing you to support 
multiple webcounters (through alternative class instances).

=item C<< UNKNOWNCHAR => '_' >>

The character to return in place of an unmatched digit.

=back

=head2 OBJECT METHODS

=over 5

=item ->readImage($image)

Reads the digits in the given image (or at least attempts to) and returns
the "value" of the image as a string. If it fails to determine the value
of any individual digit in the image the character C<_> will be returned
or whatever character has be passed as C<UNKNOWNCHAR> in the constructor.

=item ->readDigit($image)

This is intended as an internal function which is in fact called multiple
times once with each "digit" of the full image to be parsed. It should
be called with a single digit image and it will return the "value" of that
image or the C<UNKNOWNCHAR> if it fails to match it.

=back

=head1 CAVEATS

You will need to have GD compiled with support for the image format
that your counters are displayed in. (Usually gif)

=head1 TO DO

Add support to automaticaly retrieve reference images to the package

=head1 ACKNOWLEDGEMENTS

Thanks to Simon Proctor for prodding me with a sharp stick until I actually 
got on with something. :-)

=head1 COPYRIGHT

Copyright (C) 2006 Peter Wise.  All Rights Reserved

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AVAILABILITY

For the latest version check my website L<http://www.vagnerr.com/> or
visit your favourite CPAN server.

=head1 AUTHOR

Peter Wise (Vagnerr) - L<http://www.vagnerr.com/>

=head1 SEE ALSO

L<GD>


=cut

