use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sledge::Plugin::DebugLeakChecker',
    AUTHOR              => 'syushi matsumoto <matsumoto@alink.co.jp>',
    VERSION_FROM        => 'lib/Sledge/Plugin/DebugLeakChecker.pm',
    ABSTRACT_FROM       => 'lib/Sledge/Plugin/DebugLeakChecker.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Template' => 0,
        'Devel::Leak::Object' => 0,
        'Sledge::Plugin::BeforeOutput' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sledge-Plugin-DebugLeakChecker-*' },
);
