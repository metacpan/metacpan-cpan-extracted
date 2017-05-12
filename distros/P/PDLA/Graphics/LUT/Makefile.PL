use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
 'NAME'         => 'PDLA::Graphics::LUT',
 'VERSION_FROM' => '../../Basic/Core/Version.pm',
 'DIR'          => [ 'tables', 'ramps' ],
 (eval ($ExtUtils::MakeMaker::VERSION) >= 6.57_02 ? ('NO_MYMETA' => 1) : ()),
);
