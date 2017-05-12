require 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'Parse::Plain',
    VERSION_FROM => 'lib/Parse/Plain.pm',
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
