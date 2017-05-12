use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Package::Builder',
    AUTHOR              => 'Jean-Marie RENOUARD <jmrenouard@gmail.com>',
    VERSION_FROM        => 'lib/Package/Builder.pm',
    ABSTRACT_FROM       => 'lib/Package/Builder.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Text::Template' => 1.44,
	'Archive::Tar' 
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Package-Builder-*' },
);
