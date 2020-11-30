package PDF::API2::XS::ImagePNG;

use strict;
use warnings;

our $VERSION = '1.002'; # VERSION

require XSLoader;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(split_channels unfilter);

XSLoader::load();

1;
