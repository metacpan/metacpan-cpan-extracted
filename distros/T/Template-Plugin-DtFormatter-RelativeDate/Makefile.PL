use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Plugin::DtFormatter::RelativeDate',
    AUTHOR              => 'bokutin <bokuin@cpan.org>',
    VERSION_FROM        => 'lib/Template/Plugin/DtFormatter/RelativeDate.pm',
    ABSTRACT_FROM       => 'lib/Template/Plugin/DtFormatter/RelativeDate.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'                => 0,
        'Test::Base'                => 0,
        'Template'                  => 0,
        'DateTime::Format::Natural' => 0,
        'Locale::Maketext'          => 0,
        'DateTime::Format::MySQL'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Plugin-DtFormatter-RelativeDate-*' },
);
