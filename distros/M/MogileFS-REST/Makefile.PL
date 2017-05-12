use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MogileFS-REST',
    AUTHOR              => q{Yann Kerherve <yann@saymedia.com>},
    VERSION_FROM        => 'lib/MogileFS/REST.pm',
    ABSTRACT            => 'Prototype of MogileFS REST wrapper',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'  => 0,
        'YAML'        => 0,
        'Plack'       => 0,
        'MogileFS::Client' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MogileFS-REST-*' },
);
