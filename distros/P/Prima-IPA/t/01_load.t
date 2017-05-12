#! /usr/bin/perl
# $Id$

use strict;
use warnings;

my @namespace;

BEGIN { @namespace = qw(
	Prima::IPA::Geometry::rotate90
	Prima::IPA::Geometry::rotate180
	Prima::IPA::Geometry::mirror
	Prima::IPA::Geometry::shift_rotate

	Prima::IPA::Global::close_edges
	Prima::IPA::Global::fill_holes
	Prima::IPA::Global::area_filter
	Prima::IPA::Global::identify_contours
	Prima::IPA::Global::identify_scanlines
	Prima::IPA::Global::fft
	Prima::IPA::Global::band_filter

	Prima::IPA::Local::crispening
	Prima::IPA::Local::sobel
	Prima::IPA::Local::GEF
	Prima::IPA::Local::SDEF
	Prima::IPA::Local::deriche
	Prima::IPA::Local::filter3x3
	Prima::IPA::Local::median
	Prima::IPA::Local::unionFind
	Prima::IPA::Local::hysteresis
	Prima::IPA::Local::gaussian
	Prima::IPA::Local::laplacian
	Prima::IPA::Local::gradients
	Prima::IPA::Local::canny
	Prima::IPA::Local::nms
	Prima::IPA::Local::scale
	Prima::IPA::Local::ridge
	Prima::IPA::Local::convolution
	Prima::IPA::Local::zerocross

	Prima::IPA::Misc::split_channels
	Prima::IPA::Misc::combine_channels
	Prima::IPA::Misc::histogram

	Prima::IPA::Morphology::BWTransform
	Prima::IPA::Morphology::dilate
	Prima::IPA::Morphology::erode
	Prima::IPA::Morphology::algebraic_difference
	Prima::IPA::Morphology::watershed
	Prima::IPA::Morphology::reconstruct
	Prima::IPA::Morphology::thinning

	Prima::IPA::Point::combine
	Prima::IPA::Point::threshold
	Prima::IPA::Point::gamma
	Prima::IPA::Point::remap
	Prima::IPA::Point::subtract
	Prima::IPA::Point::mask
	Prima::IPA::Point::average
	Prima::IPA::Point::ab
	Prima::IPA::Point::exp
	Prima::IPA::Point::log
);};

use Test::More tests => 9 + @namespace;

use_ok('Prima::noX11');
use_ok('Prima::IPA');

ok( UNIVERSAL-> can($_), $_ ) for @namespace;

use_ok('Prima::IPA::Local');
use_ok('Prima::IPA::Global');
use_ok('Prima::IPA::Point');
use_ok('Prima::IPA::Region');
use_ok('Prima::IPA::Morphology');
use_ok('Prima::IPA::Misc');
use_ok('Prima::IPA::Geometry');
