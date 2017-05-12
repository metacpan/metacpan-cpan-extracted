use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => "Regexp::Chinese::TradSimp",
    VERSION_FROM => "lib/Regexp/Chinese/TradSimp.pm",
    PREREQ_PM => { 'Encode::HanConvert' => 0 },
    EXE_FILES => [ "bin/dets" ],
);
