use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'PDLA::Lib::GIS',
    VERSION_FROM => '../../lib/PDLA/Rest.pm',
    DIR =>  [ qw/ Proj / ],
    (eval ($ExtUtils::MakeMaker::VERSION) >= 6.57_02 ? ('NO_MYMETA' => 1) : ()),
);

