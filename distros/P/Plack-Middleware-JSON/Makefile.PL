use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Plack::Middleware::JSON',
    AUTHOR              => q{fukai <iakuf@163.com>},
    VERSION_FROM        => 'lib/Plack/Middleware/JSON.pm',
    ABSTRACT_FROM       => 'lib/Plack/Middleware/JSON.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'Plack'         => 0,
        'JSON::XS'   => 0,
        'URI::Escape'   => 0,
    },
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/iakuf/Plack-Middleware-JSON/issues',
            repository  => 'https://github.com/iakuf/Plack-Middleware-JSON.git',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Plack-Middleware-JSON-*' },
);
