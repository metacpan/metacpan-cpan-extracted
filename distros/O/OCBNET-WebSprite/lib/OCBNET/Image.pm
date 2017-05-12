###################################################################################################
# Copyright 2013/2014 by Marcel Greter
# This file is part of OCBNET-WebSprite (GPL3)
####################################################################################################
package OCBNET::Image;
####################################################################################################
# implementation agnostic image library for OCBNET-WebSprite
# will either use GD, Image::Magick or Graphics::Magick
####################################################################################################
our $VERSION = '1.0.1';
####################################################################################################

use Carp;
use strict;
use warnings;
use vars qw(@ISA);

####################################################################################################
# check if needed module is already loaded
# otherwise we try to load an implementation
####################################################################################################

# determine module
my $module;

# check for pre-loaded module first
if (eval { $OCBNET::Image::GD::VERSION }) { $module = "gd" }
elsif (eval { $OCBNET::Image::GM::VERSION }) { $module = "gm" }
elsif (eval { $OCBNET::Image::IM::VERSION }) { $module = "im" }

# check for pre-loaded library next
elsif (eval { $GD::VERSION }) { $module = "gd" }
elsif (eval { $Graphic::Magick::VERSION }) { $module = "gm" }
elsif (eval { $Image::Magick::VERSION }) { $module = "im" }

# finally try to load an implementation on my own
elsif (eval { require OCBNET::Image::GD }) { $module = "gd" }
elsif (eval { require OCBNET::Image::GM }) { $module = "gm" }
elsif (eval { require OCBNET::Image::IM }) { $module = "im" }

# fatal error if no implementation was loaded
else { die "no graphic implementation found" }

# put the correct base class implementation into place
if ($module eq "gd") { require OCBNET::Image::GD; push @ISA, qw(OCBNET::Image::GD) }
elsif ($module eq "gm") { require OCBNET::Image::GM; push @ISA, qw(OCBNET::Image::GM) }
elsif ($module eq "im") { require OCBNET::Image::IM; push @ISA, qw(OCBNET::Image::IM) }

####################################################################################################
####################################################################################################
1;