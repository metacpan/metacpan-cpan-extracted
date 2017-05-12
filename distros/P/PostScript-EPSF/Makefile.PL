require 5.002;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'PostScript::EPSF',
    VERSION_FROM => 'EPSF.pm',
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

