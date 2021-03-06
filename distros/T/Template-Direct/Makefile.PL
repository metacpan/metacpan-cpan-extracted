use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Direct',
    AUTHOR              => 'Martin Owens <doctormo@cpan.org>',
    VERSION_FROM        => 'lib/Template/Direct.pm',
    ABSTRACT_FROM       => 'lib/Template/Direct.pm',
    PL_FILES            => {},
    PREREQ_PM => {
      'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Direct-*' },
);
