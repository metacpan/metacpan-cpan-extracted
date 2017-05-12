use strict;
use warnings;
use ExtUtils::MakeMaker;

use 5.006;  # State Perl version dependency as early as possible

WriteMakefile(
    NAME                => 'Package::Data::Inheritable',
    AUTHOR              => 'Giacomo Cerrai <gcerrai@cpan.org>',
    VERSION_FROM        => 'lib/Package/Data/Inheritable.pm',
    ABSTRACT_FROM       => 'lib/Package/Data/Inheritable.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp'       => 0,
        'Exporter'   => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Package-Data-Inheritable-*' },
);
