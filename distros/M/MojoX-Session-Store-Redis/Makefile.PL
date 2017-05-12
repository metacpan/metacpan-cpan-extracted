use utf8;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MojoX::Session::Store::Redis',
    AUTHOR              => q{BlueT - Matthew Lien - 練喆明 <BlueT@BlueT.org>},
    VERSION_FROM        => 'lib/MojoX/Session/Store/Redis.pm',
    ABSTRACT_FROM       => 'lib/MojoX/Session/Store/Redis.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'Redis'                 => 0,
        'namespace::clean'      => 0,
        'MojoX::Session::Store' => 0,
        'JSON'                  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MojoX-Session-Store-Redis-*' },
);
