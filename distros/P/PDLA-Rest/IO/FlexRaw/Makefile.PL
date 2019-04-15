use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => "PDLA::IO::FlexRaw",
     'VERSION_FROM' => '../../lib/PDLA/Rest.pm',
    (eval ($ExtUtils::MakeMaker::VERSION) >= 6.57_02 ? ('NO_MYMETA' => 1) : ()),
);
