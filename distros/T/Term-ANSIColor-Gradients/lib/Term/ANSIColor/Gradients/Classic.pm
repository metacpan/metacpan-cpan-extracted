package Term::ANSIColor::Gradients::Classic ;

use strict ;
use warnings ;

our $VERSION = '0.10' ;

our @GREY    = map { 232 + $_ } (0..23) ;
our @RED     = map { 160 + $_ } (0..15) ;
our @ORANGE  = map { 166 + $_ } (0..9) ;
our @BLUE    = map { 19  + $_ } (0..10) ;
our @GREEN   = map { 34  + $_ } (0..10) ;
our @YELLOW  = map { 226 + $_ } (0..9) ;
our @CYAN    = map { 37  + $_ } (0..10) ;
our @MAGENTA = map { 127 + $_ } (0..10) ;

our @GREY_CONTRAST    = (15,15,15,15,15,15,15,15,15,15,15,15,15,0,0,0,0,0,0,0,0,0,0,0) ;
our @RED_CONTRAST     = (44,42,41,40,40,10,32,80,79,78,77,119,26,74,116,115) ;
our @ORANGE_CONTRAST  = (32,80,79,78,77,119,26,74,116,115) ;
our @BLUE_CONTRAST    = (142,184,11,53,52,88,130,172,214,90,88) ;
our @GREEN_CONTRAST   = (127,125,124,124,160,202,164,162,161,160,160) ;
our @YELLOW_CONTRAST  = (12,63,105,147,189,0,15,15,15,15) ;
our @CYAN_CONTRAST    = (124,160,202,164,162,161,160,160,9,13,199) ;
our @MAGENTA_CONTRAST = (34,40,82,25,73,72,71,113,155,19,67) ;

our %GRADIENTS =
	(
	GREY    => \@GREY,
	RED     => \@RED,
	ORANGE  => \@ORANGE,
	BLUE    => \@BLUE,
	GREEN   => \@GREEN,
	YELLOW  => \@YELLOW,
	CYAN    => \@CYAN,
	MAGENTA => \@MAGENTA,
	) ;

our %CONTRAST =
	(
	GREY    => \@GREY_CONTRAST,
	RED     => \@RED_CONTRAST,
	ORANGE  => \@ORANGE_CONTRAST,
	BLUE    => \@BLUE_CONTRAST,
	GREEN   => \@GREEN_CONTRAST,
	YELLOW  => \@YELLOW_CONTRAST,
	CYAN    => \@CYAN_CONTRAST,
	MAGENTA => \@MAGENTA_CONTRAST,
	) ;

1 ;
