use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'OAuth::Simple',
    AUTHOR              => q{Alexander Babenko <foxcool@cpan.org>},
    VERSION_FROM        => 'lib/OAuth/Simple.pm',
    ABSTRACT_FROM       => 'lib/OAuth/Simple.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'LWP::UserAgent'=> 0,
        'JSON'          => 0,
        'Carp'          => 0,
    },
    META_MERGE          => {
        resources => {
            repository => 'https://github.com/Foxcool/OAuth-Simple',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'OAuth-Simple-*' },
);
