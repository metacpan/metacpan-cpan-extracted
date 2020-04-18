use 5.026001;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'RedisScript',
    VERSION_FROM      => 'lib/RedisScript.pm',
    PREREQ_PM         => { },
    ABSTRACT_FROM     => 'lib/RedisScript.pm',
    AUTHOR            => 'pedro.frazao <pf.dev@netcf.org>',
    LICENSE           => 'perl',
);
