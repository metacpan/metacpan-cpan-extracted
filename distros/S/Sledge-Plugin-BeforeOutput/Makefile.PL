use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sledge::Plugin::BeforeOutput',
    AUTHOR              => 'syushi matsumoto <matsumoto@alink.co.jp>',
    VERSION_FROM        => 'lib/Sledge/Plugin/BeforeOutput.pm',
    ABSTRACT_FROM       => 'lib/Sledge/Plugin/BeforeOutput.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Class::Trigger' => 0,
        'Sledge::Pages::Base' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sledge-Plugin-BeforeOutput-*' },
);
