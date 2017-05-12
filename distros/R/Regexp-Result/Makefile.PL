use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Regexp::Result',
    AUTHOR              => q{Daniel Perrett <perrettdl@googlemail.com>},
    VERSION_FROM        => 'lib/Regexp/Result.pm',
    ABSTRACT_FROM       => 'lib/Regexp/Result.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
	META_MERGE    => {
                resources => {
                        repository => 'http://github.com/pdl/Regexp-Result',
                        bugtracker => 'http://github.com/pdl/Regexp-Result/issues',
                        homepage   => 'http://github.com/pdl/Regexp-Result',
                },
        },
    MIN_PERL_VERSION    => '5.010',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Moo' => 0,
        'Sub::Name' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Regexp-Result-*' },
);
