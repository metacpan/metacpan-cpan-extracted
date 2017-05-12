package PangoConst;

use strict; # not necessary in practice.

our $VERSION = '0.03';
 
our @ISA = qw/Exporter/;
 
our @EXPORT = qw(
        PANGO_WEIGHT_ULTRALIGHT
        PANGO_WEIGHT_LIGHT
        PANGO_WEIGHT_NORMAL
        PANGO_WEIGHT_BOLD
        PANGO_WEIGHT_ULTRABOLD
        PANGO_WEIGHT_HEAVY
 
        PANGO_SCALE_XX_SMALL
        PANGO_SCALE_X_SMALL
        PANGO_SCALE_SMALL
        PANGO_SCALE_MEDIUM
        PANGO_SCALE_LARGE
        PANGO_SCALE_X_LARGE
        PANGO_SCALE_XX_LARGE
 
        PANGO_SCALE
);
 
use constant PANGO_WEIGHT_ULTRALIGHT => 200;
use constant PANGO_WEIGHT_LIGHT      => 300;
use constant PANGO_WEIGHT_NORMAL     => 400;
use constant PANGO_WEIGHT_BOLD       => 700;
use constant PANGO_WEIGHT_ULTRABOLD  => 800;
use constant PANGO_WEIGHT_HEAVY      => 900;
 
use constant PANGO_SCALE_XX_SMALL => 0.5787037037037;
use constant PANGO_SCALE_X_SMALL  => 0.6444444444444;
use constant PANGO_SCALE_SMALL    => 0.8333333333333;
use constant PANGO_SCALE_MEDIUM   => 1.0;
use constant PANGO_SCALE_LARGE    => 1.2;
use constant PANGO_SCALE_X_LARGE  => 1.4399999999999;
use constant PANGO_SCALE_XX_LARGE => 1.728;
 
use constant PANGO_SCALE => 1024;
 
1;

