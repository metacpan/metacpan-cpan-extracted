package Software::GenoScan::Segmentor;

use warnings;
use strict;

require XSLoader;
require Exporter;

our $VERSION = "v1.0.4";
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ("all" => [ qw(
	segmentize
) ] );
our @EXPORT_OK = (@{ $EXPORT_TAGS{"all"} });

XSLoader::load('Software::GenoScan::Segmentor', $VERSION);

return 1;
