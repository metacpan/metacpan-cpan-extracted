use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Redis::Queue',
    AUTHOR              => q{Alex Popiel <tapopiel+redisqueue@gmail.com>},
    VERSION_FROM        => 'lib/Redis/Queue.pm',
    ABSTRACT_FROM       => 'lib/Redis/Queue.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Redis'      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Redis-Queue-*' },
);
