use strict;
use warnings;

use ExtUtils::MakeMaker;

&WriteMakefile(
    NAME          => "RPM::Header::PurePerl",
    AUTHOR        => 'Troels Liebe Bentsen <tlb@rapanden.dk>',
    VERSION_FROM  => 'lib/RPM/Header/PurePerl.pm',
    ABSTRACT_FROM => 'lib/RPM/Header/PurePerl.pm',
    PL_FILES      => {},
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
