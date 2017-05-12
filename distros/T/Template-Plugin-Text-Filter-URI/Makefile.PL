use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Plugin::Text::Filter::URI',
    AUTHOR              => 'Moritz Onken <onken@houseofdesign.de>',
    VERSION_FROM        => 'lib/Template/Plugin/Text/Filter/URI.pm',
    ABSTRACT_FROM       => 'lib/Template/Plugin/Text/Filter/URI.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Text::Filter::URI' => 0,
	'Template' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Plugin-Text-Filter-URI-*' },
);
