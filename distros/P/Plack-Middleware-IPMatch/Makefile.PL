use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Plack::Middleware::IPMatch',
    AUTHOR              => q{fukai <iakuf@163.com>},
    VERSION_FROM        => 'lib/Plack/Middleware/IPMatch.pm',
    ABSTRACT_FROM       => 'lib/Plack/Middleware/IPMatch.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'Plack'         => 0,
        'Net::IP::XS'   => 0,
        'Net::IP::Match::Trie'   => 0,
    },
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/iakuf/Plack-Middleware-IPMatch/issues',
            repository  => 'https://github.com/iakuf/Plack-Middleware-IPMatch.git',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Plack-Middleware-IPMatch-*' },
);
