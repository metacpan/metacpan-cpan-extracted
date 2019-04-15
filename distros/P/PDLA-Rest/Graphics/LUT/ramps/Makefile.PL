use strict;
use warnings;

# files ending in .fits will end up in
# PDLA/Graphics/LUT/ramps/
use ExtUtils::MakeMaker;

my @tables = glob( "*.fits" );

WriteMakefile(
  'NAME'         => 'PDLA::Graphics::LUT::ramps::DATA',   
  'VERSION_FROM' => '../../../lib/PDLA/Rest.pm',
  'PM' => {
      (map {($_,'$(INST_LIBDIR)/'.$_)} @tables)
   },
   (eval ($ExtUtils::MakeMaker::VERSION) >= 6.57_02 ? ('NO_MYMETA' => 1) : ()),
);
