use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Plack::Session::Store::Redis',
    AUTHOR              => q{Lee Aylward <leedo@cpan.org>},
    VERSION_FROM        => 'lib/Plack/Session/Store/Redis.pm',
    ABSTRACT_FROM       => 'lib/Plack/Session/Store/Redis.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'JSON'  => 0,
        'Redis' => 0,
        'Plack' => 0,
        'Plack::Session' => 0,
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Plack-Session-Store-Redis-*' },
);
