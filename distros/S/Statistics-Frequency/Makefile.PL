require 5.002;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	 => 'Statistics::Frequency',
    MAN3PODS    => {},  # Pods will be built by installman.
    VERSION_FROM => 'lib/Statistics/Frequency.pm',
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
