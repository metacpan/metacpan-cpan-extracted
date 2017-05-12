use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::SSH::Tunnel',
    AUTHOR              => q{Satoshi Yagi <satoshi.yagi@yahoo.com>},
    VERSION_FROM        => 'lib/Net/SSH/Tunnel.pm',
    ABSTRACT_FROM       => 'lib/Net/SSH/Tunnel.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'Log::Log4perl' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-SSH-Tunnel-*' },
);