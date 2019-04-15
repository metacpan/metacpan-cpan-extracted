use strict;
use warnings;
# Use this as a template for the Makefile.PL for
# any external PDLA module.

use ExtUtils::MakeMaker;
my @pack = ([qw(imagergb.pd ImageRGB PDLA::ImageRGB)]);
my %hash = pdlpp_stdargs(@pack);
$hash{'OBJECT'} .= ' ppm_quant$(OBJ_EXT)';
$hash{'clean'}{FILES} .= ' ppm_quant$(OBJ_EXT)';

# Add genpp rule
undef &MY::postamble; # suppress warning
*MY::postamble = sub { pdlpp_postamble(@pack); };

WriteMakefile(%hash);
