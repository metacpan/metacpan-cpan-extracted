BEGIN { require 5 }

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME            => 'Module-ConfigureRequires',
    AUTHOR          => 'Father Chrysostomos <sprout at, um, cpan dot org>',
    VERSION_FROM    => 'lib/Module/ConfigureRequires.pm',
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                            TAR => 'COPYFILE_DISABLE=1 tar' },
    clean              => { FILES => 'Module-ConfigureRequires-*' },
);

