use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sledge::Engine',
    AUTHOR              => 'Tomohiro IKEBE <ikebe@shebang.jp>',
    VERSION_FROM        => 'lib/Sledge/Engine.pm',
    ABSTRACT_FROM       => 'lib/Sledge/Engine.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Sledge::Hammer' => '1.0',
        'Module::Pluggable' => '3.1',
        'Class::Inspector' => '1.16',
        'Sledge::Utils' => '0.02',
        'String::CamelCase' => '0.01',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Sledge-Engine-*' },
);
